`timescale 1ns / 1ps
////////// system define //////////
`define CLK_Time_Period 5.0 //Clock整個周期的長度(單位:ns) 註:那個.0是為了讓參數格式是浮點數，半週期才能夠是小數
`define Initialize_Time 100 //輸入參數初始化之後要保持多久(單位:ns)
`define Reset_Time 200 //rst設成1之後要保持多久(單位:ns)
`define Q_Format 16 //量化格式
`define Wait 1
`define Wait_Time 100
////////// system define end //////////

////////// golden file define //////////
`define Golden_Output "output.dat" //Golden File的檔名
`define Golden_File_Address_Num 256 //Golden File有多少地址
`define Error 1 //容許誤差
////////// golden file define end //////////

////////// input define //////////
`define Mode_In 3
`define Tile_Sel_In 9'b001_000_000
`define Stride_X_In 1
`define ReLU_En_In 1
`define Padding 0
`define AGU_W_Initial_In 0
`define AGU_B_Initial_In 0
`define AGU_O_Initial_In 0
`define Width_In_In 3
`define Width_Out_In 3
`define Ch_In_In 47
`define Ch_Out_In 39
////////// input define end //////////

module tb_Core();
    reg [4*`Q_Format-1:0] golden_data [0:`Golden_File_Address_Num-1];
    reg CLK, rst, en;
    
    // control signal
    reg [2:0] mode_in;
    reg [8:0] tile_sel_in;
    reg [1:0] stride_X_in;
    reg ReLU_en_in;
    reg padding;
    
    // AGU initial
    reg [11:0] AGU_W_initial_in;
    reg [7:0] AGU_B_initial_in;
    reg [7:0] AGU_O_initial_in;
    
    // tile size
    reg [6:0] width_in_in;
    reg [6:0] width_out_in;
    reg [7:0] ch_in_in;
    reg [7:0] ch_out_in;
    
    // input tile buffer
    wire tile_in_en;
    wire [7:0] faddr;
    wire [63:0] tile_1;
    wire [63:0] tile_2;
    wire [63:0] tile_3;
    wire [63:0] tile_4;
    wire [63:0] tile_5;
    wire [63:0] tile_6;
    
    // W_storage
    wire W_storage_en;
    wire [11:0] Waddr;
    wire [63:0] wdata_0;
    wire [63:0] wdata_1;
    wire [63:0] wdata_2;
    wire [63:0] wdata_3;
    
    // B_storage
    wire B_storage_en;
    wire [7:0] baddr;
    wire [31:0] bdata_0;
    wire [31:0] bdata_1;
    wire [31:0] bdata_2;
    wire [31:0] bdata_3;
    
    // output tile buffer
    wire tile_out_en;
    wire [7:0] tile_out_addr;
    wire [63:0] tile_out;
    
    // core done
    wire core_busy;

    //testbench用
    reg Channel_0_Correct;
    reg Channel_1_Correct;
    reg Channel_2_Correct;
    reg Channel_3_Correct;

    //integer conv = 0, maxpooling = 1, DW = 2, PW = 3, GAP = 4;
    integer num_counter = 0;

    //clock generation
    initial CLK = 1'b0;
    always #(`CLK_Time_Period/2) CLK = ~CLK;
    
    //core_define
    Core core(
        .CLK(CLK), .rst(rst), .en(en),

        // control signal bus
        .core_control({mode_in, stride_X_in, ReLU_en_in, padding, tile_sel_in}),

        // AGU initial bus
        .core_AGU_initial({AGU_W_initial_in, AGU_B_initial_in, AGU_O_initial_in}),

        // tile size bus
        .core_tile_param({width_in_in, ch_in_in, width_out_in, ch_out_in}),

        // cal tile buffer bus
        .core_tbo_cal_bus({tile_in_en, faddr}),
        .tbo_core_cal_data_1(tile_1),
        .tbo_core_cal_data_2(tile_2),
        .tbo_core_cal_data_3(tile_3),
        .tbo_core_cal_data_4(tile_4),
        .tbo_core_cal_data_5(tile_5),
        .tbo_core_cal_data_6(tile_6),

        // W_storage bus
        .core_w_storage_bus({W_storage_en, Waddr}),
        .w_storage_core_data_0(wdata_0),
        .w_storage_core_data_1(wdata_1),
        .w_storage_core_data_2(wdata_2),
        .w_storage_core_data_3(wdata_3),

        // B_storage bus
        .core_b_storage_bus({B_storage_en, baddr}),
        .b_storage_core_data_0(bdata_0),
        .b_storage_core_data_1(bdata_1),
        .b_storage_core_data_2(bdata_2),
        .b_storage_core_data_3(bdata_3),

        // store tile buffer bus
        .core_tbo_store_bus({tile_out_en, tile_out_addr, tile_out}),
    
        // core busy
        .core_busy(core_busy)
    );

    //tile buffer define(single port ROM)
    Tile_buffer_1 tile_buffer_1(.douta(tile_1), .addra(faddr), .clka(CLK), .ena(tile_in_en), .regcea(1'b1));
    Tile_buffer_2 tile_buffer_2(.douta(tile_2), .addra(faddr), .clka(CLK), .ena(tile_in_en), .regcea(1'b1));
    Tile_buffer_3 tile_buffer_3(.douta(tile_3), .addra(faddr), .clka(CLK), .ena(tile_in_en), .regcea(1'b1));
    Tile_buffer_4 tile_buffer_4(.douta(tile_4), .addra(faddr), .clka(CLK), .ena(tile_in_en), .regcea(1'b1));
    Tile_buffer_5 tile_buffer_5(.douta(tile_5), .addra(faddr), .clka(CLK), .ena(tile_in_en), .regcea(1'b1));
    Tile_buffer_6 tile_buffer_6(.douta(tile_6), .addra(faddr), .clka(CLK), .ena(tile_in_en), .regcea(1'b1));
    
    //W_storage define(single port ROM)
    W_storage_0 W_storage_0(.douta(wdata_0), .addra(Waddr), .clka(CLK), .ena(W_storage_en), .regcea(1'b1));
    W_storage_1 W_storage_1(.douta(wdata_1), .addra(Waddr), .clka(CLK), .ena(W_storage_en), .regcea(1'b1));
    W_storage_2 W_storage_2(.douta(wdata_2), .addra(Waddr), .clka(CLK), .ena(W_storage_en), .regcea(1'b1));
    W_storage_3 W_storage_3(.douta(wdata_3), .addra(Waddr), .clka(CLK), .ena(W_storage_en), .regcea(1'b1));

    //B_storage define(single port ROM)
    B_storage_0 B_storage_0(.douta(bdata_0), .addra(baddr), .clka(CLK), .ena(B_storage_en), .regcea(1'b1));
    B_storage_1 B_storage_1(.douta(bdata_1), .addra(baddr), .clka(CLK), .ena(B_storage_en), .regcea(1'b1));
    B_storage_2 B_storage_2(.douta(bdata_2), .addra(baddr), .clka(CLK), .ena(B_storage_en), .regcea(1'b1));
    B_storage_3 B_storage_3(.douta(bdata_3), .addra(baddr), .clka(CLK), .ena(B_storage_en), .regcea(1'b1));

    //main
    initial begin
            $readmemh(`Golden_Output, golden_data);
            rst = 1'b0;
            en = 1'b0;

            mode_in = 3'b0;
            tile_sel_in = 9'b0;
            stride_X_in = 2'b0;
            ReLU_en_in = 1'b0;
            padding = 1'b0;
            
            AGU_W_initial_in = 12'b0;
            AGU_B_initial_in = 8'b0;
            AGU_O_initial_in = 8'b0;
           
            width_in_in = 7'b0;
            width_out_in = 7'b0;
            ch_in_in = 8'b0;
            ch_out_in = 8'b0;
        #`Initialize_Time
  
            rst = 1'b1;

        //input parameter
            
            mode_in = `Mode_In;
            tile_sel_in = `Tile_Sel_In;
            stride_X_in = `Stride_X_In;
            ReLU_en_in = `ReLU_En_In;
            padding = `Padding;
            // AGU initial
            AGU_W_initial_in = `AGU_W_Initial_In;
            AGU_B_initial_in = `AGU_B_Initial_In;
            AGU_O_initial_in = `AGU_O_Initial_In;
            // tile size
            width_in_in = `Width_In_In;
            width_out_in = `Width_Out_In;
            ch_in_in = `Ch_In_In;
            ch_out_in = `Ch_Out_In;
        #`Reset_Time
            rst = 0;
            #50;
            en = 1'b1;

            @(posedge core_busy);
            //operate
            while(core_busy == 1'b1) begin
                @(negedge CLK);
                #`Wait
                if(tile_out_en) begin
                    $display("No.%d golden output: %h(Channel 0), %h(Channel 1), %h(Channel 2), %h(Channel 3)", 
                    num_counter+1, 
                    golden_data[num_counter][4*`Q_Format-1:3*`Q_Format], 
                    golden_data[num_counter][3*`Q_Format-1:2*`Q_Format], 
                    golden_data[num_counter][2*`Q_Format-1:`Q_Format], 
                    golden_data[num_counter][`Q_Format-1:0]);
                    
                    $display("No.%d   core output: %h(Channel 0), %h(Channel 1), %h(Channel 2), %h(Channel 3)", 
                    num_counter+1, 
                    tile_out[4*`Q_Format-1:3*`Q_Format], 
                    tile_out[3*`Q_Format-1:2*`Q_Format],
                    tile_out[2*`Q_Format-1:`Q_Format],
                    tile_out[`Q_Format-1:0]);

                    Channel_0_Correct = (($signed(tile_out[4*`Q_Format-1:3*`Q_Format]) <= ($signed(golden_data[num_counter][4*`Q_Format-1:3*`Q_Format]) + $signed(`Error)))
                                        && ($signed(tile_out[4*`Q_Format-1:3*`Q_Format]) >= ($signed(golden_data[num_counter][4*`Q_Format-1:3*`Q_Format]) - $signed(`Error))));
                    Channel_1_Correct = (($signed(tile_out[3*`Q_Format-1:2*`Q_Format]) <= ($signed(golden_data[num_counter][3*`Q_Format-1:2*`Q_Format]) + $signed(`Error)))
                                        && ($signed(tile_out[3*`Q_Format-1:2*`Q_Format]) >= ($signed(golden_data[num_counter][3*`Q_Format-1:2*`Q_Format]) - $signed(`Error))));
                    Channel_2_Correct = (($signed(tile_out[2*`Q_Format-1:`Q_Format]) <= ($signed(golden_data[num_counter][2*`Q_Format-1:`Q_Format]) + $signed(`Error)))
                                        && ($signed(tile_out[2*`Q_Format-1:`Q_Format]) >= ($signed(golden_data[num_counter][2*`Q_Format-1:`Q_Format]) - $signed(`Error))));
                    Channel_3_Correct = (($signed(tile_out[`Q_Format-1:0]) <= ($signed(golden_data[num_counter][`Q_Format-1:0]) + $signed(`Error)))
                                        && ($signed(tile_out[`Q_Format-1:0]) >= ($signed(golden_data[num_counter][`Q_Format-1:0]) - $signed(`Error))));  
                    
                    if(!Channel_0_Correct) begin
                        $display("Error: Channel 0 Mismatch");
                    end
                    if(!Channel_1_Correct) begin
                        $display("Error: Channel 1 Mismatch");
                    end
                    if(!Channel_2_Correct) begin
                        $display("Error: Channel 2 Mismatch");
                    end
                    if(!Channel_3_Correct) begin
                        $display("Error: Channel 3 Mismatch");
                    end

                    if(Channel_0_Correct && Channel_1_Correct && Channel_2_Correct && Channel_3_Correct)
                        $display("No.%d Output Match", num_counter+1);
                    
                    num_counter = num_counter + 1;
                end
            end
            $display("\n\n\n");
            $display("====================");
            $display("Simulation Completed");
            $display("====================");
            $display("\n\n\n");
            #`Wait_Time
            $finish;
    end

    initial begin
        #1000000000; //1s
        $display("\n=====================");
        $display("Error: Time Out Error");
        $display("=====================\n");
        $finish;
    end
    
endmodule