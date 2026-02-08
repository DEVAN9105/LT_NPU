`timescale 1ns / 1ps

module VLIW_FSM(
    input CLK,
    input en,
    input rst,
    // en
    input [10:0] en_sel,
    output reg [10:0] en_bus,
    // VLIW decoder
    output reg VLIW_decoder_en,
    // done mux
    input complete,
    // PC
    output reg PC_en,
    input PC_done,
    // control
    output reg VLIW_done,
    output reg VLIW_rst
    );
    
    ////////// state define //////////
    parameter idle = 0, set_up = 1, run = 2, finish = 3;
    ////////// state define end //////////

    ////////// control counter //////////
    reg [4:0] control_count;
    reg cc_en;
    always@(posedge CLK) begin
        if(rst) begin
            control_count <= 0;
        end
        else begin
            if(cc_en) begin
                control_count <= control_count + 1;
            end
            else begin
                control_count <= 0;
            end
        end
    end
    ////////// control counter end //////////

    ////////// FSM //////////
    reg [1:0] state, next_state;
    always@(*) begin
        //avoid latch
        next_state = state;
        VLIW_done = 0;
        cc_en = 0;
        PC_en = 0;
        en_bus = 0;
        VLIW_decoder_en = 0;
        VLIW_rst = 0;

        case(state)
            idle: begin
                VLIW_rst = 1;
                if(en) begin
                    next_state = set_up;
                end
                else begin
                    next_state = idle;
                end
            end
            set_up: begin
                cc_en = 1;
                // next state
                if(control_count == 3) begin
                    next_state = run;
                    PC_en = 1;
                    VLIW_decoder_en = 0;
                end
                else begin
                    next_state = set_up;
                    PC_en = 0;
                    VLIW_decoder_en = 1;
                end
            end
            run: begin
                en_bus = en_sel;
                if(complete) begin
                    if(PC_done) begin
                        next_state = finish;
                    end
                    else begin
                        next_state = set_up;
                    end
                end
                else begin
                    next_state = run;
                end
            end
            finish: begin
                VLIW_done = 1;
                if(en) begin
                    next_state = finish;
                end
                else begin
                    next_state = idle;
                end
            end
            default: begin
                next_state = idle;
            end
        endcase
    end
    always@(posedge CLK) begin
        if(rst) begin
            state <= idle;
        end
        else begin
            state <= next_state;
        end
    end
    ////////// FSM end //////////

endmodule
