#---------- LT_NPU ----------#
## GLB
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/GLB.coe}] [get_ips GLB]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/GLB/GLB.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/GLB/GLB.xci]

## W_storage
# core 1
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight0.0.coe}] [get_ips W_storage_00]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_00/W_storage_00.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_00/W_storage_00.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight0.1.coe}] [get_ips W_storage_01]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_01/W_storage_01.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_01/W_storage_01.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight0.2.coe}] [get_ips W_storage_02]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_02/W_storage_02.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_02/W_storage_02.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight0.3.coe}] [get_ips W_storage_03]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_03/W_storage_03.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_03/W_storage_03.xci]

# core 2
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight1.0.coe}] [get_ips W_storage_10]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_10/W_storage_10.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_10/W_storage_10.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight1.1.coe}] [get_ips W_storage_11]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_11/W_storage_11.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_11/W_storage_11.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight1.2.coe}] [get_ips W_storage_12]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_12/W_storage_12.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_12/W_storage_12.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight1.3.coe}] [get_ips W_storage_13]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_13/W_storage_13.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_13/W_storage_13.xci]

# core 3
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight2.0.coe}] [get_ips W_storage_20]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_20/W_storage_20.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_20/W_storage_20.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight2.1.coe}] [get_ips W_storage_21]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_21/W_storage_21.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_21/W_storage_21.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight2.2.coe}] [get_ips W_storage_22]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_22/W_storage_22.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_22/W_storage_22.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight2.3.coe}] [get_ips W_storage_23]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_23/W_storage_23.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_23/W_storage_23.xci]

# core 4
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight3.0.coe}] [get_ips W_storage_30]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_30/W_storage_30.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_30/W_storage_30.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight3.1.coe}] [get_ips W_storage_31]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_31/W_storage_31.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_31/W_storage_31.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight3.2.coe}] [get_ips W_storage_32]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_32/W_storage_32.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_32/W_storage_32.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight3.3.coe}] [get_ips W_storage_33]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_33/W_storage_33.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_33/W_storage_33.xci]

# core 5
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight4.0.coe}] [get_ips W_storage_40]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_40/W_storage_40.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_40/W_storage_40.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight4.1.coe}] [get_ips W_storage_41]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_41/W_storage_41.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_41/W_storage_41.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight4.2.coe}] [get_ips W_storage_42]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_42/W_storage_42.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_42/W_storage_42.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight4.3.coe}] [get_ips W_storage_43]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_43/W_storage_43.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_43/W_storage_43.xci]

# core 6
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight5.0.coe}] [get_ips W_storage_50]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_50/W_storage_50.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_50/W_storage_50.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight5.1.coe}] [get_ips W_storage_51]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_51/W_storage_51.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_51/W_storage_51.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight5.2.coe}] [get_ips W_storage_52]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_52/W_storage_52.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_52/W_storage_52.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Weight5.3.coe}] [get_ips W_storage_53]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_53/W_storage_53.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/W_storage_53/W_storage_53.xci]


## B_storage
# core 1
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias0.0.coe}] [get_ips B_storage_00]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_00/B_storage_00.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_00/B_storage_00.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias0.1.coe}] [get_ips B_storage_01]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_01/B_storage_01.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_01/B_storage_01.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias0.2.coe}] [get_ips B_storage_02]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_02/B_storage_02.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_02/B_storage_02.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias0.3.coe}] [get_ips B_storage_03]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_03/B_storage_03.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_03/B_storage_03.xci]

# core 2
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias1.0.coe}] [get_ips B_storage_10]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_10/B_storage_10.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_10/B_storage_10.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias1.1.coe}] [get_ips B_storage_11]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_11/B_storage_11.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_11/B_storage_11.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias1.2.coe}] [get_ips B_storage_12]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_12/B_storage_12.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_12/B_storage_12.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias1.3.coe}] [get_ips B_storage_13]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_13/B_storage_13.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_13/B_storage_13.xci]

# core 3
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias2.0.coe}] [get_ips B_storage_20]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_20/B_storage_20.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_20/B_storage_20.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias2.1.coe}] [get_ips B_storage_21]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_21/B_storage_21.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_21/B_storage_21.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias2.2.coe}] [get_ips B_storage_22]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_22/B_storage_22.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_22/B_storage_22.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias2.3.coe}] [get_ips B_storage_23]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_23/B_storage_23.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_23/B_storage_23.xci]

# core 4
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias3.0.coe}] [get_ips B_storage_30]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_30/B_storage_30.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_30/B_storage_30.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias3.1.coe}] [get_ips B_storage_31]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_31/B_storage_31.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_31/B_storage_31.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias3.2.coe}] [get_ips B_storage_32]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_32/B_storage_32.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_32/B_storage_32.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias3.3.coe}] [get_ips B_storage_33]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_33/B_storage_33.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_33/B_storage_33.xci]

# core 5
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias4.0.coe}] [get_ips B_storage_40]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_40/B_storage_40.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_40/B_storage_40.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias4.1.coe}] [get_ips B_storage_41]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_41/B_storage_41.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_41/B_storage_41.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias4.2.coe}] [get_ips B_storage_42]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_42/B_storage_42.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_42/B_storage_42.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias4.3.coe}] [get_ips B_storage_43]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_43/B_storage_43.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_43/B_storage_43.xci]

# core 6
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias5.0.coe}] [get_ips B_storage_50]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_50/B_storage_50.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_50/B_storage_50.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias5.1.coe}] [get_ips B_storage_51]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_51/B_storage_51.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_51/B_storage_51.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias5.2.coe}] [get_ips B_storage_52]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_52/B_storage_52.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_52/B_storage_52.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Bias5.3.coe}] [get_ips B_storage_53]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_53/B_storage_53.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/B_storage_53/B_storage_53.xci]

## Ch_to_Y
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/Channel_To_Y.coe}] [get_ips Ch_to_Y]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/Ch_to_Y/Ch_to_Y.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/Ch_to_Y/Ch_to_Y.xci]

## IS / VLIW
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/IS.coe}] [get_ips IS_storage]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/IS_storage/IS_storage.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/IS_storage/IS_storage.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/Stage_1/VLIW.coe}] [get_ips VLIW_storage]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/VLIW_storage/VLIW_storage.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v1/LT_NPU_v1.srcs/sources_1/ip/VLIW_storage/VLIW_storage.xci]
