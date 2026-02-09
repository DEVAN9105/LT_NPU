`timescale 1ns / 1ps

module GLB_input(
    input CLK,
    input en,
    input rst,
    input glb_in_mode, // 0: pre_processing, 1: core
    // AGU_T
    input [22:0] AGU_T_param, // {AGU_T_initial[11:0], tile_width[6:0], tile_ch[7:0]}
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
    input [63:0] CIU_wb_L,
    input [63:0] CIU_wb_R,
    input [63:0] PP_wb,
    input en_wb_L,
    input en_wb_R,
    input en_wb_pp,
    // glb control
    output glb_a_en,
    output glb_a_we,
    output [63:0] din_glb,
    // done signal
    output done
    );
    
    ////////// GLB control //////////
    wire AGU_T_en;
    wire AGU_T_rst;
    wire [8:0] SR_1;
    wire glb_in_rst;
    wire AGU_T_done;
    wire data_valid = (en_wb_L | en_wb_R | en_wb_pp);
    GLB_input_controller glb_input_control(
        .CLK(CLK),
        .en(en),
        .rst(rst),
        .data_valid(data_valid),
        .AGU_T_done(AGU_T_done),
        .AGU_T_en(AGU_T_en),
        .AGU_T_rst(AGU_T_rst),
        .SR_1(SR_1),
        .done(done),
        .glb_in_rst(glb_in_rst)
    );
    ////////// GLB control end //////////

    ////////// signal assign //////////
    assign glb_a_en = SR_1[5];
    assign glb_a_we = SR_1[5];
    ////////// signal assign end //////////

    ////////// AGU_T //////////
    reg [2:0] core;
    wire write_back_en;
    always@(posedge CLK) begin
        if(glb_in_mode == 0) begin
            core <= 3'd0; // pre_processing tile
        end
        else begin
            core <= 3'd5;
        end
    end
    wire [2:0] core_pointer;
    AGU_T agu_t(
        .CLK(CLK),
        .en(AGU_T_en),
        .rst(AGU_T_rst),
        .AGU_T_initial_in(AGU_T_param[22:15]),
        .tile_width_in(AGU_T_param[14:8]),
        .tile_ch_in(AGU_T_param[7:0]),
        .core(core),
        .core_pointer(core_pointer),
        .taddr(taddr),
        .en_next(write_back_en),
        .done(AGU_T_done)
    );
    ////////// AGU_T end //////////

    ////////// write back enable //////////
    always@(*) begin
        if(glb_in_mode == 0) begin
            wb_en = 7'b0000001; // pre_processing tile
        end
        else begin
            if(write_back_en) begin
                case(core_pointer)
                    0: wb_en = 7'b0000010;
                    1: wb_en = 7'b0000100;
                    2: wb_en = 7'b0001000;
                    3: wb_en = 7'b0010000;
                    4: wb_en = 7'b0100000;
                    5: wb_en = 7'b1000000;
                    default: wb_en = 7'b0000000;
                endcase
            end
            else begin
                wb_en = 7'b0000000;
            end
        end
    end
    ////////// write back enable end //////////

    ////////// data buffer //////////
    reg [1:0] glb_in_sel;
    wire [2:0] input_en_bus = {en_wb_pp, en_wb_L, en_wb_R};
    always@(*) begin
        if(glb_in_rst) begin
            glb_in_sel = 2'd0;
        end
        else begin
            case(input_en_bus)
                3'b100: glb_in_sel = 2'd0; // pre_processing
                3'b010: glb_in_sel = 2'd1; // core 2
                3'b001: glb_in_sel = 2'd2; // core 5
                default: glb_in_sel = 2'd0;
            endcase
        end
    end
    reg [63:0] data_buffer_0, data_buffer_1;
    // data buffer 0
    always@(posedge CLK) begin
        if(glb_in_rst) begin
            data_buffer_0 <= 64'd0;
        end
        else begin
            if(data_valid) begin
                case(glb_in_sel)
                    2'd0: data_buffer_0 <= PP_wb;
                    2'd1: data_buffer_0 <= CIU_wb_L;
                    2'd2: data_buffer_0 <= CIU_wb_R;
                    default: data_buffer_0 <= 64'd0;
                endcase
            end
            else begin
                data_buffer_0 <= data_buffer_0;
            end
        end
    end
    // data buffer 1
    always@(posedge CLK) begin
        if(glb_in_rst) begin
            data_buffer_1 <= 64'd0;
        end
        else begin
            if(SR_1[0]) begin
                data_buffer_1 <= data_buffer_0;
            end
            else begin
                data_buffer_1 <= data_buffer_1;
            end
        end
    end
    ////////// data buffer end //////////

    ////////// AGU_G //////////
    AGU_G agu_g(
        .CLK(CLK),
        .en(data_valid),
        .rst(glb_in_rst),
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
        .rst(glb_in_rst),
        .en(SR_1[1]),
        .data(data_buffer_1),
        .data_transpose(din_glb)
    );
    ////////// Input Transpose end //////////

endmodule
