`timescale 1ns / 1ps

//delay = 3

module Accumulator(
    input CLK,
    input rst,
    input acc_en,
    input bias_en,
    input ReLU_en,
    input signed [31:0]bias,
    input signed [31:0]PE_out_0,
    input signed [31:0]PE_out_1,
    input signed [31:0]PE_out_2,
    input signed [31:0]PE_out_3,
    output reg signed [15:0]acc_out
    );
    
    //adder buffer
    reg signed [31:0] add_buffer_10, add_buffer_11;
    reg signed [31:0] adder_result;
    
    //adder tree stage 1
    //(* use_dsp = "yes" *)
    always@(posedge CLK) begin
        add_buffer_10 <= PE_out_0 + PE_out_1;
        add_buffer_11 <= PE_out_2 + PE_out_3;
    end
    
    //adder tree stage 2
    //(* use_dsp = "yes" *)
    always@(posedge CLK) begin
        adder_result <= add_buffer_10 + add_buffer_11;
    end
    
    //accumulate
    reg signed [47:0] accumulator_reg;
    always@(posedge CLK) begin
        if(rst == 1) begin
            accumulator_reg <= 0;
        end
        else begin
            if(acc_en == 1) begin
                //(* use_dsp = "yes" *)
                accumulator_reg <= adder_result + accumulator_reg;
            end
            else if(bias_en == 1) begin
                accumulator_reg <= {8'd0,bias,8'd0};
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
                acc_out <= accumulator_reg[23:8];
            end
            else begin
                acc_out <= 0;
            end
        end
        else begin
            acc_out <= accumulator_reg[23:8];
        end
    end
    
    //assume the result won't overflow
    
endmodule
