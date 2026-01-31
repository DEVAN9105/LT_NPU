`timescale 1ns / 1ps

module Stream_buffer(
    input CLK,
    input rst,
    input en,
    input [7:0] addr_cycle,
    input [63:0] dout_cycle,
    output [71:0] stream_initial
    );

    ////////// address buffer ////////// (2 cycle delay)
    reg [7:0] addr_buffer_0, addr_buffer_1;
    always@(posedge CLK) begin
        if(rst) begin
            addr_buffer_0 <= 0;
            addr_buffer_1 <= 0;
        end
        else begin
            addr_buffer_0 <= addr_cycle;
            addr_buffer_1 <= addr_buffer_0;
        end
    end
    ////////// address buffer end //////////

    ////////// output buffer //////////
    always@(posedge CLK) begin
        if(rst) begin
            stream_initial <= 0;
        end
        else begin
            if(en) begin
                stream_initial <= {addr_buffer_1, dout_cycle};
            end
            else begin
                stream_initial <= stream_initial;
            end
        end
    end
    ////////// output buffer end //////////
endmodule
