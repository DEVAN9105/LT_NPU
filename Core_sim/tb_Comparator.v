`timescale 1ns / 1ps

module Comparator_tb;
    reg CLK=0,en;
    reg [15:0] A,B,C;
    wire [15:0] comp_out;
    
    Comparator DUT (
        .CLK(CLK),
        .comparator_en(en),
        .comp_a(A),
        .comp_b(B),
        .comp_c(C),
        .comp_out(comp_out)
    );

    always #2.5 CLK = ~CLK;

    initial begin
        en = 0;
        A = 0;
        B = 0;
        C = 0;
        #15; // 等待 3CLK
        
        en = 1;
        // start testing
        A = 16'h0100; B = 16'h0700; C = 16'h0700;
        #5
        A = 16'hFE00; B = 16'h0000; C = 16'h0000;
        #5
        A = 0; B = 16'h0100; C = 0;
        #15
        A = 0; B = 0; C = 0;
        en = 0;
        
        #100; // 等待 100ns 讓結果穩定

        $finish;
    end

endmodule