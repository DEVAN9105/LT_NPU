`timescale 1ns / 1ps

module CIU_load_buffer(
    input CLK,
    input rst,
    input en,
    input [71:0] CIU_load,
    output valid_load,
    output [7:0] addr_load,
    output [63:0] din_load
    );

    ////////// buffer //////////
    reg [71:0] load_buffer;
    always @(posedge CLK) begin
        if (rst) begin
            load_buffer <= 0;
        end
        else begin
            if(en) begin
                load_buffer <= CIU_load;
            end
            else begin
                load_buffer <= load_buffer;
            end
        end
    end
    ////////// buffer end //////////

    ////////// output //////////
    assign valid_load = en;
    assign addr_load = load_buffer[71:64];
    assign din_load = load_buffer[63:0];
    ////////// output end //////////

endmodule
