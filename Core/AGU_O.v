`timescale 1ns / 1ps

// delay = 2 cycle

module AGU_O(
    input CLK,
    input en_in,
    input rst,
    input [11:0] AGU_O_initial_in,
    input [5:0] width_out_in, //64(0~63) => conv 1
    input [8:0] ch_out_in, //exat length [bias,weight]
    output reg [11:0] oaddr,
    output reg done
    );
    
    ////////// input buffer //////////
    reg en;
    reg [11:0] AGU_O_initial;
    reg [5:0] width_out;
    reg [8:0] ch_out;
    always@(posedge CLK) begin
        en <= en_in;
        AGU_O_initial <= AGU_O_initial_in;
        width_out <= width_out_in;
        ch_out <= ch_out_in;
    end
    ////////// input buffer end //////////

    wire ch_stride = width_out + 1;

    ////////// stage 1 //////////
    reg [6:0] X,next_X;
    reg s1_done;
    reg s2_en;
    always@(posedge CLK) begin
        s2_en <= s1_done & en;
    end
    //counter
    always@(*) begin
        //avoid latch
        next_X = X;
        s1_done = 0;
        
        //counter logic
        if(X < width_out) begin
            next_X = X + 1;
        end
        else begin
            next_X = 0;
            s1_done = 1;
        end
    end
    always@(posedge CLK) begin
        if(rst == 1) begin
            X <= 0;
        end
        else begin
            if(en == 1) begin
                X <= next_X;
            end
            else begin
                X <= X;
            end
        end
    end

    // adder
    reg [7:0] adder_1;
    always@(posedge CLK) begin
        if(rst == 1) begin
            adder_1 <= 0;
        end
        else begin
            adder_1 <= AGU_O_initial + X;
        end
    end
    ////////// stage 1 end //////////

    ////////// stage 2 //////////
    reg [7:0] ch_count, next_ch_count;
    reg [7:0] Y, next_Y;
    reg s2_done;

    //counter
    always@(*) begin
        next_ch_count = ch_count;
        s2_done = 0;
        if(ch_count < ch_out) begin
            next_ch_count = ch_count + 1;
            next_Y = Y + ch_stride;
            s2_done = 0;
        end
        else begin
            next_ch_count = ch_count;
            next_Y = Y;
            s2_done = 1;
        end
    end
    always@(posedge CLK) begin
        if(rst == 1) begin
            ch_count <= 0;
            Y <= 0;
        end
        else begin
            if(s2_en == 1) begin
                ch_count <= next_ch_count;
                Y <= next_Y;
            end
            else begin
                ch_count <= ch_count;
                Y <= Y;
            end
        end
    end

    // adder
    always@(posedge CLK) begin
        if(rst == 1) begin
            oaddr <= 0;
        end
        else begin
            oaddr <= adder_1 + Y;
        end
    end
    ////////// stage 2 end //////////

    //done logic
    always@(*) begin
        if( s2_done && s1_done) begin
            done = 1;
        end
        else begin
            done = 0;
        end
    end
    
endmodule
