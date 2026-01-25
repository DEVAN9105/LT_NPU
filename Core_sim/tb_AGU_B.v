`timescale 1ns / 1ps

module tb_AGU_B;

    // Inputs
    reg CLK = 0;
    reg en;
    reg rst;
    reg [2:0] mode;
    reg [7:0] AGU_B_initial;
    reg [6:0] width_out;
    reg [7:0] ch_in;
    reg [7:0] ch_out;

    // Outputs
    wire [7:0] baddr;
    wire done;

    // Instantiate the Unit Under Test (UUT)
    AGU_B uut (
        .CLK(CLK), 
        .en_in(en), 
        .rst(rst), 
        .mode(mode), 
        .AGU_B_initial_in(AGU_B_initial), 
        .width_out_in(width_out), 
        .ch_in_in(ch_in), 
        .ch_out_in(ch_out), 
        .baddr(baddr), 
        .done(done)
    );

    // Clock generation (10ns period -> 100MHz)
    always #2.5 CLK = ~CLK;
    
    // mode define
    parameter conv = 0, maxpooling = 1, DW = 2, PW = 3, GAP = 4;
    
    integer cycle_count;

    initial begin
        // Initialize Inputs
        en = 0;
        rst = 1; // Assert Reset
        mode = DW;
        AGU_B_initial = 10;
        width_out = 7;
        ch_in = 1;
        ch_out = 1;
        cycle_count = -3;
        
        #100;
        rst = 0;
        #5;
        en = 1;


        wait(done);
        @(posedge CLK);
        #10;
        en = 0;

        #50;
        $stop;
    end
    
    always @(posedge CLK) begin
        if (en && !done)
            cycle_count <= cycle_count + 1;
        else if (rst)
            cycle_count <= 0;
    end

endmodule

