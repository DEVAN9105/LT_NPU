`timescale 1ns / 1ps

//delay = 1 cycle

module W_buffer(
    input CLK,
    input rst,
    input en,
    input bias_en,
    input [63:0]wdata_0,
    input [63:0]wdata_1,
    input [63:0]wdata_2,
    input [63:0]wdata_3,
    output reg [63:0]PE_win_0,
    output reg [63:0]PE_win_1,
    output reg [63:0]PE_win_2,
    output reg [63:0]PE_win_3,
    output reg [31:0]acc_0_bias,
    output reg [31:0]acc_1_bias,
    output reg [31:0]acc_2_bias,
    output reg [31:0]acc_3_bias
    );
    
    always@(posedge CLK) begin
        if(rst == 1) begin
            PE_win_0 <= 0;
            PE_win_1 <= 0;
            PE_win_2 <= 0;
            PE_win_3 <= 0;
        end
        else begin
            if(en == 0) begin
                PE_win_0 <= PE_win_0;
                PE_win_1 <= PE_win_1;
                PE_win_2 <= PE_win_2;
                PE_win_3 <= PE_win_3;
            end
            else begin
                PE_win_0 <= wdata_0;
                PE_win_1 <= wdata_1;
                PE_win_2 <= wdata_2;
                PE_win_3 <= wdata_3;
            end
        end
    end

    always@(posedge CLK) begin
        if(rst == 1) begin
            acc_0_bias <= 0;
            acc_1_bias <= 0;
            acc_2_bias <= 0;
            acc_3_bias <= 0;
        end
        else begin
            if(bias_en == 0) begin
                acc_0_bias <= acc_0_bias;
                acc_1_bias <= acc_1_bias;
                acc_2_bias <= acc_2_bias;
                acc_3_bias <= acc_3_bias;
            end
            else begin
                acc_0_bias <= wdata_0[63:32];
                acc_1_bias <= wdata_1[63:32];
                acc_2_bias <= wdata_2[63:32];
                acc_3_bias <= wdata_3[63:32];
            end
        end
    end
    
endmodule
