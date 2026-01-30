`timescale 1ns / 1ps


module Tile_buffer_operator(
    input clka,
    input clkb,
    input en,
    input rst,
    // tile assign
    input [11:0] tile_Core,
    input [8:0] tile_CIU,
    // tile in
    input valid_in,
    input [7:0] addr_in,
    input [63:0] din_in,
    // tile cycle
    input valid_cycle_0,
    input valid_cycle_1,
    input [7:0] addr_cycle_0,
    input [7:0] addr_cycle_1,
    input [63:0] din_cycle_0,
    input [63:0] din_cycle_1,
    output [63:0] dout_cycle,
    // tile out
    input [7:0] addr_out,
    output [63:0] dout_out,
    // tile cal
    input [7:0] addr_cal,
    output reg [63:0] dout_cal_0,
    output reg [63:0] dout_cal_1,
    output reg [63:0] dout_cal_2,
    output reg [63:0] dout_cal_3,
    // tile store
    input valid_store,
    input [7:0] addr_store,
    input [63:0] din_store
    );

    ////////// decode //////////
    // ena
    reg [6:0] ena_in, en_cycle, ena_out, ena;
    always@(*) begin
        // tile in
        case(tile_CIU[8:6])
            1: ena_in = 7'b0000001;
            2: ena_in = 7'b0000010;
            3: ena_in = 7'b0000100;
            4: ena_in = 7'b0001000;
            5: ena_in = 7'b0010000;
            6: ena_in = 7'b0100000;
            7: ena_in = 7'b1000000;
            default: ena_in = 7'b0000000;
        endcase
        // tile cycle
        case(tile_CIU[5:3])
            1: en_cycle = 7'b0000001;
            2: en_cycle = 7'b0000010;
            3: en_cycle = 7'b0000100;
            4: en_cycle = 7'b0001000;
            5: en_cycle = 7'b0010000;
            6: en_cycle = 7'b0100000;
            7: en_cycle = 7'b1000000;
            default: en_cycle = 7'b0000000;
        endcase
        // tile out
        case(tile_CIU[2:0])  
            1: ena_out = 7'b0000001;
            2: ena_out = 7'b0000010;
            3: ena_out = 7'b0000100;
            4: ena_out = 7'b0001000;
            5: ena_out = 7'b0010000;
            6: ena_out = 7'b0100000;
            7: ena_out = 7'b1000000;
            default: ena_out = 7'b0000000;
        endcase
    end
    always@(posedge clka) begin
        if(rst) begin
            ena <= 7'd0;
        end
        else begin
            if(en) begin
                ena = ena_in | en_cycle | ena_out;
            end
            else begin
                ena <= 7'd0;
            end
        end
    end

    // enb
    reg [6:0] enb_cal_0, enb_cal_1, enb_cal_2, enb_store, enb;
    always@(*) begin
        enb = enb_cal_0 | enb_cal_1 | enb_cal_2 | enb_store;
        // tile cal
        case(tile_Core[11:9])
            1: enb_cal_0 = 7'b0000001;
            2: enb_cal_0 = 7'b0000010;
            3: enb_cal_0 = 7'b0000100;
            4: enb_cal_0 = 7'b0001000;
            5: enb_cal_0 = 7'b0010000;
            6: enb_cal_0 = 7'b0100000;
            7: enb_cal_0 = 7'b1000000;
            default: enb_cal_0 = 7'b0000000;
        endcase
        case(tile_Core[8:6])
            1: enb_cal_1 = 7'b0000001;
            2: enb_cal_1 = 7'b0000010;
            3: enb_cal_1 = 7'b0000100;
            4: enb_cal_1 = 7'b0001000;
            5: enb_cal_1 = 7'b0010000;
            6: enb_cal_1 = 7'b0100000;
            7: enb_cal_1 = 7'b1000000;
            default: enb_cal_1 = 7'b0000000;
        endcase
        case(tile_Core[8:6])
            1: enb_cal_2 = 7'b0000001;
            2: enb_cal_2 = 7'b0000010;
            3: enb_cal_2 = 7'b0000100;
            4: enb_cal_2 = 7'b0001000;
            5: enb_cal_2 = 7'b0010000;
            6: enb_cal_2 = 7'b0100000;
            7: enb_cal_2 = 7'b1000000;
            default: enb_cal_2 = 7'b0000000;
        endcase
        // tile store
        case(tile_Core[5:3])
            1: enb_store = 7'b0000001;
            2: enb_store = 7'b0000010;
            3: enb_store = 7'b0000100;
            4: enb_store = 7'b0001000;
            5: enb_store = 7'b0010000;
            6: enb_store = 7'b0100000;
            7: enb_store = 7'b1000000;
            default: enb_store = 7'b0000000;
        endcase
    end
    always@(posedge clkb) begin
        if(rst) begin
            enb <= 7'd0;
        end
        else begin
            if(en) begin
                enb = enb_cal_0 | enb_cal_1 | enb_cal_2 | en_cycle | enb_store;
            end
            else begin
                enb <= enb;
            end
        end
    end
    // 
    ////////// decode end //////////

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
