`timescale 1ns / 1ps

module VLIW_PC(
    input CLK,
    input rst,
    input en,
    input [9:0] PC_initial_in,
    input [9:0] PC_end_in,
    output reg [9:0] PC,
    output reg PC_done
    );

    ////////// input buffer //////////
    reg [9:0] PC_initial;
    reg [9:0] PC_end;
    always@(posedge CLK) begin
        PC_initial <= PC_initial_in;
        PC_end <= PC_end_in;
    end
    ////////// input buffer end //////////

    ////////// PC //////////
    reg [9:0] next_PC;
    always@(*) begin
        //avoid latch
        next_PC = PC;
        PC_done = 0;
        if(en) begin
            if(PC == PC_end) begin
                next_PC = PC;
                PC_done = 1;
            end
            else begin
                next_PC = PC + 1;
            end
        end
        else begin
            next_PC = PC;
        end
    end
    always@(posedge CLK) begin
        if(rst) begin
            PC <= PC_initial;
        end
        else begin
            if(en) begin
                PC <= next_PC;
            end
            else begin
                PC <= PC;
            end
        end
    end
    ////////// PC end //////////

endmodule
