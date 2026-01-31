`timescale 1ns / 1ps

module CIU_node(
    input CLK,
    input rst,
    input cycle_en,
    input load_en,
    input write_back_en,
    input node_sel,
    // AGU parameters
    input [7:0] width_out,
    input [7:0] ch_out,
    input [7:0] AGU_O_initial, // initial address for AGU_C
    ////////// cycle //////////
    // stream buffer
    input [63:0] dout_cycle,
    input [71:0] stream_a_in,
    output [71:0] stream_a_out,
    input [71:0] stream_b_in,
    output [71:0] stream_b_out,
    // tile buffer operator
    output valid_cycle_a,
    output valid_cycle_b,
    output reg [7:0] addr_cycle_a,
    output reg [7:0] addr_cycle_b,
    output reg [63:0] din_cycle_a,
    output reg [63:0] din_cycle_b,
    ////////// load //////////
    input [75:0] glb_out,
    output [75:0] node_out, // we + destination + addr + data
    output valid_in,
    output [7:0] addr_in,
    output [63:0] din_in,
    ////////// write back //////////
    input [7:0] addr_out_in,
    output reg [7:0] addr_out,
    input [63:0] node_in_a,
    input [63:0] node_in_b,
    input [63:0] dout_out,
    output [63:0] glb_in,
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

    ////////// Node input buffer //////////
    Node_input_buffer node_input_buffer(
        .CLK(CLK),
        .rst(rst),
        .en(load_en),
        .GLB_out(glb_out),
        .node_out(node_out),
        .valid_in(valid_in),
        .addr_in(addr_in),
        .din_in(din_in)
    );
    ////////// Node input buffer end //////////

    ////////// Node output buffer //////////
    // addr_out buffer
    always @(posedge CLK) begin
        if (rst) begin
            addr_out <= 0;
        end
        else begin
            if (write_back_en) begin
                addr_out <= addr_out_in;
            end
            else begin
                addr_out <= addr_out;
            end
        end
    end
    Node_output_buffer node_output_buffer(
    .CLK(CLK),
    .rst(rst),
    .en(write_back_en),
    .node_sel(node_sel),
    .node_in_a(node_in_a),
    .node_in_b(node_in_b),
    .dout_out(dout_out),
    .GLB_in(glb_in)
    );
    ////////// Node output buffer end //////////
endmodule
