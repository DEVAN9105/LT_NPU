`timescale 1ns / 1ps

//delay 3

module PE(
    input CLK,
    input PE_en,
    input rst,
    input PE_mode,
    input signed [15:0] PE_A,
    input signed [15:0] PE_B,
    output reg signed [31:0] PE_mac_out
    );
    wire signed [31:0] P; //mult_16 output
    
    //Mode define
    parameter MAC = 1'b0, GAP = 1'b1;
    
    //mult_16
    mult_16 mult(CLK,PE_A,PE_B,PE_en,rst,P);
    
    //shift_right_4
    wire signed [31:0] A_shift;
    assign A_shift = $signed({{16{PE_A[15]}}, PE_A}) >>> 4; //>>> is for signed bit
    
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
        if(rst==1) PE_mac_out <= 0;
        else begin
            if(PE_en==1) PE_mac_out <= out_buffer;
            else PE_mac_out <= PE_mac_out;
        end
    end
endmodule
