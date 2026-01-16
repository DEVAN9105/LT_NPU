`timescale 1ns / 1ps

module Array_bus_tb;

    // 1. 宣告訊號
    reg CLK;
    reg [63:0] fdata_0;
    reg [63:0] fdata_1;
    reg [63:0] fdata_2;
    reg [63:0] fdata_3;
    reg [2:0] cluster_mode;

    wire [63:0] PE_fin_0;
    wire [63:0] PE_fin_1;
    wire [63:0] PE_fin_2;
    wire [63:0] PE_fin_3;

    // 定義參數以方便閱讀 (對應你的 RTL)
    localparam CONV1 = 0, MAXPOOL = 1, DW = 2, PW = 3, GAP = 4, FC = 5;

    // 2. 實例化 DUT (Device Under Test)
    Array_bus dut (
        .CLK(CLK),
        .fdata_0(fdata_0),
        .fdata_1(fdata_1),
        .fdata_2(fdata_2),
        .fdata_3(fdata_3),
        .cluster_mode(cluster_mode),
        .PE_fin_0(PE_fin_0),
        .PE_fin_1(PE_fin_1),
        .PE_fin_2(PE_fin_2),
        .PE_fin_3(PE_fin_3)
    );

    // 3. 產生時脈 (週期 10ns)
    initial CLK = 0;
    always #5 CLK = ~CLK;

    // 4. 測試流程
    initial begin
        // --- 初始化 ---
        fdata_0 = 0; fdata_1 = 0; fdata_2 = 0; fdata_3 = 0;
        cluster_mode = 0;
        
        #20; // 等待 Reset 穩定

        // ============================================================
        // Case 1: 測試 PW 模式 (Pointwise Conv) -> 預期：廣播複製
        // 模式: 3 (PW)
        // 輸入 fdata_0: 1111_2222_3333_4444 (方便觀察切片)
        // ============================================================
        @(posedge CLK); #1; // 對齊時脈邊緣
        $display("---------------------------------------------------");
        $display("[TEST 1] PW Mode (Broadcast Test)");
        
        cluster_mode = PW; 
        // 設計特殊的 Pattern，每 16-bit 都不一樣
        fdata_0 = 64'h1111_2222_3333_4444; 
        // 這些輸入在 PW 模式應該被忽略
        fdata_1 = 64'hBBBB_BBBB_BBBB_BBBB; 
        fdata_2 = 64'hCCCC_CCCC_CCCC_CCCC;
        fdata_3 = 64'hDDDD_DDDD_DDDD_DDDD;

        @(negedge CLK); // 等待一個 Cycle 讓 Output Register 更新
        @(negedge CLK); // 這裡多等半個 cycle 在下降緣檢查比較穩
        
        $display("Time: %t | Mode: PW", $time);
        $display("Input 0 : %h", fdata_0);
        $display("Output 0: %h (Exp: 1111...)", PE_fin_0);
        $display("Output 1: %h (Exp: 2222...)", PE_fin_1);
        $display("Output 2: %h (Exp: 3333...)", PE_fin_2);
        $display("Output 3: %h (Exp: 4444...)", PE_fin_3);
        
        // 簡單的自動檢查
        if (PE_fin_0 == 64'h1111_1111_1111_1111 && PE_fin_1 == 64'h2222_2222_2222_2222)
            $display(">>> PW Broadcast Check: PASS <<<");
        else
            $display(">>> PW Broadcast Check: FAIL <<<");


        // ============================================================
        // Case 2: 測試 DW 模式 (Depthwise Conv) -> 預期：平行直通
        // 模式: 2 (DW)
        // 輸入: 四個 Channel 給不同的值
        // ============================================================
        @(posedge CLK); #1;
        $display("---------------------------------------------------");
        $display("[TEST 2] DW Mode (Pass-through Test)");
        
        cluster_mode = DW;
        fdata_0 = 64'hAAAA_0000_AAAA_0000;
        fdata_1 = 64'hBBBB_1111_BBBB_1111;
        fdata_2 = 64'hCCCC_2222_CCCC_2222;
        fdata_3 = 64'hDDDD_3333_DDDD_3333;

        @(negedge CLK); // 等待 Pipeline
        @(negedge CLK);
        
        $display("Time: %t | Mode: DW", $time);
        $display("Output 0: %h", PE_fin_0);
        $display("Output 1: %h", PE_fin_1);
        
        if (PE_fin_0 == fdata_0 && PE_fin_1 == fdata_1)
            $display(">>> DW Pass-through Check: PASS <<<");
        else
            $display(">>> DW Pass-through Check: FAIL <<<");

        // ============================================================
        // Case 3: 測試 FC 模式 (Fully Connected) -> 預期：廣播複製
        // 模式: 5 (FC) - 應該跟 PW 行為一樣
        // ============================================================
        @(posedge CLK); #1;
        $display("---------------------------------------------------");
        $display("[TEST 3] FC Mode (Broadcast Test 2)");
        
        cluster_mode = FC;
        // 換一個 Pattern: 000A_000B_000C_000D
        fdata_0 = 64'h000A_000B_000C_000D;

        @(negedge CLK); 
        @(negedge CLK);

        $display("Time: %t | Mode: FC", $time);
        $display("Input 0 : %h", fdata_0);
        $display("Output 3: %h (Exp: 000D...)", PE_fin_3);
        
        if (PE_fin_3 == 64'h000D_000D_000D_000D)
            $display(">>> FC Broadcast Check: PASS <<<");
        else
            $display(">>> FC Broadcast Check: FAIL <<<");

        $display("---------------------------------------------------");
        #10 $finish;
    end

endmodule