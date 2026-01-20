`timescale 1ns / 1ps

//delay = 4 cycle

module PE(
    input CLK,
    input en,
    input rst,
    input PE_mode,
    input signed [15:0] PE_A,
    input signed [15:0] PE_B,
    output reg signed [31:0] PE_out
    );
    wire signed [31:0] P; //mult_16 output
    
    //Mode define
    parameter MAC = 1'b0, GAP = 1'b1;

    //mult_16
    mult_16 mult(.CLK(CLK),
                 .A(PE_A),
                 .B(PE_B),
                 .CE(en),
                 .SCLR(rst),
                 .P(P)
    );
    
    //shift_right_4
    reg signed [31:0] A_shift_0, A_shift_1, A_shift;
    always@(posedge CLK) begin
        if(rst==1) A_shift_0 <= 0;
        else A_shift_0 <= $signed({{16{PE_A[15]}}, PE_A}) >>> 4; //>>> is for signed bit
    end

    always@(posedge CLK) begin
        if(rst==1) A_shift_1 <= 0;
        else A_shift_1 <= A_shift_0;
    end

    always@(posedge CLK) begin
        if(rst==1) A_shift <= 0;
        else A_shift <= A_shift_1;
    end

    //output mux
    reg signed [31:0]out_buffer;
    always@(*) begin
        case(PE_mode)
            MAC: out_buffer = P;
            GAP: out_buffer = A_shift;
            default: out_buffer = 0;
        endcase
    end
    
    //output reg
    always@(posedge CLK) begin
        if(rst==1) PE_out <= 0;
        else begin
            if(en==1) PE_out <= out_buffer;
            else PE_out <= PE_out;
        end
    end
endmodule
