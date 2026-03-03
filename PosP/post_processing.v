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

    reg input_data_valid_save;
    reg [31:0] input_label_save;
    reg [63:0] input_data_save;
    reg [63:0] input_data_use;
    wire [1:0] state;
    wire [3:0] next_result;
    wire signed [15:0] label [3:0];
    wire signed [15:0] data [3:0];

    assign busy = ^state;

    assign label[3] = {{2{input_label_save[31]}}, input_label_save[31:24], 6'b0};
    assign label[2] = {{2{input_label_save[23]}}, input_label_save[23:16], 6'b0};
    assign label[1] = {{2{input_label_save[15]}}, input_label_save[15:8], 6'b0};
    assign label[0] = {{2{input_label_save[7]}}, input_label_save[7:0], 6'b0};

    assign {data[3], data[2], data[1], data[0]} = input_data_use;

    assign next_result[3] = state[1]? data[3] > label[3] : result[3];
    assign next_result[2] = state[1]? data[2] > label[2] : result[2];
    assign next_result[1] = state[1]? data[1] > label[1] : result[1];
    assign next_result[0] = state[1]? data[0] > label[0] : result[0];


    Post_processing_controller controller(
        .state(state),
        .CLK(CLK),
        .rst(rst),
        .en(en),
        .valid(input_data_valid_save)
    );

    always @(posedge CLK) begin
        if(rst) begin
            result <= 4'b0;
            input_data_valid_save <= 1'b0;
            input_label_save <= 32'b0;
            input_data_save <= 64'b0;
            input_data_use <= 64'b0;
        end else begin
            result <= next_result;
            input_data_valid_save <= input_data_valid;
            input_label_save <= input_label;
            input_data_save <= input_data;
            input_data_use <= input_data_save;
        end
    end
    
endmodule