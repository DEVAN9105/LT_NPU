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
    wire [7:0] offset_out;
    wire [5:0] w_count_out;
    wire [7:0] ch_count_out;

    // 3. Instantiate the Unit Under Test (UUT)
    Core_en_counter uut (
        .CLK(CLK), 
        .en_in(en), 
        .rst(rst), 
        .mode(mode), 
        .width_out_in(width_out_in), 
        .ch_in_in(ch_in_in), 
        .ch_out_in(ch_out_in), 
        .SR_0_en(SR_0_en),
        .offset_out(offset_out),
        .w_count_out(w_count_out),
        .ch_count_out(ch_count_out)
    );

    // 4. Clock Generation (10ns period = 100MHz)
    initial begin
        CLK = 0;
        forever #2.5 CLK = ~CLK;
    end
    
    // mode define
    parameter conv = 0, maxpooling = 1, DW = 2, PW = 3, GAP = 4;
    
    // 5. Stimulus Process
    initial begin
        // --- 初始化 (Initialization) ---
        $display("Simulation Started");
        en = 0;
        rst = 1;
        mode = GAP;          // DW (Depthwise) => kernel_L will become 2
        width_out_in = 6'd0; // Width counts 0~15 (16 cycles)
        ch_in_in = 8'd7;      // Input Channel 2
        ch_out_in = 8'd7;     // Output Channel 2 (Counts 0~2 => 3 cycles)
        

        // 等待 20ns 並釋放 Reset
        #20;
        rst = 0;
        
        // --- 啟動計數 (Start) ---
        // 等待 Input Buffer 鎖存數據 (Code 中有 Buffer)
        #15; 
        
        @(negedge CLK);
        en = 1;
        
        #10;
        
        @(posedge CLK);
        wait(SR_0_en == 0);

        #5;
        en = 0;
        #20;
        
        $finish;
    end

endmodule