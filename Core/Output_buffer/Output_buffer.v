`timescale 1ns / 1ps

// delay = 1 cycle

module Output_buffer(
    input CLK,
    input rst,
    input en,
    input [63:0] acc_out,
    output reg [63:0] core_out
    );
    
    ////////// output //////////
    always@(posedge CLK) begin
        if(rst) begin
            core_out <= 0;
        end
        else begin
            if(en) begin
                core_out <= acc_out;
            end
            else begin
                core_out <= core_out;
            end
        end
    end
    ////////// output end //////////
    
endmodule
