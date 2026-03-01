`timescale 1ns / 1ps

module Post_processing_controller(
    input CLK,
    input en,
    input rst,
    input valid,
    output reg busy,
    output reg [1:0] state
    );
    
    ////////// state define //////////
    reg [1:0] next_state;
    parameter idle = 0, processing = 1, ending = 2, finish = 3;
    ////////// state define end //////////

    ////////// FSM //////////
    always@(*) begin
        //avoid latch
        busy = 0;

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
                busy = 1;
                if(valid) begin
                    next_state = ending;
                end
                else begin
                    next_state = processing;
                end
            end
            ending: begin
                busy = 1;
                next_state = finish;
            end
            finish: begin
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