`timescale 1ns / 1ps

module Core(
    // basic
    input CLK, input rst, input en,
    // control signal
    input [2:0] mode,
    input [8:0] tile_sel,
    input padding,
    input ReLU_en,
    // AGU initial
    input [11:0] AGU_W_initial_in,
    input [7:0] AGU_B_initial_in,
    input [7:0] AGU_O_stride,
    // tile size
    input [6:0] width_in_in,
    input [6:0] width_out_in,
    input [7:0] ch_in_in,
    input [7:0] ch_out_in,
    // tile buffer
    output reg ena,
    output reg enb,
    output [7:0] tile_out_addr,
    output [63:0] tile_out,
    // core done
    output core_done
    );
    
    ////////// input buffer ////////// 
    reg [2:0] mode;
    reg [6:0] width_in;
    reg [6:0] width_out;
    reg [7:0] ch_in;
    reg [7:0] ch_out;
    reg [11:0] AGU_W_initial;
    reg [7:0] AGU_B_initial;
    always@(posedge CLK) begin
        mode <= mode;
        width_in <= width_in_in;
        width_out <= width_out_in;
        ch_in <= ch_in_in;
        ch_out <= ch_out_in;
        AGU_W_initial <= AGU_W_initial_in;
        AGU_B_initial <= AGU_B_initial_in;
    end
    ////////// input buffer end //////////

    ////////// Controller //////////
    // FSM
    wire  Core_en_counter_en;
    wire AGU_O_done;
    wire [1:0] state;
    wire core_rst; // to reset FSM and other modules when core is done
    Core_FSM FSM(
        .CLK(CLK),
        .en(en),
        .rst(rst),
        .AGU_O_done(AGU_O_done),
        .state(state),
        .Core_en_counter_en(Core_en_counter_en),
        .core_done(core_done),
        .core_rst(core_rst)
    );

    // en_counter
    wire SR_0_en;
    Core_en_counter core_en_counter(
    .CLK(CLK),
    .en_in(Core_en_counter_en),
    .rst(core_rst),
    .mode(mode),
    .width_out_in(width_out),
    .ch_in_in(ch_in),
    .ch_out_in(ch_out),
    .SR_0_en(SR_0_en)
    );

    // SR
    wire acc_done;
    wire [11:0] SR_0;
    wire [7:0] SR_1;
    Core_SR SR(
    .CLK(CLK),
    .rst(core_rst),
    .en(SR_0_en),
    .acc_done(acc_done),
    .mode(mode),
    .state(state),
    .SR_0(SR_0),
    .SR_1(SR_1)
    );
    ////////// Controller end //////////

    ////////// AGU //////////
    // AGU_F
    wire [1:0] stride_X;
    wire [7:0] faddr;
    wire boundary;
    AGU_F agu_f(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_0[0]),
        .width_in_in(width_in),
        .width_out_in(width_out),
        .ch_in_in(ch_in),
        .ch_out_in(ch_out),
        .mode(mode),
        .stride_X_in(stride_X),
        .faddr(faddr),
        .boundary(boundary),
    );

    // AGU_W
    wire [11:0] Waddr;
    wire [11:0] Waddr;
    AGU_W agu_w(
        .CLK(CLK),
        .en(SR_0[1]),
        .rst(core_rst),
        .mode(mode),
        .AGU_W_initial_in(AGU_W_initial),
        .width_out_in(width_out),
        .ch_in_in(ch_in),
        .ch_out_in(ch_out),
        .Waddr(Waddr),
    );

    // AGU_B
    wire [7:0] baddr;
    AGU_B agu_b(
        .CLK(CLK),
        .en(SR_0[7]),
        .rst(core_rst),
        .mode(mode),
        .AGU_B_initial_in(AGU_B_initial),
        .width_out_in(width_out),
        .ch_in_in(ch_in),
        .ch_out_in(ch_out),
        .baddr(baddr),
    );

    // AGU_O
    wire [7:0] oaddr;
    AGU_O agu_o(
    .CLK(CLK),
    .en(SR_1[5]),
    .rst(core_rst),
    .AGU_O_initial_in(AGU_O_initial),
    .width_out_in(width_out),
    .ch_out_in(ch_out),
    .AGU_O_stride_in(AGU_O_stride),
    .oaddr(oaddr),
    );
    ////////// AGU end //////////
    
endmodule
