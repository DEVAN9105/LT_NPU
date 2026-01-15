`timescale 1ns / 1ps

//delay

module Output_Compare_buffer(
    input CLK,
    input rst,
    input en,
    input mode,
    input [63:0] fdata_0,
    input [63:0] fdata_1,
    input [63:0] fdata_2,
    input [63:0] fdata_3,
    input [63:0] acc_out,
    output reg [63:0] core_out
    );
    
    //cluster mode define
    parameter conv1 = 0, maxpooling = 1, DW = 2, PW = 3, GAP = 4, FC = 5;
    
    //shift register
    reg [63:0] SR_0,SR_1,SR_2;
    
    always@(posedge CLK) begin
        case(mode)
            conv1: begin
                SR_0 <= acc_out; SR_1 <= SR_0; SR_2 <= SR_1;
            end
            maxpooling: begin
                SR_0 <= fdata_0;
                SR_1 <= fdata_1;
                SR_2 <= fdata_2;
            end
            default: begin
                SR_0 <= acc_out;
            end
        endcase
    end
    
    //COMP
    reg comp_en;
    reg [63:0] comp_result;
    Comparator comp_0(.CLK(CLK), 
                      .en(comp_en), 
                      .comp_a(SR_0[15:0]), 
                      .comp_b(SR_1[15:0]), 
                      .comp_c(SR_2[15:0]), 
                      .comp_out(comp_result[15:0]));
    Comparator comp_1(.CLK(CLK), 
                      .en(comp_en), 
                      .comp_a(SR_0[31:16]), 
                      .comp_b(SR_1[31:16]), 
                      .comp_c(SR_2[31:16]), 
                      .comp_out(comp_result[31:16]));
    Comparator comp_2(.CLK(CLK), 
                      .en(comp_en), 
                      .comp_a(SR_0[47:32]), 
                      .comp_b(SR_1[47:32]), 
                      .comp_c(SR_2[47:32]), 
                      .comp_out(comp_result[47:32]));
    Comparator comp_3(.CLK(CLK), 
                      .en(comp_en), 
                      .comp_a(SR_0[63:48]), 
                      .comp_b(SR_1[63:48]), 
                      .comp_c(SR_2[63:48]), 
                      .comp_out(comp_result[63:48]));
    
    //output
    always@(*) begin
        case(mode)
            conv1,maxpooling: begin
                core_out = comp_result;
            end
            default: begin
                core_out = SR_0;
            end
        endcase
    end
    
endmodule
