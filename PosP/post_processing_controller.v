`timescale 1ns / 1ps


module post_processing_controller(
    output reg [1:0] state,
    input CLK,
    input rst,
    input en,
    input valid
    );

    reg [1:0] next_state;

    always @(posedge CLK) begin
        if(rst)
            state <= 2'b0;
        else
            state <= next_state;
    end

    always @(*) begin
        case(state)
            2'b00:
                begin
                    if(valid & en)
                        next_state = 2'b01;
                    else
                        next_state = state;
                end
            2'b01:
                next_state = 2'b10;
            2'b10:
                begin
                    if(!en)
                        next_state = 2'b00;
                    else
                        next_state = state;
                end
        endcase
    end
endmodule