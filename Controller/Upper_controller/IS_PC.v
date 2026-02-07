`timescale 1ns / 1ps

module IS_PC(
    input CLK,
    input rst,
    // VLIW_storage
    input signed [3:0] PC_step,
    output reg [7:0] IS_PC
    );

    ////////// PC //////////
    reg [7:0] next_PC;
    always@(*) begin
        next_PC = IS_PC + {{4{PC_step[3]}}, PC_step};
    end
    always@(posedge CLK) begin
        if(rst) begin
            IS_PC <= 0;
        end
        else begin
            IS_PC <= next_PC;
        end
    end
    ////////// PC end //////////

endmodule
