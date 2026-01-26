`timescale 1ns / 1ps

// delay = 1 cycle

module Core_Controller(
    input CLK, input rst, input en,
    input [2:0] mode,
    input padding,
    input [6:0] width_in,
    input [6:0] width_out,
    input [7:0] ch_in,
    input [7:0] ch_out,
    // AGU_F
    output [7:0] AGU_F_initial,
    // AGU_W
    output [11:0] AGU_W_initial,
    // Accumulator
    output reg rst_bias, output reg load_bias,
    // AGU_O
    input AGU_O_done,
    // PE
    output reg PE_mode,
    // pipeline delay chain
    output reg [10:0] SR_0,
    output reg [3:0] SR_1,
    output reg [2:0] SR_2,
    output reg [9:0] out_count,
    // done signal
    output core_output_en,
    output reg core_done
    );
    
    ////////// mode define & data generate //////////
    parameter conv = 0, maxpooling = 1, DW = 2, PW = 3, GAP = 4;
    parameter idle = 0, set_up = 1, proccessing = 2, ending = 3, finish = 4;
    reg [2:0] state, next_state;
    wire [7:0] ch_stride = width_in + 1; //width + 1 (Max 128)
    ////////// mode define & data generate end //////////

    ////////// Stage 1 (kernel counter) //////////
    wire s1_en = (state == proccessing);
    reg [7:0] k_count, next_k_count;
    reg [7:0]kernel_L;
    reg s1_done, s2_en;
    always@(*) begin
        //set s2_en
        s2_en = s1_done & s1_en;
        //set kernel_L
        case(mode)
            conv: kernel_L = 8;
            maxpooling, DW: kernel_L = 2;
            PW, FC: kernel_L = ch_out;
            GAP: kernel_L = 0;
            default: kernel_L = 0;
        endcase
    end
    always@(*) begin
        //avoid latch
        next_k_count = k_count;
        s1_done = 0;

        if(k_count < kernel_L) begin
            next_k_count = k_count + 1;
            s1_done = 0;
        end
        else begin
            next_k_count = 0;
            s1_done = 1;
        end
    end
    always@(posedge CLK) begin
        if(rst == 1) begin
            k_count <= 0;
        end
        else begin
            if(s1_en) begin
                k_count <= next_k_count;
            end
            else begin
                k_count <= k_count;
            end
        end
    end
    ////////// Stage 1 end //////////

    ////////// Stage 2 (width counter) //////////
    reg [6:0] width_count, next_width_count;
    reg s2_done, s3_en;
    always@(*) begin
        s3_en = s2_done & s2_en;
    end
    always@(*) begin
        //avoid latch
        next_width_count = width_count;
        s2_done = 0;

        if(width_count < width_out) begin
            next_width_count = width_count + 1;
            s2_done = 0;
        end
        else begin
            next_width_count = 0;
            s2_done = 1;
        end
    end
    always@(posedge CLK) begin
        if(rst == 1) begin
            width_count <= 0;
        end
        else begin
            if(s2_en) begin
                width_count <= next_width_count;
            end
            else begin
                width_count <= width_count;
            end
        end
    end

    // F_initial counter
    reg [7:0] F_initial;
    assign AGU_F_initial = F_initial;
    always@(posedge CLK) begin
        if(rst) begin
            F_initial <= 0;
        end
        else begin
            if(s3_en) begin
                F_initial <= F_initial + ch_stride;
            end
            else begin
                F_initial <= F_initial;
            end
        end
    end

    // W_initial counter
    reg [11:0] W_initial;
    assign AGU_W_initial = W_initial;
    always@(posedge CLK) begin
        if(rst) begin
            W_initial <= 0;
        end
        else begin
            if(s3_en) begin
                W_initial <= W_initial + ch_out;
            end
            else begin
                W_initial <= W_initial;
            end
        end
    end
    ////////// Stage 2 end //////////

    ////////// Stage 3 (channel counter) //////////
    reg [7:0] ch_count, next_ch_count;
    reg s3_done;
    always@(*) begin
        //avoid latch
        next_ch_count = ch_count;
        s3_done = 0;

        if(ch_count < ch_in) begin
            next_ch_count = ch_count + 1;
            s3_done = 0;
        end
        else begin
            next_ch_count = 0;
            s3_done = 1;
        end
    end
    always@(posedge CLK) begin
        if(rst == 1) begin
            ch_count <= 0;
        end
        else begin
            if(s3_en) begin
                ch_count <= next_ch_count;
            end
            else begin
                ch_count <= ch_count;
            end
        end
    end
    ////////// Stage 3 end //////////

    ////////// FSM //////////
    always@(*) begin
        //avoid latch
        next_state = state;
        core_done = 0;

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
                if(s3_en && s3_done) begin
                    next_state = ending;
                end
                else if(s3_en) begin
                    next_state = set_up;
                end
                else begin
                    next_state = proccessing;
                end
            end
            ending: begin
                if(AGU_O_done) begin
                    next_state = finish;
                end
                else begin
                    next_state = ending;
                end
            end
            finish: begin
                core_done = 1;
                if(rst) begin
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
        if(rst == 1) begin
            state <= idle;
        end
        else begin
            state <= next_state;
        end
    end
    ////////// FSM end //////////

    ////////// Enable //////////
    reg [1:0] conv_count, next_conv_count;
    reg SR_en;
    always@(*) begin
        if(state == proccessing) begin
            if(conv_count == 0) begin
                SR_en = 1;
            end
            else begin
                SR_en = 0;
            end
        end
        else begin
            SR_en = 0;
        end
    end
    always@(*) begin
        next_conv_count = conv_count;
        case(mode)
            conv: begin
                if(conv_count < 2) begin
                    next_conv_count = conv_count + 1;
                end
                else begin
                    next_conv_count = 0;
                end
            end
            default: begin
                next_conv_count = 0;
            end
        endcase
    end
    always@(posedge CLK) begin
        if(rst) begin
            conv_count <= 0;
        end
        else begin
            if(state == proccessing) begin
                conv_count <= next_conv_count;
            end
            else begin
                conv_count <= conv_count;
            end
        end
    end
    ////////// Enable end //////////

    ////////// Pipeline Delay Chain //////////
    reg [9:0] next_out_count;
    reg [9:0] out_L; // output wait length
    reg SR_1_en, SR_2_en;

    // out_count
    always@(*) begin
        case(mode)
            conv: begin
                out_L = 8; // 9
            end
            maxpooling: begin
                out_L = 0; // not working
            end
            DW: begin
                out_L = 2; // 3
            end
            PW: begin
                out_L = ch_in;
            end
            GAP: begin
                out_L = 3; // 4
            end
            default: begin
                out_L = 0;
            end
        endcase
    end
    always@(*) begin
        next_out_count = out_count;
        SR_1_en = 0;
        if(out_count < out_L) begin
            next_out_count = out_count + 1;
            SR_1_en = 0;
        end
        else begin
            next_out_count = 0;
            SR_1_en = 1;
        end
    end
    always@(posedge CLK) begin
        if(rst) begin
            out_count <= 0;
        end
        else begin
            if(SR_0[10]) begin
                out_count <= next_out_count;
            end
            else begin
                out_count <= out_count;
            end
        end
    end

    // oc_count
    reg [1:0] OC_count, next_OC_count;
    always@(*) begin
        next_OC_count = OC_count;
        case(mode)
            conv: begin
                if(OC_count < 2) begin
                    next_OC_count = OC_count + 1;
                    SR_2_en = 0;
                end
                else begin
                    next_OC_count = 0;
                    SR_2_en = 1;
                end
            end
            default: begin
                next_OC_count = 0;
                SR_2_en = 1;
            end
        endcase
    end
    always@(posedge CLK) begin
        if(rst) begin
            OC_count <= 0;
        end
        else begin
            if(SR_1[3]) begin
                OC_count <= next_OC_count;
            end
            else begin
                OC_count <= OC_count;
            end
        end
    end

    // delay chains
    always@(posedge CLK) begin
        if(rst) begin
            SR_0 <= 0;
            SR_1 <= 0;
            SR_2 <= 0;
        end
        else begin
            case(mode)
                maxpooling: begin
                    SR_0 <= {7'd0, SR_0[2:0], SR_en};
                    SR_1 <= {SR_0[3], 3'd0};
                    SR_2 <= {SR_1[1:0], SR_2_en};
                end
                GAP: begin
                    SR_0 <= {SR_0[7], 2'd0, SR_0[6:0], SR_en};
                    SR_1 <= {SR_1[2:0], SR_1_en};
                    SR_2 <= {SR_2[1:0], SR_2_en};
                end
                default: begin
                    SR_0 <= {SR_0[9:0], SR_en};
                    SR_1 <= {SR_1[2:0], SR_1_en};
                    SR_2 <= {SR_2[1:0], SR_2_en};
                end
            endcase
        end
    end

    assign core_output_en = SR_2[2];
    ////////// Pipeline Delay Chain end //////////
    
endmodule
