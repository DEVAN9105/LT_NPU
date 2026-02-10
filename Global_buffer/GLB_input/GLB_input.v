`timescale 1ns / 1ps

module GLB_input(
    input CLK,
    input en,
    input rst,
    input [1:0] glb_in_mode, // 0: pre_processing, 1: core
    // AGU_T
    input [22:0] AGU_T_param, // {AGU_T_initial[11:0], tile_width[6:0], tile_ch[7:0]}
    // AGU_G
    input [28:0] AGU_G_param, // {AGU_G_initial[13:0], glb_width[6:0], glb_ch[7:0]}
    output [10:0] ch_to_Y_bus, // {ch_to_Y_en, ch_sum[9:0]}
    input [11:0] ch_to_Y_Y,
    // input tile
    output [14:0] wb_tile_addr_bus, // {wb_sel[6:0], taddr[7:0]}
    input [64:0] ciu_glb_wb_bus_123, // {wb_en_123, wb_data_123[63:0]}
    input [64:0] ciu_glb_wb_bus_456, // {wb_en_456, wb_data_456[63:0]}
    input [64:0] prep_glb_wb_bus, // {wb_en_pp, wb_data_pp[63:0]}
    // glb
    output [78:0] glb_input_bus, // {glb_ena, gaddr[13:0], glb_dina[63:0]}
    // done signal
    output done
    );
    
    ////////// GLB input control //////////
    wire AGU_T_en;
    wire [5:0] SR;
    wire set;
    wire glb_in_rst;
    wire AGU_T_done;
    wire wb_data_valid = (ciu_glb_wb_bus_123[64] | ciu_glb_wb_bus_456[64] | prep_glb_wb_bus[64]);
    GLB_input_controller glb_input_control(
        .CLK(CLK),
        .en(en),
        .rst(rst),
        .set(set),
        .wb_data_valid(wb_data_valid),
        .AGU_T_done(AGU_T_done),
        .AGU_T_en(AGU_T_en),
        .SR(SR),
        .done(done),
        .glb_in_rst(glb_in_rst)
    );
    ////////// GLB input control end //////////

    ////////// signal assign //////////
    assign glb_input_bus[78] = SR[5];
    ////////// signal assign end //////////

    ////////// AGU_T //////////
    reg [2:0] core;
    wire write_back_en;
    always@(posedge CLK) begin
        if(glb_in_mode == 2'd0) begin
            core <= 3'd0; // pre_processing tile
        end
        else begin
            core <= 3'd5;
        end
    end
    wire [2:0] core_pointer;
    wire [7:0] taddr;
    AGU_T agu_t(
        .CLK(CLK),
        .en(AGU_T_en),
        .rst(glb_in_rst),
        .set(set),
        .AGU_T_param(AGU_T_param),
        .core(core),
        .core_pointer(core_pointer),
        .taddr(taddr),
        .en_next(write_back_en),
        .done(AGU_T_done)
    );
    ////////// AGU_T end //////////

    ////////// write back enable //////////
    reg [6:0] wb_sel;
    always@(*) begin
        if(glb_in_mode == 2'b00) begin
            wb_sel = 7'b0000001; // pre_processing tile
        end
        else begin
            if(write_back_en) begin
                case(core_pointer)
                    0: wb_sel = 7'b0000010;
                    1: wb_sel = 7'b0000100;
                    2: wb_sel = 7'b0001000;
                    3: wb_sel = 7'b0010000;
                    4: wb_sel = 7'b0100000;
                    5: wb_sel = 7'b1000000;
                    default: wb_sel = 7'b0000000;
                endcase
            end
            else begin
                wb_sel = 7'b0000000;
            end
        end
    end
    assign wb_tile_addr_bus = {wb_sel, taddr};
    ////////// write back enable end //////////

    ////////// data buffer //////////
    wire [2:0] wb_sel = {prep_glb_wb_bus[64], ciu_glb_wb_bus_123[64], ciu_glb_wb_bus_456[64]};
    reg [63:0] data_buffer_0, data_buffer_1;
    // data buffer 0
    always@(posedge CLK) begin
        if(glb_in_rst) begin
            data_buffer_0 <= 64'd0;
        end
        else begin
            if(wb_data_valid) begin
                case(wb_sel)
                    3'b100: data_buffer_0 <= prep_glb_wb_bus[63:0];
                    3'b010: data_buffer_0 <= ciu_glb_wb_bus_123[63:0];
                    3'b001: data_buffer_0 <= ciu_glb_wb_bus_456[63:0];
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
            if(SR[0]) begin
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
        .en(wb_data_valid),
        .rst(glb_in_rst),
        .set(set),
        .AGU_G_param(AGU_G_param),
        .ch_to_Y_bus(ch_to_Y_bus),
        .Y(ch_to_Y_Y),
        .gaddr(glb_input_bus[77:64])
    );
    ////////// AGU_G end //////////

    ////////// Input Transpose //////////
    Transpose transpose(
        .CLK(CLK),
        .rst(glb_in_rst),
        .en(SR[1]),
        .data(data_buffer_1),
        .data_transpose(glb_input_bus[63:0])
    );
    ////////// Input Transpose end //////////

endmodule
