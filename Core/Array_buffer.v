`timescale 1ns / 1ps

//delay 1

module Array_bus(
    input CLK,
    input [63:0]fdata_0,
    input [63:0]fdata_1,
    input [63:0]fdata_2,
    input [63:0]fdata_3,
    input [2:0]mode,
    output reg [63:0] PE_fin_0,
    output reg [63:0] PE_fin_1,
    output reg [63:0] PE_fin_2,
    output reg [63:0] PE_fin_3
    );
    
    //cluster mode define
    parameter conv1 = 0, maxpooling = 1, DW = 2, PW = 3, GAP = 4, FC = 5;
    
    always@(posedge CLK) begin
        case(mode)
            conv1, PW, FC: begin
                PE_fin_0 <= {4{fdata_0[63:48]}};
                PE_fin_1 <= {4{fdata_0[47:32]}};
                PE_fin_2 <= {4{fdata_0[31:16]}};
                PE_fin_3 <= {4{fdata_0[15:0]}};
            end
            maxpooling, DW, GAP: begin
                PE_fin_0 <= fdata_0;
                PE_fin_1 <= fdata_1;
                PE_fin_2 <= fdata_2;
                PE_fin_3 <= fdata_3;
            end
            default: begin
                PE_fin_0 <= fdata_0;
                PE_fin_1 <= fdata_1;
                PE_fin_2 <= fdata_2;
                PE_fin_3 <= fdata_3;
            end
        endcase
    end
    
endmodule
