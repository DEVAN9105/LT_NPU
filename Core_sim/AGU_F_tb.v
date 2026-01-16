`timescale 1ns / 1ps

//dalay 1

module AGU_F_tb;

    // --- Inputs ---
    reg CLK;
    reg en;
    reg rst;
    reg padding;
    reg [7:0] AGU_initial;
    reg [6:0] width_in;
    reg [6:0] width_out;
    reg [7:0] ch;
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
        .en(en), 
        .rst(rst), 
        .padding(padding), 
        .AGU_initial(AGU_initial), 
        .width_in(width_in), 
        .width_out(width_out),
        .ch_in(ch),
        .stride(stride), 
        .AGU_offset_X(AGU_offset_X), 
        .AGU_offset_Y(AGU_offset_Y), 
        .faddr(faddr), 
        .boundary(boundary),
        .done(done)
    );

    // --- Clock Generation ---
    initial begin
        CLK = 0;
        forever #2.5 CLK = ~CLK; // 10ns Period
    end

    // --- Test Process ---
    initial begin
        // 1. Initialization
        en = 0;
        rst = 1;
        
        // --- Parameters ---
        padding = 0;           // PW Mode (1x1)
        AGU_initial = 0;       // Base Address 0
        width_in = 7;             // Width 0~3 (ch_stride = 4)
        width_out = 7;
        ch = 0;                 
        stride = 1;        // X Stride
        AGU_offset_X = 0;      // Kernel 1x1 -> Offset Loop 0 only
        AGU_offset_Y = 40;    //last channel's first addr

        // Reset Pulse
        #20;
        rst = 0;
        #20;

        $display("\n=== [Start] Conv Last Test (1x1 PW Mode) ===");
        $display("Config: Width=3 (4 pixels), Channels=192 (0~191)");
        
        en = 1;
        
        // --- Monitor Logic to check first few cycles ---
        // 觀察第一個 Pixel (X=0) 的前幾個 Channel
        repeat (5) @(posedge CLK); 
        
        // 等待直到 Done 訊號拉高 (這會跑很久: 4 pixels * 192 ch = 768 cycles)
        wait(done);
        @(posedge CLK); 
        en = 0;
        
        $display("\n=== Simulation Completed ===");
        $finish;
    end

    // --- Monitor ---
    // 為了避免 Log 太多，我們只印出 X 改變或是 Y=0/Y=191 的時刻
    initial begin
        $monitor("Time=%0t | X=%1d OffX=%1d | Faddr=%3d | Bnd=%b | Done=%b", 
                 $time, uut.X, uut.offset_X, faddr, boundary, done);
    end

    // Optional: Waveform Dump
    initial begin
        $dumpfile("AGU_F_conv_last.vcd");
        $dumpvars(0, AGU_F_tb);
    end

endmodule