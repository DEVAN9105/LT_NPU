`timescale 1ns / 1ps

module Accumulator(
    input CLK,
    input rst,
    input en,
    input bias_en,    //reset to bias
    input load_bias,
    input ReLU_en,
    input signed [31:0]bias,
    input signed [31:0]PE_out_0,
    input signed [31:0]PE_out_1,
    input signed [31:0]PE_out_2,
    input signed [31:0]PE_out_3,
    output reg signed [15:0]acc_out
    );
    
    //adder buffer
    reg signed [32:0] add_buffer_10, add_buffer_11;
    reg signed [33:0] adder_result;
    
    //adder tree stage 1
    always@(posedge CLK) begin
        add_buffer_10 <= PE_out_0 + PE_out_1;
        add_buffer_11 <= PE_out_2 + PE_out_3;
    end
    
    //adder tree stage 2
    always@(posedge CLK) begin
        adder_result <= add_buffer_10 + add_buffer_11;
    end
    
    //bias buffer
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
    
    //accumulate
    (* use_dsp = "yes" *) reg signed [47:0] accumulator_reg;
    wire signed [47:0] bias_ext = {{16{bias_buffer[31]}}, bias_buffer};
    wire signed [47:0] adder_result_ext = {{14{adder_result[33]}}, adder_result};
    always@(posedge CLK) begin
        if(rst == 1) begin
            accumulator_reg <= 0;
        end
        else begin
            if(en == 1) begin
                accumulator_reg <= adder_result_ext + ((bias_en) ? bias_ext : accumulator_reg);
            end
            else begin
                accumulator_reg <= accumulator_reg;
            end
        end
    end
    
    //ReLU and output
    always@(posedge CLK) begin
        if(ReLU_en == 1) begin
            if(accumulator_reg > 0) begin
                acc_out <= accumulator_reg[15:0];
            end
            else begin
                acc_out <= 0;
            end
        end
        else begin
            acc_out <= accumulator_reg[15:0];
        end
    end
    
    //assume the result won't overflow
    
endmodule
