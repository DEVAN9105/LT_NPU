`timescale 1ns / 1ps

module tb_AGU_W;

    // --- Inputs ---
    reg CLK;
    reg en;
    reg rst;
    reg [2:0] mode;
    reg [11:0] AGU_W_initial;
    reg [5:0] width_out; // Max Index for reuse loop
    reg [7:0] ch_in;
    reg [7:0] ch_out;

    // --- Outputs ---
    wire [11:0] Waddr;
    wire done;
    
    // mode define
    parameter conv = 0, maxpooling = 1, DW = 2, PW = 3, GAP = 4;

    // --- Instantiation ---
    AGU_W uut (
        .CLK(CLK), 
        .en(en), 
        .rst(rst), 
        .mode(mode),
        .AGU_W_initial_in(AGU_W_initial), 
        .width_out_in(width_out), 
        .ch_in_in(ch_in),
        .ch_out_in(ch_out),
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
        mode = DW;
        AGU_W_initial = 0; // 從地址 100 開始
        width_out = 7;
        ch_in = 11;
        ch_out = 1;

        // Reset
        #100;
        rst = 0;
        #20;
        
        $display("Config: Length=3, Reuse(width)=2 times, Blocks(ch)=2");
        /*en = 1;
        #5;
        en = 0;
        #10;*/
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
    /*initial begin
        // 標題列
        $display("Time | Ch(Out) Width(In) Off | BaseAddr | Waddr(Out) | Done");
        $display("----------------------------------------------------------");
        
        // 格式化輸出
        $monitor("%4t |   %1d       %1d       %1d |   %4d   |    %4d    |  %b", 
                 $time, uut.width, uut.offset, uut.addr, Waddr, done);
    end*/

    // Waveform Dump
    initial begin
        $dumpfile("tb_AGU_W.vcd");
        $dumpvars(0, tb_AGU_W);
    end

endmodule