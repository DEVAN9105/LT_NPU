`timescale 1ns / 1ps

module Bridge_wb_buffer(
    input CLK,
    input rst,
    input en_wb_in,
    input [63:0] dout_wb,
    output reg [63:0] bridge_wb,
    // addr buffer
    output en_wb,
    input [7:0] addr_wb_in,
    output reg [7:0] addr_wb
    );

    ////////// valid SR //////////
    reg [2:0] en_SR;
    always @(posedge CLK) begin
        if (rst) begin
            en_SR <= 0;
        end
        else begin
            en_SR <= {en_SR[1:0], en_wb_in};
        end
    end
    assign en_wb = en_SR[2];
    ////////// valid SR end//////////

    ///////// addr buffer //////////
    always @(posedge CLK) begin
        if (rst) begin
            addr_wb <= 0;
        end
        else begin
            if (en_wb_in) begin
                addr_wb <= addr_wb_in;
            end
            else begin
                addr_wb <= addr_wb;
            end
        end
    end
    ///////// addr buffer end//////////

    ///////// bridge_wb buffer //////////
    always @(posedge CLK) begin
        if (rst) begin
            bridge_wb <= 0;
        end
        else begin
            if (en_SR[2]) begin
                bridge_wb <= dout_wb;
            end
            else begin
                bridge_wb <= bridge_wb;
            end
        end
    end
    ///////// bridge_wb buffer end//////////

endmodule