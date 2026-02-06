`timescale 1ns / 1ps

module IS_Controller(
    input CLK,
    input rst,
    input en,                   // PS 啟動訊號
    
    // 指令記憶體介面
    input [43:0] IS,            // 當前指令 Instruction Stream
    output reg signed [3:0] PC_step, // 決定 PC 怎麼走 (+1, 0, -2 etc.)
    
    // 系統狀態回報
    output reg DPU_done,        // 整個任務完成，通知 PS
    
    // 子模組 Done 訊號 (根據條件欄位判斷用)
    // 註：這部分你原本沒列，但為了實作 "等待done" 必須要有
    input VLIW_done_in,
    input Weight_done_in,
    // 假設 "All Done" 是所有模組 idle 的狀態
    input All_modules_idle,     

    // 子模組控制與參數輸出
    // 1. VLIW 控制
    output reg VLIW_controller_en,
    output reg [15:0] VLIW_initial,
    output reg [15:0] VLIW_end,
    
    // 2. Weight Loader 控制
    output reg weight_loader_en,
    output reg [11:0] weight_amount,
    output reg [6:0] bias_amount,
    
    // 3. GLB 參數 (根據指令 Change_GLB_parameter)
    output reg [15:0] GLB_width_in_combined, // {width_in, ch_in}
    output reg [15:0] GLB_width_out_combined,// {width_out, ch_out}
    
    // 4. Channel Order (根據指令 Change_channel_order)
    output reg [15:0] Ch_to_Y_initial
);

    // =================================================================
    // 1. 指令解碼 (Instruction Decoding)
    // =================================================================
    // [43:32] OPcode (12bit)
    //    [43:40] Class (Type)
    //    [39:36] Func (Function)
    //    [35:32] Cond (Condition: 0=None, 1=Self, 2=All, 3=PS)
    // [31:16] OpA (16bit)
    // [15:0]  OpB (16bit)
    
    wire [3:0] op_class = IS[43:40];
    wire [3:0] op_func  = IS[39:36];
    wire [3:0] op_cond  = IS[35:32];
    wire [15:0] op_a    = IS[31:16];
    wire [15:0] op_b    = IS[15:0];

    // =================================================================
    // 2. 參數定義 (OP Code Definitions)
    // =================================================================
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

    // =================================================================
    // 3. 內部暫存器與狀態機
    // =================================================================
    reg [15:0] loop_counter;
    
    // FSM States
    localparam S_IDLE    = 2'd0; // 等待啟動
    localparam S_DECODE  = 2'd1; // 解碼並觸發 Enable
    localparam S_WAIT    = 2'd2; // 等待 Done 訊號
    
    reg [1:0] state, next_state;
    
    // 用來記錄當前指令觸發了哪個模組，以便在 WAIT 狀態檢查對應的 Done 訊號
    reg current_module_is_vliw;
    reg current_module_is_weight;

    // =================================================================
    // 4. 主狀態機邏輯 (Main FSM)
    // =================================================================
    
    always @(posedge CLK) begin
        if (rst) begin
            state <= S_IDLE;
            loop_counter <= 0;
            DPU_done <= 0;
            
            // 參數重置 (Optional)
            GLB_width_in_combined <= 0;
            GLB_width_out_combined <= 0;
            Ch_to_Y_initial <= 0;
            VLIW_initial <= 0;
            VLIW_end <= 0;
            weight_amount <= 0;
            bias_amount <= 0;
            
            // Enables 重置
            VLIW_controller_en <= 0;
            weight_loader_en <= 0;
            
            // 內部旗標
            current_module_is_vliw <= 0;
            current_module_is_weight <= 0;
        end 
        else begin
            state <= next_state;
            
            // --- 狀態行為描述 ---
            case (state)
                S_IDLE: begin
                    DPU_done <= 0; // Reset done signal
                    if (en) begin
                        // 收到 PS 啟動訊號，開始解碼
                    end
                end

                S_DECODE: begin
                    // 預設關閉 Enables (Pulse behavior)
                    // 如果需要 Level behavior，邏輯要改
                    VLIW_controller_en <= 0;
                    weight_loader_en <= 0;
                    current_module_is_vliw <= 0;
                    current_module_is_weight <= 0;

                    // 根據 Class 分類處理
                    case (op_class)
                        CLASS_PARAM: begin
                            case (op_func)
                                4'h0: begin // Change_GLB_parameter
                                    GLB_width_in_combined  <= op_a;
                                    GLB_width_out_combined <= op_b;
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
                                    weight_loader_en <= 1; // Trigger
                                    current_module_is_weight <= 1; // 標記為 Weight 模組
                                end
                            endcase
                        end

                        CLASS_CTRL: begin
                            case (op_func)
                                FUNC_IDLE: begin // 203
                                    // 通常這裡什麼都不做，因為下一步會進 WAIT (Cond=3)
                                end
                                FUNC_SET_LOOP: begin // 212
                                    loop_counter <= op_a;
                                end
                                FUNC_WAIT: begin // 222
                                    // 單純等待，不做額外動作
                                end
                                FUNC_RUN_VLIW: begin // 231
                                    VLIW_initial <= op_a;
                                    VLIW_end     <= op_b;
                                    VLIW_controller_en <= 1; // Trigger
                                    current_module_is_vliw <= 1; // 標記為 VLIW 模組
                                end
                                FUNC_COMPARE: begin // 240
                                    // 邏輯在 PC_step 組合邏輯處理，但 Counter 在這裡更新
                                    if (loop_counter != 0) begin
                                        loop_counter <= loop_counter - 1;
                                    end
                                end
                                FUNC_FINISH: begin // 253
                                    DPU_done <= 1; // 通知 PS
                                end
                            endcase
                        end
                    endcase
                end

                S_WAIT: begin
                    // 保持 Enable 為 0 (假設是 Pulse 觸發)
                    VLIW_controller_en <= 0;
                    weight_loader_en <= 0;
                end
            endcase
        end
    end

    // =================================================================
    // 5. Next State 與 PC_step 邏輯 (Combinational)
    // =================================================================
    always @(*) begin
        // 預設值
        next_state = state;
        PC_step = 0; // 預設暫停 PC

        case (state)
            S_IDLE: begin
                PC_step = 0; // 停在開頭 (Address 0)
                if (en) next_state = S_DECODE;
            end

            S_DECODE: begin
                // 在 DECODE 週期，我們判斷要不要跳轉或是進入等待
                
                // 特殊指令處理：COMPARE (Class 2, Func 4)
                if (op_class == CLASS_CTRL && op_func == FUNC_COMPARE) begin
                    if (loop_counter == 0) begin
                         PC_step = 1; // 迴圈結束，往下走
                         next_state = S_DECODE; // 下個 cycle 解下一條
                    end else begin
                         PC_step = -2; // 迴圈未完，往回跳
                         next_state = S_DECODE; // 下個 cycle 解跳回去的那條
                    end
                end
                // 一般指令處理
                else begin
                    // 檢查 Condition
                    case (op_cond)
                        COND_NONE: begin // 0: 直接跳
                            PC_step = 1;
                            next_state = S_DECODE;
                        end
                        COND_WAIT_SELF: begin // 1: 等待觸發的模組 Done
                            PC_step = 0; // PC 暫停
                            next_state = S_WAIT;
                        end
                        COND_WAIT_ALL: begin // 2: 等待所有人 Done
                            PC_step = 0;
                            next_state = S_WAIT;
                        end
                        COND_WAIT_PS: begin // 3: 等待 PS (這裡實作為等待 en 保持高電位或 handshake)
                            PC_step = 0;
                            next_state = S_WAIT;
                        end
                        default: next_state = S_DECODE;
                    endcase
                end
            end

            S_WAIT: begin
                PC_step = 0; // 繼續暫停 PC

                case (op_cond)
                    COND_WAIT_SELF: begin
                        // 根據剛才觸發的模組檢查對應的 Done
                        if (current_module_is_vliw && VLIW_done_in) begin
                            PC_step = 1; // 完成，PC 往下
                            next_state = S_DECODE;
                        end
                        else if (current_module_is_weight && Weight_done_in) begin
                            PC_step = 1;
                            next_state = S_DECODE;
                        end
                        // 如果有其他模組可以在此擴充
                    end

                    COND_WAIT_ALL: begin
                        if (All_modules_idle) begin
                            PC_step = 1;
                            next_state = S_DECODE;
                        end
                    end

                    COND_WAIT_PS: begin
                        // 對於 idle (203) 指令，我們等待 en 訊號
                        // 對於 finish (253) 指令，我們發送 done 後等待 PS 重置或握手
                        // 這裡假設: 若是 IDLE 指令，且 en=1 代表開始；若是 FINISH，可能需要等待 en=0 再變 1
                        
                        // 簡單實作：如果是 FINISH，停在這裡直到外部 reset 或特定行為
                        if (op_func == FUNC_FINISH) begin
                             // 停機狀態，等待 Reset
                             next_state = S_WAIT; 
                        end else begin
                             // 一般 Wait PS (例如 idle 指令)
                             // 如果這是啟動前的 idle，en=1 應該會讓我們離開這裡
                             // 這裡邏輯視你與 PS 的協定而定
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