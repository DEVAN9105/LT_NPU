`timescale 1ns / 1ps

//combinational delay = 0 cycle

module Comparator(
    input CLK,
    input rst,
    input signed [15:0] comp_a,
    input signed [15:0] comp_b,
    output reg signed [15:0] comp_out
    );
    
    always@(posedge CLK) begin
        if(rst) begin
            comp_out <= 0;
        end
        else begin
            if(comp_a >= comp_b) begin
                comp_out <= comp_a;
            end
            else begin
                comp_out <= comp_b;
            end
        end
    end
    
endmodule

