`timescale 1ns / 1ps


module Tile_buffer_operator(
    input clka,
    input clkb,
    input [6:0] ena,
    input [6:0] enb,
    input mux_sel,
    // tile in
    input we_in,
    input [7:0] addr_in,
    input [63:0] data_in,
    input we_cycle,
    input [7:0] addr_cycle,
    input [63:0] data_cycle,
    // tile cal
    input [7:0] addr_cal,
    input [63:0] data_cal_0,
    input [63:0] data_cal_1,
    input [63:0] data_cal_2,
    // tile store
    input we_store,
    input [7:0] addr_store,
    input [63:0] data_store,
    // tile out
    input [7:0] addr_out,
    output [63:0] data_out
    );

    ////////// tile 1 //////////
    wire [63:0] data_1_out;
    Tile_buffer_sdp tile_buffer_1(
        .clka(clka),
        .ena(ena[0]),
        .wea(we_in),
        .addra(addr_in),
        .dina(data_in),
        .clkb(clkb),
        .enb(enb[0]),
        .addrb(addr_cal),
        .doutb(data_1_out)
    );
    ////////// tile 1 end //////////

    ////////// tile 2 //////////
    wire [63:0] data_2_out;
    Tile_buffer_sdp tile_buffer_2(
        .clka(clka),
        .ena(ena[1]),
        .wea(we_in),
        .addra(addr_in),
        .dina(data_in),
        .clkb(clkb),
        .enb(enb[1]),
        .addrb(addr_cal),
        .doutb(data_2_out)
    );
    ////////// tile 2 end //////////

    ////////// tile 3 //////////
    wire [63:0] data_3_out;
    Tile_buffer_sdp tile_buffer_3(
        .clka(clka),
        .ena(ena[2]),
        .wea(we_store),
        .addra(addr_store),
        .dina(data_store),
        .clkb(clkb),
        .enb(enb[2]),
        .addrb(addr_cal),
        .doutb(data_3_out)
    );
    ////////// tile 3 end //////////

    ////////// tile 4 //////////
    wire [63:0] data_4_out;
    Tile_buffer_sdp tile_buffer_4(
        .clka(clka),
        .ena(ena[3]),
        .wea(we_store),
        .addra(addr_store),
        .dina(data_store),
        .clkb(clkb),
        .enb(enb[3]),
        .addrb(addr_cal),
        .doutb(data_4_out)
    );
    ////////// tile 4 end //////////

    ////////// tile 5 //////////
    wire [63:0] data_5_out;
    Tile_buffer_sdp tile_buffer_5(
        .clka(clka),
        .ena(ena[4]),
        .wea(we_store),
        .addra(addr_store),
        .dina(data_store),
        .clkb(clkb),
        .enb(enb[4]),
        .addrb(addr_cal),
        .doutb(data_5_out)
    );
    ////////// tile 5 end //////////

    ////////// tile 6 //////////
    reg [7:0] addra_6, addrb_6;
    reg [63:0] data_6_in;
    wire [63:0] data_6_out;
    always@(*) begin
        if(mux_sel) begin
            addra_6 = addr_in;
            data_6_in = data_in;
        end
        else begin
            addra_6 = addr_store;
            data_6_in = data_store;
        end
    end
    always@(*) begin
        if(mux_sel) begin
            addrb_6 = addr_out;
        end
        else begin
            addrb_6 = addr_cal;
        end
    end
    Tile_buffer_tdp tile_buffer_6(
        .clka(clka),
        .ena(ena[5]),
        .wea(we_in),
        .addra(addra_6),
        .dina(data_6_in),
        .clkb(clkb),
        .enb(enb[5]),
        .web(we_cycle),
        .addrb(addrb_6),
        .doutb(data_6_out)
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
endmodule
