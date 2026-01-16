`timescale 1ns / 1ps

module tb_Accumulator;

    // --- 訊號宣告 ---
    reg CLK;
    reg rst;
    
    // Control Signals
    reg en;
    reg bias_en;
    reg load_bias;
    reg ReLU_en;
    
    // Data Inputs
    reg signed [31:0] bias;
    reg signed [31:0] PE_out_0, PE_out_1, PE_out_2, PE_out_3;
    
    // Outputs
    wire signed [15:0] acc_out;

    // --- DUT 實例化 ---
    Accumulator uut (
        .CLK(CLK), .rst(rst), .en(en), 
        .bias_en(bias_en), .load_bias(load_bias), .ReLU_en(ReLU_en), 
        .bias(bias), 
        .PE_out_0(PE_out_0), .PE_out_1(PE_out_1), 
        .PE_out_2(PE_out_2), .PE_out_3(PE_out_3), 
        .acc_out(acc_out)
    );

    // --- Clock 產生 (10ns) ---
    always #5 CLK = ~CLK;

    // --- 主要測試流程 ---
    initial begin
        // 1. 初始化
        CLK = 0; rst = 1; en = 0; bias_en = 0; load_bias = 0; ReLU_en = 0;
        bias = 0; PE_out_0 = 0; PE_out_1 = 0; PE_out_2 = 0; PE_out_3 = 0;

        // Reset
        #20; rst = 0; #10;

        // 2. 載入 Bias (設定 Bias = 100)
        bias = 32'd100;
        load_bias = 1;
        #10;
        load_bias = 0;
        bias = 0;
        
        // =========================================================
        // 開始 Pipeline Streaming 測試
        // 場景：連續計算兩個 Pixel，每個 Pixel 由 4 次累加組成 (Kernal 4x?)
        // 流程：Data A -> Data A -> Data A -> Data A -> Data B -> Data B ...
        // =========================================================
        
        $display("--- Start Streaming ---");
        en = 1; // en 恆為 1，模擬 NPU 持續運作

        // --- [Cycle 1] 送入 Pixel A 的第 1 筆數據 (Start of A) ---
        // 總和 = 40. 預期結果 = 100(Bias) + 40 = 140
        PE_out_0=10; PE_out_1=10; PE_out_2=10; PE_out_3=10;
        
        // 控制器邏輯：因為 Data A1 剛進去，還要 2 個 Cycle 才會到累加器
        // 所以現在 bias_en 還不能拉高
        bias_en = 0; 
        #10;

        // --- [Cycle 2] 送入 Pixel A 的第 2 筆數據 ---
        PE_out_0=10; PE_out_1=10; PE_out_2=10; PE_out_3=10;
        bias_en = 0;
        #10;

        // --- [Cycle 3] 送入 Pixel A 的第 3 筆數據 ---
        PE_out_0=10; PE_out_1=10; PE_out_2=10; PE_out_3=10;
        
        // [關鍵時刻]：Cycle 1 送進去的 Data A1，現在(經過2拍)到達 Stage 3 門口了！
        // 我們必須在這裡拉高 bias_en，讓 Accumulator 重置並吃進 (Bias + Data A1)
        bias_en = 1; 
        #10;

        // --- [Cycle 4] 送入 Pixel A 的第 4 筆數據 (End of A) ---
        PE_out_0=10; PE_out_1=10; PE_out_2=10; PE_out_3=10;
        
        // Data A1 已經吃進去了，現在輪到 Data A2 到達 Accumulator
        // 我們要變回累加模式
        bias_en = 0; 
        #10;

        // =========================================================
        // 無縫接軌：直接送入 Pixel B 的數據
        // =========================================================

        // --- [Cycle 5] 送入 Pixel B 的第 1 筆數據 (Start of B) ---
        // 總和 = 80. 預期結果 = 100(Bias) + 80 = 180
        // 此時 Pixel A 的後續數據還在 Pipeline 裡跑
        PE_out_0=20; PE_out_1=20; PE_out_2=20; PE_out_3=20;
        bias_en = 0; // 對應 Cycle 3 的輸入，繼續累加
        #10;

        // --- [Cycle 6] 送入 Pixel B 的第 2 筆數據 ---
        PE_out_0=20; PE_out_1=20; PE_out_2=20; PE_out_3=20;
        bias_en = 0; // 對應 Cycle 4 的輸入，繼續累加
        #10;

        // --- [Cycle 7] 送入 Pixel B 的第 3 筆數據 ---
        PE_out_0=20; PE_out_1=20; PE_out_2=20; PE_out_3=20;
        
        // [關鍵時刻]：Cycle 5 送進去的 Data B1 (新的一組)，現在到達 Stage 3 了！
        // 再次拉高 bias_en，強制切斷 Pixel A 的累加，開始算 Pixel B
        bias_en = 1; 
        #10;

        // --- [Cycle 8] 送入 Pixel B 的第 4 筆數據 ---
        PE_out_0=20; PE_out_1=20; PE_out_2=20; PE_out_3=20;
        bias_en = 0; 
        #10;

        // --- 停止輸入，把剩下的 Pipeline 跑完 ---
        PE_out_0=0; PE_out_1=0; PE_out_2=0; PE_out_3=0;
        bias_en = 0;
        #50;
        
        $stop;
    end
    
    // --- 監控輸出 (Optional) ---
    // 因為有 Latency，這可以幫你看清楚每一拍發生什麼事
    always @(posedge CLK) begin
        if (!rst) begin
           $display("Time=%0t | In0=%d | bias_en=%b | Acc_Reg_Internal(Approx)=%d | Out=%d", 
                    $time, PE_out_0, bias_en, uut.accumulator_reg[15:0], acc_out);
        end
    end

endmodule