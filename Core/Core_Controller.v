`timescale 1ns / 1ps

// delay = 1 cycle

module Core_Controller(
    input CLK, input rst, input en,
    input [2:0] mode,
    input padding,
    // AGU_F
    input AGU_F_done,
    output reg AGU_F_en, output reg AGU_F_rst,
    output reg [7:0] AGU_F_initial,
    output reg [1:0] AGU_F_offset_X,
    output reg [7:0] AGU_F_offset_Y,
    output reg [1:0] stride,
    // AGU_O
    input AGU_W_done,
    output reg AGU_W_en, output reg AGU_W_rst,
    output reg [11:0] AGU_W_initial,
    output reg [8:0] kernel_L,
    // Accumulator
    output reg acc_en, output reg acc_rst,
    output reg rst_bias, output reg load_bias,
    // AGU_O
    output reg AGU_O_en, output reg AGU_O_rst,
    output reg [7:0] AGU_O_initial,
    // Array_buffer
    output reg Array_buffer_en, output reg Array_buffer_rst,
    // Fdata_buffer
    output reg Fdata_buffer_en, output reg Fdata_buffer_rst,
    // PE
    output reg PE_en, output reg PE_rst,
    output reg PE_mode,
    // W_buffer
    output reg W_buffer_en, output reg W_buffer_rst,
    output reg bias_en,
    // Output_Compare_buffer
    output reg OC_en, output reg OC_rst,
    // W_storage
    output reg W_storage_en,
    // done signal
    output reg core_done
    );
    
    // mode define
    parameter conv = 0, maxpooling = 1, DW = 2, PW = 31, GAP = 4, FC = 5;

    ////////// FSM //////////
    parameter idle = 0, set_up = 1, proccessing = 2, finish = 3;
    reg [1:0] state, next_state;

    always@(*) begin
        //avoid latch
        next_state = state;

        case(state)
            idle: begin
                if(en) begin
                    next_state = set_up;
                end
                else begin
                    next_state = idle;
                end
            end
            set_up: begin
                next_state = proccessing;
            end
            proccessing: begin
                if(AGU_O_done) begin
                    next_state = finish;
                end
                else begin
                    next_state = proccessing;
                end
            end
            finish: begin
                next_state = idle;
            end
            default: begin
                next_state = idle;
            end
        endcase
    end
    always@(posedge CLK) begin
        if(rst == 1) begin
            state <= idle;
        end
        else begin
            state <= next_state;
        end
    end

    ////////// FSM end //////////

    //counter
    always@(*) begin
        //avoid latch
        next_addr = addr;
        next_done = 0;
        
        //counter logic
        if(addr < tile_size) begin
            next_addr = addr + 1;
            next_done = 0;
        end
        else begin
            next_addr = 0;
            next_done = 1;
        end
    end
    always@(posedge CLK) begin
        if(rst == 1) begin
            addr <= 0;
            done <= 0;
        end
        else begin
            if(en) begin
                addr <= next_addr;
                done <= next_done;
            end
            else begin
                addr <= addr;
                done <= done;
            end
        end
    end

    // adder
    always@(posedge CLK) begin
        if(rst) begin
            oaddr <= 0;
        end
        else begin
            if(en) begin
                oaddr <= AGU_O_initial + addr;
            end
            else begin
                oaddr <= oaddr;
            end
        end
    end
    ////////// stage 1 end //////////
    
endmodule
