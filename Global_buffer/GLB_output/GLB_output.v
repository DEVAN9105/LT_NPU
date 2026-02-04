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
    // input tile
    output reg [6:0] wb_en, // 0: pre_processing tile, 1~6: core
    output [7:0] taddr,
    input [63:0] CIU_node_wb_2,
    input [63:0] CIU_node_wb_5,
    input [63:0] PP_wb,
    input en_wb_c2,
    input en_wb_c5,
    input en_wb_pp,
    // glb control
    output glb_b_en,
    // done signal
    output done
    );
    
    ////////// GLB control //////////
    wire [9:0] SR;
    wire glb_out_rst;
    wire AGU_G_done;
    GLB_output_controller glb_output_controller(
        .CLK(CLK),
        .en(en),
        .rst(rst),
        .AGU_G_done(AGU_G_done),
        .SR(SR),
        .done(done),
        .glb_out_rst(glb_out_rst)
    );
    ////////// GLB control end //////////

    ////////// signal assign //////////
    assign glb_b_en = SR[0];
    ////////// signal assign end //////////

    ////////// AGU_T //////////
    reg [2:0] core;
    wire [2:0] core_pointer;
    AGU_T agu_t(
    .CLK(CLK),
    .en(SR_0[0]),
    .rst(rst),
    .AGU_T_initial_in(AGU_T_initial_in),
    .tile_width_in(tile_width_in),
    .tile_ch_in(tile_ch_in),
    .core(core),
    .core_pointer(core_pointer),
    .taddr(taddr),
    .done(AGU_T_done)
    );
    ////////// AGU_T end //////////

    ////////// AGU_G //////////
    AGU_G agu_g(
        .CLK(CLK),
        .en(SR[1]),
        .rst(rst),
        .AGU_G_initial_in(AGU_G_initial_in),
        .glb_width_in(glb_width_in),
        .glb_ch_in(glb_ch_in),
        .ch_to_Y_en(ch_to_Y_en),
        .ch_sum(ch_sum),
        .Y(Y),
        .gaddr(gaddr)
    );
    ////////// AGU_G end //////////

    ////////// Input Transpose //////////
    Transpose transpose(
        .CLK(CLK),
        .rst(rst),
        .en(SR_1[2]),
        .data(data_buffer_1),
        .data_transpose(din_glb)
    );
    ////////// Input Transpose end //////////

endmodule
