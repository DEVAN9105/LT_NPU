`timescale 1ns / 1ps

module Core(
    // basic
    input CLK, input rst, input en,
    // control signal
    input [2:0] mode_in,
    input [8:0] tile_sel_in,
    input [1:0] stride_X_in,
    input ReLU_en_in,
    // AGU initial
    input [11:0] AGU_W_initial_in,
    input [7:0] AGU_B_initial_in,
    input [7:0] AGU_O_initial_in,
    // tile size
    input [6:0] width_in_in,
    input [6:0] width_out_in,
    input [7:0] ch_in_in,
    input [7:0] ch_out_in,
    // cal tile buffer
    output valid_cal,
    output [7:0] addr_cal,
    input [63:0] tile_1,
    input [63:0] tile_2,
    input [63:0] tile_3,
    input [63:0] tile_4,
    input [63:0] tile_5,
    input [63:0] tile_6,
    // W_storage
    output W_storage_en,
    output [11:0] Waddr,
    input [63:0] wdata_0,
    input [63:0] wdata_1,
    input [63:0] wdata_2,
    input [63:0] wdata_3,
    // B_storage
    output B_storage_en,
    output [7:0] baddr,
    input [31:0] bdata_0,
    input [31:0] bdata_1,
    input [31:0] bdata_2,
    input [31:0] bdata_3,
    // store tile buffer
    output valid_store,
    output [7:0] addr_store,
    output [63:0] din_store,
    // core done
    output core_done
    );
    
    // mode define
    parameter conv = 0, maxpooling = 1, DW = 2, PW = 3, GAP = 4;

    ////////// input buffer ////////// 
    reg [2:0] mode;
    reg [8:0] tile_sel;
    reg ReLU_en;
    reg [1:0] stride_X;
    reg [6:0] width_in;
    reg [6:0] width_out;
    reg [7:0] ch_in;
    reg [7:0] ch_out;
    reg [11:0] AGU_W_initial;
    reg [7:0] AGU_B_initial;
    reg [7:0] AGU_O_initial;
    always@(posedge CLK) begin
        mode <= mode_in;
        tile_sel <= tile_sel_in;
        stride_X <= stride_X_in;
        ReLU_en <= ReLU_en_in;
        width_in <= width_in_in;
        width_out <= width_out_in;
        ch_in <= ch_in_in;
        ch_out <= ch_out_in;
        AGU_W_initial <= AGU_W_initial_in;
        AGU_B_initial <= AGU_B_initial_in;
        AGU_O_initial <= AGU_O_initial_in;
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
        .mode_in(mode),
        .width_out_in(width_out),
        .ch_in_in(ch_in),
        .ch_out_in(ch_out),
        .SR_0_en(SR_0_en)
    );

    // SR
    wire acc_done;
    wire [12:0] SR_0;
    wire [5:0] SR_1;
    Core_SR SR(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_0_en),
        .acc_done(acc_done),
        .mode_in(mode),
        .state(state),
        .SR_0(SR_0),
        .SR_1(SR_1)
    );
    ////////// Controller end //////////

    ////////// output signal //////////
    assign valid_cal = SR_0[4];
    assign W_storage_en = SR_0[4];
    assign B_storage_en = SR_0[9];
    assign valid_store = SR_1[2];
    ////////// output signal end //////////

    ////////// AGU //////////
    // conv1 counter
    reg [1:0] conv_count;
    always@(posedge CLK) begin
        if(rst) begin
            conv_count <= 0;
        end
        else begin
            if( SR_0[0] && mode==0 ) begin
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
        .en(SR_0[0]/* && (conv_count==0)*/),
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
        .en_in(SR_0[6]),
        .rst(core_rst),
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
        .en(SR_0[6]),
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
        .en(SR_0[7]),
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
    .en(SR_0[7]),
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
    .en(SR_0[11]),
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
    reg PE_en_00, PE_en_01, PE_en_02, PE_en_03;
    reg PE_en_10, PE_en_11, PE_en_12, PE_en_13;
    reg PE_en_20, PE_en_21, PE_en_22, PE_en_23;
    reg PE_en_30, PE_en_31, PE_en_32, PE_en_33;
    always@(posedge CLK) begin
        if(rst) begin
            PE_en_00 <= 0; PE_en_01 <= 0; PE_en_02 <= 0; PE_en_03 <= 0;
            PE_en_10 <= 0; PE_en_11 <= 0; PE_en_12 <= 0; PE_en_13 <= 0;
            PE_en_20 <= 0; PE_en_21 <= 0; PE_en_22 <= 0; PE_en_23 <= 0;
            PE_en_30 <= 0; PE_en_31 <= 0; PE_en_32 <= 0; PE_en_33 <= 0;
        end
        else begin
            case(mode)
                conv, maxpooling, DW: begin
                    PE_en_00 <= 1; PE_en_01 <= 1; PE_en_02 <= 1; PE_en_03 <= 1;
                    PE_en_10 <= 1; PE_en_11 <= 1; PE_en_12 <= 1; PE_en_13 <= 1;
                    PE_en_20 <= 1; PE_en_21 <= 1; PE_en_22 <= 1; PE_en_23 <= 1;
                    PE_en_30 <= 0; PE_en_31 <= 0; PE_en_32 <= 0; PE_en_33 <= 0;
                end
                PW, GAP: begin
                    PE_en_00 <= 1; PE_en_01 <= 1; PE_en_02 <= 1; PE_en_03 <= 1;
                    PE_en_10 <= 1; PE_en_11 <= 1; PE_en_12 <= 1; PE_en_13 <= 1;
                    PE_en_20 <= 1; PE_en_21 <= 1; PE_en_22 <= 1; PE_en_23 <= 1;
                    PE_en_30 <= 1; PE_en_31 <= 1; PE_en_32 <= 1; PE_en_33 <= 1;
                end
                default: begin
                    PE_en_00 <= 0; PE_en_01 <= 0; PE_en_02 <= 0; PE_en_03 <= 0;
                    PE_en_10 <= 0; PE_en_11 <= 0; PE_en_12 <= 0; PE_en_13 <= 0;
                    PE_en_20 <= 0; PE_en_21 <= 0; PE_en_22 <= 0; PE_en_23 <= 0;
                    PE_en_30 <= 0; PE_en_31 <= 0; PE_en_32 <= 0; PE_en_33 <= 0;
                end
            endcase
        end
    end
    reg [1:0] PE_mode;
    always@(posedge CLK) begin
        if(core_rst) PE_mode <= 0;
        else begin
            case(mode)
                conv: PE_mode <= 0;
                maxpooling: PE_mode <= 2;
                DW: PE_mode <= 0;
                PW: PE_mode <= 0;
                GAP: PE_mode <= 1;
                default: PE_mode <= 0;
            endcase
        end
    end

    // 4*4 array 
    wire [31:0] PE_out_00, PE_out_01, PE_out_02, PE_out_03;
    wire [31:0] PE_out_10, PE_out_11, PE_out_12, PE_out_13;
    wire [31:0] PE_out_20, PE_out_21, PE_out_22, PE_out_23;
    wire [31:0] PE_out_30, PE_out_31, PE_out_32, PE_out_33;
    PE PE_00(.CLK(CLK), .en(SR_0[8] & PE_en_00), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_0[63:48]), .PE_B(PE_win_0[63:48]), .PE_out(PE_out_00));
    PE PE_01(.CLK(CLK), .en(SR_0[8] & PE_en_01), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_0[47:32]), .PE_B(PE_win_1[63:48]), .PE_out(PE_out_01));
    PE PE_02(.CLK(CLK), .en(SR_0[8] & PE_en_02), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_0[31:16]), .PE_B(PE_win_2[63:48]), .PE_out(PE_out_02));
    PE PE_03(.CLK(CLK), .en(SR_0[8] & PE_en_03), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_0[15:0 ]), .PE_B(PE_win_3[63:48]), .PE_out(PE_out_03));
    PE PE_10(.CLK(CLK), .en(SR_0[8] & PE_en_10), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_1[63:48]), .PE_B(PE_win_0[47:32]), .PE_out(PE_out_10));
    PE PE_11(.CLK(CLK), .en(SR_0[8] & PE_en_11), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_1[47:32]), .PE_B(PE_win_1[47:32]), .PE_out(PE_out_11));
    PE PE_12(.CLK(CLK), .en(SR_0[8] & PE_en_12), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_1[31:16]), .PE_B(PE_win_2[47:32]), .PE_out(PE_out_12));
    PE PE_13(.CLK(CLK), .en(SR_0[8] & PE_en_13), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_1[15:0 ]), .PE_B(PE_win_3[47:32]), .PE_out(PE_out_13));
    PE PE_20(.CLK(CLK), .en(SR_0[8] & PE_en_20), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_2[63:48]), .PE_B(PE_win_0[31:16]), .PE_out(PE_out_20));
    PE PE_21(.CLK(CLK), .en(SR_0[8] & PE_en_21), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_2[47:32]), .PE_B(PE_win_1[31:16]), .PE_out(PE_out_21));
    PE PE_22(.CLK(CLK), .en(SR_0[8] & PE_en_22), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_2[31:16]), .PE_B(PE_win_2[31:16]), .PE_out(PE_out_22));
    PE PE_23(.CLK(CLK), .en(SR_0[8] & PE_en_23), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_2[15:0 ]), .PE_B(PE_win_3[31:16]), .PE_out(PE_out_23));
    PE PE_30(.CLK(CLK), .en(SR_0[8] & PE_en_30), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_3[63:48]), .PE_B(PE_win_0[15:0 ]), .PE_out(PE_out_30));
    PE PE_31(.CLK(CLK), .en(SR_0[8] & PE_en_31), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_3[47:32]), .PE_B(PE_win_1[15:0 ]), .PE_out(PE_out_31));
    PE PE_32(.CLK(CLK), .en(SR_0[8] & PE_en_32), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_3[31:16]), .PE_B(PE_win_2[15:0 ]), .PE_out(PE_out_32));
    PE PE_33(.CLK(CLK), .en(SR_0[8] & PE_en_33), .rst(core_rst), .PE_mode(PE_mode), .PE_A(PE_fin_3[15:0 ]), .PE_B(PE_win_3[15:0 ]), .PE_out(PE_out_33));
    ////////// PE Array //////////

    ////////// Accumulator //////////
    wire [15:0] acc_out_0, acc_out_1, acc_out_2, acc_out_3;
    Accumulator acc_0(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_0[12]),
        .mode_in(mode),
        .load_bias(SR_0[12]),
        .ReLU_en(ReLU_en),
        .ch_in(ch_in),
        .bias(bias_0),
        .PE_out_0_in(PE_out_00),
        .PE_out_1_in(PE_out_10),
        .PE_out_2_in(PE_out_20),
        .PE_out_3_in(PE_out_30),
        .acc_out(acc_out_0),
        .acc_done(acc_done)
    );
    Accumulator acc_1(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_0[12]),
        .mode_in(mode),
        .load_bias(SR_0[12]),
        .ReLU_en(ReLU_en),
        .ch_in(ch_in),
        .bias(bias_1),
        .PE_out_0_in(PE_out_01),
        .PE_out_1_in(PE_out_11),
        .PE_out_2_in(PE_out_21),
        .PE_out_3_in(PE_out_31),
        .acc_out(acc_out_1)
    );
    Accumulator acc_2(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_0[12]),
        .mode_in(mode),
        .load_bias(SR_0[12]),
        .ReLU_en(ReLU_en),
        .ch_in(ch_in),
        .bias(bias_2),
        .PE_out_0_in(PE_out_02),
        .PE_out_1_in(PE_out_12),
        .PE_out_2_in(PE_out_22),
        .PE_out_3_in(PE_out_32),
        .acc_out(acc_out_2)
    );
    Accumulator acc_3(
        .CLK(CLK),
        .rst(core_rst),
        .en(SR_0[12]),
        .mode_in(mode),
        .load_bias(SR_0[12]),
        .ReLU_en(ReLU_en),
        .ch_in(ch_in),
        .bias(bias_3),
        .PE_out_0_in(PE_out_03),
        .PE_out_1_in(PE_out_13),
        .PE_out_2_in(PE_out_23),
        .PE_out_3_in(PE_out_33),
        .acc_out(acc_out_3)
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
    
endmodule
