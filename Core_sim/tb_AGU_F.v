`timescale 1ns / 1ps

module tb_AGU_F;

    // --- Inputs ---
    reg CLK;
    reg en;
    reg rst;
    reg padding;
    reg [7:0] AGU_initial;
    reg [6:0] width_in;
    reg [6:0] width_out;
    reg [1:0] stride;
    reg [1:0] AGU_offset_X;
    reg [8:0] AGU_offset_Y;

    // --- Outputs ---
    wire [7:0] faddr;
    wire boundary;
    wire done;

    // --- Instantiation ---
    AGU_F uut (
        .CLK(CLK), 
        .en(en),       // [修正 1] 改回正確的 port name ".en"
        .rst(rst), 
        .padding_in(padding), 
        .AGU_F_initial_in(AGU_initial), 
        .width_in_in(width_in), 
        .width_out_in(width_out),
        .stride_in(stride), 
        .AGU_offset_X_in(AGU_offset_X), 
        .AGU_offset_Y_in(AGU_offset_Y), 
        .faddr(faddr), 
        .boundary(boundary),
        .done(done)
    );

    // --- Clock Generation ---
    initial begin
        CLK = 0;
        forever #2.5 CLK = ~CLK; // 200MHz (Period 5ns) [註] 之前寫10ns註解有誤，2.5 toggle是5ns
    end

    // --- Test Process ---
    initial begin
        // 1. Initialization
        en = 0;
        rst = 1;
        
        // [修正 2] 關鍵！Post-Synthesis Simulation 必須等待 Global Reset (GSR) 釋放
        // Xilinx 預設 GSR 時間約為 100ns。不加這行，前面的操作都會無效。
        #100; 
        
        // --- Parameters ---
        //PW
        /*padding = 0;            // PW Mode (1x1)
        AGU_initial = 0;        // Base Address 0
        width_in = 7;           // Width 0~3 (ch_stride = 4)
        width_out = 7;                  
        stride = 1;             // X Stride
        AGU_offset_X = 0;       // Kernel 1x1 -> Offset Loop 0 only
        AGU_offset_Y = 40;      // last channel's first addr*/
        
        //DW stride=2
        padding = 1;            // PW Mode (1x1)
        AGU_initial = 0;        // Base Address 0
        width_in = 15;           // Width 0~3 (ch_stride = 4)
        width_out = 7;                  
        stride = 2;             // X Stride
        AGU_offset_X = 2;       // Kernel 1x1 -> Offset Loop 0 only
        AGU_offset_Y = 0;      // last channel's first addr
        
        //DW stride=1
        /*padding = 1;            // PW Mode (1x1)
        AGU_initial = 0;        // Base Address 0
        width_in = 15;           // Width 0~3 (ch_stride = 4)
        width_out = 15;                  
        stride = 1;             // X Stride
        AGU_offset_X = 2;       // Kernel 1x1 -> Offset Loop 0 only
        AGU_offset_Y = 0;      // last channel's first addr*/

        // 2. Reset Sequence
        // 確保在 GSR 結束後，給一個乾淨的 Reset
        @(negedge  CLK); 
        rst = 1;
        #20;
        rst = 0;

        $display("\n=== [Start] Conv Last Test (1x1 PW Mode) ===");
        $display("Config: Width=3 (4 pixels), Channels=192 (0~191)");
        
        // 等幾個 Clock 讓訊號穩定
        //repeat (5) @(posedge CLK);
        #5
        en = 1;
        
        // --- Monitor Logic ---
        // 觀察前 20 個 Cycle 看看是否正常啟動
        // repeat (20) @(posedge CLK); 
        
        // 等待直到 Done 訊號拉高
        wait(done);
        
        // 再跑幾個 cycle 觀察結束行為
        //repeat (10) @(posedge CLK);
        #5;
        en = 0;
        
        $display("\n=== Simulation Completed ===");
        $finish;
    end

    // Waveform Dump
    initial begin
        $dumpfile("AGU_F_conv_last.vcd");
        $dumpvars(0, tb_AGU_F);
    end

endmodule