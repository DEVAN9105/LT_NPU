`timescale 1ns / 1ps

module AGU_W_tb;

    // --- Inputs ---
    reg CLK;
    reg en;
    reg rst;
    reg [11:0] AGU_W_initial;
    reg [5:0] width_out; // Max Index for reuse loop
    reg [7:0] ch_out;    // Max Index for channel loop
    reg [8:0] AGU_L;     // Block Length

    // --- Outputs ---
    wire [11:0] Waddr;
    wire done;

    // --- Instantiation ---
    AGU_W uut (
        .CLK(CLK), 
        .en(en), 
        .rst(rst), 
        .AGU_W_initial(AGU_W_initial), 
        .width_out(width_out), 
        .ch_out(ch_out), 
        .AGU_L(AGU_L), 
        .Waddr(Waddr), 
        .done(done)
    );

    // --- Clock Generation ---
    initial begin
        CLK = 0;
        forever #2.5 CLK = ~CLK; // 10ns Period
    end

    // --- Test Process ---
    initial begin
        $display("\n=== AGU_W Simulation Start ===");
        
        // 1. 初始化
        en = 0;
        rst = 1;
        AGU_W_initial = 100; // 從地址 100 開始
        AGU_L = 4;           // 每個 Block 長度 3 (例如 1 Bias + 2 Weights)
        
        // 設定迴圈參數 (使用 Max Index)
        // 測試情境：
        // 每個 Block 重複讀 2 次 (Index 0, 1) -> width_out = 1
        // 總共讀 2 個 Block (Index 0, 1)     -> ch_out = 1
        width_out = 3; //0~
        ch_out = 191;  //0~  

        // Reset
        #20;
        rst = 0;
        #20;
        
        $display("Config: Length=3, Reuse(width)=2 times, Blocks(ch)=2");
        en = 1;

        // 等待直到 Done 訊號拉高
        // 預計 Cycle 數: 3(Length) * 2(Reuse) * 2(Blocks) = 12 Cycles
        wait(done);
        @(posedge CLK); // 多跑一個 cycle 確認 Done 狀態
        en = 0;
        
        $display("\n=== Simulation Completed ===");
        $finish;
    end

    // --- Monitor / Visualization ---
    // 這裡直接監看你新命名的內部變數 ch, width, addr
    initial begin
        // 標題列
        $display("Time | Ch(Out) Width(In) Off | BaseAddr | Waddr(Out) | Done");
        $display("----------------------------------------------------------");
        
        // 格式化輸出
        $monitor("%4t |   %1d       %1d       %1d |   %4d   |    %4d    |  %b", 
                 $time, uut.ch, uut.width, uut.offset, uut.addr, Waddr, done);
    end

    // Waveform Dump
    initial begin
        $dumpfile("AGU_W_tb.vcd");
        $dumpvars(0, AGU_W_tb);
    end

endmodule