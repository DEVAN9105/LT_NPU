`timescale 1ns / 1ps

// delay = 4 cycle / 2 cycle

module Core_FSM(
    input CLK,
    input en,
    input rst,
    input AGU_O_done,
    output reg [1:0] state,
    output reg Core_en_counter_en,
    output reg core_done,
    output reg core_rst
    );
    
    ////////// state define //////////
    parameter idle = 0, set_up = 1, processing = 2,finish = 3;
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
    reg [1:0] next_state;
    always@(*) begin
        //avoid latch
        next_state = state;
        core_done = 0;
        core_rst = 0;
        cc_en = 0;
        Core_en_counter_en = 0;

        case(state)
            idle: begin
                core_rst = 1;
                if(en) begin
                    next_state = set_up;
                end
                else begin
                    next_state = idle;
                end
            end
            set_up: begin
                cc_en = 1;
                if(control_count == 2) begin
                    next_state = processing;
                end
                else begin
                    next_state = set_up;
                end
            end
            processing: begin
                Core_en_counter_en = 1;
                if(AGU_O_done) begin
                    next_state = finish;
                end
                else begin
                    next_state = processing;
                end
            end
            finish: begin
                core_done = 1;
                next_state = finish;
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
