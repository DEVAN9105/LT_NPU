`timescale 1ns / 1ps

// delay = 2 cycle

module Output_Compare_buffer(
    input CLK,
    input rst,
    input en,
    input [2:0] mode,
    input [63:0] fdata_0,
    input [63:0] fdata_1,
    input [63:0] fdata_2,
    input [63:0] acc_out,
    output reg [63:0] core_out
    );
    
    //cluster mode define
    parameter conv1 = 0, maxpooling = 1, DW = 2, PW = 3, GAP = 4, FC = 5;
    
    ////////// shift register //////////
    reg [63:0] SR_0,SR_1,SR_2;
    
    always@(posedge CLK) begin
        if(rst) begin
            SR_0 <= 0;
            SR_1 <= 0;
            SR_2 <= 0;
        end
        else begin
            if(en) begin
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
            else begin
                SR_0 <= SR_0;
                SR_1 <= SR_1;
                SR_2 <= SR_2;
            end
        end
    end
    ////////// shift register end //////////
    
    ////////// COMP //////////
    /*reg comp_en;
    always@(*) begin
        case(mode)
            conv1,maxpooling: comp_en = en;
            default: comp_en = 0;
        endcase
    end*/
    wire [63:0] comp_result;
    Comparator comp_0(.comp_a(SR_0[15:0]), 
                      .comp_b(SR_1[15:0]), 
                      .comp_c(SR_2[15:0]), 
                      .comp_out(comp_result[15:0]));
    Comparator comp_1(.comp_a(SR_0[31:16]), 
                      .comp_b(SR_1[31:16]), 
                      .comp_c(SR_2[31:16]), 
                      .comp_out(comp_result[31:16]));
    Comparator comp_2(.comp_a(SR_0[47:32]), 
                      .comp_b(SR_1[47:32]), 
                      .comp_c(SR_2[47:32]), 
                      .comp_out(comp_result[47:32]));
    Comparator comp_3(.comp_a(SR_0[63:48]), 
                      .comp_b(SR_1[63:48]), 
                      .comp_c(SR_2[63:48]), 
                      .comp_out(comp_result[63:48]));
    ////////// COMP end //////////
    
    ////////// output //////////
    always@(posedge CLK) begin
        case(mode)
            conv1,maxpooling: begin
                core_out <= comp_result;
            end
            default: begin
                core_out <= SR_0;
            end
        endcase
    end
    ////////// output end //////////
    
endmodule
