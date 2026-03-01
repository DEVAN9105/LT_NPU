`timescale 1ns / 1ps
`define Golden_File_Name "output.dat"


module tb_LT_NPU();
    //////////////////// system define ////////////////////
    localparam CLK_Time_Period = 5.0;
    localparam Initialize_Time = 100; //輸入參數初始化之後要保持多久(單位:ns)
    localparam Reset_Time = 100; //rst設成1之後要保持多久(單位:ns)
    localparam Wait_Time = 100;
    //////////////////////////////////////////////////////
    //////////////////// input define ////////////////////
    localparam Error = 16'd3;
    //////////////////////////////////////////////////////


    //////////////////// testbench用 ////////////////////
    reg CLK, asynchronous_rst, PS_en, PS_rst;
    wire PL_busy;
    wire [3:0] inference_result;
    reg [63:0] golden_data [0:3];
    reg Number_0_Correct, Number_1_Correct, Number_2_Correct, Number_3_Correct;
    integer counter_1 = 0;
    /////////////////////////////////////////////////////


    //clock generation
    initial CLK = 1'b0;
    always begin #(CLK_Time_Period/2) CLK = ~CLK; end
    
    
    //define PL_assenbly
    LT_NPU test_1(
        ////////// control and CLK //////////
        .CLK(CLK),
        // button rst
        .asynchronous_rst(asynchronous_rst),
        // PS control
        .PS_en(PS_en),
        .PS_rst(PS_rst),
        .PL_busy(PL_busy),

        ////////// DMA and Memory interface //////////
        /*input  wire [63:0] s_axis_weight_tdata,
        input  wire        s_axis_weight_tvalid,
        output wire        s_axis_weight_tready,

        input  wire [63:0]  s_axis_inmage_tdata,
        input  wire         s_axis_inmage_tvalid,
        input  wire         s_axis_inmage_tlast,
        output wire         s_axis_inmage_tready,*/

        ////////// output //////////
        .inference_result(inference_result)
    );




    //main
    initial begin
        ////////// INITIAL //////////
        $readmemh(`Golden_File_Name, golden_data);
        asynchronous_rst = 1'b1;
        PS_en = 1'b0;
        PS_rst = 1'b0;
        #Initialize_Time
        //////////////////////////////

        ////////// RESET //////////
        PS_rst = 1'b1;
        #Reset_Time
        PS_rst = 1'b0;
        #Wait_Time
        //////////////////////////////

        PS_en = 1'b1;
        #CLK_Time_Period
        PS_en = 1'b0;

        wait(PL_busy == 1'b1);
        @(negedge PL_busy);
        #Wait_Time;
    
        for(counter_1=0; counter_1<4; counter_1=counter_1+1) begin
            $display("Address %d:", counter_1);
            $display("\tThe Content In The Global Buffer: %h, %h, %h, %h", 
                tb_LT_NPU.test_1.glb_operator.glb.inst.native_mem_module.blk_mem_gen_v8_4_11_inst.memory[counter_1][63:48],
                tb_LT_NPU.test_1.glb_operator.glb.inst.native_mem_module.blk_mem_gen_v8_4_11_inst.memory[counter_1][47:32],
                tb_LT_NPU.test_1.glb_operator.glb.inst.native_mem_module.blk_mem_gen_v8_4_11_inst.memory[counter_1][31:16],
                tb_LT_NPU.test_1.glb_operator.glb.inst.native_mem_module.blk_mem_gen_v8_4_11_inst.memory[counter_1][15:0]
            );
            $display("\tThe Content In The Golden Output: %h, %h, %h, %h", 
                golden_data[counter_1][63:48], 
                golden_data[counter_1][47:32], 
                golden_data[counter_1][31:16], 
                golden_data[counter_1][15:0]
            );
            Number_0_Correct = (($signed(tb_LT_NPU.test_1.glb_operator.glb.inst.native_mem_module.blk_mem_gen_v8_4_11_inst.memory[counter_1][63:48]) <= ($signed(golden_data[counter_1][63:48]) + $signed(Error)))
                                        && ($signed(tb_LT_NPU.test_1.glb_operator.glb.inst.native_mem_module.blk_mem_gen_v8_4_11_inst.memory[counter_1][63:48]) >= ($signed(golden_data[counter_1][63:48]) - $signed(Error))));
            Number_1_Correct = (($signed(tb_LT_NPU.test_1.glb_operator.glb.inst.native_mem_module.blk_mem_gen_v8_4_11_inst.memory[counter_1][47:32]) <= ($signed(golden_data[counter_1][47:32]) + $signed(Error)))
                                        && ($signed(tb_LT_NPU.test_1.glb_operator.glb.inst.native_mem_module.blk_mem_gen_v8_4_11_inst.memory[counter_1][47:32]) >= ($signed(golden_data[counter_1][47:32]) - $signed(Error))));
            Number_2_Correct = (($signed(tb_LT_NPU.test_1.glb_operator.glb.inst.native_mem_module.blk_mem_gen_v8_4_11_inst.memory[counter_1][31:16]) <= ($signed(golden_data[counter_1][31:16]) + $signed(Error)))
                                        && ($signed(tb_LT_NPU.test_1.glb_operator.glb.inst.native_mem_module.blk_mem_gen_v8_4_11_inst.memory[counter_1][31:16]) >= ($signed(golden_data[counter_1][31:16]) - $signed(Error))));
            Number_3_Correct = (($signed(tb_LT_NPU.test_1.glb_operator.glb.inst.native_mem_module.blk_mem_gen_v8_4_11_inst.memory[counter_1][15:0]) <= ($signed(golden_data[counter_1][15:0]) + $signed(Error)))
                                        && ($signed(tb_LT_NPU.test_1.glb_operator.glb.inst.native_mem_module.blk_mem_gen_v8_4_11_inst.memory[counter_1][15:0]) >= ($signed(golden_data[counter_1][15:0]) - $signed(Error))));
            if(!Number_0_Correct) begin
                $display("Error: Number 0 Mismatch");
            end
            if(!Number_1_Correct) begin
                $display("Error: Number 1 Mismatch");
            end
            if(!Number_2_Correct) begin
                $display("Error: Number 2 Mismatch");
            end
            if(!Number_3_Correct) begin
                $display("Error: Number 3 Mismatch");
            end
            $display("");
            @(posedge CLK);
        end
        $finish;
    end
endmodule