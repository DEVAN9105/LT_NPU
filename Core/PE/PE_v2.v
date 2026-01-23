`timescale 1ns / 1ps

// delay = 4 cycle / 2 cycle

module PE(
    input CLK,
    input en,
    input rst,
    input [1:0] PE_mode,
    input signed [15:0] PE_A,
    input signed [15:0] PE_B,
    output reg signed [31:0] PE_out
    );
    wire signed [31:0] P; //mult_16 output
    
    ////////// SR //////////
    reg [1:0] en_sr;
    always@(posedge CLK) begin
        if(rst) begin
            en_sr <= 0;
        end
        else begin
            en_sr <= {en_sr[0], en};
        end
    end
    ////////// SR end //////////
    
    // Mode define
    parameter MAC = 0, GAP = 1, pass = 2;

    ////////// mult_16 //////////
    mult_16 mult(.CLK(CLK),
                 .A(PE_A),
                 .B(PE_B),
                 .CE(en),
                 .SCLR(rst),
                 .P(P)
    );
    ////////// mult_16 end //////////
    
    ////////// shift_right_4 //////////
    reg signed [31:0] A_shift;
    always@(posedge CLK) begin
        if(rst==1) A_shift <= 0;
        else A_shift <= {{12{PE_A[15]}}, PE_A, 4'b0};
    end
    ////////// shift_right_4 end //////////

    ////////// pass_through //////////
    reg signed [31:0] A_pass;
    always@(posedge CLK) begin
        if(rst==1) A_pass <= 0;
        else A_pass <= {{8{PE_A[15]}}, PE_A, 8'b0};
    end
    ////////// pass_through end //////////

    ////////// output mux //////////
    reg signed [31:0]out_buffer;
    always@(*) begin
        case(PE_mode)
            MAC: out_buffer = P;
            GAP: out_buffer = A_shift;
            pass: out_buffer = A_pass;
            default: out_buffer = 0;
        endcase
    end
    ////////// output mux end //////////
    
    ////////// output reg //////////
    always@(posedge CLK) begin
        if(rst==1) PE_out <= 0;
        else begin
            case(PE_mode)
                MAC: begin
                    if(en_sr[1] == 1) PE_out <= out_buffer;
                    else PE_out <= PE_out;
                end
                GAP: begin
                    if(en_sr[0] == 1) PE_out <= out_buffer;
                    else PE_out <= PE_out;
                end
                pass: begin
                    if(en_sr[0] == 1) PE_out <= out_buffer;
                    else PE_out <= PE_out;
                end
                default: PE_out <= PE_out;
            endcase
        end
    end
    ////////// output reg end //////////
endmodule
