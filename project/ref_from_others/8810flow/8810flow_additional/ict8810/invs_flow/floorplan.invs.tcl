## --------------------------------------------------------------##
##                      Floor_Plan Flow                          ##
## --------------------------------------------------------------##

#set vars(date)       [exec date "+%y%m%d"]
#set vars(view_rpt)    "1125"
## 1. read liblist
#source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/scripts/.lib_setup.tcl 
source  ../scr/setup.invs
set vars(view_from) $env(view_from)
set vars(view_rpt) $env(view_rpt)
set vars(step) floorplan
source  ../scr/defineInput.tcl
global vars
## 2. create Design
history keep 2000
setDistributeHost -local
setMultiCpuUsage -localCpu 16
setUserDataValue init_verilog $vars(netlist)

## global file 
#set sub_block_lef     ""

#set vars(view_definition_file) "../scr/viewDefine.invs"
#source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/chip_top_idp/pr_invs/scr/global.invs
set init_mmmc_file  ""
setUserDataValue init_lef_file "$vars(TECH_LEF_7T) $vars(TECH_NDR_LEF) $vars(LEF_7T_LIBS) $vars(LEF_9T_LIBS) $vars(LEF_RAM_LIBS) $vars(LEF_ROM_LIBS) $vars(LEF_IP_LIBS) $vars(LEF_IO_LIBS)"
setUserDataValue init_top_cell $vars(design)
setUserDataValue init_pwr_net  $vars(power_nets)
setUserDataValue init_gnd_net  $vars(gnd_nets)

setUserDataValue defHierChar {/}
setUserDataValue conf_net_delay {1000ps}
setUserDataValue timing_time_unit {1ns}
setUserDataValue fp_core_cntl {}
setUserDataValue delaycal_input_transition_delay {0.1ps}
setUserDataValue conf_in_tran_delay {0.1ps} 
setUserDataValue init_import_mode { -keepEmptyModule 1 -treatUndefinedCellAsBbox 0 -useLefDef56 1}
setUserDataValue fpIsMaxIoHeight 0 
setUserDataValue init_design_settop 1 
setUserDataValue timing_cap_unit {1.0} 


init_design

