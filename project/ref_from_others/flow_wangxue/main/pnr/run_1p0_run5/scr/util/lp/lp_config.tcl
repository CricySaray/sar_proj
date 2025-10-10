set power_domain(switch_cell) HDRSID2BWP7T40P140HVT
set power_domain(switch_x_pitch) 35
set power_domain(switch_x_offset) 6
set power_domain(SLP_switch_x_pitch) 45
set power_domain(SLP_switch_x_offset) 11.5
set power_domain(switch_pso_in) NSLEEPIN
set power_domain(switch_pso_out) NSLEEPOUT
set power_domain(skipRows) 3
set power_domain(psw_row_y) 1.4

#######off domain 1
set off_domain_name "PD_AON_SLP PD_AON_IO"
set vars(PD_AON_SLP,module) "u_aon_top"
set vars(PD_AON_SLP,switch_long_input) u_aon_top/u_pd_aon_top/u_dft_pd_slp_power_switch_mux/CKMUX2__dont_touch/Z
set vars(PD_AON_SLP,user_pso_channel_list) ""
set vars(PD_AON_SLP,user_pso_area_list) ""
set vars(PD_AON_SLP,primary_pwr) "DVDD0P9_AON_SLP"
set vars(PD_AON_SLP,always_on) "DVDD0P9_AON"
set vars(PD_AON_SLP,primary_gnd) "VSS_CORE"

#######off domain 1
set vars(PD_AON_IO,module) "u_aon_top/u_pd_aon_top/u_pd_aon_pad_top"
set vars(PD_AON_IO,switch_long_input) u_aon_top/u_pd_aon_top/u_dft_pd_aon_pad_power_switch_mux/CKMUX2__dont_touch/Z
set vars(PD_AON_IO,user_pso_channel_list) ""
set vars(PD_AON_IO,user_pso_area_list) ""
set vars(PD_AON_IO,primary_pwr) "DVDD0P9_AON_IO"
set vars(PD_AON_IO,always_on) "DVDD0P9_AON"
set vars(PD_AON_IO,primary_gnd) "VSS_CORE"


###########on domain ############
set on_domain_name " PD_AON PD_DBB PD_CORE"

set vars(PD_AON,primary_pwr) "DVDD0P9_AON"
set vars(PD_AON,primary_gnd) "VSS_CORE"
set vars(PD_DBB,primary_pwr) "DVDD0P9_DBB"
set vars(PD_DBB,primary_gnd) "VSS_CORE"
set vars(PD_CORE,primary_pwr) "DVDD0P9_CORE"
set vars(PD_CORE,primary_gnd) "VSS_CORE"

