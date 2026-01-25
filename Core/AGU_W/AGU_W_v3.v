`timescale 1ns / 1ps

// delay 1

module AGU_W(
    input CLK,
    input en,
    input rst,
    input [11:0] AGU_W_initial_in,
    input [5:0] width_out_in, //64(0~63) => conv 1
    input [8:0] kernel_L_in, //exat length [bias,weight]
    output reg [11:0] Waddr,
    output reg done
    );
    
    ////////// input buffer //////////
    reg [11:0] AGU_W_initial;
    reg [5:0] width_out;
    reg [8:0] kernel_L;
    always@(posedge CLK) begin
        AGU_W_initial <= AGU_W_initial_in;
        width_out <= width_out_in;
        kernel_L <= kernel_L_in;
    end
    ////////// input buffer end //////////
    
    ////////// stage 1 //////////
    reg [8:0] offset,next_offset;
    reg s1_done;
    reg s2_en;
    always@(posedge CLK) begin
        s2_en <= s1_done & en;
    end
    //counter
    always@(*) begin
        //avoid latch
        next_offset = offset;
        s1_done = 0;
        
        //counter logic
        if(offset < (kernel_L - 1)) begin
            next_offset = offset + 1;
        end
        else begin
            next_offset = 1;
            s1_done = 1;
        end
    end
    always@(posedge CLK) begin
        if(rst == 1) begin
            offset <= 0;
        end
        else begin
            if(en == 1) begin
                offset <= next_offset;
            end
            else begin
                offset <= offset;
            end
        end
    end

    // adder
    always@(posedge CLK) begin
        if(rst == 1) begin
            Waddr <= 0;
        end
        else begin
            if(en) begin
                Waddr <= AGU_W_initial + offset;
            end
            else begin
                Waddr <= Waddr;
            end
        end
    end
    ////////// stage 1 end //////////

    ////////// stage 2 //////////
    //counter ch_count & k_count
    reg [5:0] w_count,next_w_count;
    reg [11:0] 
    always@(*) begin
        next_w_count = w_count;
        if(w_count < width_out) begin
            next_w_count = w_count + 1;
        end
        else begin
            next_w_count = 0;
        end
    end
    always@(posedge CLK) begin
        if(rst == 1) begin
            w_count <= 0;
        end
        else begin
            if(s2_en == 1) begin
                w_count <= next_w_count;
            end
            else begin
                w_count <= w_count;
            end
        end
    end
    ////////// stage 2 end //////////

    //done logic
    always@(posedge CLK) begin
        if( (w_count == width_out) && s1_done) begin
            done <= 1;
        end
        else begin
            done <= 0;
        end
    end
    
endmodule