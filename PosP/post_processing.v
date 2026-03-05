`timescale 1ns / 1ps

module Post_processing(
    output busy,
    output reg [3:0] result,         //{'Hand', 'Tool', 'Block', 'Save_Operation'}
    input CLK,
    input rst,
    input en,
    input [31:0] input_label,
    input input_data_valid,
    input [63:0] input_data
    );

    wire [3:0] next_result;
    wire [1:0] state;
    reg input_data_valid_save;
    reg [63:0] input_data_save;
    wire signed [15:0] next_label [3:0];
    reg signed [15:0] label [3:0];
    wire signed [15:0] next_data [3:0];
    reg signed [15:0] data [3:0];

    post_processing_controller controller(
        .state(state),
        .CLK(CLK),
        .rst(rst),
        .en(en),
        .valid(input_data_valid_save)
    );

    assign busy = ^state;
    assign next_label[3] = (state == 2'b01) ? {{2{input_label[31]}}, input_label[31:24], 6'b0} : label[3];
    assign next_label[2] = (state == 2'b01) ? {{2{input_label[23]}}, input_label[23:16], 6'b0} : label[2];
    assign next_label[1] = (state == 2'b01) ? {{2{input_label[15]}}, input_label[15:8], 6'b0} : label[1];
    assign next_label[0] = (state == 2'b01) ? {{2{input_label[7]}}, input_label[7:0], 6'b0} : label[0];
    assign next_data[3] = (state == 2'b01) ? input_data_save[63:48] : data[3];
    assign next_data[2] = (state == 2'b01) ? input_data_save[47:32] : data[2];
    assign next_data[1] = (state == 2'b01) ? input_data_save[31:16] : data[1];
    assign next_data[0] = (state == 2'b01) ? input_data_save[15:0] : data[0];
    assign next_result[3] = (state == 2'b10) ? (data[3] >= label[3]) : result[3];
    assign next_result[2] = (state == 2'b10) ? (data[2] >= label[2]) : result[2];
    assign next_result[1] = (state == 2'b10) ? (data[1] >= label[1]) : result[1];
    assign next_result[0] = (state == 2'b10) ? (data[0] >= label[0]) : result[0];

    always @(posedge CLK) begin
        if(rst) begin
            input_data_valid_save <= 1'b0;
            input_data_save <= 64'b0;
            result <= 4'b0;
            data[3] <= 16'b0;
            data[2] <= 16'b0;
            data[1] <= 16'b0;
            data[0] <= 16'b0;
            label[3] <= 16'b0;
            label[2] <= 16'b0;
            label[1] <= 16'b0;
            label[0] <= 16'b0;
        end else begin
            input_data_valid_save <= input_data_valid;
            input_data_save <= input_data;
            result <= next_result;
            data[3] <= next_data[3];
            data[2] <= next_data[2];
            data[1] <= next_data[1];
            data[0] <= next_data[0];
            label[3] <= next_label[3];
            label[2] <= next_label[2];
            label[1] <= next_label[1];
            label[0] <= next_label[0];
        end
    end

endmodule