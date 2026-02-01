`timescale 1ns / 1ps

module Node_load_buffer#(
    parameter [2:0] CIU_ID = 3'd3
)(
    input CLK,
    input rst,
    input en,
    input [75:0] glb_load,
    output reg [75:0] node_out,
    output valid_load,
    output [7:0] addr_load,
    output [63:0] din_load
    );

    ////////// buffer //////////
    always @(posedge CLK) begin
        if (rst) begin
            node_out <= 0;
        end
        else begin
            if(en) begin
                node_out <= glb_load;
            end
            else begin
                node_out <= node_out;
            end
        end
    end
    ////////// buffer end //////////

    ////////// output //////////
    assign valid_load = node_out[75] & (node_out[74:72] == CIU_ID);
    assign addr_load = node_out[71:64];
    assign din_load = node_out[63:0];
    ////////// output end //////////

endmodule
