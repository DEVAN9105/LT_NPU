`timescale 1ns / 1ps

module Node_output_buffer(
    input CLK,
    input rst,
    input en,
    input [63:0] dout_out,
    output reg [63:0] bridge_out
    );

    always @(posedge CLK) begin
        if (rst) begin
            bridge_out <= 0;
        end
        else begin
            if (en) begin
                bridge_out <= dout_out;
            end
            else begin
                bridge_out <= bridge_out;
            end
        end
    end

endmodule
