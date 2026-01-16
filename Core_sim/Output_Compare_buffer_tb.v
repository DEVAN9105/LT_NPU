`timescale 1ns / 1ps

module tb_Output_Compare_buffer;

    // ------------------------------------------------
    // 1. 訊號宣告
    // ------------------------------------------------
    reg CLK;
    reg rst;
    reg en;
    reg [2:0] mode;
    
    // Inputs
    reg [63:0] fdata_0;
    reg [63:0] fdata_1;
    reg [63:0] fdata_2;
    reg [63:0] fdata_3; // 保留擴充用
    
    reg [15:0] acc_out_0;
    reg [15:0] acc_out_1;
    reg [15:0] acc_out_2;
    reg [15:0] acc_out_3;

    // Outputs
    wire [63:0] core_out;

    // Parameters for readability
    parameter MODE_CONV1      = 0;
    parameter MODE_MAXPOOLING = 1;
    parameter MODE_DW         = 2;
    parameter MODE_PW         = 3;

    // ------------------------------------------------
    // 2. 實例化 DUT (Device Under Test)
    // ------------------------------------------------
    // 注意：Vivado 會自動去專案中尋找 Comparator 模組
    // 請確保 Comparator.v 已經加入 Simulation Sources
    Output_Compare_buffer uut (
        .CLK(CLK), 
        .rst(rst), 
        .en(en), 
        .mode(mode), 
        .fdata_0(fdata_0), 
        .fdata_1(fdata_1), 
        .fdata_2(fdata_2), 
        .acc_out_0(acc_out_0), 
        .acc_out_1(acc_out_1), 
        .acc_out_2(acc_out_2), 
        .acc_out_3(acc_out_3), 
        .core_out(core_out)
    );

    // ------------------------------------------------
    // 3. 時脈生成 (100MHz -> Period 10ns)
    // ------------------------------------------------
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    // ------------------------------------------------
    // 4. 測試流程 (Stimulus)
    // ------------------------------------------------
    initial begin
        // --- 初始化 ---
        rst = 1;
        en = 0;
        mode = MODE_PW;
        fdata_0 = 0; fdata_1 = 0; fdata_2 = 0; fdata_3 = 0;
        acc_out_0 = 0; acc_out_1 = 0; acc_out_2 = 0; acc_out_3 = 0;

        // 等待 Reset 釋放
        #20;
        rst = 0;
        #10;
        
        // ==========================================
        // Test Case 1: PW Mode (Bypass 測試)
        // 預期：Output = SR_0 (延遲 1 cycle)
        // ==========================================
        $display("--- Test Case 1: PW Mode (Default) ---");
        en = 1;
        mode = MODE_PW;
        
        // 輸入測試資料: {4, 3, 2, 1}
        acc_out_3 = 16'd4; acc_out_2 = 16'd3; acc_out_1 = 16'd2; acc_out_0 = 16'd1;
        
        #10; // 等待 1 個 Clock
        
        if (core_out == 64'h0004000300020001) 
            $display("PW Mode Passed: Output = %h", core_out);
        else 
            $display("PW Mode Failed: Output = %h", core_out);

        // ==========================================
        // Test Case 2: Conv1 Mode (Shift Register 測試)
        // 預期：觀察波形確認 SR0 -> SR1 -> SR2 的移動
        // ==========================================
        $display("\n--- Test Case 2: Conv1 Mode (Shift Register) ---");
        mode = MODE_CONV1;
        
        // Cycle 1: Feed AAAA
        acc_out_3 = 16'hA; acc_out_2 = 16'hA; acc_out_1 = 16'hA; acc_out_0 = 16'hA;
        #10; 
        
        // Cycle 2: Feed BBBB
        acc_out_3 = 16'hB; acc_out_2 = 16'hB; acc_out_1 = 16'hB; acc_out_0 = 16'hB;
        #10;

        // Cycle 3: Feed CCCC
        acc_out_3 = 16'hC; acc_out_2 = 16'hC; acc_out_1 = 16'hC; acc_out_0 = 16'hC;
        #10;
        
        // 此時 SR0=C, SR1=B, SR2=A
        // 請在此處觀察您的真實 Comparator 輸出了什麼結果
        $display("Conv1 Mode Check: Inputs are A, B, C. Comparator Output = %h", core_out);

        // ==========================================
        // Test Case 3: Maxpooling Mode (Parallel Load 測試)
        // 預期：SR0, SR1, SR2 同時載入 fdata
        // ==========================================
        $display("\n--- Test Case 3: Maxpooling Mode ---");
        mode = MODE_MAXPOOLING;
        
        // 設定不同數值以驗證您的比較邏輯
        // Slot 0: 比較 10, 20, 30
        fdata_0 = {4{16'd10}};
        fdata_1 = {4{16'd20}};
        fdata_2 = {4{16'd30}};
        
        #10; // Load Data
        #10; // Wait for output (視您的 Comparator 是否有 Pipeline 而定)
        
        $display("Maxpooling Check: Inputs are 10, 20, 30. Comparator Output = %h", core_out);

        // ==========================================
        // Test Case 4: Reset 測試
        // ==========================================
        $display("\n--- Test Case 4: Reset Priority ---");
        rst = 1; 
        #10;
        if (core_out == 0)
            $display("Reset Passed: Output cleared to 0");
        else
            $display("Reset Failed: Output is %h", core_out);

        $stop;
    end

endmodule