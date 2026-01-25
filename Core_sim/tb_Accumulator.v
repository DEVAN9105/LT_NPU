`timescale 1ns / 1ps

module tb_Accumulator;

    // Inputs
    reg CLK;
    reg rst;
    reg en;
    reg [2:0] mode;
    reg load_bias;
    reg ReLU_en;
    reg [7:0] ch_in;
    reg signed [31:0] bias;
    reg signed [31:0] PE_out_0;
    reg signed [31:0] PE_out_1;
    reg signed [31:0] PE_out_2;
    reg signed [31:0] PE_out_3;

    // Outputs
    wire signed [15:0] acc_out;
    wire acc_done;

    // Parameters
    parameter conv = 0, maxpooling = 1, DW = 2, PW = 3, GAP = 4;

    // Instantiate the UUT
    Accumulator uut (
        .CLK(CLK), .rst(rst), .en(en), .mode(mode), 
        .load_bias(load_bias), .ReLU_en(ReLU_en), .ch_in(ch_in), 
        .bias(bias), 
        .PE_out_0(PE_out_0), .PE_out_1(PE_out_1), 
        .PE_out_2(PE_out_2), .PE_out_3(PE_out_3), 
        .acc_out(acc_out),
        .acc_done(acc_done)
    );

    // Clock
    always #2.5 CLK = ~CLK;

    // Task for driving inputs
    task drive_pe;
        input signed [31:0] p0, p1, p2, p3;
        begin
            PE_out_0 <= p0; PE_out_1 <= p1; PE_out_2 <= p2; PE_out_3 <= p3;
        end
    endtask

    integer i, k;
    reg signed [31:0] expected_val;

    initial begin
        // 1. 初始化
        CLK = 0; rst = 1; en = 0; 
        mode = 0; 
        load_bias = 0; 
        ReLU_en = 0; 
        ch_in = 0; 
        bias = 0;
        drive_pe(0,0,0,0);

        // 2. Reset
        #20; rst = 0; #10;

        // 3. 設定模式
        mode = maxpooling; 
        #20; // 等待 kernel_L 更新

        $display("=== Start DW Accumulation Test ===");
        
        load_bias = 1;
        k = 0;
        // 連續執行 8 組累加
        drive_pe(1, 2, 3, 4);
        en = 1;
        #5;
        for (i = 1; i <= 4; i = i + 1) begin
            //bias = i * 100;
            
            // 啟用輸入
            en = 1; 
            // 根據你的 RTL，Counter 數 0, 1, 2，所以跑 3 個 Cycle
            for (k = 0; k < 4; k = k + 1) begin
                // 輸入 5+5+0+0 = 10
                @(negedge CLK);
                drive_pe(i, k, i-k, 0); 
            end
            
            // 【關鍵修正】
            // 在一組資料送完後，先不要馬上把 en 拉低
            // 如果這是連續傳輸，下一組迴圈會繼續保持 en=1，所以中間不會斷
            // 如果這是最後一組，我們會在迴圈外處理
        end

        // 4. 結束處理
        // 為了確保最後一筆資料能被 Pipeline 正確吃進去，
        // 建議在送入 無效資料(0) 的同時，可以再維持一個 cycle 的 enable，或者直接由 Pipeline 延遲處理。
        // 這裡我們模擬資料結束：
        en = 0; 
        drive_pe(0,0,0,0);
        
        // 5. 等待 Pipeline 輸出 (Latency = 4)
        // 我們在第 4 個 Cycle 後檢查結果
        #40; 
        
        // 此時 acc_out 應該要等於最後一組的結果
        // 最後一組 (Set 8): Bias 800 + (10 * 3) = 830
        // 如果你看到 820，代表只加了 2 次
        if (acc_out == 830) 
            $display("Result Correct! acc_out = %d", acc_out);
        else 
            $display("Result Error! acc_out = %d (Expected 830)", acc_out);

        #100;
        $stop;
    end
    
    // 監控並印出每一組的結果
    // 由於 Pipeline 延遲，輸出會比輸入晚 4 個 Cycle
    // 我們可以簡單地監測 acc_out 的變化
    initial begin
        forever begin
            @(posedge CLK);
            if (acc_out !== 0 && acc_out % 10 == 0) begin
                // 簡單過濾掉過渡值，只印出像是 130, 230 這種完整結果
                // 注意：這只是為了觀察，嚴謹驗證靠上面的 if check
                $display("Time %t: Output detected = %d", $time, acc_out);
            end
        end
    end

endmodule