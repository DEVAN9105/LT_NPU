`timescale 1ns / 1ps

module Core(
    // basic
    input CLK, input rst, input en,
    ////////// control signal //////////
    input [15:0] core_control, //{mode_in[15:13], tile_sel_in[12:4], stride_X_in[3:2], ReLU_en_in[1], padding}
    ////////// AGU initial //////////
    input [27:0] core_AGU_initial, // {AGU_W_initial[27:16], AGU_B_initial[15:8], AGU_O_initial[7:0]}
    ////////// tile size //////////
    input [29:0] core_tile_param, // {width_in[29:23], ch_in[22:15], width_out[14:8], ch_out[7:0]}
    ////////// cal tile buffer //////////
    output [8:0] core_tbo_cal_bus, // {valid_cal, addr_cal}
    input [63:0] tile_1,
    input [63:0] tile_2,
    input [63:0] tile_3,
    input [63:0] tile_4,
    input [63:0] tile_5,
    input [63:0] tile_6,
    ////////// W_storage //////////
    output [12:0] core_w_storage_bus, // {W_storage_en, Waddr[11:0]}
    input [63:0] wdata_0,
    input [63:0] wdata_1,
    input [63:0] wdata_2,
    input [63:0] wdata_3,
    ////////// B_storage //////////
    output [8:0] core_b_storage_bus, // {B_storage_en, baddr[7:0]}
    input [31:0] bdata_0,
    input [31:0] bdata_1,
    input [31:0] bdata_2,
    input [31:0] bdata_3,
    ////////// store tile buffer //////////
    output [72:0] core_tbo_store_bus, // {valid, addr, din}
    ////////// core done //////////
    output core_done
    ////////// debug //////////
    ,
    output [47:0] acc_result_0,
    output [47:0] acc_result_1,
    output [47:0] acc_result_2,
    output [47:0] acc_result_3,
    output [2:0] state_debug,
    output [12:0] SR_0_debug,
    output [5:0] SR_1_debug
    );
    
    ////////// mode define //////////
    parameter conv = 0, maxpooling = 1, DW = 2, PW = 3, GAP = 4;
    ////////// mode define end //////////

    ////////// input buffer ////////// 
    wire [2:0] mode = core_control[15:13];
    wire [8:0] tile_sel = core_control[12:4];
    wire [1:0] stride_X = core_control[3:2];
    wire ReLU_en = core_control[1];
    wire padding = core_control[0];
    wire [6:0] width_in = core_tile_param[29:23];
    wire [7:0] ch_in = core_tile_param[22:15];
    wire [6:0] width_out = core_tile_param[14:8];
    wire [7:0] ch_out = core_tile_param[7:0];
    wire [11:0] AGU_W_initial = core_AGU_initial[27:16];
    wire [7:0] AGU_B_initial = core_AGU_initial[15:8];
    wire [7:0] AGU_O_initial = core_AGU_initial[7:0];
    ////////// input buffer end //////////

    ////////// Controller //////////
    // FSM
    wire Core_en_counter_en;
    wire AGU_O_done;
    wire acc_done;
    wire set;
    wire core_rst; // to reset FSM and other modules when core is done
    wire [12:0] SR_0;
    wire [5:0] SR_1;
    assign SR_0_debug = SR_0;
    assign SR_1_debug = SR_1;
    
    // Core controller instance
    Core_controller core_controller(
        .CLK(CLK),
        .en(en),
        .rst(rst),
        // SR control
        .mode_in(mode),
        .acc_done(acc_done),
        // Core en counter control
        .width_out_in(width_out),
        .ch_in_in(ch_in),
        .ch_out_in(ch_out),
        // FSM control
        .AGU_O_done(AGU_O_done),
        // output
        .set(set),
        .SR_0(SR_0),
        .SR_1(SR_1),
        .core_done(core_done),
        .core_rst(core_rst),
        .state_debug(state_debug)
    );
    ////////// Controller end //////////

    ////////// output signal //////////
    wire [7:0] addr_cal;
    wire [7:0] addr_store;
    wire [63:0] din_store;
    wire [11:0] Waddr;
    wire [7:0] baddr;
    assign core_tbo_cal_bus = {SR_0[4]|SR_0[5], addr_cal};
    assign core_w_storage_bus = {SR_0[4]|SR_0[5]|SR_0[6], Waddr};
    assign core_b_storage_bus = {SR_0[9], baddr};
    assign core_tbo_store_bus = {SR_1[2], addr_store, din_store};
    ////////// output signal end //////////

    ////////// AGU //////////
    // conv1 counter
    reg [1:0] conv_count;
    always@(posedge CLK) begin
        if(rst) begin
            conv_count <= 0;
        end
        else begin
            if( SR_0[0] && mode==conv ) begin
                if(conv_count == 2) begin
                    conv_count <= 0;
                end
                else begin
                    conv_count <= conv_count + 1;
                end
            end
            else conv_count <= 0;
        end
    end
    
    // AGU_F
    wire boundary;
    AGU_F agu_f(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_0[0] && (conv_count==0)),
        .set(set),
        .padding_in(padding),
        .width_in_in(width_in),
        .width_out_in(width_out),
        .ch_in_in(ch_in),
        .ch_out_in(ch_out),
        .mode_in(mode),
        .stride_X_in(stride_X),
        .faddr(addr_cal),
        .boundary(boundary)
    );

    // AGU_W
    AGU_W agu_w(
        .CLK(CLK),
        .en(SR_0[1]),
        .rst(core_rst),
        .set(set),
        .mode_in(mode),
        .AGU_W_initial_in(AGU_W_initial),
        .width_out_in(width_out),
        .ch_in_in(ch_in),
        .ch_out_in(ch_out),
        .Waddr(Waddr)
    );

    // AGU_B
    AGU_B agu_b(
        .CLK(CLK),
        .en(SR_0[6]),
        .rst(core_rst),
        .set(set),
        .mode_in(mode),
        .AGU_B_initial_in(AGU_B_initial),
        .width_out_in(width_out),
        .ch_in_in(ch_in),
        .ch_out_in(ch_out),
        .baddr(baddr)
    );

    // AGU_O
    AGU_O agu_o(
        .CLK(CLK),
        .en(SR_1[0]),
        .rst(core_rst),
        .set(set),
        .AGU_O_initial_in(AGU_O_initial),
        .width_out_in(width_out),
        .ch_out_in(ch_out),
        .oaddr(addr_store),
        .done(AGU_O_done)
    );
    ////////// AGU end //////////

    ////////// Bus and Buffer//////////
    // Fdata buffer
    wire [63:0] fdata_0, fdata_1, fdata_2, fdata_3;
    Fdata_buffer fdata_buffer(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_0[6]|SR_0[7]),
        .set(set),
        .tile_sel(tile_sel), //3*tile
        .mode_in(mode), //function
        .boundary(boundary),
        .tile_1(tile_1),
        .tile_2(tile_2),
        .tile_3(tile_3),
        .tile_4(tile_4),
        .tile_5(tile_5),
        .tile_6(tile_6),
        .fdata_0(fdata_0),
        .fdata_1(fdata_1),
        .fdata_2(fdata_2),
        .fdata_3(fdata_3)
    );

    // Array_buffer
    wire [63:0] PE_fin_0, PE_fin_1, PE_fin_2, PE_fin_3;
    Array_buffer array_buffer(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_0[7]|SR_0[8]),
        .set(set),
        .fdata_0(fdata_0),
        .fdata_1(fdata_1),
        .fdata_2(fdata_2),
        .fdata_3(fdata_3),
        .mode_in(mode),
        .PE_fin_0(PE_fin_0),
        .PE_fin_1(PE_fin_1),
        .PE_fin_2(PE_fin_2),
        .PE_fin_3(PE_fin_3)
    );

    // W_buffer
    wire [63:0] PE_win_0, PE_win_1, PE_win_2, PE_win_3;
    W_buffer w_buffer(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_0[7]|SR_0[8]),
        .wdata_0(wdata_0),
        .wdata_1(wdata_1),
        .wdata_2(wdata_2),
        .wdata_3(wdata_3),
        .PE_win_0(PE_win_0),
        .PE_win_1(PE_win_1),
        .PE_win_2(PE_win_2),
        .PE_win_3(PE_win_3)
    );

    // B_buffer
    wire [31:0] bias_0, bias_1, bias_2, bias_3;
    B_buffer b_buffer(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_0[11]|SR_0[12]),
        .bdata_0(bdata_0),
        .bdata_1(bdata_1),
        .bdata_2(bdata_2),
        .bdata_3(bdata_3),
        .bias_0(bias_0),
        .bias_1(bias_1),
        .bias_2(bias_2),
        .bias_3(bias_3)
    );
    ////////// Bus end //////////

    ////////// PE Array //////////
    wire [127:0] PE_out_0, PE_out_1, PE_out_2, PE_out_3;
    // PE array instance
    PE_array pe_array(
        .CLK(CLK),
        .en(SR_0[8]|SR_0[9]),
        .rst(rst),
        .set(set),
        .mode_in(mode),
        .PE_fin_0(PE_fin_0),
        .PE_fin_1(PE_fin_1),
        .PE_fin_2(PE_fin_2),
        .PE_fin_3(PE_fin_3),
        .PE_win_0(PE_win_0),
        .PE_win_1(PE_win_1),
        .PE_win_2(PE_win_2),
        .PE_win_3(PE_win_3),
        .PE_out_0(PE_out_0),
        .PE_out_1(PE_out_1),
        .PE_out_2(PE_out_2),
        .PE_out_3(PE_out_3)
    );
    ////////// PE Array //////////

    ////////// Accumulator //////////
    wire [15:0] acc_out_0, acc_out_1, acc_out_2, acc_out_3;
    Accumulator acc_0(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_0[12]),
        .set(set),
        .mode_in(mode),
        .load_bias(SR_0[12]),
        .ReLU_en(ReLU_en),
        .ch_in(ch_in),
        .bias(bias_0),
        .PE_out_0_in(PE_out_0[127:96]),
        .PE_out_1_in(PE_out_1[127:96]),
        .PE_out_2_in(PE_out_2[127:96]),
        .PE_out_3_in(PE_out_3[127:96]),
        .acc_out(acc_out_0),
        .acc_done(acc_done)
        ,
        .acc_result(acc_result_0)
    );
    Accumulator acc_1(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_0[12]),
        .set(set),
        .mode_in(mode),
        .load_bias(SR_0[12]),
        .ReLU_en(ReLU_en),
        .ch_in(ch_in),
        .bias(bias_1),
        .PE_out_0_in(PE_out_0[95:64]),
        .PE_out_1_in(PE_out_1[95:64]),
        .PE_out_2_in(PE_out_2[95:64]),
        .PE_out_3_in(PE_out_3[95:64]),
        .acc_out(acc_out_1)
        ,
        .acc_result(acc_result_1)
    );
    Accumulator acc_2(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_0[12]),
        .set(set),
        .mode_in(mode),
        .load_bias(SR_0[12]),
        .ReLU_en(ReLU_en),
        .ch_in(ch_in),
        .bias(bias_2),
        .PE_out_0_in(PE_out_0[63:32]),
        .PE_out_1_in(PE_out_1[63:32]),
        .PE_out_2_in(PE_out_2[63:32]),
        .PE_out_3_in(PE_out_3[63:32]),
        .acc_out(acc_out_2)
        ,
        .acc_result(acc_result_2)
    );
    Accumulator acc_3(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_0[12]),
        .set(set),
        .mode_in(mode),
        .load_bias(SR_0[12]),
        .ReLU_en(ReLU_en),
        .ch_in(ch_in),
        .bias(bias_3),
        .PE_out_0_in(PE_out_0[31:0]),
        .PE_out_1_in(PE_out_1[31:0]),
        .PE_out_2_in(PE_out_2[31:0]),
        .PE_out_3_in(PE_out_3[31:0]),
        .acc_out(acc_out_3)
        ,
        .acc_result(acc_result_3)
    );
    ////////// Accumulator end //////////

    ////////// Output buffer //////////
    Output_buffer output_buffer(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_1[0]),
        .acc_out({acc_out_0, acc_out_1, acc_out_2, acc_out_3}),
        .core_out(din_store)
    );
    ////////// Output buffer end //////////
    
    //tile buffer define(single port ROM)
    //Tile_buffer_1 tile_buffer_1(.douta(tile_1), .addra(core_tbo_cal_bus[7:0]), .clka(CLK), .ena(core_tbo_cal_bus[8]));
    Tile_buffer_2 tile_buffer_2(.douta(tile_2), .addra(core_tbo_cal_bus[7:0]), .clka(CLK), .ena(core_tbo_cal_bus[8]));
    Tile_buffer_3 tile_buffer_3(.douta(tile_3), .addra(core_tbo_cal_bus[7:0]), .clka(CLK), .ena(core_tbo_cal_bus[8]));
    Tile_buffer_4 tile_buffer_4(.douta(tile_4), .addra(core_tbo_cal_bus[7:0]), .clka(CLK), .ena(core_tbo_cal_bus[8]));
    //Tile_buffer_5 tile_buffer_5(.douta(tile_5), .addra(core_tbo_cal_bus[7:0]), .clka(CLK), .ena(core_tbo_cal_bus[8]n));
    //Tile_buffer_6 tile_buffer_6(.douta(tile_6), .addra(core_tbo_cal_bus[7:0]), .clka(CLK), .ena(core_tbo_cal_bus[8]));
    
    //W_storage define(single port ROM)
    W_storage_0 W_storage_0(.douta(wdata_0), .addra(core_w_storage_bus[11:0]), .clka(CLK), .ena(core_w_storage_bus[12]));
    W_storage_1 W_storage_1(.douta(wdata_1), .addra(core_w_storage_bus[11:0]), .clka(CLK), .ena(core_w_storage_bus[12]));
    W_storage_2 W_storage_2(.douta(wdata_2), .addra(core_w_storage_bus[11:0]), .clka(CLK), .ena(core_w_storage_bus[12]));
    W_storage_3 W_storage_3(.douta(wdata_3), .addra(core_w_storage_bus[11:0]), .clka(CLK), .ena(core_w_storage_bus[12]));

    //B_storage define(single port ROM)
    B_storage_0 B_storage_0(.douta(bdata_0), .addra(core_b_storage_bus[7:0]), .clka(CLK), .ena(core_b_storage_bus[8]));
    B_storage_1 B_storage_1(.douta(bdata_1), .addra(core_b_storage_bus[7:0]), .clka(CLK), .ena(core_b_storage_bus[8]));
    B_storage_2 B_storage_2(.douta(bdata_2), .addra(core_b_storage_bus[7:0]), .clka(CLK), .ena(core_b_storage_bus[8]));
    B_storage_3 B_storage_3(.douta(bdata_3), .addra(core_b_storage_bus[7:0]), .clka(CLK), .ena(core_b_storage_bus[8]));
    
endmodule
