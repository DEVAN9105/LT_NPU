`timescale 1ns / 1ps

//delay = 1

module Comparator(
    input CLK,
    input en,
    input signed [15:0] comp_a,
    input signed [15:0] comp_b,
    input signed [15:0] comp_c,
    output reg signed [15:0] comp_out
    );
    
    always@(posedge CLK) begin
        if(en == 1) begin
            if(comp_a >= comp_b) begin
                if(comp_a >= comp_c) begin
                    comp_out <= comp_a;
                end
                else begin
                    comp_out <= comp_c;
                end
            end
            else begin
                if(comp_b >= comp_c) begin
                    comp_out <= comp_b;
                end
                else begin
                    comp_out <= comp_c;
                end
            end
        end
        else begin
            comp_out <= 0;
        end
    end
    
endmodule
