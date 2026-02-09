`timescale 1ns / 1ps

// delay = 3

module Core_counter(
    input CLK,
    input en_in,
    input rst,
    input [2:0] mode_in,
    input [5:0] width_out_in,
    input [7:0] ch_in_in,
    input [7:0] ch_out_in,
    output reg core_counter_done
    /*output [7:0] offset_out,
    output [5:0] w_count_out,
    output [7:0] ch_count_out*/
    );
    
    // mode define
    parameter conv = 0, maxpooling = 1, DW = 2, PW = 3, GAP = 4;

    ////////// input buffer ////////// (2 cycle)
    reg en;
    reg [2:0] mode;
    reg [5:0] width_out;
    reg [7:0] ch_in;
    reg [7:0] ch_out;
    reg [7:0] kernel_L;
    always@(posedge CLK) begin
        mode <= mode_in;
        en <= en_in;
        width_out <= width_out_in;
        ch_in <= ch_in_in;
        ch_out <= ch_out_in;
    end
    // kernel_L define
    always@(posedge CLK) begin
        case (mode)
            conv: kernel_L <= 8;
            maxpooling: kernel_L <= 2;
            DW: kernel_L <= 2;
            PW: kernel_L <= ch_in;
            GAP: kernel_L <= 3;
            default: kernel_L <= 0;
        endcase
    end
    wire [11:0] k_stride = kernel_L + 1;
    ////////// input buffer end //////////

    ////////// en SR //////////
    reg [1:0] adder_en;
    always@(posedge CLK) begin
        if(rst) begin
            adder_en <= 0;
        end
        else begin
            adder_en <= {adder_en[0], en};
        end
    end
    ////////// en SR end //////////
    
    ////////// Stage 1 //////////
    reg [7:0] offset,next_offset;
    reg s1_done;
    wire s2_en;
    assign s2_en = s1_done & en;
    //counter
    always@(*) begin
        //avoid latch
        next_offset = offset;
        s1_done = 0;
        
        //counter logic
        if(offset < kernel_L) begin
            next_offset = offset + 1;
        end
        else begin
            next_offset = 0;
            s1_done = 1;
        end
    end
    always@(posedge CLK) begin
        if(rst) begin
            offset <= 0;
        end
        else begin
            if(en) begin
                offset <= next_offset;
            end
            else begin
                offset <= offset;
            end
        end
    end
    ////////// Stage 1 end //////////

    ////////// Stage 2 //////////
    //counter w_count
    reg [6:0] w_count,next_w_count;
    reg s2_done;
    wire s3_en;
    assign s3_en = s2_done & s2_en;
    always@(*) begin
        next_w_count = w_count;
        s2_done = 0;
        if(w_count < width_out) begin
            next_w_count = w_count + 1;
            s2_done = 0;
        end
        else begin
            next_w_count = 0;
            s2_done = 1;
        end
    end
    always@(posedge CLK) begin
        if(rst) begin
            w_count <= 0;
        end
        else begin
            if(s2_en) begin
                w_count <= next_w_count;
            end
            else begin
                w_count <= w_count;
            end
        end
    end
    ////////// Stage 2 end //////////

    ////////// Stage 3 //////////
    reg [8:0] ch_count,next_ch_count;
    reg s3_done;
    //counter ch_count & L
    always@(*) begin
        //avoid latch
        next_ch_count = ch_count;
        s3_done = 0;

        //counter logic
        if(ch_count < ch_out) begin
            next_ch_count = ch_count + 1;
            s3_done = 0;
        end
        else begin
            next_ch_count = 0;
            s3_done = 1;
        end
    end
    always@(posedge CLK) begin
        if(rst) begin
            ch_count <= 0;
        end
        else begin
            if(s3_en) begin
                ch_count <= next_ch_count;
            end
            else begin
                ch_count <= ch_count;
            end
        end
    end
    ////////// Stage 3 end //////////

    //done logic
    always@(posedge CLK) begin
        if(rst) begin
            core_counter_done <= 0;
        end
        else begin
            if(en_in) begin
                if( s3_done && s3_en) begin
                    core_counter_done <= 1;
                end
                else begin
                    core_counter_done <= 0;
                end
            end
            else begin
                core_counter_done <= core_counter_done;
            end
        end
    end
    
    // debug
    /*assign offset_out = offset;
    assign w_count_out = w_count;
    assign ch_count_out = ch_count;*/
    
endmodule