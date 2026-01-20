`timescale 1ns / 1ps

module tb_PE;
    reg rst;
    reg CLK=0,en;
    reg mode;
    reg [15:0] A;
    reg [15:0] B;
    wire [31:0] PE_out;
    
    PE DUT (
        .CLK(CLK),
        .en(en),
        .rst(rst),
        .PE_mode(mode),
        .PE_A(A),
        .PE_B(B),
        .PE_out(PE_out)
    );

    always #2.5 CLK = ~CLK;

    initial begin
        en = 0;
        rst = 1;
        mode = 0; //MAC or GAP
        A = 0;
        B = 0;
        #10;
        rst = 0;
        #5;
        
        en = 1;
        // start testing
        A = 16'h8000; B = 16'h8000; //7
        #5
        A = 16'hFE00; B = 16'h0900; //-18
        #5
        A = 16'h0500; B = 16'h0A00; //50
        #5
        A = 0; B = 0; //0
        #15
        en = 0;
        
        #100; // 等待 100ns 讓結果穩定

        $finish;
    end

endmodule