`timescale 1ns / 1ps


module Tile_buffer_operator(
    input clka,
    input clkb,
    input [6:0] ena,
    input [6:0] enb,
    input [6:0] wea,
    input [4:0] mux_sel,
    // tile in
    input [7:0] tile_in_addr,
    // tile read
    input [7:0] tile_read_addr,
    // tile store
    input [7:0] tile_store_addr,
    // tile out
    input [7:0] tile_out_addr,
    // tile data in
    input [63:0] tile_1_in,
    input [63:0] tile_2_in,
    input [63:0] tile_3_in,
    input [63:0] tile_4_in,
    input [63:0] tile_5_in,
    input [63:0] tile_6_in,
    input [63:0] tile_7_in,
    // tile data out
    output [63:0] tile_1_out,
    output [63:0] tile_2_out,
    output [63:0] tile_3_out,
    output [63:0] tile_4_out,
    output [63:0] tile_5_out,
    output [63:0] tile_6_out,
    output [63:0] tile_7_out
    );

    ////////// tile 1 //////////
    Tile_buffer tile_buffer_1(
        .clka(clka),
        .ena(ena[0]),
        .wea(wea[0]),
        .addra(tile_in_addr),
        .dina(tile_1_in),
        .clkb(clkb),
        .enb(enb[0]),
        .addrb(tile_store_addr),
        .doutb(tile_1_out)
    );
    ////////// tile 1 end //////////

    ////////// tile 2 //////////
    Tile_buffer tile_buffer_2(
        .clka(clka),
        .ena(ena[1]),
        .wea(wea[1]),
        .addra(tile_in_addr),
        .dina(tile_2_in),
        .clkb(clkb),
        .enb(enb[1]),
        .addrb(tile_store_addr),
        .doutb(tile_2_out)
    );
    ////////// tile 2 end //////////

    ////////// tile 3 //////////
    reg [7:0] addra_3;
    always@(*) begin
        if(mux_sel[0]) begin
            addra_3 = tile_store_addr;
        end
        else begin
            addra_3 = tile_in_addr;
        end
    end
    Tile_buffer tile_buffer_3(
        .clka(clka),
        .ena(ena[2]),
        .wea(wea[2]),
        .addra(addra_3),
        .dina(tile_3_in),
        .clkb(clkb),
        .enb(enb[2]),
        .addrb(tile_store_addr),
        .doutb(tile_3_out)
    );
    ////////// tile 3 end //////////

    ////////// tile 4 //////////
    reg [7:0] addra_4;
    always@(*) begin
        if(mux_sel[1]) begin
            addra_4 = tile_store_addr;
        end
        else begin
            addra_4 = tile_in_addr;
        end
    end
    Tile_buffer tile_buffer_4(
        .clka(clka),
        .ena(ena[3]),
        .wea(wea[3]),
        .addra(addra_4),
        .dina(tile_4_in),
        .clkb(clkb),
        .enb(enb[3]),
        .addrb(tile_store_addr),
        .doutb(tile_4_out)
    );
    ////////// tile 4 end //////////

    ////////// tile 5 //////////
    reg [7:0] addra_5;
    always@(*) begin
        if(mux_sel[2]) begin
            addra_5 = tile_store_addr;
        end
        else begin
            addra_5 = tile_in_addr;
        end
    end
    Tile_buffer tile_buffer_5(
        .clka(clka),
        .ena(ena[4]),
        .wea(wea[4]),
        .addra(addra_5),
        .dina(tile_5_in),
        .clkb(clkb),
        .enb(enb[4]),
        .addrb(tile_store_addr),
        .doutb(tile_5_out)
    );
    ////////// tile 5 end //////////

    ////////// tile 6 //////////
    reg [7:0] addra_6, addrb_6;
    always@(*) begin
        if(mux_sel[3]) begin
            addra_6 = tile_store_addr;
        end
        else begin
            addra_6 = tile_in_addr;
        end
    end
    always@(*) begin
        if(mux_sel[4]) begin
            addrb_6 = tile_in_addr;
        end
        else begin
            addrb_6 = tile_store_addr;
        end
    end
    Tile_buffer tile_buffer_6(
        .clka(clka),
        .ena(ena[5]),
        .wea(wea[5]),
        .addra(addra_6),
        .dina(tile_6_in),
        .clkb(clkb),
        .enb(enb[5]),
        .addrb(addrb_6),
        .doutb(tile_6_out)
    );
    ////////// tile 6 end //////////

    ////////// tile 7 //////////
    Tile_buffer tile_buffer_7(
        .clka(clka),
        .ena(ena[6]),
        .wea(wea[6]),
        .addra(tile_store_addr),
        .dina(tile_7_in),
        .clkb(clkb),
        .enb(enb[6]),
        .addrb(tile_out_addr),
        .doutb(tile_7_out)
    );
endmodule
