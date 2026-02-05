`timescale 1ns / 1ps

// delay = 4

module CIU_wb_buffer(
    input CLK,
    input rst,
    input en_wb_in,
    input [7:0] addr_wb_in,
    // tile buffer
    output en_wb,
    output reg [7:0] addr_wb,
    input [63:0] dout_wb,
    // output data
    output data_valid,
    output reg [63:0] CIU_wb
    );

    ////////// valid SR //////////
    reg [3:0] en_SR;
    always @(posedge CLK) begin
        if (rst) begin
            en_SR <= 0;
        end
        else begin
            en_SR <= {en_SR[2:0], en_wb_in};
        end
    end
    assign en_wb = en_SR[0];
    assign data_valid = en_SR[3];
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

    ///////// wb buffer //////////
    always @(posedge CLK) begin
        if (rst) begin
            CIU_wb <= 0;
        end
        else begin
            if (en_SR[2]) begin
                CIU_wb <= dout_wb;
            end
            else begin
                CIU_wb <= CIU_wb;
            end
        end
    end
    ///////// wb buffer end//////////

endmodule