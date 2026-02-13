`timescale 1ns / 1ps

module Top_Controller(
    input CLK,
    input asynchronous_rst,
    input PS_en,
    input PS_rst,
    output reg controller_rst, // Notify PS that controller is ready after reset
    output reg VLIW_rst,
    output reg Weight_loader_rst,
    
    ////////// Instruction memory interface //////////
    output [8:0] IS_PC_bus, // {en, 8bit address}
    input [39:0] IS,
    
    ////////// Submodule Done signals //////////
    input VLIW_done,
    input Weight_done,

    ////////// Submodule control and parameter outputs //////////
    // VLIW control
    output reg VLIW_controller_en, 
    output reg [9:0] VLIW_initial,
    output reg [9:0] VLIW_end,
    output reg [47:0] cycle_initial,
    // Weight Loader control
    output reg weight_loader_en,
    output reg [11:0] weight_amount,
    output reg [6:0] bias_amount,
    // param
    output reg [31:0] glb_output_combined, // {glb_width_out, glb_ch_out, tile_width_out, tile_ch_out}
    output reg [31:0] glb_input_combined,// {glb_width_in, glb_ch_in, tile_width_in, tile_ch_in}
    output reg [31:0] glb_initial_combined, // {glb_width_init, glb_ch_init, tile_width_init, tile_ch_init}
    output reg [29:0] core_param, // {W_initial[29:16], B_initial[15:8], cycle_tile_size[7:0]}
    output reg [10:0] Ch_to_Y_initial,
    output reg [31:0] posp_param, // {hand_th, tool_th, block_th, safe_th}
    ////////// DPU status //////////
    output reg DPU_done             // entire task done, notify PS
);
    
    
endmodule