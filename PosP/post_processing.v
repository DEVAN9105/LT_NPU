`timescale 1ns / 1ps


module post_processing(
    output done,
    output reg [3:0] result,         //{'Hand', 'Tool', 'Block', 'Save_Operation'}
    input CLK,
    input rst,
    input en,
    input [31:0] input_label,
    input input_data_valid,
    input [63:0] input_data
    );

    wire [1:0] state;
    wire [3:0] next_result;
    wire signed [15:0] label [3:0];
    wire signed [15:0] data [3:0];

    assign done = state[1];

    assign label[3] = {{2{input_label[31]}}, input_label[31:24], 6'b0};
    assign label[2] = {{2{input_label[23]}}, input_label[23:16], 6'b0};
    assign label[1] = {{2{input_label[15]}}, input_label[15:8], 6'b0};
    assign label[0] = {{2{input_label[7]}}, input_label[7:0], 6'b0};

    assign {data[3], data[2], data[1], data[0]} = input_data;

    assign next_result[3] = state[0]? data[3] > label[3] : result;
    assign next_result[2] = state[0]? data[2] > label[2] : result;
    assign next_result[1] = state[0]? data[1] > label[1] : result;
    assign next_result[0] = state[0]? data[0] > label[0] : result;


    post_processing_controller controller(
        .state(state),
        .CLK(CLK),
        .rst(rst),
        .en(en),
        .valid(input_data_valid)
    );

    always @(posedge CLK) begin
        if(rst)
            result <= 4'b0;
        else
            result <= next_result;
    end
    
endmodule