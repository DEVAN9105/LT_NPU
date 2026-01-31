`timescale 1ns / 1ps

module Node_input_buffer(
    input CLK,
    input rst,
    input en,
    input [71:0] GLB_out,
    output reg [71:0] node_out
    );
    
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
endmodule
