`timescale 1ns / 1ps

module Node_load_buffer#(
    parameter [2:0] CIU_ID = 3'd3
)(
    input CLK,
    input rst,
    input en,
    input [75:0] glb_load,
    output reg [75:0] node_load,
    output valid_load,
    output [7:0] addr_load,
    output [63:0] din_load
    );

    ////////// buffer //////////
    always @(posedge CLK) begin
        if (rst) begin
            node_load <= 0;
        end
        else begin
            if(en) begin
                node_load <= glb_load;
            end
            else begin
                node_load <= node_load;
            end
        end
    end
    ////////// buffer end //////////

    ////////// output //////////
    assign valid_load = node_load[75] & (node_load[74:72] == CIU_ID);
    assign addr_load = node_load[71:64];
    assign din_load = node_load[63:0];
    ////////// output end //////////

endmodule
