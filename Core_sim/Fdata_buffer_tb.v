`timescale 1ns / 1ps

module Fdata_buffer_tb;

    // =========================================================
    // 1. 宣告訊號
    // =========================================================
    reg CLK;
    reg [8:0] tile_sel;
    reg [2:0] cluster_mode;
    reg padding=0;
    
    // 模擬用的 Tile 資料 (給定固定 Pattern 方便觀察)
    reg [63:0] tile_1 = 64'h1111_1111_1111_1111;
    reg [63:0] tile_2 = 64'h2222_2222_2222_2222;
    reg [63:0] tile_3 = 64'h3333_3333_3333_3333;
    reg [63:0] tile_4 = 64'h4444_4444_4444_4444;
    reg [63:0] tile_5 = 64'h5555_5555_5555_5555;
    reg [63:0] tile_6 = 64'h6666_6666_6666_6666;
    reg [7:0] faddr;

    // 輸出觀測
    wire [63:0] fdata_0;
    wire [63:0] fdata_1;
    wire [63:0] fdata_2;
    wire [63:0] fdata_3;

    // =========================================================
    // 2. 實例化 (Instantiate)
    // =========================================================
    Fdata_buffer uut (
        .CLK(CLK),
        .tile_sel(tile_sel),
        .cluster_mode(cluster_mode),
        .padding(padding),
        .tile_1(tile_1),
        .tile_2(tile_2),
        .tile_3(tile_3),
        .tile_4(tile_4),
        .tile_5(tile_5),
        .tile_6(tile_6),
        .fdata_0(fdata_0),
        .fdata_1(fdata_1),
        .fdata_2(fdata_2),
        .fdata_3(fdata_3)
    );

    // =========================================================
    // 3. 時脈產生 (100MHz, Period = 10ns)
    // =========================================================
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    // =========================================================
    // 4. 測試流程
    // =========================================================
    initial begin
        // --- 初始化狀態 ---
        tile_sel = 0;
        cluster_mode = 0; // Default mode (Conv)
        faddr = 0;
        
        $display("==================================================");
        $display("   Fdata_buffer Simulation Start ");
        $display("==================================================");

        // 等待 50ns
        #50;

        // -----------------------------------------------------------
        // 測試案例 1: 驗證 Default Mode 的 1 Cycle 延遲
        // -----------------------------------------------------------
        // 目標: 
        // fdata_0 選 Tile 1 (tile_sel[8:6] = 1)
        // fdata_1 選 Tile 5 (tile_sel[5:3] = 5)
        // fdata_2 選 Tile 6 (tile_sel[2:0] = 6)
        // 組合: 3'd1, 3'd5, 3'd6 -> 9'b001_101_110
        
        @(negedge CLK); // 在時脈下降緣改變輸入
        $display("[Time %t] Input Changed: requesting T1, T5, T6", $time);
        tile_sel = 9'b000_101_110; 
        
        // --- 檢查點 A: 輸入剛變，CLK 上升緣還沒來 ---
        #1; 
        if (fdata_0 !== tile_1) 
            $display("[Check 1] Correct: Output holds old value before Clock.");
        else 
            $display("[Check 1] Error: Output changed too fast!");

        // --- 等待 CLK 上升緣 ---
        @(posedge CLK); 
        #1; // 等待硬體反應

        // --- 檢查點 B: CLK 上升緣過後 ---
        $display("[Time %t] Clock Edge Passed.", $time);
        
        // 檢查 fdata_0
        if (fdata_0 === tile_1) $display("  -> fdata_0: OK (Updated to Tile 1)");
        else $display("  -> fdata_0: FAIL (Expected %h, Got %h)", tile_1, fdata_0);

        // 檢查 fdata_1
        if (fdata_1 === tile_5) $display("  -> fdata_1: OK (Updated to Tile 5)");
        else $display("  -> fdata_1: FAIL (Expected %h, Got %h)", tile_5, fdata_1);

        // 檢查 fdata_2 (你修正了 bit 範圍，現在應該要能選到 Tile 6)
        if (fdata_2 === tile_6) $display("  -> fdata_2: OK (Updated to Tile 6)");
        else $display("  -> fdata_2: FAIL (Expected %h, Got %h)", tile_6, fdata_2);

        // 檢查 fdata_3 (Default 模式應該是 0)
        if (fdata_3 === 0) $display("  -> fdata_3: OK (Zero Padding in Default Mode)");
        else $display("  -> fdata_3: FAIL (Should be 0, Got %h)", fdata_3);


        // -----------------------------------------------------------
        // 測試案例 2: 驗證 GAP Mode
        // -----------------------------------------------------------
        // GAP 模式下:
        // fdata_0 固定 Tile 1
        // fdata_1 固定 Tile 2
        // fdata_2 固定 Tile 3
        // fdata_3 固定 Tile 4
        
        #20; // 等待幾個 cycle
        @(negedge CLK);
        $display("\n[Time %t] Changing Mode to GAP (3'b100)", $time);
        cluster_mode = 3'b100; // GAP
        tile_sel = 0;          // 把 sel 歸零，確保輸出不是因為 sel 選到的

        @(posedge CLK); // 等待上升緣
        #1;

        if (fdata_3 === tile_4) $display("  -> GAP Mode fdata_3: OK (Updated to Tile 4)");
        else $display("  -> GAP Mode fdata_3: FAIL");

        if (fdata_0 === tile_1) $display("  -> GAP Mode fdata_0: OK (Fixed to Tile 1)");
        else $display("  -> GAP Mode fdata_0: FAIL");


        // -----------------------------------------------------------
        // 測試案例 3: 驗證 Default 0 (清零測試)
        // -----------------------------------------------------------
        #20;
        @(negedge CLK);
        $display("\n[Time %t] Testing Select 0 (Should output 0)", $time);
        cluster_mode = 3'b000; // Default
        tile_sel = 9'b000_000_000; // 全部選 0

        @(posedge CLK);
        #1;
        
        if (fdata_0 == 0 && fdata_1 == 0 && fdata_2 == 0)
            $display("  -> Zero Check: OK (All outputs cleared)");
        else
            $display("  -> Zero Check: FAIL");

        #50;
        $display("\n=== Simulation Finished ===");
        $finish;
    end

endmodule