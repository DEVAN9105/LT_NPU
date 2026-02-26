`timescale 1ns / 1ps

module Processing_V1 (
    input  wire        aclk,
    input  wire        aresetn,

    input  wire [63:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tlast,
    output wire        s_axis_tready,

    output reg  [127:0] m_axis_tdata, 
    output reg          m_axis_tvalid, 
    output reg          m_axis_tlast,
    input  wire         m_axis_tready
);

    // =========================================================================
    // 1. Parameters
    // =========================================================================
    localparam H_TOTAL_W      = 640;
    localparam H_CROP_LEFT    = 128;
    localparam H_ACTIVE_W     = 384; 
    localparam CNT_CROP_END   = (H_CROP_LEFT / 4); 
    localparam CNT_ACTIVE_END = CNT_CROP_END + (H_ACTIVE_W / 4);

    localparam signed [17:0] R_CONST = -56992;
    localparam signed [17:0] G_CONST =  34784;
    localparam signed [17:0] B_CONST = -70688;

    // =========================================================================
    // 2. Internal Signals
    // =========================================================================
    wire ce; 
    assign s_axis_tready = m_axis_tready; 
    assign ce = s_axis_tvalid && m_axis_tready;

    // Stage 0
    reg [9:0] x_clk_cnt;
    reg [9:0] y_line_cnt;
    reg [1:0] mod3_cnt;
    reg [1:0] phase_cnt;
    
    // Stage 1 Inputs
    reg signed [12:0] s1_y_a, s1_u_a, s1_v_a;
    reg signed [12:0] s1_y_b, s1_u_b, s1_v_b;
    reg                s1_valid_a, s1_valid_b;
    reg [1:0]          s1_phase_ref;

    // Stage 1a: Control & Intermediate Data
    reg       reg_s1a_valid_a, reg_s1a_valid_b;
    reg [1:0] reg_s1a_phase;
    // 【修正】加回中間暫存器以對齊控制訊號的 2 cycle 延遲
    reg signed [24:0] r_sum_a_reg, g_sum_a_reg, b_sum_a_reg;
    reg signed [24:0] r_sum_b_reg, g_sum_b_reg, b_sum_b_reg;

    // Stage 2: Outputs
    reg signed [24:0] s2_r_a, s2_g_a, s2_b_a;
    reg signed [24:0] s2_r_b, s2_g_b, s2_b_b;
    reg                s2_valid_a, s2_valid_b;
    reg [1:0]          s2_phase_ref;

    reg [63:0] pending_pixel_reg;
    reg [6:0]  out_x_cnt; 
    reg [6:0]  out_y_cnt; 

    // Input slicing
    wire [7:0] in_u0 = s_axis_tdata[7:0];
    wire [7:0] in_y0 = s_axis_tdata[15:8];
    wire [7:0] in_v0 = s_axis_tdata[23:16];
    wire [7:0] in_y1 = s_axis_tdata[31:24];
    wire [7:0] in_u2 = s_axis_tdata[39:32];
    wire [7:0] in_y2 = s_axis_tdata[47:40];
    wire [7:0] in_v2 = s_axis_tdata[55:48];
    wire [7:0] in_y3 = s_axis_tdata[63:56];

    // =========================================================================
    // 3. Stage 0: Sampling
    // =========================================================================
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            x_clk_cnt  <= 0;
            y_line_cnt <= 0;
            mod3_cnt   <= 0; 
            phase_cnt  <= 0;
            s1_valid_a <= 0;
            s1_valid_b <= 0;
        end else if (ce) begin
            if (s_axis_tlast || x_clk_cnt == (H_TOTAL_W/4 - 1)) begin
                x_clk_cnt <= 0;
                if (s_axis_tlast) begin 
                    y_line_cnt <= 0;
                    mod3_cnt   <= 0; 
                end else begin 
                    y_line_cnt <= y_line_cnt + 1;
                    if (mod3_cnt == 2'd2) mod3_cnt <= 2'd0;
                    else mod3_cnt <= mod3_cnt + 1'b1;
                end
            end else begin
                x_clk_cnt <= x_clk_cnt + 1;
            end

            if ((mod3_cnt == 2'd0) && (x_clk_cnt >= CNT_CROP_END) && (x_clk_cnt < CNT_ACTIVE_END)) begin
                s1_phase_ref <= phase_cnt; 
                case (phase_cnt)
                    2'd0: begin
                        s1_y_a <= {5'd0, in_y0}; s1_u_a <= {5'd0, in_u0}; s1_v_a <= {5'd0, in_v0};
                        s1_valid_a <= 1;
                        s1_y_b <= {5'd0, in_y3}; s1_u_b <= {5'd0, in_u2}; s1_v_b <= {5'd0, in_v2};
                        s1_valid_b <= 1;
                        phase_cnt <= 2'd1;
                    end
                    2'd1: begin
                        s1_y_a <= {5'd0, in_y2}; s1_u_a <= {5'd0, in_u2}; s1_v_a <= {5'd0, in_v2};
                        s1_valid_a <= 1;
                        s1_valid_b <= 0;
                        phase_cnt <= 2'd2;
                    end
                    2'd2: begin
                        s1_y_a <= {5'd0, in_y1}; s1_u_a <= {5'd0, in_u0}; s1_v_a <= {5'd0, in_v0};
                        s1_valid_a <= 1;
                        s1_valid_b <= 0;
                        phase_cnt <= 2'd0;
                    end
                endcase
            end else begin
                s1_valid_a <= 0;
                s1_valid_b <= 0;
                if (x_clk_cnt == CNT_CROP_END - 1) phase_cnt <= 0; 
            end
        end else if (!m_axis_tready) begin
        end else begin
            s1_valid_a <= 0;
            s1_valid_b <= 0;
        end
    end

    // =========================================================================
    // 4. Stage 1: DSP Multiplication
    // =========================================================================
    (* use_dsp = "yes" *) wire signed [24:0] mult_y_298_a = s1_y_a * 298;
    (* use_dsp = "yes" *) wire signed [24:0] mult_u_100_a = s1_u_a * 100;
    (* use_dsp = "yes" *) wire signed [24:0] mult_u_516_a = s1_u_a * 516;
    (* use_dsp = "yes" *) wire signed [24:0] mult_v_208_a = s1_v_a * 208;
    (* use_dsp = "yes" *) wire signed [24:0] mult_v_409_a = s1_v_a * 409;

    (* use_dsp = "yes" *) wire signed [24:0] mult_y_298_b = s1_y_b * 298;
    (* use_dsp = "yes" *) wire signed [24:0] mult_u_100_b = s1_u_b * 100;
    (* use_dsp = "yes" *) wire signed [24:0] mult_u_516_b = s1_u_b * 516;
    (* use_dsp = "yes" *) wire signed [24:0] mult_v_208_b = s1_v_b * 208;
    (* use_dsp = "yes" *) wire signed [24:0] mult_v_409_b = s1_v_b * 409;

    // =========================================================================
    // Stage 1a: Summation Logic (Force LUTs + Align Timing)
    // =========================================================================
    // 1. 先用 wire 定義純邏輯加法 (強制不使用 DSP)
    (* use_dsp = "no" *) wire signed [24:0] w_r_sum_a = mult_y_298_a + mult_v_409_a + R_CONST;
    (* use_dsp = "no" *) wire signed [24:0] w_g_sum_a = mult_y_298_a - mult_u_100_a - mult_v_208_a + G_CONST;
    (* use_dsp = "no" *) wire signed [24:0] w_b_sum_a = mult_y_298_a + mult_u_516_a + B_CONST;

    (* use_dsp = "no" *) wire signed [24:0] w_r_sum_b = mult_y_298_b + mult_v_409_b + R_CONST;
    (* use_dsp = "no" *) wire signed [24:0] w_g_sum_b = mult_y_298_b - mult_u_100_b - mult_v_208_b + G_CONST;
    (* use_dsp = "no" *) wire signed [24:0] w_b_sum_b = mult_y_298_b + mult_u_516_b + B_CONST;

    // 2. 存入暫存器 (Stage 1a) 以對齊 reg_s1a_valid 的延遲
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            reg_s1a_valid_a <= 0;
            reg_s1a_valid_b <= 0;
            s2_valid_a <= 0;
            s2_valid_b <= 0;
            // Data regs reset is optional
        end else if (m_axis_tready) begin 
            // --- Pipeline Stage 1a (Alignment) ---
            if (s1_valid_a) begin
                r_sum_a_reg <= w_r_sum_a; // 存入中間暫存
                g_sum_a_reg <= w_g_sum_a;
                b_sum_a_reg <= w_b_sum_a;
            end
            if (s1_valid_b) begin
                r_sum_b_reg <= w_r_sum_b;
                g_sum_b_reg <= w_g_sum_b;
                b_sum_b_reg <= w_b_sum_b;
            end
            
            reg_s1a_valid_a <= s1_valid_a; // 延遲 1
            reg_s1a_valid_b <= s1_valid_b;
            reg_s1a_phase   <= s1_phase_ref;

            // --- Pipeline Stage 2 (Output) ---
            s2_r_a <= r_sum_a_reg; // 讀取中間暫存 (延遲 2)
            s2_g_a <= g_sum_a_reg;
            s2_b_a <= b_sum_a_reg;
            
            s2_r_b <= r_sum_b_reg;
            s2_g_b <= g_sum_b_reg;
            s2_b_b <= b_sum_b_reg;
            
            s2_valid_a   <= reg_s1a_valid_a; // 讀取延遲後的 Valid (延遲 2)
            s2_valid_b   <= reg_s1a_valid_b;
            s2_phase_ref <= reg_s1a_phase;
        end
    end

    // =========================================================================
    // 5. Stage 2: Output Packing
    // =========================================================================
    function [15:0] clamp_to_8bit;
        input signed [24:0] val;
        begin
            if (val[24]) clamp_to_8bit = 16'd0;       
            else if (|val[23:16]) clamp_to_8bit = 16'd255; 
            else clamp_to_8bit = {8'd0, val[15:8]};   
        end
    endfunction

    wire [63:0] pixel_a = {clamp_to_8bit(s2_r_a), clamp_to_8bit(s2_g_a), clamp_to_8bit(s2_b_a), 16'd0};
    wire [63:0] pixel_b = {clamp_to_8bit(s2_r_b), clamp_to_8bit(s2_g_b), clamp_to_8bit(s2_b_b), 16'd0};

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axis_tvalid <= 0;
            m_axis_tdata  <= 0;
            m_axis_tlast  <= 0;
            out_x_cnt <= 0;
            out_y_cnt <= 0;
            pending_pixel_reg <= 0;
        end else if (m_axis_tready) begin
            
            m_axis_tvalid <= 0;
            m_axis_tlast  <= 0;

            if (s2_valid_a) begin
                case (s2_phase_ref)
                    2'd0: begin
                        m_axis_tdata  <= {pixel_b, pixel_a};
                        m_axis_tvalid <= 1;
                        if (out_x_cnt == 63) begin
                            out_x_cnt <= 0;
                            if (out_y_cnt == 127) begin
                                m_axis_tlast <= 1; 
                                out_y_cnt <= 0;
                            end else begin
                                out_y_cnt <= out_y_cnt + 1;
                            end
                        end else begin
                            out_x_cnt <= out_x_cnt + 1;
                        end
                    end

                    2'd1: begin
                        pending_pixel_reg <= pixel_a;
                        m_axis_tvalid <= 0; 
                    end

                    2'd2: begin
                        m_axis_tdata  <= {pixel_a, pending_pixel_reg};
                        m_axis_tvalid <= 1;
                        if (out_x_cnt == 63) begin
                            out_x_cnt <= 0;
                            if (out_y_cnt == 127) begin
                                m_axis_tlast <= 1; 
                                out_y_cnt <= 0;
                            end else begin
                                out_y_cnt <= out_y_cnt + 1;
                            end
                        end else begin
                            out_x_cnt <= out_x_cnt + 1;
                        end
                    end
                endcase
            end
        end
    end

endmodule