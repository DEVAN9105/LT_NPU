`timescale 1ns / 1ps

//delay = 1 cycle

module W_buffer(
    input CLK,
    input rst,
    input [63:0]wdata_0,
    input [63:0]wdata_1,
    input [63:0]wdata_2,
    input [63:0]wdata_3,
    output reg [63:0]PE_win_0,
    output reg [63:0]PE_win_1,
    output reg [63:0]PE_win_2,
    output reg [63:0]PE_win_3
    );
    
    // buffer 0
    reg [63:0] w_buffer_0, w_buffer_1, w_buffer_2, w_buffer_3;
    always@(posedge CLK) begin
        if(rst == 1) begin
            w_buffer_0 <= 0;
            w_buffer_1 <= 0;
            w_buffer_2 <= 0;
            w_buffer_3 <= 0;
        end
        else begin
            w_buffer_0 <= wdata_0;
            w_buffer_1 <= wdata_1;
            w_buffer_2 <= wdata_2;
            w_buffer_3 <= wdata_3;
        end
    end
    
    // buffer 1
    always@(posedge CLK) begin
        if(rst == 1) begin
            PE_win_0 <= 0;
            PE_win_1 <= 0;
            PE_win_2 <= 0;
            PE_win_3 <= 0;
        end
        else begin
            PE_win_0 <= w_buffer_0;
            PE_win_1 <= w_buffer_1;
            PE_win_2 <= w_buffer_2;
            PE_win_3 <= w_buffer_3;
        end
    end
    
endmodule
