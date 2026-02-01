`timescale 1ns / 1ps

module CIU_node#(
    parameter [2:0] CIU_ID = 3'd3
)(
    input CLK,
    input rst,
    input cycle_en,
    input load_en,
    input write_back_en,
    input [1:0] node_sel,
    // AGU parameters
    input [7:0] width_out,
    input [7:0] ch_out,
    input [7:0] AGU_O_initial, // initial address for AGU_C
    ////////// cycle //////////
    // stream buffer
    input [71:0] stream_a_in,
    output [71:0] stream_a_out,
    input [71:0] stream_b_in,
    output [71:0] stream_b_out,
    // tile buffer operator
    input [63:0] dout_cycle,
    output valid_cycle_a,
    output valid_cycle_b,
    output reg [7:0] addr_cycle_a,
    output reg [7:0] addr_cycle_b,
    output reg [63:0] din_cycle_a,
    output reg [63:0] din_cycle_b,
    ////////// load //////////
    input [75:0] glb_load,
    output [75:0] node_load, // we + destination + addr + data
    output valid_load,
    output [7:0] addr_load,
    output [63:0] din_load,
    ////////// write back //////////
    input en_a,
    input en_b,
    input [7:0] addr_wb_in,
    output [7:0] addr_wb,
    input [63:0] node_wb_a,
    input [63:0] node_wb_b,
    input [63:0] dout_wb,
    // GLB write back
    output [63:0] glb_wb,
    output en_wb,
    ////////// done //////////
    output cycle_done
    );

    ////////// SR //////////
    wire [8:0] cycle_SR;
    ////////// SR end //////////

    ////////// signals for tile buffer operator //////////
    assign valid_cycle_a = cycle_SR[6] | cycle_SR[7];
    assign valid_cycle_b = cycle_SR[6] | cycle_SR[7] | cycle_SR[8];
    always@(*) begin
        addr_cycle_b = stream_b_out[71:64];
        if(cycle_SR[2]) begin
            addr_cycle_a = caddr;
        end
        else begin
            addr_cycle_a = stream_a_out[71:64];
        end
    end
    always@(*) begin
        din_cycle_a = stream_a_out[63:0];
        din_cycle_b = stream_b_out[63:0];
    end
    ////////// signals for tile buffer operator end //////////


    ////////// AGU //////////
    wire [7:0] caddr;
    wire AGU_C_done;
    AGU_C agu_c(
        .CLK(CLK),
        .en(cycle_SR[0]),
        .rst(rst),
        .AGU_O_initial_in(AGU_O_initial),
        .width_out_in(width_out),
        .ch_out_in(ch_out),
        .caddr(caddr),
        .done(AGU_C_done)
    );
    ////////// AGU end //////////

    ////////// cycle controller //////////
    Cycle_controller cycle_controller(
        .CLK(CLK),
        .rst(rst),
        .en(cycle_en),
        .AGU_C_done(AGU_C_done),
        .cycle_SR(cycle_SR),
        .cycle_done(cycle_done)
    );
    ////////// cycle controller end //////////

    ////////// stream buffer //////////
    wire [71:0] stream_initial;
    Stream_buffer stream_buffer(
        .CLK(CLK),
        .rst(rst),
        .en(cycle_SR[4]),
        .addr_cycle(addr_cycle_a),
        .dout_cycle(dout_cycle),
        .stream_initial(stream_initial)
    );
    ////////// stream buffer end //////////

    ////////// CI buffer //////////
    // A
    wire CI_buffer_A_en = cycle_SR[5] | cycle_SR[6] | cycle_SR[7] | cycle_SR[8];
    CI_buffer CI_buffer_A(
        .CLK(CLK),
        .rst(rst),
        .en(CI_buffer_A_en),
        .mux_sel(cycle_SR[5]),
        .stream_in(stream_a_in),
        .stream_initial(stream_initial),
        .stream_out(stream_a_out)
    );
    // B
    wire CI_buffer_B_en = cycle_SR[5] | cycle_SR[6] | cycle_SR[7] | cycle_SR[8];
    CI_buffer CI_buffer_B(
        .CLK(CLK),
        .rst(rst),
        .en(CI_buffer_B_en),
        .mux_sel(cycle_SR[5]),
        .stream_in(stream_b_in),
        .stream_initial(stream_initial),
        .stream_out(stream_b_out)
    );
    ////////// CI buffer end //////////

    ////////// Node load buffer //////////
    Node_load_buffer #(
        .CIU_ID(CIU_ID)
    ) node_load_buffer(
        .CLK(CLK),
        .rst(rst),
        .en(load_en),
        .glb_load(glb_load),
        .node_load(node_load),
        .valid_load(valid_load),
        .addr_load(addr_load),
        .din_load(din_load)
    );
    ////////// Node load buffer end //////////

    ////////// Node write back buffer //////////
    wire en_wb_in = write_back_en | en_a | en_b;
    Node_wb_buffer node_wb_buffer(
        .CLK(CLK),
        .rst(rst),
        .en_wb_in(en_wb_in),
        .node_sel(node_sel),
        .node_wb_a(node_wb_a),
        .node_wb_b(node_wb_b),
        .dout_wb(dout_wb),
        .glb_wb(glb_wb),
        // addr buffer
        .en_wb(en_wb),
        .addr_wb_in(addr_wb_in),
        .addr_wb(addr_wb)
    );
    ////////// Node write back buffer end //////////
endmodule
