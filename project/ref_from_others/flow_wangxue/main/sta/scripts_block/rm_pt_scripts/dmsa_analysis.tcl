puts "RM-Info: Running script [info script]\n"
#################################################################################
# PrimeTime Reference Methodology Script
# Script: dmsa_analysis.tcl
# Version: F-2011.06 (June 27, 2011)
# Copyright (C) 2009-2011 Synopsys All rights reserved.
#################################################################################


#################################################################################
# 
# This file will produce the reports for the DMSA mode based on the options
# used within the GUI.
#
# The output files will reside within the work/scenario subdirectories.
#
#################################################################################


# send some non-merged reports to our slave processes
##################################################################
#    Update_timing and check_timing Section                      #
##################################################################
###@remote_execute {
###@set report_default_significant_digits 3
###@update_timing -full
###@# Ensure design is properly constrained
###@check_timing -verbose > $REPORTS_DIR/${DESIGN_NAME}_check_timing.report
###@}

###@##################################################################
###@#    Report_timing Section                                       #
###@##################################################################
###@#report_timing -crosstalk_delta -slack_lesser_than 0.0 -delay min_max -nosplit -input -net -sign 4 > $REPORTS_DIR/${DESIGN_NAME}_dmsa_report_timing.report
###@report_analysis_coverage -status_details untested -exclude_untested {constant_disabled user_disabled false_paths} -nosplit > $REPORTS_DIR/${DESIGN_NAME}_dmsa_report_analysis_coverage.report

set prefix [exec date +%m%d%H%M]
report_constraint -all_violators -nosplit > $REPORTS_DIR/${DESIGN_NAME}_dmsa_report_constraint_$prefix.report
# Noise Reporting
remote_execute {

group_path -from [all_registers ] -to [all_registers ] -name reg2reg
group_path -from [all_inputs  ] -to [all_registers ] -name in2reg
group_path -from [all_registers   ] -to [all_outputs ] -name reg2out
group_path -from  [all_inputs ] -to [all_outputs ] -name in2out
group_path -from [all_registers ] -to [get_cells -filter "is_integrated_clock_gating_cell && !is_hierarchical" -hierarchical ] -name reg2ICG
group_path -from u_afe_core  -to [all_registers ] -name afe2reg
group_path -to  u_afe_core  -from  [all_registers ] -name reg2afe
set_noise_parameters -enable_propagation -analysis_mode report_at_endpoint


if {[regexp "t$" $corner]} {
	set_false_path -setup -to *
} elseif {[regexp "T$" $corner]} {
	set_false_path -hold -to *
}

if {[regexp "ff" $corner]} {
	set_clock_uncertainty -hold 0.04 [all_clocks]
}

set_propagated_clock [all_clocks]

report_noise -nosplit -all_violators -above -low > $REPORTS_DIR/${DESIGN_NAME}_report_noise_all_viol_abv_low.report
#report_noise -nosplit -nworst 10 -above -low > $REPORTS_DIR/${DESIGN_NAME}_report_noise_alow.report

report_noise -nosplit -all_violators -below -high > $REPORTS_DIR/${DESIGN_NAME}_report_noise_all_viol_below_high.report
#report_noise -nosplit -nworst 10 -below -high > $REPORTS_DIR/${DESIGN_NAME}_report_noise_below_high.report

# Clock Network Double Switching Report
report_si_double_switching -nosplit -rise -fall > $REPORTS_DIR/${DESIGN_NAME}_report_si_double_switching.report
report_clock -skew -attribute > $REPORTS_DIR/${DESIGN_NAME}_report_clock.report

report_constrain -all_violators -significant_digits 3 > $REPORTS_DIR/cons_vio.rpt
report_constrain -all_violators -verbose -significant_digits 3 > $REPORTS_DIR/cons_vio_verbose.rpt

report_constrain -pba_mode path -all_violators -significant_digits 3 > $REPORTS_DIR/cons_vio.pba.rpt
report_constrain -pba_mode path -all_violators -verbose -significant_digits 3 > $REPORTS_DIR/cons_vio_verbose.pba.rpt

check_timing -verbose > $REPORTS_DIR/check_timing.rpt

report_qor > $REPORTS_DIR/qor.rpt
report_qor -pba_mode exhaustive > $REPORTS_DIR/qor.pba.rpt
# SDF generation
#write_sdf -context verilog  -include {SETUPHOLD RECREM} -compress gzip ${DESIGN_NAME}_${mode}_${corner}.sdf.gz -version 3.0
#write_sdf -context verilog  -include {SETUPHOLD RECREM} -compress gzip ${DESIGN_NAME}_${mode}_${corner}.sdf.gz -version 3.0 -no_edge -no_internal_pins -significant 4
#write_sdf -no_negative_values {cell_delays net_delays} -exclude {default_cell_delay_arcs no_condelse}  -no_edge  -version 3.0 -context verilog -compress gzip ${DESIGN_NAME}_${mode}_${corner}.sdf.gz
#write_sdf -no_negative_values {cell_delays net_delays} -exclude {default_cell_delay_arcs no_condelse}  -no_edge  -version 3.0 -context verilog ${DESIGN_NAME}_${mode}_${corner}.sdf
}
report_global_timing -include {scenario_details} -format wide -significant_digits 4 > $REPORTS_DIR/${DESIGN_NAME}_dmsa_glo_timing_$prefix.report

##################################################################
#    Power Analysis Section                                      #
##################################################################
#remote_execute {
#  if { $mode == "func" && $corner == "tc_typ" } {
#    ## run power analysis
#    check_power   > $REPORTS_DIR/${DESIGN_NAME}_check_power.report
#    update_power 
#     
#    ## report_power
#    report_power > $REPORTS_DIR/${DESIGN_NAME}_report_power.report
#  }
#}


##################################################################
#    Save_Session Section                                        #
##################################################################
remote_execute {
save_session ${DESIGN_NAME}_ss -disable_common_data_sharing
source /eda/gc/icexplorer-xtop_2021.12.d2844605_linux-x86_64_rhel6_20220711/utilities/sta/pt_util2.tcl
report_scenario_data_for_icexplorer -scenario_name ${mode}_${corner} -dir /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/dataout/$env(DATAOUT_VERSION)/xtop_data
#set si_enable_analysis false
#reset_timing_derate
#set_operating_conditions -analysis_type single
write_sdf -no_internal_pins -no_negative_values {cell_delays net_delays} -exclude {default_cell_delay_arcs no_condelse}  -no_edge  -version 3.0 -context verilog /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/dataout/$env(DATAOUT_VERSION)/sdf/${DESIGN_NAME}_${mode}_${corner}.sdf
#write_sdf -no_negative_values {cell_delays net_delays} -version 3.0 -context verilog ${DESIGN_NAME}_${mode}_${corner}.sdf
#write_sdf  -version 2.1 -context verilog ${DESIGN_NAME}_${mode}_${corner}_2.1.sdf
#write_sdf -version 3.0 -include {SETUPHOLD RECREM} ${DESIGN_NAME}_${mode}_${corner}_3.0.sdf -context verilog
#write_sdf -version 2.1 ${DESIGN_NAME}_${mode}_${corner}_2.1.sdf -context verilog
#source /ext2/projects/TCA102TA0/team/jiangzhe/ICC2/icc2_0710/ICC2_S/STA/sta_0621/rm_pt/run/report.tcl
#source /local_disk/home/user1/projects/CX100_A2/sta/rm_pt/run/report.tcl > /local_disk/home/user2/project/CX100_B/sta/0730/rm_pt/run/reports/${DESIGN_NAME}_${mode}_${corner}_ioskew.rpt
}






puts "RM-Info: Completed script [info script]\n"

