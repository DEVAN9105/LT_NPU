`timescale 1ns / 1ps

module IS_Controller(
    input CLK,
    input rst,
    input en,                        // PS enable signal
    output reg DPU_rst,
    
    ////////// Instruction memory interface //////////
    input [43:0] IS,                 // current IS
    output reg signed [3:0] PC_step, // decide how PC moves (+1, 0, -2 etc.)
    
    ////////// System status //////////
    output reg DPU_done,             // entire task done, notify PS
    
    ////////// Submodule Done signals //////////
    input VLIW_done_in,
    input Weight_done_in,

    ////////// Submodule control and parameter outputs //////////
    // 1. VLIW control
    output reg VLIW_controller_en,
    output reg [9:0] VLIW_initial,
    output reg [9:0] VLIW_end,
    
    // 2. Weight Loader control
    output reg weight_loader_en,
    output reg [11:0] weight_amount,
    output reg [6:0] bias_amount,
    
    // 3. GLB parameter
    output reg [15:0] GLB_tile_in_combined, // {width_in, ch_in}
    output reg [15:0] GLB_tile_out_combined,// {width_out, ch_out}
    
    // 4. Channel Order
    output reg [15:0] Ch_to_Y_initial
);
    ////////// Instruction Decoding //////////
    // [43:32] OPcode (12bit) = [43:40] Class + [39:36] Func + [35:32] Cond
    // [31:16] OpA (16bit)
    // [15:0]  OpB (16bit)
    wire [3:0] op_class = IS[43:40];
    wire [3:0] op_func  = IS[39:36];
    wire [3:0] op_cond  = IS[35:32];
    wire [15:0] op_a    = IS[31:16];
    wire [15:0] op_b    = IS[15:0];

    ////////// OP Code Definitions //////////
    // Class 0: Parameter
    localparam CLASS_PARAM = 4'h0;
    localparam FUNC_GLB_PARAM = 4'h0; // 000
    localparam FUNC_CH_ORDER  = 4'h1; // 010
    // Class 1: DRAM
    localparam CLASS_DRAM  = 4'h1;
    localparam FUNC_GET_WEIGHT = 4'h0; // 100
    // Class 2: Control
    localparam CLASS_CTRL  = 4'h2;
    localparam FUNC_IDLE      = 4'h0; // 203
    localparam FUNC_SET_LOOP  = 4'h1; // 212
    localparam FUNC_WAIT      = 4'h2; // 222
    localparam FUNC_RUN_VLIW  = 4'h3; // 231
    localparam FUNC_COMPARE   = 4'h4; // 240
    localparam FUNC_FINISH    = 4'h5; // 253
    // Conditions
    localparam COND_NONE      = 4'h0;
    localparam COND_WAIT_SELF = 4'h1; // Wait for the module triggered by current instr
    localparam COND_WAIT_ALL  = 4'h2;
    localparam COND_WAIT_PS   = 4'h3;
    ////////// OP Code Definitions end //////////

    ////////// Internal Registers and State //////////
    reg [15:0] loop_counter;
    
    // FSM States
    reg [1:0] state, next_state;
    localparam S_IDLE    = 2'd0; // Wait for start
    localparam S_DECODE  = 2'd1; // Decode and trigger Enable
    localparam S_WAIT    = 2'd2; // Wait for Done signal
    
    // enabled module tracking (for COND_WAIT_SELF)
    reg current_module_is_vliw;
    reg current_module_is_weight;

    ////////// FSM and register//////////
    always @(posedge CLK) begin
        if (rst) begin
            state <= S_IDLE;
            loop_counter <= 0;
            DPU_done <= 0;
            // Parameter reset
            GLB_tile_in_combined <= 0;
            GLB_tile_out_combined <= 0;
            Ch_to_Y_initial <= 0;
            VLIW_initial <= 0;
            VLIW_end <= 0;
            weight_amount <= 0;
            bias_amount <= 0;
            // Enables reset
            VLIW_controller_en <= 0;
            weight_loader_en <= 0;
            // Internal flags
            current_module_is_vliw <= 0;
            current_module_is_weight <= 0;
        end 
        else begin
            state <= next_state;
            case (state)
                S_IDLE: begin
                    DPU_done <= 0; // Reset done signal
                end

                S_DECODE: begin
                    VLIW_controller_en <= 0;
                    weight_loader_en <= 0;
                    current_module_is_vliw <= 0;
                    current_module_is_weight <= 0;

                    case (op_class)
                        CLASS_PARAM: begin
                            case (op_func)
                                4'h0: begin // Change_GLB_parameter
                                    GLB_tile_in_combined  <= op_a;
                                    GLB_tile_out_combined <= op_b;
                                end
                                4'h1: begin // Change_channel_order
                                    Ch_to_Y_initial <= op_a;
                                end
                            endcase
                        end

                        CLASS_DRAM: begin
                            case (op_func)
                                4'h0: begin // get_weight
                                    weight_amount <= op_a[11:0];
                                    bias_amount   <= op_b[6:0];
                                    weight_loader_en <= 1;
                                    current_module_is_weight <= 1;
                                end
                            endcase
                        end

                        CLASS_CTRL: begin
                            case (op_func)
                                FUNC_IDLE: begin // 203
                                    // none
                                end
                                FUNC_SET_LOOP: begin // 212
                                    loop_counter <= op_a[15:0];
                                end
                                FUNC_WAIT: begin // 222
                                    // none
                                end
                                FUNC_RUN_VLIW: begin // 231
                                    VLIW_initial <= op_a[9:0];
                                    VLIW_end     <= op_b[9:0];
                                    VLIW_controller_en <= 1;
                                    current_module_is_vliw <= 1;
                                end
                                FUNC_COMPARE: begin // 240
                                    // Loop counter
                                    if (loop_counter != 0) begin
                                        loop_counter <= loop_counter - 1;
                                    end
                                end
                                FUNC_FINISH: begin // 253
                                    DPU_done <= 1; // Notify PS
                                end
                            endcase
                        end
                    endcase
                end

                S_WAIT: begin
                    VLIW_controller_en <= 0;
                    weight_loader_en <= 0;
                end
            endcase
        end
    end

    ////////// Next State Logic and PC_step Control //////////
    always @(*) begin
        next_state = state;
        PC_step = 0;
        DPU_rst = 0;

        case (state)
            S_IDLE: begin
                PC_step = 0;
                DPU_rst = 1;
                if (en) next_state = S_DECODE;
            end

            S_DECODE: begin
                // compare
                if (op_class == CLASS_CTRL && op_func == FUNC_COMPARE) begin
                    if (loop_counter == 0) begin
                         PC_step = 1;
                         next_state = S_DECODE;
                    end else begin
                         PC_step = -3;
                         next_state = S_DECODE;
                    end
                end
                // General instruction
                else begin
                    case (op_cond)
                        COND_NONE: begin // 0: Direct jump
                            PC_step = 1;
                            next_state = S_DECODE;
                        end
                        COND_WAIT_SELF: begin // 1: Wait for triggered module Done
                            PC_step = 0; // PC pause
                            next_state = S_WAIT;
                        end
                        COND_WAIT_ALL: begin // 2: Wait for all modules Done
                            PC_step = 0;
                            next_state = S_WAIT;
                        end
                        COND_WAIT_PS: begin
                            PC_step = 0;
                            next_state = S_WAIT;
                        end
                        default: next_state = S_DECODE;
                    endcase
                end
            end

            S_WAIT: begin
                PC_step = 0;
                case (op_cond)
                    COND_WAIT_SELF: begin
                        if (current_module_is_vliw && VLIW_done_in) begin
                            PC_step = 1;
                            next_state = S_DECODE;
                        end
                        else if (current_module_is_weight && Weight_done_in) begin
                            PC_step = 1;
                            next_state = S_DECODE;
                        end
                    end

                    COND_WAIT_ALL: begin
                        if (VLIW_done_in && Weight_done_in) begin
                            PC_step = 1;
                            next_state = S_DECODE;
                        end
                    end

                    COND_WAIT_PS: begin
                        if (op_func == FUNC_FINISH) begin
                             next_state = S_WAIT; // wait for rst
                        end 
                        else begin
                             if (en) begin
                                 PC_step = 1; 
                                 next_state = S_DECODE;
                             end
                        end
                    end
                    
                    default: next_state = S_DECODE;
                endcase
            end
        endcase
    end

endmodule