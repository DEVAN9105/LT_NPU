`timescale 1ns / 1ps

(* DONT_TOUCH = "TRUE" *)
module W_storage (
    input wire clk,
    input wire rst,             // Reset (只重置輸出 Register，不清除內部資料)
    
    // Port A: 寫入端 (給 DMA 用)
    input wire we_a,            // Write Enable
    input wire [11:0] addr_a,   // Write Address (Depth 4096 -> 12 bits)
    input wire [63:0] din_a,    // Data Input
    
    // Port B: 讀取端 (給 Core 用)
    input wire en_b,            // Read Enable (通常恆 1，或由 Controller 控制)
    input wire [11:0] addr_b,   // Read Address
    output wire [63:0] dout_b   // Data Output
);

    // -------------------------------------------------------------------------
    // XPM_MEMORY_SDPRAM: Simple Dual Port RAM for UltraRAM
    // -------------------------------------------------------------------------
    xpm_memory_sdpram #(
        .ADDR_WIDTH_A(12),               // 地址寬度: 12 bits (2^12 = 4096)
        .ADDR_WIDTH_B(12),               // 讀取端通常跟寫入端一樣
        .BYTE_WRITE_WIDTH_A(64),         // 64: 代表不使用 Byte Enable (一次寫64bit)
        .CLOCKING_MODE("common_clock"),  // 讀寫共用同一個 Clock
        .ECC_MODE("no_ecc"),             // 不需要 ECC
        .MEMORY_INIT_FILE("none"),       // URAM 不支援初始值
        .MEMORY_OPTIMIZATION("true"),    // 讓 Vivado 自動優化
        .MEMORY_PRIMITIVE("ultra"),      // ★★★ 關鍵：強制指定 "ultra" (URAM) ★★★
        .MEMORY_SIZE(262144),            // 總容量 bits = 64 * 4096 = 262,144
        .MESSAGE_CONTROL(0),
        .READ_DATA_WIDTH_B(64),          // 讀取寬度
        .READ_LATENCY_B(3),              // ★★★ 關鍵：設為 3 以確保 200MHz 時序收斂 (Pipeline)
        .USE_MEM_INIT(0),
        .WAKEUP_TIME("disable_sleep"),
        .WRITE_DATA_WIDTH_A(64),         // 寫入寬度
        .WRITE_MODE_B("read_first")       // 讀取時不干擾 (效能最好)
    )
    xpm_memory_sdpram_inst (
        // Common Clock
        .clka(clk),
        .clkb(clk),
        .rstb(rst),          // URAM 的 Reset 主要是清空 Output Register

        // Port A (Write)
        .ena(1'b1),          // Port A Enable 恆開，用 wea 控制寫入即可
        .wea(we_a),          // Write Enable
        .addra(addr_a),
        .dina(din_a),
        
        // Port B (Read)
        .enb(en_b),          // Read Enable
        .addrb(addr_b),
        .doutb(dout_b),
        
        // 未使用的功能接 0 或 open
        .regceb(1'b1),
        .sleep(1'b0),
        .injectsbiterra(1'b0),
        .injectdbiterra(1'b0)
    );

endmodule