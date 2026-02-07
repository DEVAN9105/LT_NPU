`timescale 1ns / 1ps

module Done_mux(
    input CLK,
    input rst,
    input [10:0] en_sel_in,
    input [5:0] core_done_in,
    input [5:0] CIU_done_in,
    input [1:0] GLB_done_in, // input & output
    input PreP_done_in,
    input PosP_done_in,
    output reg complete
    );

    ////////// input buffer //////////
    reg [10:0] en_sel;
    reg [5:0] core_done;
    reg CIU_done;
    reg [1:0] GLB_done;
    reg PreP_done;
    reg PosP_done;
    always@(posedge CLK) begin
        if(rst) begin
            en_sel <= 0;
            core_done <= 0;
            CIU_done <= 0;
            GLB_done <= 0;
            PreP_done <= 0;
            PosP_done <= 0;
        end
        else begin
            en_sel <= en_sel_in;
            core_done <= core_done_in;
            CIU_done <= &CIU_done_in;
            GLB_done <= GLB_done_in;
            PreP_done <= PreP_done_in;
            PosP_done <= PosP_done_in;
        end
    end
    ////////// input buffer end //////////

    ////////// complete //////////
    wire [10:0] done_buffer = {core_done, CIU_done, GLB_done, PreP_done, PosP_done};
    always@(posedge CLK) begin
        if(rst) begin
            complete <= 0;
        end
        else begin
            complete <= ((en_sel & done_buffer) == en_sel);
        end
    end
    ////////// complete end //////////

endmodule
