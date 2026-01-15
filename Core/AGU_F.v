`timescale 1ns / 1ps

module AGU_F(
    input CLK,
    input en,
    input rst,
    input padding,           // 0: PW Mode, 1: DW Mode
    input [7:0] AGU_initial, // Y initial
    input [6:0] width_in,    // Map Width (0~127)
    input [7:0] ch_in,       // DW ch addr end
    input [1:0] AGU_stride,  // Stride
    input [1:0] AGU_offset_X,// DW Max Offset
    input [8:0] AGU_offset_Y,// PW Max Offset (last channel's first addr)
    output reg [7:0] faddr,
    output reg boundary,
    output reg done
    ); 
    
    wire [7:0] ch_stride = width_in + 1; //width + 1 (Max 128)
    
    // Counters
    reg [7:0] X, next_X;
    reg [8:0] Y, next_Y;
    reg [1:0] offset_X, next_offset_X;
    reg [8:0] offset_Y, next_offset_Y;

    //Boundary Logic (DW & MaxPooling & conv_1)
    reg [8:0] addr_X; //real addr
    reg [8:0] addr_Y; //real addr
    always@(*) begin
        addr_Y = Y + offset_Y;
        if(padding == 1) begin
            if((X + offset_X) == 0 || (X + offset_X) > ch_stride) begin
                addr_X = X + offset_X;
            end
            else begin
                addr_X = (X - 1) + offset_X;
            end
        end
        else begin
            addr_X = X + offset_X;
        end
    end
    
    //boundary signal
    always@(*) begin
        if (padding == 1) begin
            if ( ((X + offset_X) == 0) || ((X + offset_X) > ch_stride) ) boundary = 1;
            else boundary = 0;
        end
        else boundary = 0;
    end
    
    // AGU Logic
    reg next_done;
    always@(*) begin
        // Default Assignments (防止 Latch)
        next_X = X;
        next_Y = Y;
        next_offset_X = offset_X;
        next_offset_Y = offset_Y;
        next_done = done;
        if ((offset_Y < AGU_offset_Y) && (~padding)) begin
                next_offset_Y = offset_Y + ch_stride;
                //next_Y = Y + 1;
        end
        else begin
            //next_Y = Y;
            next_offset_Y = 0;
            if(offset_X < AGU_offset_X) begin
                next_offset_X = offset_X + 1;
                next_Y = Y;
            end
            else begin
                next_offset_X = 0;
                if( (X + offset_X) < (ch_stride + (padding << 1) - 1) ) begin //DW stride
                    next_X = X + AGU_stride;
                    next_Y = Y;
                end
                else begin
                    next_X = 0;
                    if(Y < ch_in) begin
                        next_Y = Y + ch_stride;
                    end
                    else begin
                        next_Y = Y;
                        next_done = 1;
                    end
                end
            end
        end
    end
    
    
    // FSM & Output
    always@(posedge CLK) begin
        if(rst) begin
            X <= 0;
            Y <= 0;
            offset_X <= 0;
            offset_Y <= 0;
            faddr <= AGU_initial;
            done <= 0;
        end
        else if(en) begin
            X <= next_X;
            Y <= next_Y;
            offset_X <= next_offset_X;
            offset_Y <= next_offset_Y;
            done <= next_done;
            
            // --- Faddr Generation ---
            if (boundary) begin // DW
                faddr <= 0;
            end
            else begin // PW
                faddr <= AGU_initial + addr_X + addr_Y;
            end
        end
    end
    
endmodule 
