`timescale 1ns / 1ps

module Node_wb_buffer(
    input CLK,
    input rst,
    input en_wb_in,
    input [1:0] node_sel, // 00: none, 01: dout_out, 10: node_wb_a, 11: node_wb_b
    input [63:0] node_wb_a,
    input [63:0] node_wb_b,
    input [63:0] dout_wb,
    output reg [63:0] glb_wb,
    // addr buffer
    output en_wb,
    input [7:0] addr_wb_in,
    output reg [7:0] addr_wb
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
    assign en_wb = en_SR[3];
    ////////// valid SR end//////////

    ///////// addr buffer //////////
    always @(posedge CLK) begin
        if (rst) begin
            addr_wb <= 0;
        end
        else begin
            if (en_SR[0]) begin
                addr_wb <= addr_wb_in;
            end
            else begin
                addr_wb <= addr_wb;
            end
        end
    end
    ///////// addr buffer end//////////

    ///////// GLB_wb buffer //////////
    always @(posedge CLK) begin
        if (rst) begin
            glb_wb <= 0;
        end
        else begin
            if (en_SR[3]) begin
                case (node_sel)
                    2'b01: glb_wb <= dout_wb;
                    2'b10: glb_wb <= node_wb_a;
                    2'b11: glb_wb <= node_wb_b;
                    default: glb_wb <= 0;
                endcase
            end
            else begin
                glb_wb <= glb_wb;
            end
        end
    end
    ///////// GLB_wb buffer end//////////

endmodule
