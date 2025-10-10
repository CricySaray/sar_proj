sh date
set_host_options -max_core 16
set TOP_DESIGN $env(DESIGN)
set synopsys_auto_setup true
set hdlin_dwroot /eda/synopsys/dc/dc_2018.06-SP5-5
#set hdlin_unresolved_modules black_box
set hdlin_ignore_parallel_case false
set hdlin_warn_on_mismatch_message "FMR_ELAB-147 FMR_ELAB-149"
# set verification_set_undriven_signals x
set verification_assume_reg_init none
set verification_failing_point_limit 200
set verification_timeout_limit "20:0:0"

set_app_var verification_clock_gate_edge_analysis true
# set_app_var verification_inversion_push true

set search_path .


source /home95/user3/project/CX200UR1/lib_conf/all_db.tcl



set all_lib "$vars(ssm40,timing)"

read_db "$all_lib"


read_verilog -libname WORK -r /process/TSMC28/projects/CX200UR1/backend/user3/backend/input/syn/2.0/CX250UR1_SOC_TOP_final.v 
set_reference_design r:/WORK/${TOP_DESIGN}
set_top r:/WORK/${TOP_DESIGN} 
#load_upf -container r /process/TSMC28/projects/CX200UR1/backend/user3/backend/input/syn/1.0/20250725/cx200_ur1.upf

read_verilog -libname WORK -i /home95/user3/project/CX200UR1/CX250UR1_SOC_TOP/dataout/$env(DATAOUT_VERSION)/netlist/$env(DESIGN).pr.v.gz 
set_implementation_design i:/WORK/${TOP_DESIGN}
set_top i:/WORK/${TOP_DESIGN}
#load_upf -container i /process/TSMC28/projects/CX200UR1/backend/user3/backend/input/syn/1.0/20250725/cx200_ur1.upf

#set_constant r:/WORK/${TOP_DESIGN}/u_aon_top/u_pd_slp_top/u_aon_pad/DFT_scan_mode_ckbuf/std_cell_dont_touch_ckbuf/Z  0 -type pin
set_constant r:/WORK/${TOP_DESIGN}/u_aon_top/u_pd_aon_top/u_pd_aon_pad_top/DFT_scan_mode_ckbuf/std_cell_dont_touch_ckbuf/Z  0 -type pin
set_constant r:/WORK/${TOP_DESIGN}/u_aon_top/u_pd_aon_top/o_dftmode_en_reg_reg/Q 0 -type pin
set_constant r:/WORK/${TOP_DESIGN}/u_core_top/u_io_top/DFT_scan_se_ckbuf/std_cell_dont_touch_ckbuf/Z  0 -type pin
set_constant r:/WORK/${TOP_DESIGN}/u_core_top/u_io_top/DFT_nTRST_ckbuf/std_cell_dont_touch_ckbuf/Z 0 -type pin

#set_constant i:/WORK/${TOP_DESIGN}/u_aon_top/u_pd_slp_top/u_aon_pad/DFT_scan_mode_ckbuf/std_cell_dont_touch_ckbuf/Z  0 -type pin
set_constant i:/WORK/${TOP_DESIGN}/u_aon_top/u_pd_aon_top/u_pd_aon_pad_top/DFT_scan_mode_ckbuf/std_cell_dont_touch_ckbuf/Z  0 -type pin
set_constant i:/WORK/${TOP_DESIGN}/u_aon_top/u_pd_aon_top/o_dftmode_en_reg_reg/Q 0 -type pin
set_constant i:/WORK/${TOP_DESIGN}/u_core_top/u_io_top/DFT_scan_se_ckbuf/std_cell_dont_touch_ckbuf/Z  0 -type pin
set_constant i:/WORK/${TOP_DESIGN}/u_core_top/u_io_top/DFT_nTRST_ckbuf/std_cell_dont_touch_ckbuf/Z 0 -type pin

set_constant r:/WORK/${TOP_DESIGN}/u_core_top/u_top_edt/edt_channels_out*  0 -type pin
set_constant i:/WORK/${TOP_DESIGN}/u_core_top/u_top_edt/edt_channels_out*  0 -type pin

#set_constant r:/WORK/${TOP_DESIGN}/u_aon_top/u_pd_aon_top/o_dftmode_en 0 -type pin
#set_constant i:/WORK/${TOP_DESIGN}/u_aon_top/u_pd_aon_top/o_dftmode_en 0 -type pin
#

#set_constant  r:/WORK/${TOP_DESIGN}/u_dbe_top/u_dbb_top/u_rx_dig/u_sync/u_despr/CX200A_SOC_TOP_gate_tessent_tdr_mem_cfg_inst/ijtag_data_out_18_latch_reg/Q   0 -type pin
#####backend use it
#set_constant  i:/WORK/${TOP_DESIGN}/u_dbe_top/u_dbb_top/u_rx_dig/u_sync/u_despr/CX200A_SOC_TOP_gate_tessent_tdr_mem_cfg_inst/ijtag_data_out_18_latch_reg/Q   0 -type pin
#set_constant i:/WORK/${TOP_DESIGN}/u_core_top/u_io_top/u_io_mux/u_gpio12_do/POST_HOLD_FE_OCPC22471_edt_channels_out_0/ZN 0 -type pin

source /home/user3/project/CX200UR1/CX250UR1_SOC_TOP/dataout/$env(DATAOUT_VERSION)/netlist/set_user_match.tcl
#source scanisocase_r
#source scanisocase
#set_constant r:/WORK/${TOP_DESIGN}/u_core_top/u_io_top/u_io_mux/DFT_scan_se_ckbuf/std_cell_dont_touch_ckbuf/Z  0 -type pin
#set_constant i:/WORK/${TOP_DESIGN}/u_core_top/u_io_top/u_io_mux/DFT_scan_se_ckbuf/std_cell_dont_touch_ckbuf/Z  0 -type pin


match

 #      tion_effort_level value, where value  is  "High",  "Medium",  "Low"  or




set verification_effort_level High
verify

report_failing_points > ./log/failing_point.rpt
save session.ss -replace

