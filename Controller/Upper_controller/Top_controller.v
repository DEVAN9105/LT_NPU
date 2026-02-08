`timescale 1ns / 1ps

module Top_Controller(
    input CLK,
    input rst,
    input PS_en,
    output reg DPU_rst,
    
    ////////// Instruction memory interface //////////
    input [39:0] IS,                 // current IS
    output reg signed [3:0] PC_step, // decide how PC moves (+1, 0, -2 etc.)
    
    ////////// Submodule Done signals //////////
    input VLIW_done,
    input Weight_done,

    ////////// Submodule control and parameter outputs //////////
    // VLIW control
    output reg VLIW_controller_en,
    output reg [9:0] VLIW_initial,
    output reg [9:0] VLIW_end,
    output reg [7:0] tile_out,
    output reg [47:0] cycle_initial,
    // Weight Loader control
    output reg weight_loader_en,
    output reg [11:0] weight_amount,
    output reg [6:0] bias_amount,
    // GLB operator
    output reg [15:0] GLB_in_combined, // {width_in, ch_in}
    output reg [15:0] GLB_out_combined,// {width_out, ch_out}
    output reg [10:0] Ch_to_Y_initial,
    ////////// System status //////////
    output reg DPU_done             // entire task done, notify PS
);

    ////////// Instruction Decoding //////////
    // [43:32] OPcode (12bit) = [43:40] Class + [39:36] Func + [35:32] Cond
    // [31:16] OpA (16bit)
    // [15:0]  OpB (16bit)
    wire [2:0] op_class = IS[39:37];
    wire [2:0] op_func  = IS[36:34];
    wire [1:0] op_cond  = IS[33:32];
    wire [15:0] op_a    = IS[31:16];
    wire [15:0] op_b    = IS[15:0];

    ////////// OP Code Definitions //////////
    // Class 0: Parameter
    localparam CLASS_param = 2'd0;
    localparam FUNC_glb_param = 3'd0; // 000
    localparam FUNC_ch_order  = 3'd1; // 010
    // Class 1: DRAM
    localparam CLASS_dram  = 2'd1;
    localparam FUNC_get_weight = 3'd0; // 100
    // Class 2: Control
    localparam CLASS_control  = 2'd2;
    localparam FUNC_idle      = 3'd0; // 203
    localparam FUNC_set_loop  = 3'd1; // 212
    localparam FUNC_wait      = 3'd2; // 222
    localparam FUNC_run_VLIW  = 3'd3; // 231
    localparam FUNC_compare   = 3'd4; // 240
    localparam FUNC_finish    = 3'd5; // 253
    // Conditions
    localparam COND_none         = 2'b00;
    localparam COND_wait_VLIW    = 2'b01; // Wait for the module triggered by current instr
    localparam COND_wait_weight  = 2'b10;
    localparam COND_wait_both    = 2'b11;
    ////////// OP Code Definitions end //////////

    ////////// Internal Registers and State //////////
    reg [3:0] loop_counter;
    // FSM States
    reg [1:0] state, next_state;
    localparam S_idle    = 2'd0; // Wait for start
    localparam S_decode  = 2'd1; // Decode and trigger Enable
    localparam S_wait    = 2'd2; // Wait for Done signal
    localparam S_finish  = 2'd3; // Finish state
    ////////// Internal Registers and State end //////////

    ////////// cycle initial //////////
    always@(posedge CLK) begin
        if(rst) begin
            cycle_initial <= 0;
        end
        else begin
            cycle_initial[47:40] <= 0;
            cycle_initial[39:32] <= tile_out + 1;
            cycle_initial[31:24] <= (tile_out << 1) + 1;
            cycle_initial[23:16] <= (tile_out << 1) + tile_out + 1;
            cycle_initial[15:8]  <= (tile_out << 2) + 1;
            cycle_initial[7:0]   <= (tile_out << 2) + tile_out + 1;
        end
    end
    ////////// cycle initial end //////////

    ////////// Next State Logic and PC_step //////////
    always @(*) begin
        next_state = state;
        PC_step = 0;
        DPU_rst = 0;

        case (state)
            S_idle: begin
                PC_step = 0;
                DPU_rst = 1;
                if(PS_en) next_state = S_decode;
                else next_state = S_idle;
            end
            S_decode: begin
                if((op_class == CLASS_control) && (op_func == FUNC_compare)) begin // Compare and loop control
                    if(loop_counter == 0) begin
                         PC_step = 1;
                         next_state = S_decode;
                    end 
                    else begin
                         PC_step = -3;
                         next_state = S_decode;
                    end
                end
                else begin // Other instructions
                    case (op_cond)
                        COND_none: begin // 0: Direct jump
                            PC_step = 1;
                            next_state = S_decode;
                        end
                        COND_wait_VLIW: begin
                            PC_step = 0;
                            next_state = S_wait;
                        end
                        COND_wait_weight: begin
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
            end
            S_wait: begin
                PC_step = 0;
                case (op_cond)
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
                next_state = S_finish; // Stay in finish state
            end
            default: begin
                PC_step = 0;
                next_state = S_idle;
            end
        endcase
    end
    ////////// Next State Logic and PC_step end //////////

    ////////// FSM and register //////////
    always @(posedge CLK) begin
        if (rst) begin
            state <= S_idle;
            loop_counter <= 0;
            DPU_done <= 0;
            // Parameter reset
            GLB_in_combined <= 0;
            GLB_out_combined <= 0;
            Ch_to_Y_initial <= 0;
            VLIW_initial <= 0;
            VLIW_end <= 0;
            weight_amount <= 0;
            bias_amount <= 0;
            tile_out <= 0;
            // Enables reset
            VLIW_controller_en <= 0;
            weight_loader_en <= 0;
        end 
        else begin
            state <= next_state;
            case (state)
                S_idle: begin
                    DPU_done <= 0; // Reset done signal
                end
                S_decode: begin
                    case (op_class)
                        CLASS_param: begin
                            case (op_func)
                                FUNC_glb_param: begin // Change_GLB_parameter
                                    GLB_in_combined  <= op_a[15:0];
                                    GLB_out_combined <= op_b[15:0];
                                end
                                FUNC_ch_order: begin // Change_channel_order
                                    Ch_to_Y_initial <= op_a[10:0];
                                    tile_out <= op_b[7:0];
                                end
                                default: begin
                                    // none
                                end
                            endcase
                        end
                        CLASS_dram: begin
                            case (op_func)
                                FUNC_get_weight: begin // get_weight
                                    weight_amount <= op_a[11:0];
                                    bias_amount   <= op_b[6:0];
                                    weight_loader_en <= 1;
                                end
                                default: begin
                                    // none
                                end
                            endcase
                        end
                        CLASS_control: begin
                            case (op_func)
                                FUNC_idle: begin // 203
                                    // none
                                end
                                FUNC_set_loop: begin // 212
                                    loop_counter <= op_a[3:0];
                                end
                                FUNC_wait: begin // 222
                                    // none
                                end
                                FUNC_run_VLIW: begin // 231
                                    VLIW_initial <= op_a[9:0];
                                    VLIW_end     <= op_b[9:0];
                                    VLIW_controller_en <= 1;
                                end
                                FUNC_compare: begin // 240
                                    // Loop counter
                                    if (loop_counter != 0) begin
                                        loop_counter <= loop_counter - 1;
                                    end
                                end
                                FUNC_finish: begin // 253
                                    DPU_done <= 1; // Notify PS
                                end
                            endcase
                        end
                    endcase
                end

                S_wait: begin
                    case (op_cond)
                        COND_wait_VLIW: begin
                            if (VLIW_done) begin
                                VLIW_controller_en <= 0;
                            end
                        end
                        COND_wait_weight: begin
                            if (Weight_done) begin
                                weight_loader_en <= 0;
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
    
endmodule