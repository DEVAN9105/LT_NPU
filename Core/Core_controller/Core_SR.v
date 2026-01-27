`timescale 1ns / 1ps

module Core_SR(
    input CLK,
    input rst,
    input en,
    input acc_done,
    input [2:0] mode,
    input [1:0] state,
    output reg [11:0] SR_0,
    output reg [7:0] SR_1
    );

    ////////// parameter define //////////
    // mode define
    parameter conv = 0, maxpooling = 1, DW = 2, PW = 3, GAP = 4;
    ////////// parameter define end //////////

    ////////// SR_0 //////////
    always@(posedge CLK) begin
        if (rst) begin
            SR_0 <= 12'b0;
        end
        else if (en) begin
            case(mode)
                maxpooling, GAP: begin
                    if(state == 2) begin 
                        SR_0 <= {SR_0[8], 2'b0, SR_0[7:0], acc_done};
                    end
                    else begin
                        SR_0 <= SR_0;
                    end
                end
                default: begin
                    if(state == 2) begin 
                        SR_0 <= {SR_0[10:0], acc_done};
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
            SR_1 <= 8'b0;
        end
        else begin
            if(state == 2) begin
                SR_1 <= {SR_1[6:0], acc_done};
            end
            else begin
                SR_1 <= SR_1;
            end
        end
    end
    ////////// SR_1 end //////////

endmodule
