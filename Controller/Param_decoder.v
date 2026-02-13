`timescale 1ns / 1ps

module Param_decoder(
    input CLK,
    input rst, // global reset

    ////////// IS/VLIW input //////////
    // VLIW
    input [132:0] VLIW_num,
    // IS
    output reg [31:0] glb_output_combined, // {glb_width_out, glb_ch_out, tile_width_out, tile_ch_out}
    output reg [31:0] glb_input_combined,// {glb_width_in, glb_ch_in, tile_width_in, tile_ch_in}
    input [31:0] glb_initial_combined, // {input_glb_initial, output_glb_initial}
    input [7:0] cycle_tile_size,
    input [27:0] core_agu_param, // {W_initial[27:16], B_initial[15:8], cycle_tile_size[7:0]}

    ////////// CIU //////////
    // AGU C parameters
    output [15:0] AGU_C_param_1, // {AGU_C_initial, tile_size}
    output [15:0] AGU_C_param_2, // {AGU_C_initial, tile_size}
    output [15:0] AGU_C_param_3, // {AGU_C_initial, tile_size}
    output [15:0] AGU_C_param_4, // {AGU_C_initial, tile_size}
    output [15:0] AGU_C_param_5, // {AGU_C_initial, tile_size}
    output [15:0] AGU_C_param_6 // {AGU_C_initial, tile_size}

    ////////// Tile Buffer Operator //////////
    // control param
    output [22:0] tbo_param, // {tile_sel_cycle, tile_assign}

    ////////// Core //////////
    // control signal
    output [15:0] core_control, // {mode_in[15:13], stride_X_in[12:11], ReLU_en_in[10], padding[9], tile_sel_in[8:0]}
    // AGU initial
    output [27:0] core_AGU_initial_1, // {AGU_W_initial[27:16], AGU_B_initial[15:8], AGU_O_initial[7:0]}
    output [27:0] core_AGU_initial_2, // {AGU_W_initial[27:16], AGU_B_initial[15:8], AGU_O_initial[7:0]}
    output [27:0] core_AGU_initial_3, // {AGU_W_initial[27:16], AGU_B_initial[15:8], AGU_O_initial[7:0]}
    output [27:0] core_AGU_initial_4, // {AGU_W_initial[27:16], AGU_B_initial[15:8], AGU_O_initial[7:0]}
    output [27:0] core_AGU_initial_5, // {AGU_W_initial[27:16], AGU_B_initial[15:8], AGU_O_initial[7:0]}
    output [27:0] core_AGU_initial_6, // {AGU_W_initial[27:16], AGU_B_initial[15:8], AGU_O_initial[7:0]}
    // tile size
    output [29:0] core_tile_param, // {width_in[29:23], ch_in[22:15], width_out[14:8], ch_out[7:0]}

    ////////// GLB operator //////////
    // GLB input
    output [53:0] glb_input_param, // {glb_in_mode[53:52], AGU_G_initial[51:38], AGU_T_initial[37:30], glb_width_in[29:23], glb_ch_in[22:15], tile_width_in[14:8], tile_ch_in[7:0]}
    // GLB output
    output [53:0] glb_output_param // {glb_out_mode[53:52], AGU_G_initial[51:38], AGU_T_initial[37:30], glb_width_out[29:23], glb_ch_out[22:15], tile_width_out[14:8], tile_ch_out[7:0]}

    ////////// prep //////////
    output [7:0] prep_buffer_initial
    );

    
    ////////// VLIW input buffer //////////
    reg [132:0] VLIW_buffer;
    always@(posedge CLK) begin
        if(rst) begin
            VLIW_buffer <= 0;
        end
        else begin
            VLIW_buffer <= VLIW_num;
        end
    end
     ////////// VLIW input buffer end //////////

    ////////// VLIW decoder //////////
    wire [2:0] tile_sel_cycle;
    wire [8:0] tile_sel_cal;
    VLIW_decoder vliw_decoder(
    .CLK(CLK),
    .rst(rst),
    .VLIW_in(VLIW_num),
    .tile_sel_cal(tile_sel_cal),
    .tile_sel_cycle(tile_sel_cycle)
    );
    ////////// VLIW decoder end //////////

    ////////// cycle initial //////////
    reg [47:0] cycle_initial;
    wire [7:0] cycle_tile_size = core_agu_param[7:0];
    always@(posedge CLK) begin
        if(rst) begin
            cycle_initial <= 0;
        end
        else begin
            cycle_initial[47:40] <= 0;
            cycle_initial[39:32] <= cycle_tile_size + 1;
            cycle_initial[31:24] <= (cycle_tile_size << 1) + 1;
            cycle_initial[23:16] <= (cycle_tile_size << 1) + cycle_tile_size + 1;
            cycle_initial[15:8]  <= (cycle_tile_size << 2) + 1;
            cycle_initial[7:0]   <= (cycle_tile_size << 2) + cycle_tile_size + 1;
        end
    end
    ////////// cycle initial end //////////

    ////////// AGU initial //////////
    // AGU_O_initial
    reg [7:0] AGU_O_initial_1, AGU_O_initial_2, AGU_O_initial_3, AGU_O_initial_4, AGU_O_initial_5, AGU_O_initial_6;
    always@(posedge CLK) begin
        if(rst) begin
            AGU_O_initial_1 <= 0;
            AGU_O_initial_2 <= 0;
            AGU_O_initial_3 <= 0;
            AGU_O_initial_4 <= 0;
            AGU_O_initial_5 <= 0;
            AGU_O_initial_6 <= 0;
        end
        else begin
            if(VLIW_num[132:130] == 3'd2) begin
                AGU_O_initial_1 <= cycle_tile_size + 1;
                AGU_O_initial_2 <= (cycle_tile_size << 1) + 1;
                AGU_O_initial_3 <= (cycle_tile_size << 1) + cycle_tile_size + 1;
                AGU_O_initial_4 <= (cycle_tile_size << 2) + 1;
                AGU_O_initial_5 <= (cycle_tile_size << 2) + cycle_tile_size + 1;
                AGU_O_initial_6 <= (cycle_tile_size << 3) + 1;
            end
            else begin
                AGU_O_initial_1 <= 0;
                AGU_O_initial_2 <= 0;
                AGU_O_initial_3 <= 0;
                AGU_O_initial_4 <= 0;
                AGU_O_initial_5 <= 0;
                AGU_O_initial_6 <= 0;
            end
        end
    end
    // AGU_W AGU_B AGU_G AGU_T
    reg [11:0] AGU_W_initial;
    reg [7:0] AGU_B_initial;
    reg [13:0] input_AGU_G_initial, output_AGU_G_initial;
    reg [7:0] input_AGU_T_initial, output_AGU_T_initial;
    always@(posedge CLK) begin
        if(rst) begin
            AGU_W_initial <= 0;
            AGU_B_initial <= 0;
            input_AGU_G_initial <= 0;
            output_AGU_G_initial <= 0;
            input_AGU_T_initial <= 0;
            output_AGU_T_initial <= 0;
        end
        else begin
            AGU_W_initial <= core_agu_param[27:16] + VLIW_num[125:114];
            AGU_B_initial <= core_agu_param[15:8] + VLIW_num[113:106];
            input_AGU_G_initial <= glb_initial_combined[29:16] + VLIW_num[53:40];
            output_AGU_G_initial <= glb_initial_combined[13:0] + VLIW_num[29:16];
            input_AGU_T_initial <= VLIW_num[39:32];
            output_AGU_T_initial <= VLIW_num[15:8];
        end
    end
    ////////// AGU initial end //////////

    ////////// combine control signals //////////
    // CIU control
    assign AGU_C_param_1 = {cycle_initial[47:40], cycle_tile_size};
    assign AGU_C_param_2 = {cycle_initial[39:32], cycle_tile_size};
    assign AGU_C_param_3 = {cycle_initial[31:24], cycle_tile_size};
    assign AGU_C_param_4 = {cycle_initial[23:16], cycle_tile_size};
    assign AGU_C_param_5 = {cycle_initial[15:8], cycle_tile_size};
    assign AGU_C_param_6 = {cycle_initial[7:0], cycle_tile_size};
    // TBO control
    assign tbo_param = {tile_sel_cycle, VLIW_buffer[75:56]};
    // Core control
    assign core_control = {VLIW_buffer[132:126], tile_sel_cal};
    assign core_AGU_initial_1 = {AGU_W_initial, AGU_B_initial, AGU_O_initial_1};
    assign core_AGU_initial_2 = {AGU_W_initial, AGU_B_initial, AGU_O_initial_2};
    assign core_AGU_initial_3 = {AGU_W_initial, AGU_B_initial, AGU_O_initial_3};
    assign core_AGU_initial_4 = {AGU_W_initial, AGU_B_initial, AGU_O_initial_4};
    assign core_AGU_initial_5 = {AGU_W_initial, AGU_B_initial, AGU_O_initial_5};
    assign core_AGU_initial_6 = {AGU_W_initial, AGU_B_initial, AGU_O_initial_6};
    assign core_tile_param = VLIW_buffer[105:76];
    // GLB control
    assign glb_input_param = {VLIW_buffer[55:54], input_AGU_G_initial, input_AGU_T_initial, glb_input_combined};
    assign glb_output_param = {VLIW_buffer[53:52], output_AGU_G_initial, output_AGU_T_initial, glb_output_combined};
    // prep control
    assign prep_buffer_initial = VLIW_buffer[7:0];
    ////////// combine control signals end //////////

endmodule