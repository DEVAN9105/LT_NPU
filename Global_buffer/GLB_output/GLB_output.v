`timescale 1ns / 1ps

module GLB_input(
    input CLK,
    input en,
    input rst,
    input glb_in_mode, // 0: pre_processing, 1: core
    // AGU_T
    input [7:0] AGU_T_initial_in,
    input [6:0] tile_width_in,
    input [7:0] tile_ch_in,
    // AGU_G
    input [11:0] AGU_G_initial_in,
    input [6:0] glb_width_in,
    input [7:0] glb_ch_in,
    output ch_to_Y_en,
    output [9:0] ch_sum,
    input [11:0] Y,
    output [11:0] gaddr,
    // output tile
    output load_en,
    output [7:0] taddr,
    output [63:0] glb_load,
    // glb control
    output glb_b_en,
    input [63:0] dout_glb,
    // done signal
    output done
    );
    
    ////////// GLB control //////////
    wire [5:0] SR_0;
    wire [10:0] SR_1;
    wire glb_out_rst;
    wire AGU_G_en;
    wire AGU_G_done;
    GLB_output_controller glb_output_controller(
        .CLK(CLK),
        .en(en),
        .rst(rst),
        .AGU_G_done(AGU_G_done),
        .AGU_G_en(AGU_G_en),
        .SR_0(SR_0),
        .SR_1(SR_1),
        .done(done),
        .glb_out_rst(glb_out_rst)
    );
    ////////// GLB control end //////////

    ////////// signal assign //////////
    assign glb_b_en = SR_1[0];
    assign load_en = SR_1[8];
    ////////// signal assign end //////////

    ////////// AGU_G //////////
    AGU_G agu_g(
        .CLK(CLK),
        .en(AGU_G_en),
        .rst(glb_out_rst),
        .AGU_G_initial_in(AGU_G_initial_in),
        .glb_width_in(glb_width_in),
        .glb_ch_in(glb_ch_in),
        .ch_to_Y_en(ch_to_Y_en),
        .ch_sum(ch_sum),
        .Y(Y),
        .gaddr(gaddr)
    );
    ////////// AGU_G end //////////

    ////////// AGU_T //////////
    reg [2:0] core;
    wire [2:0] core_pointer;
    AGU_T agu_t(
        .CLK(CLK),
        .en(SR_1[4]),
        .rst(glb_out_rst),
        .AGU_T_initial_in(AGU_T_initial_in),
        .tile_width_in(tile_width_in),
        .tile_ch_in(tile_ch_in),
        .core(core),
        .core_pointer(core_pointer),
        .taddr(taddr)
    );
    ////////// AGU_T end //////////

    ////////// Output Transpose //////////
    Transpose transpose(
        .CLK(CLK),
        .rst(glb_out_rst),
        .en(SR_1[3]),
        .data(data_buffer_1),
        .data_transpose(din_glb)
    );
    ////////// Output Transpose end //////////

endmodule
