`timescale 1ns / 1ps

module Node_input_buffer#(
    parameter [2:0] CIU_ID = 3'd3
)(
    input CLK,
    input rst,
    input en,
    input [75:0] GLB_out,
    output reg [75:0] node_out,
    output valid_in,
    output [7:0] addr_in,
    output [63:0] din_in
    );

    ////////// buffer //////////
    always @(posedge CLK) begin
        if (rst) begin
            node_out <= 0;
        end
        else begin
            if(en) begin
                node_out <= GLB_out;
            end
            else begin
                node_out <= node_out;
            end
        end
    end
    ////////// buffer end //////////

    ////////// output //////////
    assign valid_in = node_out[75] & (node_out[74:72] == CIU_ID);
    assign addr_in = node_out[71:64];
    assign din_in = node_out[63:0];
    ////////// output end //////////

endmodule
