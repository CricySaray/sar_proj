global vars

setUserDataValue defHierChar {/}
setUserDataValue conf_net_delay {1000ps}
setUserDataValue timing_time_unit {1ns}
setUserDataValue report_timing_format {instance cell arc fanout slew load delay arrival}
setUserDataValue fp_core_cntl {}
setUserDataValue init_oa_search_lib {}
setUserDataValue lsgOCPGainMult 1.000000
setUserDataValue conf_ioOri {R0}
setUserDataValue init_verilog $vars(netlist)
setUserDataValue init_pwr_net $vars(power_nets)
setUserDataValue init_gnd_net $vars(ground_nets)
setUserDataValue init_mmmc_file $vars(view_definition_file)
set delaycal_input_transition_delay {0.1ps}
setUserDataValue init_lef_file $vars(lef_files)
setUserDataValue init_top_cell $vars(design)
setUserDataValue fpIsMaxIoHeight 0
setUserDataValue init_design_settop 1
setUserDataValue timing_cap_unit {1.0}

set_message -id IMPVL-346 -severity error ;####miss lef
set_message -id IMPSYC-2 -severity error ;####miss lib

