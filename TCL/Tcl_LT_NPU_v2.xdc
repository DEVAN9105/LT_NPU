## Ch_to_Y
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/PreP/Channel_To_Y.coe}] [get_ips Ch_to_Y]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v2/LT_NPU_v2.srcs/sources_1/ip/Ch_to_Y/Ch_to_Y.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v2/LT_NPU_v2.srcs/sources_1/ip/Ch_to_Y/Ch_to_Y.xci]

## IS / VLIW
set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/PreP/IS.coe}] [get_ips IS_storage]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v2/LT_NPU_v2.srcs/sources_1/ip/IS_storage/IS_storage.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v2/LT_NPU_v2.srcs/sources_1/ip/IS_storage/IS_storage.xci]

set_property -dict [list CONFIG.Load_Init_File {true} CONFIG.Coe_File {C:/Vivado_test/LT_NPU/PreP/VLIW.coe}] [get_ips VLIW_storage]
reset_target all [get_files  C:/Code/Vivado/LT_NPU_v2/LT_NPU_v2.srcs/sources_1/ip/VLIW_storage/VLIW_storage.xci]
generate_target all [get_files  C:/Code/Vivado/LT_NPU_v2/LT_NPU_v2.srcs/sources_1/ip/VLIW_storage/VLIW_storage.xci]