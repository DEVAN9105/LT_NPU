`timescale 1ns / 1ps

// delay = 4 cycle / 2 cycle

module Core_controller(
    input CLK,
    input en,
    input rst,
    // SR control
    input [2:0] mode_in,
    input acc_done,
    // FSM control
    input core_counter_done,
    input AGU_O_done,
    // output
    output reg set,
    output reg [12:0] SR_0,
    output reg [5:0] SR_1,
    output reg Core_counter_en,
    output reg core_done,
    output reg core_rst
    );
    
    ////////// state define //////////
    parameter idle = 0, set_up = 1, processing = 2, ending = 3, finish = 4;
    ////////// state define end //////////

    ////////// input buffer //////////
    reg [2:0] mode;
    always@(posedge CLK) begin
        if(rst) begin
            mode <= 0;
        end
        else if(set) begin
            mode <= mode_in;
        end
        else begin
            mode <= mode;
        end
    end
    ////////// input buffer end //////////
    
    ////////// FSM //////////
    reg [2:0] state, next_state;
    always@(*) begin
        //avoid latch
        next_state = state;
        core_done = 0;
        Core_counter_en = 0;
        core_rst = 0;
        set = 0;
        
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
                next_state = processing;
                set = 1;
            end
            processing: begin
                Core_counter_en = 1;
                if(core_counter_done) begin
                    next_state = ending;
                end
                else begin
                    next_state = processing;
                end
            end
            ending: begin
                if( SR_0==0 && SR_1==0 ) begin
                    next_state = finish;
                end
                else begin
                    next_state = ending;
                end
            end
            finish: begin
                core_done = 1;
                if(en) begin
                    next_state = idle;
                end
                else begin
                    next_state = finish;
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

    ////////// SR_0 //////////
    always@(posedge CLK) begin
        if (rst) begin
            SR_0 <= 13'b0;
        end
        else if (en) begin
            case(mode)
                maxpooling, GAP: begin
                    if(state == 2) begin 
                        SR_0 <= {SR_0[11], SR_0[8], 2'b0, SR_0[7:0], en};
                    end
                    else begin
                        SR_0 <= SR_0;
                    end
                end
                default: begin
                    if(state == 2) begin 
                        SR_0 <= {SR_0[11:0], en};
                    end
                    else begin
                        SR_0 <= SR_0;
                    end
                end
            endcase
        end
    end
    ////////// SR_0 end //////////

    ////////// SR_1 //////////
    always@(posedge CLK) begin
        if(rst) begin
            SR_1 <= 6'b0;
        end
        else begin
            if(state == 2) begin
                SR_1 <= {SR_1[4:0], acc_done};
            end
            else begin
                SR_1 <= SR_1;
            end
        end
    end
    ////////// SR_1 end //////////

endmodule
