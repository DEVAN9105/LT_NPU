`timescale 1ns / 1ps

module VLIW_buffer(
    input CLK,
    input rst,
    input en,
    input [127:0] VLIW_in,
    output reg [127:0] VLIW,
    output reg PC_done
    );

    ////////// input buffer //////////
    always@(posedge CLK) begin
        if(en) begin
            VLIW <= VLIW_in;
        end
        else begin
            VLIW <= VLIW;
        end
    end
    ////////// input buffer end //////////

    
endmodule
