`timescale 1ns / 1ps

module Output_transpose(
    input CLK,
    input rst,
    input en,
    input [63:0] glb_out,
    output reg [63:0] glb_out_transpose
    );
    reg [63:0] buffer_0;
    reg [79:0] buffer_1;
    reg [95:0] buffer_2;
    reg [111:0] buffer_3;

    ////////// SR buffer //////////
    always @(posedge CLK) begin
        if (en) begin
            buffer_0 <= {buffer_0[47:0], glb_out[63:48]};
            buffer_1 <= {buffer_1[63:0], glb_out[47:32]};
            buffer_2 <= {buffer_2[79:0], glb_out[31:16]};
            buffer_3 <= {buffer_3[95:0], glb_out[15:0]};
        end
        else begin
            buffer_0 <= buffer_0;
            buffer_1 <= buffer_1;
            buffer_2 <= buffer_2;
            buffer_3 <= buffer_3;
        end
    end
    ////////// SR buffer end //////////

    ////////// output //////////
    reg [1:0] count;
    always @(posedge CLK) begin
        if (rst) begin
            count <= 2'd0;
            glb_out_transpose <= 64'd0;
        end
        else begin
            if (en) begin
                count <= count + 2'd1;
                case (count)
                    0: begin
                        glb_out_transpose <= buffer_0;
                    end
                    1: begin
                        glb_out_transpose <= buffer_1[79:16];
                    end
                    2: begin
                        glb_out_transpose <= buffer_2[95:32];
                    end
                    3: begin
                        glb_out_transpose <= buffer_3[111:48];
                    end
                    default: begin
                        glb_out_transpose <= 64'd0;
                    end
                endcase
            end
            else begin
                count <= count;
                glb_out_transpose <= glb_out_transpose;
            end
        end
    end

endmodule
