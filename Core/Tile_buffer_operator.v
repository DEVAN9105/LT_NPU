`timescale 1ns / 1ps


module Tile_buffer_operator(
    input clka,
    input clkb,
    input [6:0] ena,
    input [6:0] enb,
    input [2:0] mux_sel,
    // tile in
    input we_in,
    input [7:0] addr_in,
    input [63:0] data_in,
    // tile cycle
    input we_cycle_0,
    input we_cycle_1,
    input [7:0] addr_cycle_0,
    input [7:0] addr_cycle_1,
    input [63:0] din_cycle_0,
    input [63:0] din_cycle_1,
    output [63:0] dout_cycle,
    // tile cal
    input [7:0] addr_cal,
    output reg [63:0] dout_cal_0,
    output reg [63:0] dout_cal_1,
    output reg [63:0] dout_cal_2,
    // tile store
    input we_store,
    input [7:0] addr_store,
    input [63:0] din_store,
    // tile out
    input [7:0] addr_out,
    output [63:0] data_out
    );

    ////////// tile 1 //////////
    wire [63:0] dout_1;
    Tile_buffer_sdp tile_buffer_1(
        .clka(clka),
        .ena(ena[0]),
        .wea(we_in),
        .addra(addr_in),
        .dina(data_in),
        .clkb(clkb),
        .enb(enb[0]),
        .addrb(addr_cal),
        .doutb(dout_1)
    );
    ////////// tile 1 end //////////

    ////////// tile 2 //////////
    wire [63:0] dout_2;
    Tile_buffer_sdp tile_buffer_2(
        .clka(clka),
        .ena(ena[1]),
        .wea(we_in),
        .addra(addr_in),
        .dina(data_in),
        .clkb(clkb),
        .enb(enb[1]),
        .addrb(addr_cal),
        .doutb(dout_2)
    );
    ////////// tile 2 end //////////

    ////////// tile 3 //////////
    wire [63:0] dout_3;
    Tile_buffer_sdp tile_buffer_3(
        .clka(clka),
        .ena(ena[2]),
        .wea(we_store),
        .addra(addr_store),
        .dina(data_store),
        .clkb(clkb),
        .enb(enb[2]),
        .addrb(addr_cal),
        .doutb(dout_3)
    );
    ////////// tile 3 end //////////

    ////////// tile 4 //////////
    wire [63:0] dout_4;
    Tile_buffer_sdp tile_buffer_4(
        .clka(clka),
        .ena(ena[3]),
        .wea(we_store),
        .addra(addr_store),
        .dina(data_store),
        .clkb(clkb),
        .enb(enb[3]),
        .addrb(addr_cal),
        .doutb(dout_4)
    );
    ////////// tile 4 end //////////

    ////////// tile 5 //////////
    wire [63:0] dout_5;
    Tile_buffer_sdp tile_buffer_5(
        .clka(clka),
        .ena(ena[4]),
        .wea(we_store),
        .addra(addr_store),
        .dina(data_store),
        .clkb(clkb),
        .enb(enb[4]),
        .addrb(addr_cal),
        .doutb(dout_5)
    );
    ////////// tile 5 end //////////

    ////////// tile 6 //////////
    reg [7:0] addra_6, addrb_6;
    reg [63:0] dina_6;
    wire [63:0] douta_6, doutb_6;
    always@(*) begin // a
        if(mux_sel[0]) begin
            addra_6 = addr_cycle_0;
            dina_6 = din_cycle_0;
        end
        else begin
            addra_6 = addr_store;
            dina_6 = din_store;
        end
    end
    always@(*) begin // b
        case(mux_sel[2:1])
            2'b00: addrb_6 = addr_cal;
            2'b01: addrb_6 = addr_cycle_1;
            2'b10: addrb_6 = addr_out;
            default: addrb_6 = addr_cal;
        endcase
    end
    Tile_buffer_tdp tile_buffer_6(
        .clka(clka),
        .ena(ena[5]),
        .wea(we_in),
        .addra(addra_6),
        .dina(dina_6),
        .douta(douta_6),
        .clkb(clkb),
        .enb(enb[5]),
        .web(we_cycle_1),
        .addrb(addrb_6),
        .dinb(din_cycle_1),
        .doutb(doutb_6)
    );
    ////////// tile 6 end //////////

    ////////// tile 7 //////////
    Tile_buffer_sdp tile_buffer_7(
        .clka(clka),
        .ena(ena[6]),
        .wea(wea[6]),
        .addra(addr_store),
        .dina(data_store),
        .clkb(clkb),
        .enb(enb[6]),
        .addrb(addr_out),
        .doutb(data_out)
    );
    ////////// tile 7 end //////////

    ////////// cal out //////////
    always@(*) begin
        case()
    end
    ////////// cal out //////////
endmodule
