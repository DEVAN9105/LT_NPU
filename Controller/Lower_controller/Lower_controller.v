`timescale 1ns / 1ps

module Lower_controller(
    input CLK,
    input rst,
    input en,
    input [9:0] PC_initial,
    input [9:0] PC_end,
    // module done
    input [5:0] core_done,
    input [5:0] CIU_done,
    input [1:0] GLB_done, // input & output
    input PreP_done,
    input PosP_done,
    // output control signal
    output [10:0] en_bus,
    output [132:0] VLIW_out,
    output [8:0] tile_sel,
    // VLIW done
    output VLIW_done
    );

    ////////// VLIW storage //////////
    wire [9:0] PC;
    wire [143:0] VLIW_in;
    VLIW_storage vliw_storage(
        .CLK(CLK),
        .ena(en),
        .addra(PC),
        .douta(VLIW_in)
    );
    ////////// VLIW storage end //////////

    ////////// VLIW FSM //////////
    wire VLIW_decoder_en;
    wire complete;
    wire PC_en, PC_done;
    wire VLIW_rst;
    VLIW_FSM vliw_fsm(
        .CLK(CLK),
        .en(en),
        .rst(rst),
        .en_sel(VLIW_in[143:133]),
        .en_bus(en_bus),
        .VLIW_decoder_en(VLIW_decoder_en),
        .complete(complete),
        .PC_en(PC_en),
        .PC_done(PC_done),
        .VLIW_done(VLIW_done),
        .VLIW_rst(VLIW_rst)
    );
    ////////// VLIW FSM end //////////

    ////////// VLIW decoder //////////
    VLIW_decoder vliw_decoder( 
        .CLK(CLK),
        .rst(VLIW_rst),
        .en(VLIW_decoder_en),
        .VLIW_in(VLIW_in[132:0]),
        .VLIW(VLIW_out),
        .tile_sel(tile_sel)
    );
    ////////// VLIW decoder end //////////

    ////////// VLIW_PC //////////
    VLIW_PC vliw_pc(
        .CLK(CLK),
        .rst(VLIW_rst),
        .en(PC_en),
        // VLIW_storage
        .PC_initial_in(PC_initial),
        .PC_end_in(PC_end),
        .PC(PC),
        .PC_done(PC_done)
    );
    ////////// VLIW_PC end //////////

    ////////// done mux //////////
    Done_mux done_mux_inst(
        .CLK(CLK),
        .rst(VLIW_rst),
        .en_sel_in(en_bus),
        .core_done_in(core_done),
        .CIU_done_in(CIU_done),
        .GLB_done_in(GLB_done), // input & output
        .PreP_done_in(PreP_done),
        .PosP_done_in(PosP_done),
        .complete(complete)
    );
    ////////// done mux end //////////
    
endmodule
