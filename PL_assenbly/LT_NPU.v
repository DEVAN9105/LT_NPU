`timescale 1ns / 1ps

module LT_NPU(
    ////////// control and CLK //////////
    input CLK,
    // button rst
    input asynchronous_rst,
    // PS control
    input PS_en,
    input PS_rst,
    output PL_busy,

    ////////// DMA and Memory interface //////////
    input [48:0] IS_load_bus,
    input [154:0] VLIW_load_bus,

    ////////// output //////////
    output [3:0] inference_result
    );

    ////////// Controller Assembly //////////
    // global reset
    wire system_rst;
    // busy signals
    wire instruction_loader_busy;
    wire weight_loader_busy;
    wire [10:0] lower_busy_bus; // {Core_1, Core_2, Core_3, Core_4, Core_5, Core_6, GLB_out, GLB_in, CIU, PreP, PosP}
    // control signals
    wire instruction_loader_en;
    wire [19:0] weight_loader_bus; // {en[19], weight_amount[18:7], bias_amount[6:0]}
    wire core_en_1, core_en_2, core_en_3, core_en_4, core_en_5, core_en_6;
    wire [15:0] core_control; // {mode_in[15:13], stride_X_in[12:11], ReLU_en_in[10], padding[9], tile_sel_in[8:0]}

    Controller_assembly controller_assembly_inst(
        .CLK(CLK),
        .asynchronous_rst(asynchronous_rst),
        .PS_en(PS_en),
        .PS_rst(PS_rst),
        .system_rst(system_rst),
    
        // Instruction memory interface
        .IS_load_bus(IS_load_bus),
        .VLIW_load_bus(VLIW_load_bus),
    
        // Submodule Busy signals
        .instruction_loader_busy(instruction_loader_busy),
        .weight_loader_busy(weight_loader_busy),
        .lower_busy_bus(lower_busy_bus), // {Core_1, Core_2, Core_3, Core_4, Core_5, Core_6, CIU, GLB_in, GLB_out, PreP, PosP}

    // Instruction Loader control
    .instruction_loader_en(instruction_loader_en),

        // Weight Loader control
        .weight_loader_bus(weight_loader_bus), // {en[19], weight_amount[18:7], bias_amount[6:0]}

        // Core control and parameters
        .core_en_1(core_en_1),
        .core_en_2(core_en_2),
        .core_en_3(core_en_3),
        .core_en_4(core_en_4),
        .core_en_5(core_en_5),
        .core_en_6(core_en_6),
    .core_control(core_control), // {mode_in[15:13], stride_X_in[12:11], ReLU_en_in[10], padding[9], tile_sel_in[8:0]}
    // AGU initial
    output [27:0] core_AGU_initial_1, // {AGU_W_initial[27:16], AGU_B_initial[15:8], AGU_O_initial[7:0]}
    output [27:0] core_AGU_initial_2, // {AGU_W_initial[27:16], AGU_B_initial[15:8], AGU_O_initial[7:0]}
    output [27:0] core_AGU_initial_3, // {AGU_W_initial[27:16], AGU_B_initial[15:8], AGU_O_initial[7:0]}
    output [27:0] core_AGU_initial_4, // {AGU_W_initial[27:16], AGU_B_initial[15:8], AGU_O_initial[7:0]}
    output [27:0] core_AGU_initial_5, // {AGU_W_initial[27:16], AGU_B_initial[15:8], AGU_O_initial[7:0]}
    output [27:0] core_AGU_initial_6, // {AGU_W_initial[27:16], AGU_B_initial[15:8], AGU_O_initial[7:0]}
    // tile size
    output [29:0] core_tile_param, // {width_in[29:23], ch_in[22:15], width_out[14:8], ch_out[7:0]}

    ////////// TBO control and parameters //////////
    output [22:0] tbo_param, // {tile_sel_cycle, tile_assign}

    ////////// CIU control and parameters //////////
    output cycle_en,
    output [15:0] AGU_C_param_1, // {AGU_C_initial, tile_size}
    output [15:0] AGU_C_param_2, // {AGU_C_initial, tile_size}
    output [15:0] AGU_C_param_3, // {AGU_C_initial, tile_size}
    output [15:0] AGU_C_param_4, // {AGU_C_initial, tile_size}
    output [15:0] AGU_C_param_5, // {AGU_C_initial, tile_size}
    output [15:0] AGU_C_param_6, // {AGU_C_initial, tile_size}

    ////////// GLB control and parameters //////////
    output glb_input_en,
    output glb_output_en,
    output [10:0] ch_to_Y_initial, // 0~2047
    output [53:0] glb_input_param, // {glb_in_mode[1:0], input_AGU_param[51:0]}
    output [53:0] glb_output_param, // {glb_out_mode[1:0], output_AGU_param[51:0]}

    ////////// PreP control and parameters //////////
    output [1:0] prep_control_bus, // {prep_en, prep_buffer_sel}

    ////////// PosP control and parameters //////////
    output [32:0] posp_control_bus, // {posp_en[32], hand_th[31:24], tool_th[23:16], block_th[15:8], safe_th[7:0]}

    ////////// PL status //////////
    output PL_busy
);

endmodule
