`timescale 1ns / 1ps

module GLB_operator(
    input CLK,
    input en,
    input rst,
    ////////// Ch_to_Y //////////
    input [10:0] ch_to_Y_initial, // 2048
    ////////// GLB_input //////////
    input glb_in_mode, // 0: pre_processing, 1: core
    // AGU_T
    input [7:0] input_AGU_T_initial,
    input [6:0] input_tile_width,
    input [7:0] input_tile_ch,
    // AGU_G
    input [13:0] input_AGU_G_initial,
    input [6:0] input_glb_width,
    input [7:0] input_glb_ch,
    // input tile
    output reg [8:0] wb_pp,
    output reg [10:0] wb_0,
    output reg [10:0] wb_1,
    input [64:0] CIU_wb_1, // valid | data
    input [64:0] CIU_wb_2,
    input [64:0] CIU_wb_3,
    input [64:0] CIU_wb_4,
    input [64:0] CIU_wb_5,
    input [64:0] CIU_wb_6,
    input [64:0] PP_wb,
    ////////// GLB_output //////////
    // AGU_T
    input [2:0] output_core,
    input [7:0] output_AGU_T_initial,
    input [6:0] output_tile_width,
    input [7:0] output_tile_ch,
    // AGU_G
    input [13:0] output_AGU_G_initial,
    input [6:0] output_glb_width,
    input [7:0] output_glb_ch,
    // output tile
    output reg [74:0] load_0,
    output reg [74:0] load_1,
    ////////// glb control //////////
    output glb_a_en,
    output glb_a_we,
    output [63:0] din_glb,
    output glb_b_en,
    input [63:0] dout_glb,
    // done signal
    output input_done,
    output output_done
    );

    ////////// ch_to_Y //////////
    wire input_ch_to_Y_en, output_ch_to_Y_en;
    wire [9:0] input_ch_sum, output_ch_sum;
    wire [10:0] input_ch, output_ch;
    wire [9:0] input_Y, output_Y;

    assign input_ch = ch_to_Y_initial + input_ch_sum;
    assign output_ch = ch_to_Y_initial + output_ch_sum;

    Ch_to_Y ch_to_Y(
        // port a
        .clka(CLK),
        .ena(input_ch_to_Y_en),
        .addra(input_ch),
        .douta(input_Y),
        // port b
        .clkb(CLK),
        .enb(output_ch_to_Y_en),
        .addrb(output_ch),
        .doutb(output_Y)
    );
    ////////// ch_to_Y end //////////

    ////////// GLB //////////
    wire we_a, en_a, en_b;
    wire [13:0] addr_a, addr_b;
    GLB glb(
        .clk(CLK),
        .rst(rst),
        // port a
        .en_a(en_a),
        .we_a(we_a),
        .addr_a(addr_a),
        .din_a(din_a),
        // port b
        .en_b(en_b),
        .addr_b(addr_b),
        .dout_b(dout_b)
    );
    ////////// GLB end //////////

    ////////// GLB_input //////////
    // wb control signal
    wire [6:0] wb_en;
    wire [7:0] taddr;
    always@(posedge CLK) begin
        if(rst) begin
            wb_0 <= 11'd0;
            wb_1 <= 11'd0;
            wb_pp <= 9'd0;
        end
        else begin
            wb_0 <= {wb_en[3:1], taddr};
            wb_1 <= {wb_en[6:4], taddr};
            wb_pp <= {wb_en[0], taddr};
        end
    end

    // wb data buffer
    reg [64:0] CIU_wb_0, CIU_wb_1;
    wire [2:0] mux_sel_0, mux_sel_1;
    assign mux_sel_0 = {CIU_wb_1[64], CIU_wb_2[64], CIU_wb_3[64]};
    assign mux_sel_1 = {CIU_wb_4[64], CIU_wb_5[64], CIU_wb_6[64]};
    always@(posedge CLK) begin
        case(mux_sel_0)
            3'b100: CIU_wb_0 <= CIU_wb_1;
            3'b010: CIU_wb_0 <= CIU_wb_2;
            3'b001: CIU_wb_0 <= CIU_wb_3;
            default: CIU_wb_0 <= 65'd0;
        endcase
        case(mux_sel_1)
            3'b100: CIU_wb_1 <= CIU_wb_4;
            3'b010: CIU_wb_1 <= CIU_wb_5;
            3'b001: CIU_wb_1 <= CIU_wb_6;
            default: CIU_wb_1 <= 65'd0;
        endcase
    end

    GLB_input glb_input(
        .CLK(CLK),
        .en(en),
        .rst(rst),
        .glb_in_mode(glb_in_mode),
        // AGU_T
        .AGU_T_initial_in(input_AGU_T_initial),
        .tile_width_in(input_tile_width),
        .tile_ch_in(input_tile_ch),
        // AGU_G
        .AGU_G_initial_in(input_AGU_G_initial),
        .glb_width_in(input_glb_width),
        .glb_ch_in(input_glb_ch),
        .ch_to_Y_en(input_ch_to_Y_en),
        .ch_sum(input_ch_sum),
        .Y(input_Y),
        .gaddr(addr_a),
        // input tile
        .wb_en(wb_en), // 0: pre_processing tile, 1~6: core
        .taddr(taddr),
        .en_wb_0(CIU_wb_0[64]),
        .en_wb_1(CIU_wb_1[64]),
        .en_wb_pp(PP_wb[64]),
        .CIU_wb_0(CIU_wb_0[63:0]),
        .CIU_wb_1(CIU_wb_1[63:0]),
        .PP_wb(PP_wb[63:0]),
        // glb control
        .glb_a_en(glb_a_en),
        .glb_a_we(glb_a_we),
        .din_glb(din_glb),
        // done signal
        .done(input_done)
    );
    ////////// GLB_input end //////////

    ////////// GLB_output //////////
    // load data buffer
    wire [5:0] load_en;
    wire [71:0] CIU_load;
    always@(posedge CLK) begin
        if(rst) begin
            load_0 <= 75'd0;
            load_1 <= 75'd0;
        end
        else begin
            load_0 <= {load_en[2:0], CIU_load};
            load_1 <= {load_en[5:3], CIU_load};
        end
    end

    GLB_output glb_output(
        .CLK(CLK),
        .en(en),
        .rst(rst),
        // AGU_T
        .core(output_core),
        .AGU_T_initial_in(output_AGU_T_initial),
        .tile_width_in(output_tile_width),
        .tile_ch_in(output_tile_ch),
        // AGU_G
        .AGU_G_initial_in(output_AGU_G_initial),
        .glb_width_in(output_glb_width),
        .glb_ch_in(output_glb_ch),
        .ch_to_Y_en(output_ch_to_Y_en),
        .ch_sum(output_ch_sum),
        .Y(output_Y),
        .gaddr(output_gaddr),
        // output tile
        .load_en(load_en),
        .CIU_load(CIU_load),
        // glb control
        .glb_b_en(en_b),
        .dout_glb(dout_glb),
        // done signal
        .done(output_done)
    );
    ////////// GLB_output end //////////
    
endmodule
