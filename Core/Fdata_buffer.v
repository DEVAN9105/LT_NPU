`timescale 1ns / 1ps

// delay = 1 cycle

(* keep_hierarchy = "yes" *)
module Fdata_buffer(
    input CLK,
    input rst,
    input en,
    input [8:0]tile_sel, //3*tile
    input [2:0]mode, //function
    input boundary,
    input [63:0]tile_1,
    input [63:0]tile_2,
    input [63:0]tile_3,
    input [63:0]tile_4,
    input [63:0]tile_5,
    input [63:0]tile_6,
    output reg [63:0]fdata_0,
    output reg [63:0]fdata_1,
    output reg [63:0]fdata_2,
    output reg [63:0]fdata_3
    );
    
    //cluster mode define
    parameter conv = 0, maxpooling = 1, DW = 2, PW = 3, GAP = 4;
    
    //tile selecting
    reg [63:0]mux_out_0,mux_out_1,mux_out_2;
    always@(*) begin
        //fdata_0
        case(tile_sel[8:6])
            1: mux_out_0 = tile_1;
            2: mux_out_0 = tile_2;
            3: mux_out_0 = tile_3;
            4: mux_out_0 = tile_4;
            5: mux_out_0 = tile_5;
            6: mux_out_0 = tile_6;
            default: mux_out_0 = 0; //tile_sel = 0
        endcase
        //fdata_1
        case(tile_sel[5:3])
            1: mux_out_1 = tile_1;
            2: mux_out_1 = tile_2;
            3: mux_out_1 = tile_3;
            4: mux_out_1 = tile_4;
            5: mux_out_1 = tile_5;
            6: mux_out_1 = tile_6;
            default: mux_out_1 = 0; //tile_sel = 0
        endcase
        //fdata_2
        case(tile_sel[2:0])
            1: mux_out_2 = tile_1;
            2: mux_out_2 = tile_2;
            3: mux_out_2 = tile_3;
            4: mux_out_2 = tile_4;
            5: mux_out_2 = tile_5;
            6: mux_out_2 = tile_6;
            default: mux_out_2 = 0; //tile_sel = 0
        endcase
    end
    
    //output
    always@(posedge CLK) begin
        if(rst) begin
            fdata_0 <= 64'd0;
            fdata_1 <= 64'd0;
            fdata_2 <= 64'd0;
            fdata_3 <= 64'd0;
        end
        else if(en) begin
            if (mode == GAP) begin
                //Pass-through
                fdata_0 <= tile_1;
                fdata_1 <= tile_2;
                fdata_2 <= tile_3;
                fdata_3 <= tile_4;
            end
            else begin
                // (Conv/Pool/DW) + Padding
                fdata_0 <= (boundary) ? 64'd0 : mux_out_0;
                fdata_1 <= (boundary) ? 64'd0 : mux_out_1;
                fdata_2 <= (boundary) ? 64'd0 : mux_out_2;
                fdata_3 <= 64'd0;
            end
        end
        else begin
            fdata_0 <= fdata_0;
            fdata_1 <= fdata_1;
            fdata_2 <= fdata_2;
            fdata_3 <= fdata_3;
        end
    end
    
endmodule