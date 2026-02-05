`timescale 1ns / 1ps

module GLB_output_controller(
    input CLK,
    input en,
    input rst,
    // AGU_G
    output reg AGU_G_en,
    output reg AGU_G_rst,
    input AGU_G_done,
    input AGU_G_en_next,
    // output
    output reg [11:0] SR_1,
    output reg done,
    output reg glb_out_rst
    );
    
    ////////// state define //////////
    reg [1:0] state, next_state;
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
    
    always@(*) begin
        //avoid latch
        next_state = state;
        done = 0;
        AGU_G_en = 0;
        AGU_G_rst = 0;
        
        case(state)
            idle: begin
                AGU_G_rst = 1;
                if(en) begin
                    next_state = processing;
                end
                else begin
                    next_state = idle;
                end
            end
            processing: begin
                AGU_G_en = 1;
                if(AGU_G_done) begin
                    next_state = ending;
                end
                else begin
                    next_state = processing;
                end
            end
            ending: begin
                AGU_G_rst = 1;
                if(SR_1 != 0) begin
                    next_state = ending;
                end
                else begin
                    next_state = finish;
                end
            end
            finish: begin
                done = 1;
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

    ////////// SR //////////
    // SR_1
    always@(posedge CLK) begin
        if(rst) begin
            SR_1 <= 0;
        end
        else begin
            SR_1 <= {SR_1[10:0], AGU_G_en_next };
        end
    end
    ////////// SR end //////////

endmodule
