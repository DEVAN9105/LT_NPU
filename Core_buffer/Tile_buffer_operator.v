`timescale 1ns / 1ps

module Tile_buffer_operator(
    input clka,
    input clkb,
    // tile assign
    input [2:0] tile_sel_cycle_in,
    input [19:0] tile_assign_in,
    // tile load
    input valid_load,
    input [7:0] addr_load,
    input [63:0] din_load,
    // tile cycle
    input valid_cycle_a,
    input valid_cycle_b,
    input [7:0] addr_cycle_a,
    input [7:0] addr_cycle_b,
    input [63:0] din_cycle_a,
    input [63:0] din_cycle_b,
    output reg [63:0] dout_cycle,
    // tile wb
    input en_wb,
    input [7:0] addr_wb,
    output [63:0] dout_wb,
    // tile cal
    input valid_cal,
    input [7:0] addr_cal,
    output [63:0] tile_1,
    output [63:0] tile_2,
    output [63:0] tile_3,
    output [63:0] tile_4,
    output [63:0] tile_5,
    output [63:0] tile_6,
    // tile store
    input valid_store,
    input [7:0] addr_store,
    input [63:0] din_store
    );

    ////////// input buffer ///////////
    reg [19:0] tile_assign;
    reg [2:0] tile_sel_cycle;
    always@(posedge clka) begin
        tile_assign <= tile_assign_in;
        tile_sel_cycle <= tile_sel_cycle_in;
    end
    ////////// input buffer end ///////////

    ////////// define function //////////
    parameter none = 3'd0, cal = 3'd1, load = 3'd2, cycle = 3'd3, store = 3'd4;
    ////////// define function end /////////

    ////////// tile 1 //////////
    reg ena_1, enb_1;
    reg wea_1, web_1;
    wire [63:0] douta_1;
    reg [7:0] addra_1, addrb_1;
    reg [63:0] dina_1, dinb_1;
    // mux
    always@(*) begin
        case(tile_assign[19:17])
            cal: begin
                ena_1 = 0;
                enb_1 = valid_cal;
                wea_1 = 0;
                web_1 = 0;
                addra_1 = 8'd0;
                dina_1 = 64'd0;
                addrb_1 = addr_cal;
                dinb_1 = 64'd0;
            end
            load: begin
                ena_1 = 1;
                enb_1 = 0;
                wea_1 = valid_load;
                web_1 = 0;
                addra_1 = addr_load;
                dina_1 = din_load;
                addrb_1 = 8'd0;
                dinb_1 = 64'd0;
            end
            cycle: begin
                ena_1 = 1;
                enb_1 = 1;
                wea_1 = valid_cycle_a;
                web_1 = valid_cycle_b;
                addra_1 = addr_cycle_a;
                dina_1 = din_cycle_a;
                addrb_1 = addr_cycle_b;
                dinb_1 = din_cycle_b;
            end
            store: begin
                ena_1 = 0;
                enb_1 = 1;
                wea_1 = 0;
                web_1 = valid_store;
                addra_1 = 8'd0;
                dina_1 = 64'd0;
                addrb_1 = addr_store;
                dinb_1 = din_store;
            end
            default: begin
                ena_1 = 0;
                enb_1 = 0;
                wea_1 = 0;
                web_1 = 0;
                addra_1 = 8'd0;
                dina_1 = 64'd0;
                addrb_1 = 8'd0;
                dinb_1 = 64'd0;
            end
        endcase
    end

    Tile_buffer_tdp tile_buffer_1(
        .clka(clka),
        .ena(ena_1),
        .wea(wea_1),
        .addra(addra_1),
        .dina(dina_1),
        .douta(douta_1),
        .clkb(clkb),
        .enb(enb_1),
        .web( web_1 ),
        .addrb(addrb_1),
        .dinb(dinb_1),
        .doutb(tile_1)
    );
    ////////// tile 1 end //////////

    ////////// tile 2 //////////
    reg ena_2, enb_2;
    reg wea_2, web_2;
    wire [63:0] douta_2;
    reg [7:0] addra_2, addrb_2;
    reg [63:0] dina_2, dinb_2;
    // mux
    always@(*) begin
        case(tile_assign[16:14])
            cal: begin
                ena_2 = 0;
                enb_2 = valid_cal;
                wea_2 = 0;
                web_2 = 0;
                addra_2 = 8'd0;
                dina_2 = 64'd0;
                addrb_2 = addr_cal;
                dinb_2 = 64'd0;
            end
            load: begin
                ena_2 = 1;
                enb_2 = 0;
                wea_2 = valid_load;
                web_2 = 0;
                addra_2 = addr_load;
                dina_2 = din_load;
                addrb_2 = 8'd0;
                dinb_2 = 64'd0;
            end
            cycle: begin
                ena_2 = 1;
                enb_2 = 1;
                wea_2 = valid_cycle_a;
                web_2 = valid_cycle_b;
                addra_2 = addr_cycle_a;
                dina_2 = din_cycle_a;
                addrb_2 = addr_cycle_b;
                dinb_2 = din_cycle_b;
            end
            store: begin
                ena_2 = 0;
                enb_2 = 1;
                wea_2 = 0;
                web_2 = valid_store;
                addra_2 = 8'd0;
                dina_2 = 64'd0;
                addrb_2 = addr_store;
                dinb_2 = din_store;
            end
            default: begin
                ena_2 = 0;
                enb_2 = 0;
                wea_2 = 0;
                web_2 = 0;
                addra_2 = 8'd0;
                dina_2 = 64'd0;
                addrb_2 = 8'd0;
                dinb_2 = 64'd0;
            end
        endcase
    end

    Tile_buffer_tdp tile_buffer_2(
        .clka(clka),
        .ena(ena_2),
        .wea(wea_2),
        .addra(addra_2),
        .dina(dina_2),
        .douta(douta_2),
        .clkb(clkb),
        .enb(enb_2),
        .web( web_2 ),
        .addrb(addrb_2),
        .dinb(dinb_2),
        .doutb(tile_2)
    );
    ////////// tile 2 end //////////

    ////////// tile 3 //////////
    reg ena_3, enb_3;
    reg wea_3, web_3;
    wire [63:0] douta_3;
    reg [7:0] addra_3, addrb_3;
    reg [63:0] dina_3, dinb_3;
    // mux
    always@(*) begin
        case(tile_assign[13:11])
            cal: begin
                ena_3 = 0;
                enb_3 = valid_cal;
                wea_3 = 0;
                web_3 = 0;
                addra_3 = 8'd0;
                dina_3 = 64'd0;
                addrb_3 = addr_cal;
                dinb_3 = 64'd0;
            end
            load: begin
                ena_3 = 1;
                enb_3 = 0;
                wea_3 = valid_load;
                web_3 = 0;
                addra_3 = addr_load;
                dina_3 = din_load;
                addrb_3 = 8'd0;
                dinb_3 = 64'd0;
            end
            cycle: begin
                ena_3 = 1;
                enb_3 = 1;
                wea_3 = valid_cycle_a;
                web_3 = valid_cycle_b;
                addra_3 = addr_cycle_a;
                dina_3 = din_cycle_a;
                addrb_3 = addr_cycle_b;
                dinb_3 = din_cycle_b;
            end
            store: begin
                ena_3 = 0;
                enb_3 = 1;
                wea_3 = 0;
                web_3 = valid_store;
                addra_3 = 8'd0;
                dina_3 = 64'd0;
                addrb_3 = addr_store;
                dinb_3 = din_store;
            end
            default: begin
                ena_3 = 0;
                enb_3 = 0;
                wea_3 = 0;
                web_3 = 0;
                addra_3 = 8'd0;
                dina_3 = 64'd0;
                addrb_3 = 8'd0;
                dinb_3 = 64'd0;
            end
        endcase
    end

    Tile_buffer_tdp tile_buffer_3(
        .clka(clka),
        .ena(ena_3),
        .wea(wea_3),
        .addra(addra_3),
        .dina(dina_3),
        .douta(douta_3),
        .clkb(clkb),
        .enb(enb_3),
        .web( web_3 ),
        .addrb(addrb_3),
        .dinb(dinb_3),
        .doutb(tile_3)
    );
    ////////// tile 3 end //////////

    ////////// tile 4 //////////
    reg ena_4, enb_4;
    reg wea_4, web_4;
    wire [63:0] douta_4;
    reg [7:0] addra_4, addrb_4;
    reg [63:0] dina_4, dinb_4;
    // mux
    always@(*) begin
        case(tile_assign[10:8])
            cal: begin
                ena_4 = 0;
                enb_4 = valid_cal;
                wea_4 = 0;
                web_4 = 0;
                addra_4 = 8'd0;
                dina_4 = 64'd0;
                addrb_4 = addr_cal;
                dinb_4 = 64'd0;
            end
            load: begin
                ena_4 = 1;
                enb_4 = 0;
                wea_4 = valid_load;
                web_4 = 0;
                addra_4 = addr_load;
                dina_4 = din_load;
                addrb_4 = 8'd0;
                dinb_4 = 64'd0;
            end
            cycle: begin
                ena_4 = 1;
                enb_4 = 1;
                wea_4 = valid_cycle_a;
                web_4 = valid_cycle_b;
                addra_4 = addr_cycle_a;
                dina_4 = din_cycle_a;
                addrb_4 = addr_cycle_b;
                dinb_4 = din_cycle_b;
            end
            store: begin
                ena_4 = 0;
                enb_4 = 1;
                wea_4 = 0;
                web_4 = valid_store;
                addra_4 = 8'd0;
                dina_4 = 64'd0;
                addrb_4 = addr_store;
                dinb_4 = din_store;
            end
            default: begin
                ena_4 = 0;
                enb_4 = 0;
                wea_4 = 0;
                web_4 = 0;
                addra_4 = 8'd0;
                dina_4 = 64'd0;
                addrb_4 = 8'd0;
                dinb_4 = 64'd0;
            end
        endcase
    end

    Tile_buffer_tdp tile_buffer_4(
        .clka(clka),
        .ena(ena_4),
        .wea(wea_4),
        .addra(addra_4),
        .dina(dina_4),
        .douta(douta_4),
        .clkb(clkb),
        .enb(enb_4),
        .web( web_4 ),
        .addrb(addrb_4),
        .dinb(dinb_4),
        .doutb(tile_4)
    );
    ////////// tile 4 end //////////

    ////////// tile 5 //////////
    reg ena_5, enb_5;
    reg wea_5, web_5;
    wire [63:0] douta_5;
    reg [7:0] addra_5, addrb_5;
    reg [63:0] dina_5, dinb_5;
    // mux
    always@(*) begin
        case(tile_assign[7:5])
            cal: begin
                ena_5 = 0;
                enb_5 = valid_cal;
                wea_5 = 0;
                web_5 = 0;
                addra_5 = 8'd0;
                dina_5 = 64'd0;
                addrb_5 = addr_cal;
                dinb_5 = 64'd0;
            end
            load: begin
                ena_5 = 1;
                enb_5 = 0;
                wea_5 = valid_load;
                web_5 = 0;
                addra_5 = addr_load;
                dina_5 = din_load;
                addrb_5 = 8'd0;
                dinb_5 = 64'd0;
            end
            cycle: begin
                ena_5 = 1;
                enb_5 = 1;
                wea_5 = valid_cycle_a;
                web_5 = valid_cycle_b;
                addra_5 = addr_cycle_a;
                dina_5 = din_cycle_a;
                addrb_5 = addr_cycle_b;
                dinb_5 = din_cycle_b;
            end
            store: begin
                ena_5 = 0;
                enb_5 = 1;
                wea_5 = 0;
                web_5 = valid_store;
                addra_5 = 8'd0;
                dina_5 = 64'd0;
                addrb_5 = addr_store;
                dinb_5 = din_store;
            end
            default: begin
                ena_5 = 0;
                enb_5 = 0;
                wea_5 = 0;
                web_5 = 0;
                addra_5 = 8'd0;
                dina_5 = 64'd0;
                addrb_5 = 8'd0;
                dinb_5 = 64'd0;
            end
        endcase
    end

    Tile_buffer_tdp tile_buffer_5(
        .clka(clka),
        .ena(ena_5),
        .wea( wea_5 ),
        .addra(addra_5),
        .dina(dina_5),
        .douta(douta_5),
        .clkb(clkb),
        .enb(enb_5),
        .web( web_5 ),
        .addrb(addrb_5),
        .dinb(dinb_5),
        .doutb(tile_5)
    );
    ////////// tile 5 end //////////

    ////////// tile 6 //////////
    reg ena_6, enb_6;
    reg wea_6, web_6;
    wire [63:0] douta_6;
    reg [7:0] addra_6, addrb_6;
    reg [63:0] dina_6, dinb_6;
    // mux
    always@(*) begin
        case(tile_assign[4:2])
            cal: begin
                ena_6 = 0;
                enb_6 = valid_cal;
                wea_6 = 0;
                web_6 = 0;
                addra_6 = 8'd0;
                dina_6 = 64'd0;
                addrb_6 = addr_cal;
                dinb_6 = 64'd0;
            end
            load: begin
                ena_6 = 1;
                enb_6 = 0;
                wea_6 = valid_load;
                web_6 = 0;
                addra_6 = addr_load;
                dina_6 = din_load;
                addrb_6 = 8'd0;
                dinb_6 = 64'd0;
            end
            cycle: begin
                ena_6 = 1;
                enb_6 = 1;
                wea_6 = valid_cycle_a;
                web_6 = valid_cycle_b;
                addra_6 = addr_cycle_a;
                dina_6 = din_cycle_a;
                addrb_6 = addr_cycle_b;
                dinb_6 = din_cycle_b;
            end
            store: begin
                ena_6 = 0;
                enb_6 = 1;
                wea_6 = 0;
                web_6 = valid_store;
                addra_6 = 8'd0;
                dina_6 = 64'd0;
                addrb_6 = addr_store;
                dinb_6 = din_store;
            end
            default: begin
                ena_6 = 0;
                enb_6 = 0;
                wea_6 = 0;
                web_6 = 0;
                addra_6 = 8'd0;
                dina_6 = 64'd0;
                addrb_6 = 8'd0;
                dinb_6 = 64'd0;
            end
        endcase
    end

    Tile_buffer_tdp tile_buffer_6(
        .clka(clka),
        .ena(ena_6),
        .wea( wea_6 ),
        .addra(addra_6),
        .dina(dina_6),
        .douta(douta_6),
        .clkb(clkb),
        .enb(enb_6),
        .web( web_6 ),
        .addrb(addrb_6),
        .dinb(dinb_6),
        .doutb(tile_6)
    );
    ////////// tile 6 end //////////

    ////////// tile 7 //////////
    reg ena_7, enb_7;
    reg wea_7;
    reg [7:0] addra_7, addrb_7;
    reg [63:0] dina_7;
    // mux
    always@(*) begin
        case(tile_assign[1:0])
            1: begin // store
                ena_7 = 1;
                enb_7 = 0;
                wea_7 = valid_store;
                addra_7 = addr_store;
                dina_7 = din_store;
                addrb_7 = 8'd0;
            end
            2: begin // out
                ena_7 = 0;
                enb_7 = en_wb;
                wea_7 = 0;
                addra_7 = 8'd0;
                dina_7 = 64'd0;
                addrb_7 = addr_wb;
            end
            default: begin
                ena_7 = 0;
                enb_7 = 0;
                wea_7 = 0;
                addra_7 = 8'd0;
                dina_7 = 64'd0;
                addrb_7 = 8'd0;
            end
        endcase
    end

    Tile_buffer_sdp tile_buffer_7(
        .clka(clka),
        .ena(ena_7),
        .wea(wea_7),
        .addra(addra_7),
        .dina(dina_7),
        .clkb(clkb),
        .enb(enb_7),
        .addrb(addrb_7),
        .doutb(dout_wb)
    );
    ////////// tile 7 end //////////

    ////////// cycle out //////////
    always@(*) begin
        case(tile_sel_cycle)
            1: dout_cycle = douta_1;
            2: dout_cycle = douta_2;
            3: dout_cycle = douta_3;
            4: dout_cycle = douta_4;
            5: dout_cycle = douta_5;
            6: dout_cycle = douta_6;
            default: dout_cycle = 64'd0;
        endcase
    end
    ////////// cycle out end //////////
endmodule
