`timescale 1ns / 1ps

module tb_Output_Compare_buffer;
    reg CLK;
    reg rst;
    reg en;
    reg [2:0] mode; // 根據 parameter 定義，mode 應至少 3 bits
    reg [63:0] fdata_0;
    reg [63:0] fdata_1;
    reg [63:0] fdata_2;
    reg [63:0] acc_out;
    
    wire [63:0] core_out;

    // 2. 實例化 DUT
    // 注意：我假設你已經修正了 DUT 內部的 comp_result (wire) 和 comp_en (driver) 問題
    Output_Compare_buffer uut (
        .CLK(CLK),
        .rst(rst),
        .en(en),
        .mode(mode),
        .fdata_0(fdata_0),
        .fdata_1(fdata_1),
        .fdata_2(fdata_2),
        .acc_out(acc_out),
        .core_out(core_out)
    );

    // 3. Clock 產生 (10ns 週期)
    always #2.5 CLK = ~CLK;

    // 4. 測試流程
    initial begin
        // --- 初始化 ---
        CLK = 0;
        rst = 1;
        en = 0;
        mode = 0;
        fdata_0 = 0; fdata_1 = 0; fdata_2 = 0;
        acc_out = 0;

        // Reset
        #20 rst = 0;
        #10;
        
        // Maxpooling mode
        @(negedge CLK);
        mode = 1; // mode = 1
        en = 1;            // 假設你的 comparator 需要 enable
        
        fdata_0 = 64'h0064_0005_0032_000A; // Lane3:100, Lane2:5,  Lane1:50, Lane0:10
        fdata_1 = 64'h0164_0009_000A_0014; // Lane3:100, Lane2:9,  Lane1:10, Lane0:20
        fdata_2 = 64'h0063_0001_000A_001E; // Lane3:99,  Lane2:1,  Lane1:10, Lane0:30
        #5;
        en = 0;
        #60;
        // Conv_1 mode
        en = 1;
        mode = 0;
        acc_out = 64'h0064_0005_0032_000A; // Lane3:100, Lane2:5,  Lane1:50, Lane0:10
        #5;
        en = 0;
        #45
        en = 1;
        acc_out = 64'h0164_0009_000A_0014; // Lane3:100, Lane2:9,  Lane1:10, Lane0:20
        #5;
        en = 0;
        #45
        en = 1;
        acc_out = 64'h0063_0001_000A_001E; // Lane3:99,  Lane2:1,  Lane1:10, Lane0:30 
        #5;
        en = 0;
        
        #100;

        $finish;
    end

endmodule