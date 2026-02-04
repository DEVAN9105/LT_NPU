`timescale 1ns / 1ps

// delay = 4 cycle / 2 cycle

module GLB_output_controller(
    input CLK,
    input en,
    input rst,
    input AGU_G_done,
    output reg AGU_G_en,
    output reg [10:0] SR,
    output reg done,
    output reg glb_out_rst
    );
    
    ////////// state define //////////
    parameter idle = 0, processing = 1, ending = 2,finish = 3;
    ////////// state define end //////////

    ////////// reset //////////
    always@(posedge CLK) begin
        if(state == idle) begin
            glb_out_rst <= 1;
        end
        else begin
            glb_out_rst <= 0;
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
        AGU_G_en = 0;
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
                AGU_G_en = 1;
                if(AGU_G_done) begin
                    next_state = finish;
                end
                else begin
                    next_state = processing;
                end
            end
            ending: begin
                if(SR[10]) begin
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
    always@(posedge CLK) begin
        if(rst) begin
            SR <= 0;
        end
        else begin
            SR <= {SR[9:0], en_SR};
        end
    end
    ////////// SR end //////////

endmodule
