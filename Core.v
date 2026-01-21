`timescale 1ns / 1ps

// delay = 1 cycle

module Core(
    input CLK, input rst, input en,
    input [2:0] mode,
    input [8:0] tile_sel,
    input padding,
    input ReLU_en,
    input [6:0] width_in,
    input [6:0] width_out,
    input [7:0] ch_in,
    input [7:0] ch_out,
    input [7:0] tile_size,
    input [63:0] tile_in,
    input [7:0] tile_in_addr,
    input [63:0] tile_store,
    input [7:0] tile_store_addr,
    input ena, input enb,
    output reg [63:0] tile_out,
    output reg [7:0] tile_out_addr,
    output reg core_done
    );
    
    
    ////////// input buffer //////////
    reg [7:0] AGU_O_initial;
    reg [7:0] tile_size;
    always@(posedge CLK) begin
        AGU_O_initial <= AGU_O_initial_in;
        tile_size <= tile_size_in;
    end
    ////////// input buffer end //////////

    ////////// stage 1 //////////
    reg [7:0] addr,next_addr;
    reg next_done;

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
