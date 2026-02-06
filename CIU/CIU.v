`timescale 1ns / 1ps

module CIU(
    input CLK,
    input rst,
    input cycle_en,
    input load_en,
    input wb_en,
    ////////// AGU parameters //////////
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
    output valid_cycle_a,
    output valid_cycle_b,
    output [7:0] addr_cycle_a,
    output [7:0] addr_cycle_b,
    output [63:0] din_cycle_a,
    output [63:0] din_cycle_b,
    input [63:0] dout_cycle,
    ////////// load //////////
    input load_en,
    input [71:0] CIU_load,
    output valid_load,
    output [7:0] addr_load,
    output [63:0] din_load,
    ////////// write back //////////
    input [7:0] addr_wb_in,
    output [7:0] addr_wb,
    input [63:0] dout_wb,
    output data_valid,
    output [63:0] CIU_wb,
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
    assign addr_cycle_a = (cycle_SR[2]) ? caddr : stream_a_out[71:64];
    assign addr_cycle_b = stream_b_out[71:64];
    assign din_cycle_a = stream_a_out[63:0];
    assign din_cycle_b = stream_b_out[63:0];
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

    ////////// CIU load buffer //////////
    CIU_load_buffer CIU_load_buffer(
        .CLK(CLK),
        .rst(rst),
        .en(load_en),
        .CIU_load(CIU_load),
        // tile buffer
        .valid_load(valid_load),
        .addr_load(addr_load),
        .din_load(din_load)
    );
    ////////// CIU load buffer end //////////

    ////////// CIU write back buffer //////////
    CIU_wb_buffer CIU_wb_buffer(
        .CLK(CLK),
        .rst(rst),
        .en_wb_in(wb_en),
        .addr_wb_in(addr_wb_in),
        // output data
        .data_valid(data_valid),
        .CIU_wb(CIU_wb),
        // tile buffer
        .en_wb(en_wb),
        .addr_wb(addr_wb),
        .dout_wb(dout_wb)
    );
    ////////// CIU write back buffer end //////////
endmodule
