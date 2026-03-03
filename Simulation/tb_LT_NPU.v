`timescale 1ns / 1ps
`define Golden_File_Name "C:/Vivado_test/LT_NPU/Shufflenet/output.dat" // 記得確認檔名
`define Image_File_Name  "C:/Vivado_test/LT_NPU/Shufflenet/new1_image_hex_64b.txt" // 影像輸入檔路徑
`define Weight_File_Name "C:/Vivado_test/LT_NPU/Shufflenet/weight_bias_64b.txt" // 權重輸入檔路徑

// =============================================================================
// 模組名稱: tb_LT_NPU_Stage1
// 描述: 測試 Stage 1 - 同時啟動 Weight 與 Image DMA
// =============================================================================

module tb_LT_NPU_Stage1();

    // =========================================================
    // 1. 系統與測試參數定義
    // =========================================================
    localparam CLK_Time_Period = 10.0; 
    localparam Error = 16'd10;          
    localparam CHECK_LENGTH = 4;   // 這裡填你輸出的總筆數
    localparam Initial_Address = 0;

    reg CLK;
    reg asynchronous_rst;
    
    initial begin
        CLK = 0;
        forever #2.5 CLK = ~CLK; 
    end

    // =========================================================
    // 2. PS 控制訊號與 NPU 狀態
    // =========================================================
    reg  PS_en;
    reg  PS_rst;
    wire PL_busy;
    wire [3:0] inference_result;

    reg  start_dma_flag; 
    reg  wgt_dma_done_flag; // 獨立的權重完成旗標
    reg  img_dma_done_flag; // 獨立的影像完成旗標

    // 比對專用變數
    reg [63:0] golden_data [0:65535]; 
    reg Number_0_Correct, Number_1_Correct, Number_2_Correct, Number_3_Correct;
    integer counter_1 = 0;

    // =========================================================
    // 3. AXI-Stream 介面與記憶體陣列宣告
    // =========================================================
    // 權重端
    reg  [63:0] s_axis_weight_tdata;
    reg         s_axis_weight_tvalid;
    wire        s_axis_weight_tready;
    integer     wgt_idx;
    reg  [63:0] WGT_MEMORY [0:89016];

    // 影像端 (已修正拼字 inmage -> image)
    reg  [63:0] s_axis_image_tdata;
    reg         s_axis_image_tvalid;
    reg         s_axis_image_tlast;
    wire        s_axis_image_tready;
    integer     img_idx;
    reg  [63:0] IMG_MEMORY [0:65535]; // 宣告足夠大的陣列裝 61440 拍影像

    // =========================================================
    // 4. 實例化頂層待測物 (Top Module DUT)
    // =========================================================
    LT_NPU u_dut (
        .CLK                    (CLK),
        .PS_en                  (PS_en),
        .PS_rst                 (PS_rst),
        .PL_busy                (PL_busy),

        .s_axis_weight_tdata    (s_axis_weight_tdata),
        .s_axis_weight_tvalid   (s_axis_weight_tvalid),
        .s_axis_weight_tready   (s_axis_weight_tready),

        // 影像端 Port (已修正拼字)
        .s_axis_image_tdata     (s_axis_image_tdata),
        .s_axis_image_tvalid    (s_axis_image_tvalid),
        .s_axis_image_tlast     (s_axis_image_tlast),
        .s_axis_image_tready    (s_axis_image_tready),

        .inference_result       (inference_result)
    );

    // =========================================================
    // 5A. 獨立線程 1：權重 DMA (負責 240 拍)
    // =========================================================
    initial begin
        s_axis_weight_tvalid = 0; 
        s_axis_weight_tdata  = 0;
        wgt_dma_done_flag    = 0;

        wait(start_dma_flag == 1'b1); 
        @(posedge CLK); 

        wgt_idx = 0; 
      while (wgt_idx < 89016) begin 
            @(negedge CLK);
            s_axis_weight_tvalid = 1;
            s_axis_weight_tdata  = WGT_MEMORY[wgt_idx];
            
            @(posedge CLK);
            if (s_axis_weight_tready == 1'b1) begin
                wgt_idx = wgt_idx + 1; 
            end
        end

        @(negedge CLK);
        s_axis_weight_tvalid = 0;
        wgt_dma_done_flag = 1;
    end

    // =========================================================
    // 5B. 獨立線程 2：影像 DMA (負責 61440 拍)
    // =========================================================
    initial begin
        // 已修正拼字
        s_axis_image_tvalid = 0; 
        s_axis_image_tdata  = 0;
        s_axis_image_tlast  = 0;
        img_dma_done_flag   = 0;

        wait(start_dma_flag == 1'b1); 
        @(posedge CLK); 

        img_idx = 0; 
        while (img_idx < 61440) begin
            @(negedge CLK);
            s_axis_image_tvalid = 1;
            s_axis_image_tdata  = IMG_MEMORY[img_idx];
            
            // 只有在最後一拍拉高 TLAST
            if (img_idx == 61439) begin
                s_axis_image_tlast = 1'b1;
            end else begin
                s_axis_image_tlast = 1'b0;
            end
            
            @(posedge CLK);
            if (s_axis_image_tready == 1'b1) begin
                img_idx = img_idx + 1; 
            end
        end

        @(negedge CLK);
        s_axis_image_tvalid = 0;
        s_axis_image_tlast  = 0;
        img_dma_done_flag   = 1;
    end

    // =========================================================
    // 6. 主控流程與自動比對邏輯 (Main & Checking)
    // =========================================================
    initial begin
        // 一口氣把所有檔案都讀進來
        $readmemh(`Weight_File_Name, WGT_MEMORY);
        $readmemh(`Image_File_Name, IMG_MEMORY);
        $readmemh(`Golden_File_Name, golden_data);

        $display("=== [Time %0t] System reset start ===", $time);
        CLK = 0; 
        PS_en = 0; 
        start_dma_flag = 0; 
        
        PS_rst = 1;

        #100;  
        PS_rst = 0;
        $display("=== [Time %0t] System reset end，start NPU ===", $time);

        #100;

        // 發送喚醒脈衝 (Pulse)
        @(posedge CLK); PS_en = 1;
        @(posedge CLK); PS_en = 0;
        $display("=== [Time %0t] sned PS_en wake up pulse ===", $time);

        // 這裡一拉高，5A 和 5B 兩個 DMA 線程就會「同時」開始狂塞資料！
        start_dma_flag = 1;

        wait(PL_busy == 1'b1);
        $display("=== [Time %0t] NPU start (PL_busy = 1) ===", $time);

        // 乖乖等待 PL_busy 降下來
        wait(PL_busy == 1'b0);
        $display("=== [Time %0t] NPU done (PL_busy = 0) ===", $time);

        #100;

        //  ==========================================================
        //  自動比對階段
        //  ==========================================================
        $display("\n=== Start memory check (check amount: %0d) ===", CHECK_LENGTH);
        
        for(counter_1 = 0; counter_1 < CHECK_LENGTH; counter_1 = counter_1 + 1) begin
            $display("Address %d:", counter_1);
            
            // 印出實際硬體記憶體內容 (注意路徑已改為 u_dut 起頭)
            $display("\tThe Content In The Global Buffer: %h, %h, %h, %h", 
                u_dut.glb_operator.glb.xpm_memory_sdpram_inst.xpm_memory_base_inst.mem[counter_1+Initial_Address][63:48],
                u_dut.glb_operator.glb.xpm_memory_sdpram_inst.xpm_memory_base_inst.mem[counter_1+Initial_Address][47:32],
                u_dut.glb_operator.glb.xpm_memory_sdpram_inst.xpm_memory_base_inst.mem[counter_1+Initial_Address][31:16],
                u_dut.glb_operator.glb.xpm_memory_sdpram_inst.xpm_memory_base_inst.mem[counter_1+Initial_Address][15:0]
            );
            
            // 印出 Golden Model 答案
            $display("\tThe Content In The Golden Output: %h, %h, %h, %h", 
                golden_data[counter_1][63:48], 
                golden_data[counter_1][47:32],
                golden_data[counter_1][31:16],
                golden_data[counter_1][15:0]
            );
            
            Number_0_Correct = (($signed(u_dut.glb_operator.glb.xpm_memory_sdpram_inst.xpm_memory_base_inst.mem[counter_1+Initial_Address][63:48]) <= ($signed(golden_data[counter_1][63:48]) + $signed(Error)))
                             && ($signed(u_dut.glb_operator.glb.xpm_memory_sdpram_inst.xpm_memory_base_inst.mem[counter_1+Initial_Address][63:48]) >= ($signed(golden_data[counter_1][63:48]) - $signed(Error))));
            Number_1_Correct = (($signed(u_dut.glb_operator.glb.xpm_memory_sdpram_inst.xpm_memory_base_inst.mem[counter_1+Initial_Address][47:32]) <= ($signed(golden_data[counter_1][47:32]) + $signed(Error)))
                             && ($signed(u_dut.glb_operator.glb.xpm_memory_sdpram_inst.xpm_memory_base_inst.mem[counter_1+Initial_Address][47:32]) >= ($signed(golden_data[counter_1][47:32]) - $signed(Error))));
            Number_2_Correct = (($signed(u_dut.glb_operator.glb.xpm_memory_sdpram_inst.xpm_memory_base_inst.mem[counter_1+Initial_Address][31:16]) <= ($signed(golden_data[counter_1][31:16]) + $signed(Error)))
                             && ($signed(u_dut.glb_operator.glb.xpm_memory_sdpram_inst.xpm_memory_base_inst.mem[counter_1+Initial_Address][31:16]) >= ($signed(golden_data[counter_1][31:16]) - $signed(Error))));
            Number_3_Correct = (($signed(u_dut.glb_operator.glb.xpm_memory_sdpram_inst.xpm_memory_base_inst.mem[counter_1+Initial_Address][15:0]) <= ($signed(golden_data[counter_1][15:0]) + $signed(Error)))
                             && ($signed(u_dut.glb_operator.glb.xpm_memory_sdpram_inst.xpm_memory_base_inst.mem[counter_1+Initial_Address][15:0]) >= ($signed(golden_data[counter_1][15:0]) - $signed(Error))));

            if(!Number_0_Correct) $display("\t>>> Error: Number 0 Mismatch");
            if(!Number_1_Correct) $display("\t>>> Error: Number 1 Mismatch");
            if(!Number_2_Correct) $display("\t>>> Error: Number 2 Mismatch");
            if(!Number_3_Correct) $display("\t>>> Error: Number 3 Mismatch");
            
            $display("");
            @(posedge CLK);
        end
        
        $display("=== Stage 1 End ===");
        $finish;
    end

endmodule