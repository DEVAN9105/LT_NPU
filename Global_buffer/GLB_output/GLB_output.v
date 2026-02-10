`timescale 1ns / 1ps

module GLB_output(
    input CLK,
    input en,
    input rst,
    input [1:0] glb_out_mode, // 0: multi_cast, 1: uni_cast, 2: post_processing
    // AGU_G
    input [28:0] AGU_G_param, // {AGU_G_initial[13:0], glb_width[6:0], glb_ch[7:0]}
    output [10:0] ch_to_Y_bus, // {ch_to_Y_en, ch_sum[9:0]}
    input [11:0] ch_to_Y_Y, // addr offset for AGU_G
    // glb
    output [14:0] glb_output_bus, // {enb, gaddr[13:0]}
    input [63:0] glb_doutb,
    // AGU_T
    input [22:0] AGU_T_param, // {AGU_T_initial[11:0], tile_width[6:0], tile_ch[7:0]}
    // output tile
    output [78:0] glb_load_bus, // {load_sel[6:0], taddr[7:0], glb_doutb_transposed[63:0]}
    // done signal
    output done
    );
    
    ////////// GLB control //////////
    wire [9:0] SR;
    wire set;
    wire glb_out_rst;
    wire AGU_G_done;
    wire AGU_G_en;
    wire AGU_G_en_next;
    GLB_output_controller glb_output_controller(
        .CLK(CLK),
        .en(en),
        .rst(rst),
        .set(set),
        .AGU_G_done(AGU_G_done),
        .AGU_G_en(AGU_G_en),
        .AGU_G_en_next(AGU_G_en_next),
        .SR(SR),
        .done(done),
        .glb_out_rst(glb_out_rst)
    );
    ////////// GLB control end //////////

    ////////// signal assign //////////
    reg [6:0] load_sel; // {core 1~6, Post_processing}
    wire [7:0] taddr;
    wire [13:0] gaddr;
    wire [63:0] glb_doutb_transposed;
    assign glb_output_bus = {AGU_G_en_next, gaddr[13:0]};
    assign glb_load_bus = {load_sel, taddr_buffer, glb_doutb_transposed};
    ////////// signal assign end //////////

    ////////// AGU_G //////////
    AGU_G agu_g(
        .CLK(CLK),
        .en(AGU_G_en),
        .rst(glb_out_rst),
        .set(set),
        .AGU_G_param(AGU_G_param),
        .ch_to_Y_en(ch_to_Y_bus[10]),
        .ch_sum(ch_to_Y_bus[9:0]),
        .Y(ch_to_Y_Y),
        .gaddr(gaddr),
        .en_next(AGU_G_en_next),
        .done(AGU_G_done)
    );
    ////////// AGU_G end //////////

    ////////// AGU_T //////////
    reg [2:0] core;
    wire [2:0] core_pointer;
    reg [7:0] taddr_buffer;
    wire AGU_T_en_next;
    reg [22:0] AGU_T_param_decoded;
    // channel max: 39
    wire [7:0] tile_ch_decoded = ((AGU_T_param[7:0] + 1) << 2) + ((AGU_T_param[7:0] + 1) << 1) - 1; // tile_ch * 6
    // core & channel decode
    always@(*) begin
        if(glb_out_mode == 2'd0 || glb_out_mode == 2'd2) begin
            core = 3'd0; // pre_processing tile
            AGU_T_param_decoded = {AGU_T_param[22:8], tile_ch_decoded}; // for pre_processing, tile_ch is always 1
        end
        else begin
            core = 3'd5; // multi_cast tile
            AGU_T_param_decoded = AGU_T_param;
        end
    end

    AGU_T agu_t(
        .CLK(CLK),
        .en(SR[2]),
        .rst(glb_out_rst),
        .set(set),
        .AGU_T_param(AGU_T_param_decoded),
        .core(core),
        .core_pointer(core_pointer),
        .taddr(taddr),
        .en_next(AGU_T_en_next)
    );

    // load_sel decoder
    always@(posedge CLK) begin
        if (glb_out_rst) begin
            load_sel <= 7'd0;
        end
        else begin
            if(AGU_T_en_next) begin
                if(glb_out_mode == 2'd2) begin
                    load_sel <= 7'b0000001; // pre_processing tile only write to core 1
                end
                else begin
                    case(core_pointer)
                        3'b000: load_sel <= 7'b1000000;
                        3'b001: load_sel <= 7'b0100000;
                        3'b010: load_sel <= 7'b0010000;
                        3'b011: load_sel <= 7'b0001000;
                        3'b100: load_sel <= 7'b0000100;
                        3'b101: load_sel <= 7'b0000010;
                        default: load_sel <= 7'b0000000;
                    endcase
                end
            end
            else begin
                load_sel <= 7'b0000000;
            end
        end
    end

    // taddr buffer
    always@(posedge CLK) begin
        if (glb_out_rst) begin
            taddr_buffer <= 8'b0;
        end
        else begin
            taddr_buffer <= taddr;
        end
    end
    ////////// AGU_T end //////////

    ////////// Output Transpose //////////
    Transpose transpose(
        .CLK(CLK),
        .rst(glb_out_rst),
        .en(SR[2]),
        .data(glb_doutb),
        .data_transpose(glb_doutb_transposed)
    );
    ////////// Output Transpose end //////////

endmodule
