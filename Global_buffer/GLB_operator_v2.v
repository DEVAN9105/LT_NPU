`timescale 1ns / 1ps

module GLB_operator(
    input CLK,
    input en,
    input rst,
    ////////// Ch_to_Y //////////
    input [10:0] ch_to_Y_initial, // 0~2047
    ////////// GLB_input //////////
    input glb_in_mode, // 0: pre_processing, 1: core
    // AGU_G
    input [28:0] input_AGU_G_param, // {AGU_G_initial, glb_width, glb_ch}
    // input tile
    output reg [8:0] glb_to_prep_bus,
    output reg [10:0] glb_to_ciu_input_L_bus,
    output reg [10:0] glb_to_ciu_input_R_bus,
    input [64:0] ciu_to_glb_wb_1, // valid | data
    input [64:0] ciu_to_glb_wb_2,
    input [64:0] ciu_to_glb_wb_3,
    input [64:0] ciu_to_glb_wb_4,
    input [64:0] ciu_to_glb_wb_5,
    input [64:0] ciu_to_glb_wb_6,
    input [64:0] prep_to_glb_wb,
    ////////// GLB_output //////////
    // AGU_T
    input [2:0] output_core,
    // AGU_G
    input [28:0] output_AGU_G_param, // {AGU_G_initial, glb_width, glb_ch}
    // output tile
    output reg [74:0] glb_to_ciu_output_L_bus,
    output reg [74:0] glb_to_ciu_output_R_bus,
    // done signal
    output input_done,
    output output_done
    );

    ////////// tile parameter //////////
    wire [6:0] input_tile_width = ((input_AGU_G_param[14:8] + 1) << 1) - 1;
    wire [7:0] input_tile_ch = ((input_AGU_G_param[7:0] + 1) >> 1) - 1;
    wire [6:0] output_tile_width = ((output_AGU_G_param[14:8] + 1) << 1) - 1;
    wire [7:0] output_tile_ch = ((output_AGU_G_param[7:0] + 1) >> 1) - 1;
    wire [7:0] input_AGU_T_initial = 0;
    wire [7:0] output_AGU_T_initial = 0;
    ////////// tile parameter end //////////


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
    wire [63:0] din_a, dout_b;
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
            glb_to_prep_bus <= 11'd0;
            glb_to_ciu_input_L_bus <= 11'd0;
            glb_to_ciu_input_R_bus <= 11'd0;
        end
        else begin
            glb_to_prep_bus <= {wb_en[3:1], taddr};
            glb_to_ciu_input_L_bus <= {wb_en[6:4], taddr};
            glb_to_ciu_input_R_bus <= {wb_en[0], taddr};
        end
    end

    // wb data buffer
    reg [64:0] CIU_wb_L, CIU_wb_R;
    wire [2:0] mux_sel_0, mux_sel_1;
    assign mux_sel_0 = {ciu_to_glb_wb_1[64], ciu_to_glb_wb_2[64], ciu_to_glb_wb_3[64]};
    assign mux_sel_1 = {ciu_to_glb_wb_4[64], ciu_to_glb_wb_5[64], ciu_to_glb_wb_6[64]};
    always@(posedge CLK) begin
        if(rst) begin
            CIU_wb_L <= 65'd0;
            CIU_wb_R <= 65'd0;
        end
        else begin
            case(mux_sel_0)
                3'b100: CIU_wb_L <= ciu_to_glb_wb_1;
                3'b010: CIU_wb_L <= ciu_to_glb_wb_2;
                3'b001: CIU_wb_L <= ciu_to_glb_wb_3;
                default: CIU_wb_L <= 65'd0;
            endcase
            case(mux_sel_1)
                3'b100: CIU_wb_R <= ciu_to_glb_wb_4;
                3'b010: CIU_wb_R <= ciu_to_glb_wb_5;
                3'b001: CIU_wb_R <= ciu_to_glb_wb_6;
                default: CIU_wb_R <= 65'd0;
            endcase
        end
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
        .AGU_G_initial_in(input_AGU_G_param[28:15]),
        .glb_width_in(input_AGU_G_param[14:8]),
        .glb_ch_in(input_AGU_G_param[7:0]),
        .ch_to_Y_en(input_ch_to_Y_en),
        .ch_sum(input_ch_sum),
        .Y(input_Y),
        .gaddr(addr_a),
        // input tile
        .wb_en(wb_en), // 0: pre_processing tile, 1~6: core
        .taddr(taddr),
        .en_wb_L(CIU_wb_L[64]),
        .en_wb_R(CIU_wb_R[64]),
        .en_wb_pp(prep_to_glb_wb[64]),
        .CIU_wb_L(CIU_wb_L[63:0]),
        .CIU_wb_R(CIU_wb_R[63:0]),
        .PP_wb(prep_to_glb_wb[63:0]),
        // glb control
        .glb_a_en(en_a),
        .glb_a_we(we_a),
        .din_glb(din_a),
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
            glb_to_ciu_output_L_bus <= 75'd0;
            glb_to_ciu_output_R_bus <= 75'd0;
        end
        else begin
            glb_to_ciu_output_L_bus <= {load_en[2:0], CIU_load};
            glb_to_ciu_output_R_bus <= {load_en[5:3], CIU_load};
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
        .AGU_G_initial_in(output_AGU_G_param[28:15]),
        .glb_width_in(output_AGU_G_param[14:8]),
        .glb_ch_in(output_AGU_G_param[7:0]),
        .ch_to_Y_en(output_ch_to_Y_en),
        .ch_sum(output_ch_sum),
        .Y(output_Y),
        .gaddr(addr_b),
        // output tile
        .load_en(load_en),
        .CIU_load(CIU_load),
        // glb control
        .glb_b_en(en_b),
        .dout_glb(dout_b),
        // done signal
        .done(output_done)
    );
    ////////// GLB_output end //////////
    
endmodule
