`timescale 1ns / 1ps

// delay = 2 cycle

module AGU_F(
    input CLK,
    input en_in,
    input rst,
    input padding_in,              // 0: PW Mode, 1: DW Mode
    input [7:0] AGU_F_initial_in, // Y initial
    input [6:0] width_in_in,    // Map Width (0~127)
    input [6:0] width_out_in,
    input [1:0] stride_in,      // Stride
    input [1:0] AGU_offset_X_in,// DW Max Offset
    input [8:0] AGU_offset_Y_in,// PW Max Offset (last channel's first addr)
    output reg [7:0] faddr,
    output reg boundary,
    output reg done
    ); 
    
    ////////// input buffer //////////
    reg en;
    reg padding;
    reg [7:0] AGU_F_initial;
    reg [6:0] width_in;
    reg [6:0] width_out;
    reg [1:0] stride;
    reg [1:0] AGU_offset_X;
    reg [8:0] AGU_offset_Y;
    always@(posedge CLK) begin
        en <= en_in;
        padding <= padding_in;
        AGU_F_initial <= AGU_F_initial_in;
        width_in <= width_in_in;
        width_out <= width_out_in;
        stride <= stride_in;
        AGU_offset_X <= AGU_offset_X_in;
        AGU_offset_Y <= AGU_offset_Y_in;
    end
    ////////// input buffer end //////////
    
    // ch_stride define
    wire [7:0] ch_stride = width_in + 1; //width + 1 (Max 128)
    
    // adder delay chain
    reg [1:0] adder_en;
    always@(posedge CLK) begin
        if(rst) begin
            adder_en <= 0;
        end
        else begin
            adder_en <= {adder_en[0], en};
        end
    end

    ////////// Stage 1 //////////
    reg [8:0] offset_Y, next_offset_Y;
    reg s1_done;
    reg s2_en;
    always@(posedge CLK) begin
        s2_en <= s1_done & en;
    end
    //counter offset_Y
    always@(*) begin
        if (padding == 1) begin
            next_offset_Y = 0;
            s1_done = 1;
        end
        else begin
            if (offset_Y < AGU_offset_Y) begin
                next_offset_Y = offset_Y + ch_stride;
                s1_done = 0;
            end
            else begin
                next_offset_Y = 0;
                s1_done = 1;
            end
        end
    end
    always@(posedge CLK) begin        
        if(rst) begin
            offset_Y <= 0;
        end
        else begin
            if(en) begin
                offset_Y <= next_offset_Y;
            end
            else begin
                offset_Y <= offset_Y;
            end
        end
    end

    //adder
    reg [8:0] adder_1;
    always@(posedge CLK) begin
        if(rst) begin
            adder_1 <= 0;
        end
        else begin
            if(adder_en[0]) begin
                adder_1 <= AGU_F_initial + offset_Y;
            end
            else begin
                adder_1 <= adder_1;
            end
        end
    end
    ////////// Stage 1 end //////////

    ////////// Stage 2 //////////
    reg [1:0] offset_X, next_offset_X;
    reg s2_done;
    reg s3_en;
    always@(posedge CLK) begin
        s3_en <= s2_done & s2_en;
    end
    //counter offset_X
    always@(*) begin
        if (offset_X < AGU_offset_X) begin
            next_offset_X = offset_X + 1;
            s2_done = 0;
        end
        else begin
            next_offset_X = 0;
            s2_done = 1;
        end
    end
    always@(posedge CLK) begin
        if(rst) begin
            offset_X <= 0;
        end
        else begin
            if(s1_done) begin
                offset_X <= next_offset_X;
            end
            else begin
                offset_X <= offset_X;
            end
        end
    end

    //adder
    reg [8:0] adder_2;  
    always@(posedge CLK) begin
        if(rst) begin
            adder_2 <= 0;
        end
        else begin
            if(adder_en[0]) begin
                adder_2 <= adder_1 + offset_X;
            end
            else begin
                adder_2 <= adder_2;
            end
        end
    end
    ////////// Stage 2 end //////////

    ////////// Stage 3 //////////
    reg [7:0] x_count,next_x_count;
    reg signed [7:0] X, next_X;
    reg s3_done;
    //counter X & x_count
    always@(*) begin
        // Default Assignments (防止 Latch)
        next_X = X;
        next_x_count = x_count;
        s3_done = 0;
        if (x_count < width_out) begin
            next_X = X + stride;
            next_x_count = x_count + 1;
        end
        else begin
            next_X = X;
            next_x_count = x_count;
            s3_done = 1;
        end
    end
    always@(posedge CLK) begin
        if(rst) begin
            X <= 0 - padding_in;
            x_count <= 0;
        end
        else begin
            if(s3_en) begin
                X <= next_X;
                x_count <= next_x_count;
            end
            else begin
                X <= X;
                x_count <= x_count;
            end
        end
    end
    
    //adder
    always@(posedge CLK) begin
        if(rst) begin
            faddr <= AGU_F_initial;
        end
        else begin
            if(adder_en[1]) begin
                faddr <= $signed({1'b0, adder_2}) + X;
            end
            else begin
                faddr <= faddr;
            end
        end
    end
    ////////// Stage 3 end //////////
    
    //boundary signal
    wire [7:0] addr_X = ($signed({1'b0, adder_2}) + X) - AGU_F_initial;
    wire boundary_cond = ( (addr_X == 255) || (addr_X > width_in) ) ? 1 : 0;
    always@(posedge CLK) begin
        if ( (padding == 1) && boundary_cond) begin
            boundary <= 1;
        end
        else boundary <= 0;
    end
    
    //done logic
    always@(posedge CLK) begin
        if( s3_done && s3_en) begin
            done <= 1;
        end
        else begin
            done <= 0;
        end 
    end
    
endmodule 