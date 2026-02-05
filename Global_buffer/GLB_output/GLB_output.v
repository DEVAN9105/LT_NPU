`timescale 1ns / 1ps

module GLB_input(
    input CLK,
    input en,
    input rst,
    input glb_in_mode, // 0: pre_processing, 1: core
    // AGU_T
    input [2:0] core,
    input [7:0] AGU_T_initial_in,
    input [6:0] tile_width_in,
    input [7:0] tile_ch_in,
    // AGU_G
    input [11:0] AGU_G_initial_in,
    input [6:0] glb_width_in,
    input [7:0] glb_ch_in,
    output ch_to_Y_en,
    output [9:0] ch_sum,
    input [11:0] Y,
    output [11:0] gaddr,
    // output tile
    output reg [5:0] load_en,
    output reg [7:0] taddr,
    output [63:0] glb_load,
    // glb control
    output glb_b_en,
    input [63:0] dout_glb,
    // done signal
    output done
    );
    
    ////////// GLB control //////////
    wire [11:0] SR_1;
    wire glb_out_rst;
    wire AGU_G_done;
    wire AGU_G_en;
    wire AGU_G_rst;
    wire AGU_G_en_next;
    GLB_output_controller glb_output_controller(
        .CLK(CLK),
        .en(en),
        .rst(rst),
        .AGU_G_done(AGU_G_done),
        .AGU_G_en(AGU_G_en),
        .AGU_G_rst(AGU_G_rst),
        .AGU_G_en_next(AGU_G_en_next),
        .SR_1(SR_1),
        .done(done),
        .glb_out_rst(glb_out_rst)
    );
    ////////// GLB control end //////////

    ////////// signal assign //////////
    assign glb_b_en = SR_1[0];
    ////////// signal assign end //////////

    ////////// AGU_G //////////
    AGU_G agu_g(
        .CLK(CLK),
        .en(AGU_G_en),
        .rst(AGU_G_rst),
        .AGU_G_initial_in(AGU_G_initial_in),
        .glb_width_in(glb_width_in),
        .glb_ch_in(glb_ch_in),
        .ch_to_Y_en(ch_to_Y_en),
        .ch_sum(ch_sum),
        .Y(Y),
        .gaddr(gaddr),
        .en_next(AGU_G_en_next),
        .done(AGU_G_done)
    );
    ////////// AGU_G end //////////

    ////////// AGU_T //////////
    wire [2:0] core_pointer;
    wire [7:0] taddr_buffer;
    AGU_T agu_t(
        .CLK(CLK),
        .en(SR_1[3]),
        .rst(glb_out_rst),
        .AGU_T_initial_in(AGU_T_initial_in),
        .tile_width_in(tile_width_in),
        .tile_ch_in(tile_ch_in),
        .core(core),
        .core_pointer(core_pointer),
        .taddr(taddr_buffer)
    );

    // core decoder
    always@(posedge CLK) begin
        if (glb_out_rst) begin
            load_en <= 6'b0;
        end
        else begin
            if(SR_1[8]) begin
                case(core_pointer)
                    3'b000: load_en <= 6'b000001;
                    3'b001: load_en <= 6'b000010;
                    3'b010: load_en <= 6'b000100;
                    3'b011: load_en <= 6'b001000;
                    3'b100: load_en <= 6'b010000;
                    3'b101: load_en <= 6'b100000;
                    default: load_en <= 6'b000000;
                endcase
            end
            else begin
                load_en <= load_en;
            end
        end
    end

    // taddr buffer
    always@(posedge CLK) begin
        if (glb_out_rst) begin
            taddr <= 8'b0;
        end
        else begin
            taddr <= taddr_buffer;
        end
    end
    ////////// AGU_T end //////////

    ////////// Output Transpose //////////
    Transpose transpose(
        .CLK(CLK),
        .rst(glb_out_rst),
        .en(SR_1[3]),
        .data(dout_glb),
        .data_transpose(glb_load)
    );
    ////////// Output Transpose end //////////

endmodule
