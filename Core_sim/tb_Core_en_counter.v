`timescale 1ns / 1ps

module tb_Core_en_counter;

    // 1. Inputs (reg)
    reg CLK;
    reg en;
    reg rst;
    reg [2:0] mode;
    reg [5:0] width_out_in;
    reg [7:0] ch_in_in;
    reg [7:0] ch_out_in;

    // 2. Outputs (wire)
    wire SR_0_en;

    // 3. Instantiate the Unit Under Test (UUT)
    Core_en_counter uut (
        .CLK(CLK), 
        .en(en), 
        .rst(rst), 
        .mode(mode), 
        .width_out_in(width_out_in), 
        .ch_in_in(ch_in_in), 
        .ch_out_in(ch_out_in), 
        .SR_0_en(SR_0_en)
    );

    // 4. Clock Generation (10ns period = 100MHz)
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    // 5. Stimulus Process
    initial begin
        // --- 初始化 (Initialization) ---
        $display("Simulation Started");
        en = 0;
        rst = 1;
        mode = 0;
        width_out_in = 0;
        ch_in_in = 0;
        ch_out_in = 0;

        // 等待 20ns 並釋放 Reset
        #20;
        rst = 0;

        // --- 設定參數 (Set Parameters) ---
        // 題目要求：width=15, ch=2, mode=DW
        #10;
        mode = 3'd2;          // DW (Depthwise) => kernel_L will become 2
        width_out_in = 6'd15; // Width counts 0~15 (16 cycles)
        ch_in_in = 8'd2;      // Input Channel 2
        ch_out_in = 8'd2;     // Output Channel 2 (Counts 0~2 => 3 cycles)
        
        // --- 啟動計數 (Start) ---
        // 等待 Input Buffer 鎖存數據 (Code 中有 Buffer)
        #10; 
        
        @(posedge CLK);
        en = 1; 
        $display("Enable Triggered at time: %t", $time);

        // --- 等待完成 (Wait for Completion) ---
        // 根據你的邏輯，SR_0_en 平常是 1，做完時會變成 0
        wait(SR_0_en == 0);
        
        $display("Counter Finished (SR_0_en went LOW) at time: %t", $time);

        // 再跑幾個 cycle 觀察波形
        repeat(5) @(posedge CLK);
        
        // 停止 Enable
        en = 0;
        #20;
        
        $display("Simulation Finished");
        $stop;
    end

endmodule