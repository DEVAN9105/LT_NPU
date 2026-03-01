`timescale 1ns / 1ps


module Post_processing(
    input CLK,
    input rst,
    input PS_rst,
    input en,
    input [31:0] input_label,
    input input_data_valid,
    input [63:0] input_data,
    output reg [3:0] result,         //{'Hand', 'Tool', 'Block', 'Save_Operation'}
    output busy
    );

    ////////// input buffer //////////
    reg [31:0] input_label_save;
    reg [63:0] input_data_save;
    wire [3:0] next_result;
    wire signed [15:0] label_3, label_2, label_1, label_0;
    ////////// input buffer end //////////

    ////////// label decode //////////
    // data decode
    wire signed [15:0] data_3 = input_data_save[63:48];
    wire signed [15:0] data_2 = input_data_save[47:32];
    wire signed [15:0] data_1 = input_data_save[31:16];
    wire signed [15:0] data_0 = input_data_save[15:0];
    // label decode
    assign label_3 = {{2{input_label_save[31]}}, input_label_save[31:24], 6'b0};
    assign label_2 = {{2{input_label_save[23]}}, input_label_save[23:16], 6'b0};
    assign label_1 = {{2{input_label_save[15]}}, input_label_save[15:8], 6'b0};
    assign label_0 = {{2{input_label_save[7]}}, input_label_save[7:0], 6'b0};
    // label compare
    assign next_result[3] = data_3 > label_3;
    assign next_result[2] = data_2 > label_2;
    assign next_result[1] = data_1 > label_1;
    assign next_result[0] = data_0 > label_0;
    ////////// label decode end //////////

    ////////// controller //////////
    wire [1:0] state;
    Post_processing_controller controller(
        .CLK(CLK),
        .rst(rst),
        .en(en),
        .valid(input_data_valid),
        .busy(busy),
        .state(state)
    );
    ////////// controller end //////////

    ////////// output logic //////////
    always @(posedge CLK) begin
        if(rst) begin
            input_label_save <= 32'b0;
            input_data_save <= 64'b0;
        end
        else begin
            input_label_save <= input_label;
            input_data_save <= input_data;
        end
    end
    always@(posedge CLK) begin
        if(PS_rst) begin
            result <= 4'b0;
        end
        else begin
            if(state == 2) begin
                result <= next_result;
            end
        end
    end
    ////////// output logic end //////////
    
endmodule