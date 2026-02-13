`timescale 1ns / 1ps

module Top_Controller(
    input CLK,
    input asynchronous_rst,
    input PS_en,
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
    ////////// System status //////////
    output reg DPU_done             // entire task done, notify PS
);
    ////////// Instruction Decoding //////////
    // [43:32] OPcode (12bit) = [43:40] Class + [39:36] Func + [35:32] Cond
    // [31:16] OpA (16bit)
    // [15:0]  OpB (16bit)
    wire [2:0] op_class  = IS[39:37];
    wire [2:0] op_func   = IS[36:34];
    wire [1:0] op_cond   = IS[33:32];
    wire [15:0] num_1    = IS[31:16];
    wire [15:0] num_2    = IS[15:0];

    ////////// OP Code Definitions //////////
    // Class 0: Parameter
    localparam CLASS_change_param    = 3'd0;
    localparam FUNC_glb_output_param = 3'd0; // 000
    localparam FUNC_glb_input_param  = 3'd1; // 001
    localparam FUNC_glb_initial      = 3'd2; // 010
    localparam FUNC_core_param       = 3'd3; // 011
    localparam FUNC_ch_order         = 3'd4; // 100
    localparam FUNC_posp_param       = 3'd5; // 101
    // Class 1: DRAM
    localparam CLASS_dram       = 3'd1;
    localparam FUNC_get_weight  = 3'd0; // 100
    // Class 2: Control
    localparam CLASS_control    = 3'd2;
    localparam FUNC_run_VLIW     = 3'd0; // 203
    localparam FUNC_wait        = 3'd1; // 212
    localparam FUNC_finish      = 3'd2; // 222
    // Conditions
    localparam COND_none         = 2'd0;
    localparam COND_wait_weight  = 2'd1; // Wait for the module triggered by current instr
    localparam COND_wait_VLIW     = 2'd2;
    localparam COND_wait_both    = 2'd3;
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

    ////////// cycle initial //////////
    wire [7:0] cycle_tile_size = core_param[7:0];
    always@(posedge CLK) begin
        if(controller_rst) begin
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

    ////////// Next State Logic and PC_step //////////
    always @(*) begin
        next_state = state;
        PC_step = 0;
        controller_rst = 0;
        VLIW_rst = 0;
        Weight_loader_rst = 0;
        DPU_done = 0;

        case (state)
            S_idle: begin
                PC_step = 0;
                controller_rst = 1;
                VLIW_rst = 1;
                Weight_loader_rst = 1;
                if(PS_en) next_state = S_decode;
                else next_state = S_idle;
            end
            S_set_0: begin
                PC_step = 0;
                next_state = S_set_1;
            end
            S_set_1: begin
                PC_step = 0;
                next_state = S_decode;
            end
            S_decode: begin
                case (op_cond)
                    COND_none: begin // 0: Direct jump
                        PC_step = 1;
                        next_state = S_decode;
                    end
                    COND_wait_weight: begin
                        PC_step = 0;
                        next_state = S_wait;
                    end
                    COND_wait_VLIW: begin
                        PC_step = 0;
                        next_state = S_wait;
                    end
                    COND_wait_both: begin
                        PC_step = 0;
                        next_state = S_wait;
                    end
                    default: next_state = S_decode;
                endcase
            end
            S_wait: begin
                PC_step = 0;
                case (op_cond)
                    COND_wait_weight: begin
                        if (Weight_done) begin
                            PC_step = 1;
                            next_state = S_decode;
                        end
                        else begin
                            PC_step = 0;
                            next_state = S_wait;
                        end
                    end
                    COND_wait_VLIW: begin
                        if (VLIW_done) begin
                            PC_step = 1;
                            next_state = S_decode;
                        end
                        else begin
                            PC_step = 0;
                            next_state = S_wait;
                        end
                    end
                    COND_wait_both: begin
                        if (VLIW_done && Weight_done) begin
                            PC_step = 1;
                            next_state = S_decode;
                        end
                        else begin
                            PC_step = 0;
                            next_state = S_wait;
                        end
                    end
                    default: next_state = S_decode;
                endcase
            end
            S_finish: begin
                PC_step = 0;
                DPU_done = 1; // Notify PS
                if(PS_en) next_state = S_finish; // Allow new task start
                else next_state = S_idle;
            end
            default: begin
                PC_step = 0;
                next_state = S_idle;
            end
        endcase
    end
    ////////// Next State Logic and PC_step end //////////

    ////////// FSM and register //////////
    always @(posedge CLK or negedge asynchronous_rst) begin
        if(!asynchronous_rst) begin
            state <= S_idle;
            // VLIW control
            VLIW_controller_en <= 0;
            VLIW_initial <= 0;
            VLIW_end <= 0;
            cycle_initial <= 0;
            // Weight Loader control
            weight_loader_en <= 0;
            weight_amount <= 0;
            bias_amount <= 0;
            // param
            glb_output_combined <= 0; // {glb_width_out, glb_ch_out, tile_width_out, tile_ch_out}
            glb_input_combined <= 0;// {glb_width_in, glb_ch_in, tile_width_in, tile_ch_in}
            glb_initial_combined <= 0; // {glb_width_init, glb_ch_init, tile_width_init, tile_ch_init}
            core_param <= 0; // {W_initial, B_initial, cycle_tile_size}
            Ch_to_Y_initial <= 0;
            posp_param <= 32'd0; // {hand_th, tool_th, block_th, safe_th}
        end 
        else begin
            state <= next_state;
            case (state)
                S_idle: begin
                    // VLIW control
                    VLIW_controller_en <= 0;
                    VLIW_initial <= 0;
                    VLIW_end <= 0;
                    cycle_initial <= 0;
                    // Weight Loader control
                    weight_loader_en <= 0;
                    weight_amount <= 0;
                    bias_amount <= 0;
                    // param
                    glb_output_combined <= 0; // {glb_width_out, glb_ch_out, tile_width_out, tile_ch_out}
                    glb_input_combined <= 0;// {glb_width_in, glb_ch_in, tile_width_in, tile_ch_in}
                    glb_initial_combined <= 0; // {glb_width_init, glb_ch_init, tile_width_init, tile_ch_init}
                    core_param <= 0; // {W_initial, B_initial, cycle_tile_size}
                    Ch_to_Y_initial <= 0;
                    posp_param <= 32'd0; // {hand_th, tool_th, block_th, safe_th}
                end
                S_decode: begin
                    case (op_class)
                        CLASS_change_param: begin
                            case (op_func)
                                FUNC_glb_output_param: begin // Change_GLB_parameter
                                    glb_output_combined  <= {num_1, num_2};
                                end
                                FUNC_glb_input_param: begin // Change_GLB_parameter
                                    glb_input_combined  <= {num_1, num_2};
                                end
                                FUNC_glb_initial: begin // Change_GLB_parameter
                                    glb_initial_combined  <= {num_1, num_2};
                                end
                                FUNC_core_param: begin // Change_core_parameter
                                    core_param <= {num_1[13:0], num_2};
                                end
                                FUNC_ch_order: begin // Change_channel_order
                                    Ch_to_Y_initial <= num_1[10:0];
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
                                default: begin
                                    // none
                                end
                            endcase
                        end
                        CLASS_control: begin
                            case (op_func)
                                FUNC_run_VLIW: begin // 231
                                    VLIW_initial <= num_1[9:0];
                                    VLIW_end     <= num_2[9:0];
                                    VLIW_controller_en <= 1;
                                end
                                FUNC_wait: begin // 222
                                    // none
                                end
                                FUNC_finish: begin // 253
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
                endcase
                end
            endcase
        end
    end
    ////////// FSM and register end //////////

    ////////// PC //////////
    reg [7:0] PC, next_PC;
    always@(*) begin
        next_PC = PC + PC_step;
    end
    always@(posedge CLK or negedge asynchronous_rst) begin
        if(!asynchronous_rst) begin
            PC <= 0;
        end
        else if(controller_rst) begin
            PC <= 0;
        end
        else begin
            PC <= next_PC;
        end
    end
    assign IS_PC_bus = {~controller_rst, PC}; // Disable PC increment when reset
    ////////// PC end //////////
    
endmodule