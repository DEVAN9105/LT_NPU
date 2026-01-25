`timescale 1ns / 1ps

module W_storage#(
    parameter   p_wdith_addr_a              = 12                                ,
    parameter   p_wdith_wdata               = 64                                ,
    parameter   p_wdith_addr_b              = 12                                ,
    parameter   p_wdith_rdata               = 64                                ,
    parameter   p_memory_size               = 4096* 64                        ,
    parameter   p_read_delay                = 3                                ,
    parameter   p_byte_with                 = 8                                 ,
    parameter   p_wea_with                  = 1                                ,
)
(
    input                                                       clk             ,
    input                                                       rst_n           ,
    //port a
    input       [ p_wea_with-1     : 0 ]                        wea             ,
    input       [ p_wdith_wdata-1  : 0 ]                        dina            ,
 
    input                                                       ena             ,
    input       [ p_wdith_addr_a-1 : 0 ]                        addra           ,
    output      [ p_wdith_rdata-1  : 0 ]                        douta           ,
    // port b
    input       [ p_web_with-1     : 0 ]                        web             ,
    input       [ p_wdith_addr_b-1 : 0 ]                        addrb           ,
    input       [ p_wdith_wdata-1  : 0 ]                        dinb            ,
 
    input                                                       enb             ,
    output      [ p_wdith_rdata-1 : 0  ]                        doutb
 );
 
// xpm_memory_tdpram : In order to incorporate this function into the design,
//      Verilog      : the following instance declaration needs to be placed
//     instance      : in the body of the design code.  The instance name
//    declaration    : (xpm_memory_tdpram_inst) and/or the port declarations within the
//       code        : parenthesis may be changed to properly reference and
//                   : connect this function to the design.  All inputs
//                   : and outputs must be connected.
 
//  Please reference the appropriate libraries guide for additional information on the XPM modules.
 
//  <-----Cut code below this line---->
 
   // xpm_memory_tdpram: True Dual Port RAM
   // Xilinx Parameterized Macro, version 2019.1
 
   xpm_memory_sdpram #(
      .ADDR_WIDTH_A             (p_wdith_addr_a ),    // DECIMAL
      .ADDR_WIDTH_B             (p_wdith_addr_b ),    // DECIMAL
      .AUTO_SLEEP_TIME          (0              ),    // DECIMAL
      .BYTE_WRITE_WIDTH_A       (p_byte_with    ),    // DECIMAL
      .BYTE_WRITE_WIDTH_B       (p_wdith_rdata  ),    // DECIMAL
      .CASCADE_HEIGHT           (0              ),    // DECIMAL
      .CLOCKING_MODE            ("common_clock" ),    // String
      .ECC_MODE                 ("no_ecc"       ),    // String
      .MEMORY_INIT_FILE         ("none"         ),    // String
      .MEMORY_INIT_PARAM        ("0"            ),    // String
      .MEMORY_OPTIMIZATION      ("true"         ),    // String
      .MEMORY_PRIMITIVE         ("ultra"        ),    // String
      .MEMORY_SIZE              (p_memory_size  ),    // DECIMAL
      .MESSAGE_CONTROL          (0              ),    // DECIMAL
      .READ_DATA_WIDTH_A        (p_wdith_rdata  ),    // DECIMAL
      .READ_DATA_WIDTH_B        (p_wdith_rdata  ),    // DECIMAL
      .READ_LATENCY_A           (p_read_delay   ),    // DECIMAL
      .READ_LATENCY_B           (p_read_delay   ),    // DECIMAL
      .READ_RESET_VALUE_A       ("0"            ),    // String
      .READ_RESET_VALUE_B       ("0"            ),    // String
      .RST_MODE_A               ("SYNC"         ),    // String
      .RST_MODE_B               ("SYNC"         ),    // String
      .SIM_ASSERT_CHK           (0              ),    // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_EMBEDDED_CONSTRAINT  (0              ),    // DECIMAL
      .USE_MEM_INIT             (1              ),    // DECIMAL
      .WAKEUP_TIME              ("disable_sleep"),    // String
      .WRITE_DATA_WIDTH_A       (p_wdith_wdata  ),    // DECIMAL
      .WRITE_DATA_WIDTH_B       (p_wdith_wdata  ),    // DECIMAL
      .WRITE_MODE_A             ("no_change"    ),    // String
      .WRITE_MODE_B             ("no_change"    )     // String
   )
   xpm_memory_sdpram_inst (
      .dbiterra             (                   ), // 1-bit output: Status signal to indicate double bit error occurrence
                                                   // on the data output of port A.
 
      .dbiterrb             (                   ), // 1-bit output: Status signal to indicate double bit error occurrence
                                                   // on the data output of port A.
 
      .douta                (douta              ), // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      .doutb                (doutb              ), // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterra             (                   ), // 1-bit output: Status signal to indicate single bit error occurrence
                                                   // on the data output of port A.
 
      .sbiterrb             (                   ), // 1-bit output: Status signal to indicate single bit error occurrence
                                                   // on the data output of port B.
 
      .addra                (addra              ), // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
      .addrb                (addrb              ), // ADDR_WIDTH_B-bit input: Address for port B write and read operations.
      .clka                 (clk                ), // 1-bit input: Clock signal for port A. Also clocks port B when
                                                   // parameter CLOCKING_MODE is "common_clock".
 
      .clkb                 (clk                ), // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                                   // "independent_clock". Unused when parameter CLOCKING_MODE is
                                                   // "common_clock".
      .dina                 (dina               ), // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .dinb                 (dinb               ), // WRITE_DATA_WIDTH_B-bit input: Data input for port B write operations.
      .ena                  (ena                ), // 1-bit input: Memory enable signal for port A. Must be high on clock
                                                   // cycles when read or write operations are initiated. Pipelined
                                                   // internally.
      .enb                  (enb                ),  // 1-bit input: Memory enable signal for port B. Must be high on clock
                                                   // cycles when read or write operations are initiated. Pipelined
                                                   // internally.
 
      .injectdbiterra       (1'b0               ), // 1-bit input: Controls double bit error injection on input data when
                                                 // ECC enabled (Error injection capability is not available in
                                                 // "decode_only" mode).
      .injectdbiterrb       (1'b0               ), // 1-bit input: Controls double bit error injection on input data when
                                                 // ECC enabled (Error injection capability is not available in
                                                 // "decode_only" mode).
 
      .injectsbiterra       (1'b0               ), // 1-bit input: Controls single bit error injection on input data when
                                                 // ECC enabled (Error injection capability is not available in
                                                 // "decode_only" mode).
      .injectsbiterrb       (1'b0               ), // 1-bit input: Controls single bit error injection on input data when
                                                 // ECC enabled (Error injection capability is not available in
                                                 // "decode_only" mode).
 
      .regcea               (1'b1               ), // 1-bit input: Clock Enable for the last register stage on the output
                                                 // data path.
      .regceb               (1'b1               ), // 1-bit input: Clock Enable for the last register stage on the output
                                                 // data path.
 
      .rsta                 (~rst_n             ),  // 1-bit input: Reset signal for the final port A output register stage.
                                                    // Synchronously resets output port douta to the value specified by
                                                    // parameter READ_RESET_VALUE_A.
 
      .rstb                 (~rst_n             ), // 1-bit input: Reset signal for the final port B output register stage.
                                                  // Synchronously resets output port doutb to the value specified by
                                                  // parameter READ_RESET_VALUE_B.
 
      .sleep                (1'b0               ),  // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea                  (wea                ),  // WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input
                                                    // data port dina. 1 bit wide when word-wide writes are used. In
                                                    // byte-wide write configurations, each bit controls the writing one
                                                    // byte of dina to address addra. For example, to synchronously write
                                                    // only bits [15-8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be
                                                    // 4'b0010.
 
      .web                  (web                )   // WRITE_DATA_WIDTH_B-bit input: Write enable vector for port B input
                                                    // data port dinb. 1 bit wide when word-wide writes are used. In
                                                    // byte-wide write configurations, each bit controls the writing one
                                                    // byte of dinb to address addrb. For example, to synchronously write
                                                    // only bits [15-8] of dinb when WRITE_DATA_WIDTH_B is 32, web would be
                                                    // 4'b0010.
   );