`timescale 1ns / 1ps

module tb_AGU_O;

    // Inputs
    reg CLK;
    reg en_in;
    reg rst;
    reg [7:0] AGU_O_initial_in;
    reg [7:0] tile_size_in;

    // Outputs
    wire [7:0] oaddr;
    wire done;

    // Instantiate the Unit Under Test (UUT)
    AGU_O uut (
        .CLK(CLK), 
        .en_in(en_in), 
        .rst(rst), 
        .AGU_O_initial_in(AGU_O_initial_in), 
        .tile_size_in(tile_size_in), 
        .oaddr(oaddr), 
        .done(done)
    );

    // Clock generation (100MHz)
    always #2.5 CLK = ~CLK;

    initial begin
        // 1. Initialize Inputs
        CLK = 0;
        en_in = 0;
        rst = 1;
        AGU_O_initial_in = 0;
        tile_size_in = 0;

        // Wait for global reset
        #100;
        
        // 2. Release Reset
        @(negedge CLK); 
        rst = 0;

        tile_size_in = 95;    
        AGU_O_initial_in = 0;
        

        // 4. Enable Module
        @(negedge CLK);
        en_in = 1;
        
        #5;
        en_in = 0;
        
        #20
        en_in = 1;
        
        wait(done);
        
        #10;
        
        $finish;
    end
    
endmodule