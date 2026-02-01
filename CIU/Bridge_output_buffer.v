`timescale 1ns / 1ps

module Bridge_output_buffer(
    input CLK,
    input rst,
    input en_in,
    input [63:0] dout_out,
    output reg [63:0] bridge_out,
    // addr buffer
    output en_out,
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
    assign en_out = en_SR[2];
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

    ///////// bridge_out buffer //////////
    always @(posedge CLK) begin
        if (rst) begin
            bridge_out <= 0;
        end
        else begin
            if (en_SR[2]) begin
                bridge_out <= dout_out;
            end
            else begin
                bridge_out <= bridge_out;
            end
        end
    end
    ///////// bridge_out buffer end//////////

endmodule