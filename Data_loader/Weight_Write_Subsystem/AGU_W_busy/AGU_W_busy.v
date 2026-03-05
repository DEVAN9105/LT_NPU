`timescale 1ns / 1ps

// =============================================================================
// Module: AGU_W_busy (Controller Handshake Version)
// Description: Weight and Bias Address Generation Unit
//              Generates read/write addresses for Weight URAM and Bias BRAM.
//              Uses level handshake for controller synchronization.
// =============================================================================

module AGU_W_busy(
    input  wire        clk, 
    input  wire        rst_n, 
    
    // --- 外部輸入 ---
    input  wire        i_valid,
    input  wire [11:0] i_weight_len, 
    input  wire [6:0]  i_bias_len, 
    
    // --- 控制輸入 (交握訊號) ---
    input  wire        i_buffer_sel,   // Buffer 選擇 (0 或 1)
    input  wire        i_layer_start,  // 啟動脈衝 (開始單層處理)
    input  wire        i_image_done,   // 全域重置訊號 (Frame 處理完畢)

    // --- 記憶體輸出 ---
    (* MAX_FANOUT = 8 *) output reg [11:0] o_uram_addr,
    (* MAX_FANOUT = 8 *) output reg [6:0]  o_bram_addr,
    output reg [23:0] o_uram_we, 
    output reg [23:0] o_bram_we,
    
    // --- 狀態輸出 ---
    output reg [4:0]  o_layer_cnt,
    output reg        o_layer_done,    // 單層處理完畢訊號 (Level High)
    output reg        o_all_done,      // 所有層處理完畢訊號
    output reg        o_busy,          // 模組狀態輸出 (High 代表傳輸中)
    output wire       o_ready          // 準備訊號 (送出給 Loader)
);
    
    localparam TOTAL_LAYERS = 22;

    // =========================================================================
    // 內部暫存器與狀態宣告
    // =========================================================================
    reg [11:0] cnt_remain, active_w_len;
    reg [6:0]  active_b_len;
    reg [23:0] bank_pointer;
    reg [11:0] internal_addr;
    reg [4:0]  layer_cnt;
    reg        is_bias_phase, all_done_reg;
    reg        active_buffer_sel; 
    reg        wait_for_start;         // 等待啟動的狀態旗標

    // 🌟 (已移除 start_shift 與 start_pulse，直接使用 i_layer_start)

    // --- 狀態訊號 ---
    reg [11:0] next_cnt_remain, next_active_w_len; 
    reg [6:0]  next_active_b_len;
    reg [23:0] next_bank_pointer;
    reg [11:0] next_internal_addr;
    reg [4:0]  next_layer_cnt;
    reg        next_is_bias_phase, next_all_done_reg;
    reg        next_active_buffer_sel;

    wire block_done = (cnt_remain == 1);

    // --- 準備訊號 ---
    assign o_ready = !all_done_reg && !wait_for_start && rst_n;

    // =========================================================================
    // 組合邏輯 (計算下個狀態)
    // =========================================================================
    always @(*) begin
        // 1. 預設給值
        next_cnt_remain        = cnt_remain;
        next_bank_pointer      = bank_pointer;
        next_layer_cnt         = layer_cnt;
        next_is_bias_phase     = is_bias_phase;
        next_all_done_reg      = all_done_reg;
        next_internal_addr     = internal_addr;
        next_active_w_len      = active_w_len;
        next_active_b_len      = active_b_len;
        next_active_buffer_sel = active_buffer_sel; 

        // 2. 參數鎖定 (Idle 或等待啟動時)
        if ((!i_valid || wait_for_start) && !all_done_reg) begin
            if (cnt_remain == 0 || (bank_pointer == 1 && !is_bias_phase && internal_addr == 0)) begin
                next_active_w_len      = i_weight_len;
                next_active_b_len      = i_bias_len;
                next_cnt_remain        = i_weight_len;
                next_active_buffer_sel = i_buffer_sel; 
            end
        end

        // 3. 主要狀態機 (Valid & Ready 時運作)
        if (i_valid && o_ready && !all_done_reg) begin
            next_internal_addr = (block_done) ? 0 : internal_addr + 1;

            if (!block_done) begin
                next_cnt_remain = cnt_remain - 1;
            end else begin
                // 當前 Bank 寫滿
                if (bank_pointer[23]) begin 
                    next_bank_pointer = 1;
                    
                    if (!is_bias_phase) begin // Weight 結束 -> 進入 Bias
                        next_is_bias_phase = 1;
                        next_cnt_remain    = active_b_len;
                    end else begin            // Bias 結束 -> 進入下一層
                        next_is_bias_phase     = 0;
                        
                        // 預先鎖定下一層參數
                        next_active_w_len      = i_weight_len;
                        next_active_b_len      = i_bias_len;
                        next_cnt_remain        = i_weight_len;
                        next_active_buffer_sel = i_buffer_sel; 

                        if (layer_cnt < TOTAL_LAYERS - 1) 
                            next_layer_cnt = layer_cnt + 1;
                        else 
                            next_all_done_reg = 1;
                    end
                end else begin // Bank 移位
                    next_bank_pointer = bank_pointer << 1;
                    next_cnt_remain   = (!is_bias_phase) ? active_w_len : active_b_len;
                end
            end
        end
    end

    // =========================================================================
    // 循序邏輯 (狀態更新與輸出交握)
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 1. 硬體重置
            cnt_remain        <= 0;
            bank_pointer      <= 1;
            layer_cnt         <= 0;
            is_bias_phase     <= 0;
            all_done_reg      <= 0;
            internal_addr     <= 0;
            active_w_len      <= 0;
            active_b_len      <= 0;
            active_buffer_sel <= 0;
            wait_for_start    <= 1'b1; 
            
            o_uram_addr       <= 0;
            o_bram_addr       <= 0;
            o_uram_we         <= 0;
            o_bram_we         <= 0;
            o_layer_cnt       <= 0;
            o_layer_done      <= 0;
            o_all_done        <= 0;
            o_busy            <= 1'b0; 
            
        end else if (i_image_done) begin
            // 2. 軟體重置 (Frame 結束)
            cnt_remain        <= 0;
            bank_pointer      <= 1;
            layer_cnt         <= 0;
            is_bias_phase     <= 0;
            all_done_reg      <= 0;
            internal_addr     <= 0;
            active_w_len      <= 0;
            active_b_len      <= 0;
            active_buffer_sel <= 0;
            wait_for_start    <= 1'b1; 
            
            o_uram_addr       <= 0;
            o_bram_addr       <= 0;
            o_uram_we         <= 0;
            o_bram_we         <= 0;
            o_layer_cnt       <= 0;
            o_layer_done      <= 0; 
            o_all_done        <= 0;
            o_busy            <= 1'b0; 
            
        end else begin
            // 3. 正常運作邏輯
            
            // 3.1 閒置與交握狀態管理
            if (wait_for_start) begin
                // 🌟 當前 Clock 看到外部 i_layer_start 為 1 時執行
                if (i_layer_start) begin 
                    wait_for_start <= 1'b0; 
                    o_layer_done   <= 1'b0; 
                    o_busy         <= 1'b1; // 🌟 賦值 1，會在「下一個 Clock 上升緣」對外生效
                end
            end else begin
                // 單層傳輸完畢的確認
                if (i_valid && o_ready && block_done && bank_pointer[23] && is_bias_phase) begin
                    o_layer_done <= 1'b1;   
                    o_busy       <= 1'b0;   // 傳輸完畢，降下 Busy
                    
                    if (layer_cnt < TOTAL_LAYERS - 1) begin
                        wait_for_start <= 1'b1; 
                    end
                end
            end

            // 3.2 內部狀態更新 
            // 🌟 條件改為直接判斷 i_layer_start
            if (!wait_for_start || i_layer_start) begin
                cnt_remain        <= next_cnt_remain;
                bank_pointer      <= next_bank_pointer;
                layer_cnt         <= next_layer_cnt;
                is_bias_phase     <= next_is_bias_phase;
                all_done_reg      <= next_all_done_reg;
                internal_addr     <= next_internal_addr;
                active_w_len      <= next_active_w_len;
                active_b_len      <= next_active_b_len;
                active_buffer_sel <= next_active_buffer_sel;
            end
            
            // 3.3 輸出與位址生成
            if (i_valid && o_ready && !all_done_reg && !wait_for_start) begin
                
                o_uram_addr <= (active_buffer_sel == 1'b1) ? (internal_addr + 12'd2048) : internal_addr;
                o_bram_addr <= {active_buffer_sel, internal_addr[5:0]};
                
                o_uram_we   <= (!is_bias_phase) ? bank_pointer : 0;
                o_bram_we   <= ( is_bias_phase) ? bank_pointer : 0;
                
                o_layer_cnt <= layer_cnt;
                o_all_done  <= all_done_reg;
            end else begin
                o_uram_we   <= 0;
                o_bram_we   <= 0;
                o_all_done  <= all_done_reg;
            end
        end
    end

endmodule