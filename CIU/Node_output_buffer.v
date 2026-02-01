`timescale 1ns / 1ps

module Node_output_buffer(
    input CLK,
    input rst,
    input en_in,
    input [1:0] node_sel, // 00: none, 01: dout_out, 10: node_in_a, 11: node_in_b
    input [63:0] node_in_a,
    input [63:0] node_in_b,
    input [63:0] dout_out,
    output reg [63:0] GLB_in,
    // addr buffer
    output en_wb,
    input [7:0] addr_out_in,
    output reg [7:0] addr_out
    );

    ////////// valid SR //////////
    reg [2:0] en_SR;
    always @(posedge CLK) begin
        if (rst) begin
            en_SR <= 0;
        end
        else begin
            en_SR <= {en_SR[1:0], en_in};
        end
    end
    assign en_wb = en_SR[2];
    ////////// valid SR end//////////

    ///////// addr buffer //////////
    always @(posedge CLK) begin
        if (rst) begin
            addr_out <= 0;
        end
        else begin
            if (en_in) begin
                addr_out <= addr_out_in;
            end
            else begin
                addr_out <= addr_out;
            end
        end
    end
    ///////// addr buffer end//////////

    ///////// GLB_in buffer //////////
    always @(posedge CLK) begin
        if (rst) begin
            GLB_in <= 0;
        end
        else begin
            if (en_SR[2]) begin
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
    ///////// GLB_in buffer end//////////

endmodule
