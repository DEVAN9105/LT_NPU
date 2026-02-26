`timescale 1ns / 1ps

module Data_loader (
    input  wire         clk,
    input  wire         rst_n,

    // ==========================================
    // 1. AXI-Stream 介面 (直接接外部 DMA)
    // ==========================================
    input  wire [63:0]  s_axis_image_tdata,
    input  wire         s_axis_image_tvalid,
    input  wire         s_axis_image_tlast,
    output wire         s_axis_image_tready,

    input  wire [63:0]  s_axis_weight_tdata,
    input  wire         s_axis_weight_tvalid,
    output wire         s_axis_weight_tready,

    // ==========================================
    // 2. 控制與狀態介面 (接 Controller)
    // ==========================================
    input  wire         i_image_start,
    input  wire         i_weight_start,
    input  wire         i_buffer_sel,
    input  wire         i_image_done,
    
    // 權重控制 (從隊友的 weight_loader_bus 拆解過來)
    input  wire [11:0]  i_weight_len,
    input  wire [6:0]   i_bias_len,

    // 狀態回傳
    output wire         o_image_busy,
    output wire         o_weight_busy,
    output wire         o_image_tile_done,
    output wire         o_weight_layer_done,

    // ==========================================
    // 3. 影像輸出介面 (接頂層的 Ping-Pong BRAM)
    // ==========================================
    output wire [6:0]   o_img_uram_addr,
    output wire         o_img_uram_we,
    output wire [127:0] o_img_uram_data,

    // ==========================================
    // 4. 權重與偏差輸出匯流排 (接 6 個 Core)
    // ==========================================
    // {we[3:0], addr[11:0], data[63:0]} = 80-bit
    output wire [79:0]  o_wgt_storage_bus_1,
    output wire [79:0]  o_wgt_storage_bus_2,
    output wire [79:0]  o_wgt_storage_bus_3,
    output wire [79:0]  o_wgt_storage_bus_4,
    output wire [79:0]  o_wgt_storage_bus_5,
    output wire [79:0]  o_wgt_storage_bus_6,

    // {we[3:0], addr[6:0], data[63:0]} = 75-bit
    output wire [74:0]  o_bias_storage_bus_1,
    output wire [74:0]  o_bias_storage_bus_2,
    output wire [74:0]  o_bias_storage_bus_3,
    output wire [74:0]  o_bias_storage_bus_4,
    output wire [74:0]  o_bias_storage_bus_5,
    output wire [74:0]  o_bias_storage_bus_6
);

    // =========================================================================
    // 內部接線宣告
    // =========================================================================
    wire [63:0] wgt_g_data;
    wire [11:0] wgt_g_w_addr;
    wire [6:0]  wgt_g_b_addr;
    wire [23:0] wgt_g_w_we, wgt_g_b_we;
    wire        wgt_layer_done;

    // Daisy-chain 轉發線 (L0 -> L1 -> L2 -> L3 -> L4 -> L5)
    wire [63:0] L1_d, L2_d, L3_d, L4_d, L5_d;
    wire [11:0] L1_wa, L2_wa, L3_wa, L4_wa, L5_wa;
    wire [6:0]  L1_ba, L2_ba, L3_ba, L4_ba, L5_ba;
    wire [23:0] L1_wwe, L2_wwe, L3_wwe, L4_wwe, L5_wwe;
    wire [23:0] L1_bwe, L2_bwe, L3_bwe, L4_bwe, L5_bwe;
    wire        L1_ld, L2_ld, L3_ld, L4_ld, L5_ld, L6_ld;
    wire        L1_busy, L2_busy, L3_busy, L4_busy, L5_busy, L6_busy;
    wire        wgt_sub_busy; 

    // 各層 Local 輸出
    wire [63:0] l_d1, l_d2, l_d3, l_d4, l_d5, l_d6;
    wire [11:0] l_wa1, l_wa2, l_wa3, l_wa4, l_wa5, l_wa6;
    wire [6:0]  l_ba1, l_ba2, l_ba3, l_ba4, l_ba5, l_ba6;
    wire [3:0]  l_wwe1, l_wwe2, l_wwe3, l_wwe4, l_wwe5, l_wwe6;
    wire [3:0]  l_bwe1, l_bwe2, l_bwe3, l_bwe4, l_bwe5, l_bwe6;

    // =========================================================================
    // 實例化 1: 影像子系統
    // =========================================================================
    Image_Write_Subsystem u_image_sub (
        .clk            (clk),
        .rst_n          (rst_n),
        .s_axis_tdata   (s_axis_image_tdata),
        .s_axis_tvalid  (s_axis_image_tvalid),
        .s_axis_tlast   (s_axis_image_tlast),
        .s_axis_tready  (s_axis_image_tready),
        .i_layer_start  (i_image_start),
        .i_buffer_sel   (i_buffer_sel),
        .i_image_done   (i_image_done),
        .o_tile_done    (o_image_tile_done),
        .o_busy         (o_image_busy),
        .o_uram_addr    (o_img_uram_addr),
        .o_uram_we      (o_img_uram_we),
        .o_uram_data    (o_img_uram_data)
    );

    // =========================================================================
    // 實例化 2: 權重總站
    // =========================================================================
    Weight_Write_Subsystem u_weight_sub (
        .clk                  (clk),
        .rst_n                (rst_n),
        .s_axis_tdata         (s_axis_weight_tdata),
        .s_axis_tvalid        (s_axis_weight_tvalid),
        .s_axis_tready        (s_axis_weight_tready),
        .i_weight_len         (i_weight_len),
        .i_bias_len           (i_bias_len),
        .i_layer_start        (i_weight_start),
        .i_buffer_sel         (i_buffer_sel),
        .i_image_done         (i_image_done),
        .o_aligned_data       (wgt_g_data),
        .o_aligned_w_addr     (wgt_g_w_addr),
        .o_aligned_b_addr     (wgt_g_b_addr),
        .o_aligned_w_we_group (wgt_g_w_we),
        .o_aligned_b_we_group (wgt_g_b_we),
        .o_layer_cnt          (),
        .o_layer_done         (wgt_layer_done),
        .o_all_done           (),
        .o_busy               (wgt_sub_busy)
    );


    // =========================================================================
    // 實例化 3: WBR 路由器 x6 (菊花鏈)
    // =========================================================================
    WBR u_wbr_1 (.clk(clk), .rst_n(rst_n), .i_data(wgt_g_data), .i_w_addr(wgt_g_w_addr), .i_b_addr(wgt_g_b_addr), .i_w_we_group(wgt_g_w_we), .i_b_we_group(wgt_g_b_we), .i_layer_done(wgt_layer_done), .i_busy(wgt_sub_busy), .o_local_data(l_d1), .o_local_w_we(l_wwe1), .o_local_b_we(l_bwe1), .o_local_w_addr(l_wa1), .o_local_b_addr(l_ba1), .o_next_data(L1_d), .o_next_w_addr(L1_wa), .o_next_b_addr(L1_ba), .o_next_w_we_group(L1_wwe), .o_next_b_we_group(L1_bwe), .o_next_layer_done(L1_ld), .o_next_busy(L1_busy));
    
    WBR u_wbr_2 (.clk(clk), .rst_n(rst_n), .i_data(L1_d), .i_w_addr(L1_wa), .i_b_addr(L1_ba), .i_w_we_group(L1_wwe), .i_b_we_group(L1_bwe), .i_layer_done(L1_ld), .i_busy(L1_busy), .o_local_data(l_d2), .o_local_w_we(l_wwe2), .o_local_b_we(l_bwe2), .o_local_w_addr(l_wa2), .o_local_b_addr(l_ba2), .o_next_data(L2_d), .o_next_w_addr(L2_wa), .o_next_b_addr(L2_ba), .o_next_w_we_group(L2_wwe), .o_next_b_we_group(L2_bwe), .o_next_layer_done(L2_ld), .o_next_busy(L2_busy));
    
    WBR u_wbr_3 (.clk(clk), .rst_n(rst_n), .i_data(L2_d), .i_w_addr(L2_wa), .i_b_addr(L2_ba), .i_w_we_group(L2_wwe), .i_b_we_group(L2_bwe), .i_layer_done(L2_ld), .i_busy(L2_busy), .o_local_data(l_d3), .o_local_w_we(l_wwe3), .o_local_b_we(l_bwe3), .o_local_w_addr(l_wa3), .o_local_b_addr(l_ba3), .o_next_data(L3_d), .o_next_w_addr(L3_wa), .o_next_b_addr(L3_ba), .o_next_w_we_group(L3_wwe), .o_next_b_we_group(L3_bwe), .o_next_layer_done(L3_ld), .o_next_busy(L3_busy));
    
    WBR u_wbr_4 (.clk(clk), .rst_n(rst_n), .i_data(L3_d), .i_w_addr(L3_wa), .i_b_addr(L3_ba), .i_w_we_group(L3_wwe), .i_b_we_group(L3_bwe), .i_layer_done(L3_ld), .i_busy(L3_busy), .o_local_data(l_d4), .o_local_w_we(l_wwe4), .o_local_b_we(l_bwe4), .o_local_w_addr(l_wa4), .o_local_b_addr(l_ba4), .o_next_data(L4_d), .o_next_w_addr(L4_wa), .o_next_b_addr(L4_ba), .o_next_w_we_group(L4_wwe), .o_next_b_we_group(L4_bwe), .o_next_layer_done(L4_ld), .o_next_busy(L4_busy));
    
    WBR u_wbr_5 (.clk(clk), .rst_n(rst_n), .i_data(L4_d), .i_w_addr(L4_wa), .i_b_addr(L4_ba), .i_w_we_group(L4_wwe), .i_b_we_group(L4_bwe), .i_layer_done(L4_ld), .i_busy(L4_busy), .o_local_data(l_d5), .o_local_w_we(l_wwe5), .o_local_b_we(l_bwe5), .o_local_w_addr(l_wa5), .o_local_b_addr(l_ba5), .o_next_data(L5_d), .o_next_w_addr(L5_wa), .o_next_b_addr(L5_ba), .o_next_w_we_group(L5_wwe), .o_next_b_we_group(L5_bwe), .o_next_layer_done(L5_ld), .o_next_busy(L5_busy));
    
    WBR u_wbr_6 (.clk(clk), .rst_n(rst_n), .i_data(L5_d), .i_w_addr(L5_wa), .i_b_addr(L5_ba), .i_w_we_group(L5_wwe), .i_b_we_group(L5_bwe), .i_layer_done(L5_ld), .i_busy(L5_busy), .o_local_data(l_d6), .o_local_w_we(l_wwe6), .o_local_b_we(l_bwe6), .o_local_w_addr(l_wa6), .o_local_b_addr(l_ba6), .o_next_data(), .o_next_w_addr(), .o_next_b_addr(), .o_next_w_we_group(), .o_next_b_we_group(), .o_next_layer_done(L6_ld), .o_next_busy(L6_busy));

    // =========================================================================
    // 5. 輸出打包 (Packaging into Buses) 
    // =========================================================================
    assign o_wgt_storage_bus_1 = {l_wwe1, l_wa1, l_d1};
    assign o_wgt_storage_bus_2 = {l_wwe2, l_wa2, l_d2};
    assign o_wgt_storage_bus_3 = {l_wwe3, l_wa3, l_d3};
    assign o_wgt_storage_bus_4 = {l_wwe4, l_wa4, l_d4};
    assign o_wgt_storage_bus_5 = {l_wwe5, l_wa5, l_d5};
    assign o_wgt_storage_bus_6 = {l_wwe6, l_wa6, l_d6};

    assign o_bias_storage_bus_1 = {l_bwe1, l_ba1, l_d1};
    assign o_bias_storage_bus_2 = {l_bwe2, l_ba2, l_d2};
    assign o_bias_storage_bus_3 = {l_bwe3, l_ba3, l_d3};
    assign o_bias_storage_bus_4 = {l_bwe4, l_ba4, l_d4};
    assign o_bias_storage_bus_5 = {l_bwe5, l_ba5, l_d5};
    assign o_bias_storage_bus_6 = {l_bwe6, l_ba6, l_d6};
    

    // =========================================================================
    // Done 訊號：必須等「最後一個 (L6)」做完，才是真正的做完！
    assign o_weight_layer_done = L6_ld;

    // Busy 訊號：只要管線上「任何一個」還在忙，整個子系統就標示為忙碌！
    assign o_weight_busy = wgt_sub_busy | L1_busy | L2_busy | L3_busy | L4_busy | L5_busy | L6_busy;

endmodule