`timescale 1ns / 1ps

// delay = 4 cycle / 2 cycle

module GLB_input_controller(
    input CLK,
    input en,
    input rst,
    input data_valid,
    input AGU_T_done,
    output reg [2:0] SR_0,
    output reg [6:0] SR_1,
    output reg done,
    output reg glb_in_rst
    );
    
    ////////// state define //////////
    parameter idle = 0, processing = 1, ending = 2,finish = 3;
    ////////// state define end //////////

    ////////// reset //////////
    always@(posedge CLK) begin
        if(state == idle) begin
            glb_in_rst <= 1;
        end
        else begin
            glb_in_rst <= 0;
        end
    end
    ////////// reset end //////////

    ////////// FSM //////////
    reg en_SR;
    reg [1:0] next_state;
    always@(*) begin
        //avoid latch
        next_state = state;
        done = 0;
        en_SR = 0;
        
        case(state)
            idle: begin
                if(en) begin
                    next_state = processing;
                end
                else begin
                    next_state = idle;
                end
            end
            processing: begin
                en_SR = 1;
                if(AGU_T_done) begin
                    next_state = finish;
                end
                else begin
                    next_state = processing;
                end
            end
            ending: begin
                if(SR_1[6]) begin
                    next_state = ending;
                end
                else begin
                    next_state = finish;
                end
            end
            finish: begin
                done = 1;
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

    ////////// SR //////////
    // SR_0
    always@(posedge CLK) begin
        if(rst) begin
            SR_0 <= 0;
        end
        else begin
            if(en_SR) begin
                SR_0 <= {SR_0[1:0], 1'b1};
            end
            else begin
                SR_0 <= SR_0;
            end
        end
    end

    // SR_1
    always@(posedge CLK) begin
        if(rst) begin
            SR_1 <= 0;
        end
        else begin
            if(en_SR) begin
                SR_1 <= {SR_1[5:0], data_valid};
            end
            else begin
                SR_1 <= SR_1;
            end
        end
    end
    ////////// SR end //////////

endmodule
