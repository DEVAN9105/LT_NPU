`timescale 1ns / 1ps

module Bridge_load_buffer#(
    parameter [2:0] CIU_ID = 3'd1
)(
    input CLK,
    input rst,
    input en,
    input [75:0] bridge_load,
    output valid_load,
    output [7:0] addr_load,
    output [63:0] din_load
    );

    ////////// buffer //////////
    reg [75:0] load_buffer;
    always @(posedge CLK) begin
        if (rst) begin
            load_buffer <= 0;
        end
        else begin
            if(en) begin
                load_buffer <= bridge_load;
            end
            else begin
                load_buffer <= load_buffer;
            end
        end
    end
    ////////// buffer end //////////

    ////////// output //////////
    assign valid_load = load_buffer[75] & (load_buffer[74:72] == CIU_ID);
    assign addr_load = load_buffer[71:64];
    assign din_load = load_buffer[63:0];
    ////////// output end //////////

endmodule
