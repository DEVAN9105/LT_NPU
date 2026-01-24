`timescale 1ns / 1ps

module tb_AGU_F;

    // --- Inputs ---
    reg CLK;
    reg en;
    reg rst;
    reg [1:0] stride;
    reg [7:0] width_in;
    reg [7:0] width_out;
    reg [7:0] ch_in;
    reg [7:0] ch_out;
    reg [2:0] mode;

    // --- Outputs ---
    wire [7:0] faddr;
    wire boundary;
    wire done;

    // --- Instantiation ---
    AGU_F uut (
        .CLK(CLK), 
        .en(en),       // [修正 1] 改回正確的 port name ".en"
        .rst(rst), 
        .mode(mode),
        .stride_X_in(stride),
        .width_in_in(width_in), 
        .width_out_in(width_out),
        .ch_in_in(ch_in),
        .ch_out_in(ch_out),
        .faddr(faddr), 
        .boundary(boundary),
        .done(done)
    );

    // --- Clock Generation ---
    initial begin
        CLK = 0;
        forever #2.5 CLK = ~CLK; // 200MHz (Period 5ns) [註] 之前寫10ns註解有誤，2.5 toggle是5ns
    end
    
    // mode
    parameter conv = 0, maxpooling = 1, DW = 2, PW = 3, GAP = 4;
    
    // --- Test Process ---
    initial begin
        // 1. Initialization
        en = 0;
        rst = 1;
        
        // [修正 2] 關鍵！Post-Synthesis Simulation 必須等待 Global Reset (GSR) 釋放
        // Xilinx 預設 GSR 時間約為 100ns。不加這行，前面的操作都會無效。
        
        // --- Parameters ---
        mode = GAP;
        stride = 1;
        width_in = 3;           // Width 0~3 (ch_stride = 4)
        width_out = 0; 
        ch_in = 39;
        ch_out = 39;               
        
        #100;

        // 2. Reset Sequence
        // 確保在 GSR 結束後，給一個乾淨的 Reset
        @(negedge  CLK); 
        rst = 1;
        #20;
        rst = 0;
        
        // 等幾個 Clock 讓訊號穩定
        //repeat (5) @(posedge CLK);
        /*#20;
        en = 1;
        #10;
        en = 0;*/
        #5;
        en = 1;
        
        // 等待直到 Done 訊號拉高
        wait(done);
        
        // 再跑幾個 cycle 觀察結束行為
        //repeat (10) @(posedge CLK);
        #50;
        en = 0;
        
        $finish;
    end

    // Waveform Dump
    initial begin
        $dumpfile("AGU_F_conv_last.vcd");
        $dumpvars(0, tb_AGU_F);
    end

endmodule