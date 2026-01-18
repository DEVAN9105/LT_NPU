`timescale 1ns / 1ps

// delay 1

module AGU_W(
    input CLK,
    input en,
    input rst,
    input [11:0] AGU_W_initial,
    input [5:0] width_out, //64(0~63) => conv 1
    input [7:0] ch_out,// 256(0~191) => channel
    input [8:0] AGU_L, //exat length [bias,weight]
    output reg [11:0] Waddr,
    output reg done
    );
    
    //counter
    reg [7:0] ch,next_ch;
    reg [11:0] addr,next_addr;
    reg [8:0] offset,next_offset;
    reg [5:0] width,next_width;
    reg next_done;
    
    //AGU Logic
    always@(*) begin
        //avoid latch
        next_width = width;
        next_addr = addr;
        next_offset = offset;
        next_ch = ch;
        next_done = done;
        
        //counter logic
        if(offset < (AGU_L - 1)) begin
            next_offset = offset + 1;
        end
        else begin
            next_offset = 0;
            if(width < width_out) begin
                next_ch = ch;
                next_addr = addr;
                next_width = width + 1;
            end
            else begin
                next_width = 0;
                if(ch < ch_out) begin
                    next_addr = addr + AGU_L;
                    next_ch = ch + 1;
                end
                else begin
                    next_ch = ch;
                    next_addr = addr;
                    next_done = 1;
                end
            end
        end
    end
    
    //FSM
    always@(posedge CLK) begin
        if(rst == 1) begin
            addr <= 0;
            ch <= 0;
            offset <= 0;
            width <= 0;
            Waddr <= 0;
            done <= 0;
        end
        else begin
            if(en == 1) begin
                ch <= next_ch;
                addr <= next_addr;
                width <= next_width;
                offset <= next_offset;
                Waddr <= AGU_W_initial + addr + offset;
                done <= next_done;
            end
            else begin
                ch <= ch;
                addr <= addr;
                width <= width;
                offset <= offset;
                Waddr <= Waddr;
                done <= done;
            end
        end
    end
    
endmodule
