`timescale 1ns / 1ps

//delay = 4 cycle

module Accumulator(
    input CLK,
    input rst,
    input en,
    input load_bias,
    input ReLU_en,
    input [7:0] kernel_L;
    input signed [31:0]bias,
    input signed [31:0]PE_out_0,
    input signed [31:0]PE_out_1,
    input signed [31:0]PE_out_2,
    input signed [31:0]PE_out_3,
    output reg signed [15:0]acc_out
    );

    ////////// Stage 1 counter //////////
    reg [7:0] acc_count, next_acc_count;

    // reset bias
    reg rst_bias;
    always@(*) begin
        if(acc_count == 0) begin
            rst_bias = 1;
        end
        else begin
            rst_bias = 0;
        end
    end

    // acc_count
    always@(*) begin
        next_acc_count = acc_count;
        if(acc_count < kernel_L) begin
            next_acc_count = acc_count + 1;
        end
        else begin
            next_acc_count = 0;
        end
    end
    always@(posedge CLK) begin
        if(rst) begin
            acc_count <= 0;
        end
        else begin
            if(en) begin
                acc_count <= next_acc_count;
            end
            else begin
                acc_count <= acc_count;
            end
        end
    end
    //////////// Stage 1 counter end //////////


    ////////// SR //////////
    reg rst_bias_sr;
    reg [1:0] en_sr;
    always@(posedge CLK) begin
        rst_bias_sr <= rst_bias;
        en_sr <= {en_sr[0], en};
    end
    ////////// SR end //////////
    
    ////////// Stage 1 ////////// 

    // adder tree
    reg signed [32:0] add_buffer_10, add_buffer_11;
    always@(posedge CLK) begin
        add_buffer_10 <= PE_out_0 + PE_out_1;
        add_buffer_11 <= PE_out_2 + PE_out_3;
    end

    // compare tree
    wire signed [15:0] PE_out_0_trunc = PE_out_0[15:0];
    wire signed [15:0] PE_out_1_trunc = PE_out_1[15:0];
    reg signed [15:0] PE_out_2_trunc;
    always@(posedge CLK) begin
        if(rst) begin
            PE_out_2_trunc <= 0;
        end
        else begin
            if(en) begin
            PE_out_2_trunc <= PE_out_2[15:0];
            end
            else begin
                PE_out_2_trunc <= PE_out_2_trunc;
            end
        end
    end

    
    ////////// Stage 1 end //////////

    ////////// Stage 2 adder tree //////////
    reg signed [33:0] adder_result;
    always@(posedge CLK) begin
        adder_result <= add_buffer_10 + add_buffer_11;
    end
    ////////// Stage 2 adder tree end //////////
    
    ////////// bias buffer //////////
    reg signed [31:0] bias_buffer;
    always@(posedge CLK) begin
        if(rst) begin
            bias_buffer <= 0;
        end
        else begin
            if(load_bias) begin
                bias_buffer <= bias;
            end
            else begin
                bias_buffer <= bias_buffer;
            end
        end
    end
    ////////// bias buffer end //////////

    ////////// Stage 3 accumulate //////////
    (* use_dsp = "yes" *) reg signed [47:0] accumulator_reg;
    wire signed [47:0] bias_ext = {{16{bias_buffer[31]}}, bias_buffer};
    wire signed [47:0] adder_result_ext = {{14{adder_result[33]}}, adder_result};
    always@(posedge CLK) begin
        if(rst == 1) begin
            accumulator_reg <= 0;
        end
        else begin
            if(acc_en_sr[1]) begin
                if(rst_bias_sr[1] == 1) begin
                    accumulator_reg <= adder_result_ext + bias_ext;
                end
                else begin
                    accumulator_reg <= adder_result_ext + accumulator_reg;
                end
            end
            else begin
                accumulator_reg <= accumulator_reg;
            end
        end
    end
    ////////// Stage 3 accumulate end //////////
    
    ////////// Truncate //////////
    reg signed [15:0] acc_out_truncated;
    always@(*) begin
        if(accumulator_reg[47:16] != {32{accumulator_reg[15]}}) begin
            //overflow
            if(accumulator_reg[47] == 0) begin
                acc_out_truncated <= 16'h7FFF; //max pos
            end
            else begin
                acc_out_truncated <= 16'h8000; //max neg
            end
        end
        else begin
            acc_out_truncated <= accumulator_reg[15:0];
        end
    end
    ////////// Truncate end //////////

    ////////// Output register && ReLU //////////
    always@(posedge CLK) begin
        if(rst) begin
            acc_out <= 0;
        end
        else begin
            if(ReLU_en == 1) begin
                if(acc_out_truncated > 0) begin
                    acc_out <= acc_out_truncated;
                end
                else begin
                    acc_out <= 0;
                end
            end
            else begin
                acc_out <= acc_out_truncated;
            end
        end
    end
    ////////// Output register end //////////
    
endmodule
