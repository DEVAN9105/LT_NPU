`timescale 1ns / 1ps

module Cycle_controller(
    input CLK,
    input rst,
    input en,
    input AGU_C_done,
    output reg set,
    output cycle_rst,
    output reg [7:0] cycle_SR,
    output reg cycle_done
    );
    
    ////////// control counter //////////
    reg cc_en;
    reg [2:0] cc_end;
    reg [2:0] cc, next_cc;
    always@(*) begin
        //avoid latch
        next_cc = cc;
        
        if(cc == cc_end) begin
            next_cc = 0;
        end
        else begin
            next_cc = cc + 1;
        end
    end
    always@(posedge CLK) begin
        if(rst) begin
            cc <= 0;
        end
        else begin
            if(cc_en) begin
                cc <= next_cc;
            end
            else begin
                cc <= 0;
            end
        end
    end
    ////////// control counter end //////////
    
    ////////// FSM //////////
    reg [1:0] state, next_state;
    parameter idle = 0, processing = 1, ending = 2, finish = 3;
    always@(*) begin
        //avoid latch
        next_state = state;
        cycle_done = 0;
        cc_en = 0;
        cc_end = 0;
        set = 0;
        cycle_rst = 0;
        //FSM logic
        case(state)
            idle: begin
                set = 1;
                if(en) begin
                    next_state = processing;
                end
                else begin
                    next_state = idle;
                end
            end
            processing: begin
                cc_en = 1;
                cc_end = 2;

                //state transition
                if(AGU_C_done) begin
                    next_state = ending;
                end
                else begin
                    next_state = processing;
                end
            end
            ending: begin
                if(cycle_SR == 8'b00000000) begin
                    next_state = finish;
                end
                else begin
                    next_state = ending;
                end
            end
            finish: begin
                next_state = finish;
                cycle_done = 1;
                cycle_rst = 1;
            end
            default: begin
                next_state = idle;
                cycle_done = 0;
            end
        endcase
    end
    //state register
    always@(posedge CLK) begin
        if(rst) begin
            state <= idle;
        end
        else begin
            state <= next_state;
        end
    end
    ////////// FSM end //////////

    ////////// cycle_SR //////////
    wire SR_en = (state == processing) & (cc == 0);
    always@(posedge CLK) begin
        if(rst) begin
            cycle_SR <= 0;
        end
        else begin
            cycle_SR <= {cycle_SR[6:0], SR_en};
        end
    end
    ////////// cycle_SR end //////////
endmodule
