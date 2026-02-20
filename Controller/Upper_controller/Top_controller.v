`timescale 1ns / 1ps

module Top_Controller(
    input CLK,
    input asynchronous_rst,
    input PS_en,
    input PS_rst,
    output reg system_rst,
    
    ////////// Instruction memory interface //////////
    output [8:0] IS_PC_bus, // {en, 8bit address}
    input [39:0] IS,
    
    ////////// Submodule Done signals //////////
    input instruction_done,
    input VLIW_done,
    input Weight_done,

    ////////// Submodule control and parameter outputs //////////
    // VLIW control
    output reg VLIW_controller_en, 
    output reg [9:0] VLIW_initial,
    output reg [9:0] VLIW_length,
    // Weight Loader control
    output reg weight_loader_en,
    output reg [11:0] weight_amount,
    output reg [6:0] bias_amount,
    // Instruction Loader control
    output reg instruction_loader_en,
    // param
    output reg [31:0] output_combined,      // {glb_out_mode, glb_width_out, glb_ch_out, tile_ch_out}
    output reg [31:0] input_combined,       // {glb_in_mode, glb_width_in, glb_ch_in, tile_ch_in}
    output reg [ 2:0] double_buffer_sel,    // {glb, W_storage, B_storage}
    output reg [ 7:0] cycle_tile_size,      // {cycle_tile_size[7:0]}
    output reg [10:0] Ch_to_Y_increment,
    output reg [31:0] posp_param,           // {hand_th, tool_th, block_th, safe_th}
    ////////// System status //////////
    output reg PL_busy                      // PL working, notify PS
);
    ////////// Instruction Decoding //////////
    wire [1:0] op_class  = IS[39:38];
    wire [2:0] op_func   = IS[37:35];
    wire [2:0] op_cond   = IS[34:32];
    wire [31:0] num_1    = IS[31:16];
    wire [15:0] num_2    = IS[15:0];
    ////////// Instruction Decoding end //////////

    ////////// Instruction RAM interface //////////
    // PC
    reg [7:0] PC, next_PC;
    reg PC_en;
    assign IS_PC_bus = {PC_en, PC};
    always@(*) begin
        next_PC = PC + PC_en;
    end
    always@(posedge CLK or negedge asynchronous_rst) begin
        if(!asynchronous_rst) begin
            PC <= 0;
        end
        else if(system_rst || PS_rst) begin
            PC <= 0;
        end
        else begin
            PC <= next_PC;
        end
    end
    ////////// Instruction RAM interface end //////////

    ////////// OP Code Definitions //////////
    // Class 0: Change Parameter
    localparam CLASS_change_param    = 2'd0;
    localparam FUNC_output_param     = 3'd0;
    localparam FUNC_input_param      = 3'd1;
    localparam FUNC_buffer_initial   = 3'd2;
    localparam FUNC_core_param       = 3'd3;
    localparam FUNC_ch_order         = 3'd4;
    localparam FUNC_posp_param       = 3'd5;
    // Class 1: DRAM
    localparam CLASS_dram            = 2'd1;
    localparam FUNC_get_instruction  = 3'd0;
    localparam FUNC_get_weight       = 3'd1;
    // Class 2: Control
    localparam CLASS_control         = 2'd2;
    localparam FUNC_idle             = 3'd0;
    localparam FUNC_run_VLIW         = 3'd1;
    localparam FUNC_wait             = 3'd2;
    localparam FUNC_finish           = 3'd3;
    // Conditions
    localparam COND_none             = 3'd0;
    localparam COND_wait_weight      = 3'd1;
    localparam COND_wait_VLIW        = 3'd2;
    localparam COND_wait_both        = 3'd3;
    localparam COND_wait_instruction = 3'd4;
    ////////// OP Code Definitions end //////////

    ////////// Internal Registers and State //////////
    // FSM States
    reg [2:0] state, next_state;
    localparam S_idle    = 3'd0; // Wait for start
    localparam S_set_0   = 3'd1;
    localparam S_set_1   = 3'd2;
    localparam S_decode  = 3'd3; // Decode and trigger Enable
    localparam S_wait    = 3'd4; // Wait for Done signal
    localparam S_finish  = 3'd5; // Finish state
    ////////// Internal Registers and State end //////////

    ////////// Start Signal //////////
    reg PS_en_d; // Delayed version of PS_en for edge detection
    always @(posedge CLK or negedge asynchronous_rst) begin
        if (!asynchronous_rst) begin
            PS_en_d <= 0;
        end
        else if (PS_rst) begin
            PS_en_d <= 0; // Latch the start signal
        end
        else begin
            PS_en_d <= PS_en; // Update delayed signal
        end
    end
    wire PS_start_pulse = PS_en & ~PS_en_d; // Detect rising edge of PS_en
    ////////// Start Signal end //////////

    ////////// Next State Logic and PC_en //////////
    always @(*) begin
        next_state = state;
        PC_en = 0;
        PL_busy = 0;

        case (state)
            S_idle: begin
                if(PS_start_pulse) next_state = S_set_0;
                else next_state = S_idle;
            end
            S_set_0: begin
                PC_en = 1; // Start fetching instructions
                PL_busy = 1;
                next_state = S_set_1;
            end
            S_set_1: begin
                PL_busy = 1;
                PC_en = 1; // Continue fetching instructions
                next_state = S_decode;
            end
            S_decode: begin
                PL_busy = 1;
                case (op_cond)
                    COND_none: begin // 0: Direct jump
                        PC_en = 1;
                        next_state = S_decode;
                    end
                    COND_wait_weight: begin
                        PC_en = 0;
                        next_state = S_wait;
                    end
                    COND_wait_VLIW: begin
                        PC_en = 0;
                        next_state = S_wait;
                    end
                    COND_wait_both: begin
                        PC_en = 0;
                        next_state = S_wait;
                    end
                    default: next_state = S_decode;
                endcase
            end
            S_wait: begin
                PC_en = 0;
                PL_busy = 1;
                case (op_cond)
                    COND_wait_weight: begin
                        if (Weight_done) begin
                            PC_en = 1;
                            next_state = S_decode;
                        end
                        else begin
                            PC_en = 0;
                            next_state = S_wait;
                        end
                    end
                    COND_wait_VLIW: begin
                        if (VLIW_done) begin
                            PC_en = 1;
                            next_state = S_decode;
                        end
                        else begin
                            PC_en = 0;
                            next_state = S_wait;
                        end
                    end
                    COND_wait_both: begin
                        if (VLIW_done && Weight_done) begin
                            PC_en = 1;
                            next_state = S_decode;
                        end
                        else begin
                            PC_en = 0;
                            next_state = S_wait;
                        end
                    end
                    COND_wait_instruction: begin
                        if (instruction_done) begin
                            PC_en = 1;
                            next_state = S_decode;
                        end
                        else begin
                            PC_en = 0;
                            next_state = S_wait;
                        end
                    end
                    default: next_state = S_decode;
                endcase
            end
            S_finish: begin
                PL_busy = 0; // Notify PS
                next_state = S_idle;
            end
            default: begin
                next_state = S_idle;
            end
        endcase
    end
    ////////// Next State Logic and PC_en end //////////

    ////////// FSM and register //////////
    always @(posedge CLK or negedge asynchronous_rst) begin
        if(!asynchronous_rst) begin
            state <= S_idle;
            system_rst <= 1;
            // VLIW control
            VLIW_controller_en <= 0;
            VLIW_initial <= 0;
            VLIW_end <= 0;
            // Weight Loader control
            weight_loader_en <= 0;
            weight_amount <= 0;
            bias_amount <= 0;
            // Instruction Loader control
            instruction_loader_en <= 0;
            // param
            output_combined <= 0;
            input_combined <= 0;
            double_buffer_sel <= 0;
            cycle_tile_size <= 0;
            Ch_to_Y_increment <= 0;
            posp_param <= 32'd0;
        end
        else if(PS_rst) begin
            state <= S_idle;
            system_rst <= 1;
            // VLIW control
            VLIW_controller_en <= 0;
            VLIW_initial <= 0;
            VLIW_end <= 0;
            // Weight Loader control
            weight_loader_en <= 0;
            weight_amount <= 0;
            bias_amount <= 0;
            // Instruction Loader control
            instruction_loader_en <= 0;
            // param
            output_combined <= 0;
            input_combined <= 0;
            double_buffer_sel <= 0;
            cycle_tile_size <= 0;
            Ch_to_Y_increment <= 0;
            posp_param <= 32'd0;
        end
        else begin
            state <= next_state;
            system_rst <= 0;
            case (state)
                S_idle: begin
                    system_rst <= 1;
                    // VLIW control
                    VLIW_controller_en <= 0;
                    VLIW_initial <= 0;
                    VLIW_end <= 0;
                    // Weight Loader control
                    weight_loader_en <= 0;
                    weight_amount <= 0;
                    bias_amount <= 0;
                    // Instruction Loader control
                    instruction_loader_en <= 0;
                    // param
                    output_combined <= 0;
                    input_combined <= 0;
                    double_buffer_sel <= 0;
                    cycle_tile_size <= 0;
                    Ch_to_Y_increment <= 0;
                    posp_param <= 32'd0;
                end
                S_decode: begin
                    case (op_class)
                        CLASS_change_param: begin
                            case (op_func)
                                FUNC_output_param: begin // Change_GLB_parameter
                                    output_combined  <= {num_1, num_2};
                                end
                                FUNC_input_param: begin // Change_GLB_parameter
                                    input_combined  <= {num_1, num_2};
                                end
                                FUNC_buffer_initial: begin // Change_GLB_parameter
                                    double_buffer_sel  <= num_1[2:0];
                                end
                                FUNC_core_param: begin // Change_core_parameter
                                    cycle_tile_size <= num_1[7:0];
                                end
                                FUNC_ch_order: begin // Change_channel_order
                                    Ch_to_Y_increment <= num_1[10:0];
                                end
                                FUNC_posp_param: begin // Change_postprocess_parameter
                                    posp_param <= {num_1, num_2};
                                end
                                default: begin
                                    // none
                                end
                            endcase
                        end
                        CLASS_dram: begin
                            case (op_func)
                                FUNC_get_weight: begin // get_weight
                                    weight_amount <= num_1[11:0];
                                    bias_amount   <= num_2[6:0];
                                    weight_loader_en <= 1;
                                end
                                FUNC_get_instruction: begin // get_instruction
                                    instruction_loader_en <= 1;
                                end
                                default: begin
                                    // none
                                end
                            endcase
                        end
                        CLASS_control: begin
                            case (op_func)
                                FUNC_run_VLIW: begin
                                    VLIW_initial <= num_1[9:0];
                                    VLIW_length <= num_2[9:0];
                                    VLIW_controller_en <= 1;
                                end
                                FUNC_wait: begin
                                    // none
                                end
                                FUNC_finish: begin
                                    // none
                                end
                                default: begin
                                    // none
                                end
                            endcase
                        end
                    endcase
                end
                S_wait: begin
                    case (op_cond)
                        COND_wait_weight: begin
                            if (Weight_done) begin
                                weight_loader_en <= 0;
                            end
                        end
                        COND_wait_VLIW: begin
                            if (VLIW_done) begin
                                VLIW_controller_en <= 0;
                            end
                        end
                        COND_wait_both: begin
                            if (VLIW_done && Weight_done) begin
                                VLIW_controller_en <= 0;
                                weight_loader_en <= 0;
                            end
                        end
                        COND_wait_instruction: begin
                            if (instruction_done) begin
                                instruction_loader_en <= 0;
                            end
                        end
                        default: begin
                            // none
                        end
                endcase
                end
            endcase
        end
    end
    ////////// FSM and register end //////////
    
endmodule