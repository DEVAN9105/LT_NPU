`timescale 1ns / 1ps

module tb_Core_SR();

    // Inputs
    reg CLK;
    reg rst;
    reg en;
    reg acc_done;
    reg [2:0] mode;
    reg [1:0] state;

    // Outputs
    wire [11:0] SR_0;
    wire [7:0] SR_1;

    // Instantiate the Unit Under Test (UUT)
    Core_SR uut (
        .CLK(CLK), 
        .rst(rst), 
        .en(en), 
        .acc_done(acc_done), 
        .mode(mode), 
        .state(state), 
        .SR_0(SR_0), 
        .SR_1(SR_1)
    );

    // Clock generation (10ns period = 100MHz)
    always #2.5 CLK = ~CLK;


    initial begin
        // Initialize Inputs
        CLK = 0;
        rst = 1;
        en = 0;
        acc_done = 0;
        mode = 1;   // Default: CONV
        state = 2;  // Default: Idle
        #20;
        rst = 0;
        #15;
        en = 1;
        
        #100;
        acc_done = 1;
        #5;
        acc_done = 0;
        // Change state to Idle (0), but keep en=1
        
        #200 $finish;
    end

endmodule