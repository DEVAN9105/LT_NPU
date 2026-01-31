`timescale 1ns / 1ps

module Node_output_buffer(
    input CLK,
    input rst,
    input en,
    input [1:0] node_sel, // 00: none, 01: dout_out, 10: node_in_a, 11: node_in_b
    input [63:0] node_in_a,
    input [63:0] node_in_b,
    input [63:0] dout_out,
    output reg [63:0] GLB_in
    );

    always @(posedge CLK) begin
        if (rst) begin
            GLB_in <= 0;
        end
        else begin
            if (en) begin
                case (node_sel)
                    2'b01: GLB_in <= dout_out;
                    2'b10: GLB_in <= node_in_a;
                    2'b11: GLB_in <= node_in_b;
                    default: GLB_in <= 0;
                endcase
            end
            else begin
                GLB_in <= GLB_in;
            end
        end
    end

endmodule
