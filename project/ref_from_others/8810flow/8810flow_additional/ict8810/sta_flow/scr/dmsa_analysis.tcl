
puts "RM-Info: Running script [info script]\n"
#################################################################################
# PrimeTime Reference Methodology Script
# Script: dmsa_analysis.tcl
# Version: P-2019.03 (April 5, 2019)
# Copyright (C) 2009-2019 Synopsys All rights reserved.
#################################################################################


#################################################################################
# 
# This file will produce the reports for the DMSA mode based on the options
# used within the GUI.
#
# The output files will reside within the work/scenario subdirectories.
#
#################################################################################


##################################################################
#    Constraint Analysis Section
##################################################################
#remote_execute {
#check_constraints -verbose > $REPORTS_DIR/${DESIGN_NAME}_check_constraints.report
#}

##################################################################
#    Update_timing and check_timing Section                      #
##################################################################
remote_execute {
#set_false_path -thr chip_core_inst/lb_modem_top_inst/lb_modem_top1_inst/*
#---------------------------------------------------------- 
# basic path group
#---------------------------------------------------------- 
set all_clock_inputs ""
foreach_in_collection CLOCK [all_clocks] {
    foreach_in_collection PORTS [get_ports [get_attribute $CLOCK sources -quiet] -quiet] {
        set all_clock_inputs [add_to_collection $all_clock_inputs $PORTS]
    }
}

group_path -name reg2reg    -from [all_registers] -to [all_registers]
group_path -name  in2reg    -from [remove_from_collection [all_inputs] $all_clock_inputs] -to [all_registers]
group_path -name reg2out    -from [all_registers] -to [remove_from_collection [all_outputs] $all_clock_inputs]
group_path -name  in2out    -from [remove_from_collection [all_inputs] $all_clock_inputs] -to [remove_from_collection [all_outputs] $all_clock_inputs]
group_path -name reg2cgate  -from [all_registers] -to [get_cells [all_registers] -filter "is_integrated_clock_gating_cell == true"]

puts "INFO: update_timing and update noise"
redirect -tee ${REPORTS_DIR}/update_timing.log {update_timing -full}
update_noise

## check timing
redirect -tee ${REPORTS_DIR}/check_timing.rpt {check_timing -verbose}
#save_session ${DATA_DIR}/${DESIGN_NAME}.${VIEW}.${mode}_${corner}_${check}_afterUpdateTiming.session

# global timing
set command "report_global_timing"
if {[info exists pba_mode]} {append command " -pba_mode $pba_mode"}
if {[info exists check]} {
    if {$check == "setup"} {
        set check_type max
    } elseif {$check == "hold"} {
        set check_type min 
    } else {
        set check_type max_min
    }
    append command " -delay_type $check_type"
}
if {$check_type != "max_min"} {
    redirect ${REPORTS_DIR}/${DESIGN_NAME}.global_timing.rpt {eval $command}
}

save_session ${DATA_DIR}/${DESIGN_NAME}.${VIEW}.${mode}_${corner}_${check}.session


### check spef issue 
report_annotated_parasitics  -list_not_annotated -pin_to_pin_nets -check -max_nets  10000 > $REPORTS_DIR/${DESIGN_NAME}_report_annotated_para.${VIEW}.report
report_annotated_parasitics  -list_not_annotated -pin_to_pin_nets -check -max_nets  10000 > $REPORTS_DIR/report_annotated_parasitics.rpt
### check sdc issue unconstain poin  
#check_timing -verbose > $REPORTS_DIR/${DESIGN_NAME}_check_timing.${VIEW}.report
### check sdc covrage 
report_analysis_coverage > $REPORTS_DIR/${DESIGN_NAME}_dmsa_report_analysis_coverage.${VIEW}.report
### check net not annot by spef 
report_ideal_network  > $REPORTS_DIR/${DESIGN_NAME}_report_ideal_network.report

### global timing check
if {$check_type != "max_min"} {
    report_global_timing -pba_mode exhaustive -delay_type $check_type > $REPORTS_DIR/${DESIGN_NAME}_dmsa_report_global_timing_${check}.${VIEW}.pba.report
    report_global_timing -delay_type $check_type > $REPORTS_DIR/${DESIGN_NAME}_dmsa_report_global_timing_${check}.${VIEW}.report
    report_global_timing -group [get_object_name [get_path_groups]] -separate_all_groups -delay_type $check_type -include non_violated -format {wide csv} -output $REPORTS_DIR/${DESIGN_NAME}_dmsa_report_global_timing_${check}.${VIEW}.csv
    report_global_timing -pba_mode exhaustive -group [get_object_name [get_path_groups]] -separate_all_groups -delay_type $check_type -include non_violated -format {wide csv} -output $REPORTS_DIR/${DESIGN_NAME}_dmsa_report_global_timing_${check}.${VIEW}.pba.csv
    exec /eda_files/proj/ict8810/archive/common_script/sta_common_script/format_global_timing.sh $REPORTS_DIR/${DESIGN_NAME}_dmsa_report_global_timing_${check}.${VIEW}.csv > $REPORTS_DIR/global_timing_${check}.${VIEW}.rpt
    exec /eda_files/proj/ict8810/archive/common_script/sta_common_script/format_global_timing.sh $REPORTS_DIR/${DESIGN_NAME}_dmsa_report_global_timing_${check}.${VIEW}.pba.csv > $REPORTS_DIR/global_timing_${check}.${VIEW}.pba.rpt

    ##### check timimg  reg 2reg 
    report_timing -crosstalk_delta -derate -path_type full_clock_ex -slack_lesser_than 0.0 -pba_mode exhaustive -variation -delay_type ${check_type} -nosplit -input -nworst 1000 -max_path 1000 -net -voltage -sign 3 -trans -cap -exclude [get_ports *] >  $REPORTS_DIR/${DESIGN_NAME}_report_timing_${check}_pba_r2r.${VIEW}.report
    report_timing -crosstalk_delta -derate -path_type full_clock_ex -slack_lesser_than 0.0 -variation -delay_type ${check_type} -nosplit -input -nworst 1000 -max_path 1000 -net -voltage -sign 3 -trans -cap -exclude [get_ports *] >  $REPORTS_DIR/${DESIGN_NAME}_report_timing_${check}_r2r.${VIEW}.report
    
    ##### check timimg   IO 
    report_timing -crosstalk_delta -derate -path_type full_clock_ex -slack_lesser_than 0.0 -pba_mode exhaustive -variation -delay_type ${check_type} -nosplit -input -nworst 1000 -max_path 1000 -net -voltage -sign 3 -trans -cap -through [get_ports *] >  $REPORTS_DIR/${DESIGN_NAME}_report_timing_${check}_pba_io.${VIEW}.report
    report_timing -crosstalk_delta -derate -path_type full_clock_ex -slack_lesser_than 0.0 -variation -delay_type ${check_type} -nosplit -input -nworst 1000 -max_path 1000 -net -voltage -sign 3 -trans -cap -through [get_ports *] >  $REPORTS_DIR/${DESIGN_NAME}_report_timing_${check}_io.${VIEW}.report
}
#report_clock -skew -attribute > $REPORTS_DIR/${DESIGN_NAME}_report_clock.${VIEW}.report
### check noise si 
report_si_double_switching -nosplit -rise -fall > $REPORTS_DIR/${DESIGN_NAME}_report_si_double_switching.${VIEW}.report
check_noise > $REPORTS_DIR/${DESIGN_NAME}_check_noise.${VIEW}.report

##### check  timing summary ,max cap ,transition,period, pulse ,fanout ,
report_constraint -nosplit  -all_violators -pba_mode exhaustive >  $REPORTS_DIR/${DESIGN_NAME}_report_constrain.${VIEW}.pba.report
report_constraint -nosplit  -all_violators >  $REPORTS_DIR/${DESIGN_NAME}_report_constrain.${VIEW}.report
report_constraint -nosplit  -verbose -all_violators -pba_mode exhaustive >  $REPORTS_DIR/${DESIGN_NAME}_report_constrain.${VIEW}.pba.report_v
report_constraint -nosplit  -verbose -all_violators >  $REPORTS_DIR/${DESIGN_NAME}_report_constrain.${VIEW}.report_v

######  add by wenjie 
report_constraint -max_capacitance    -nosplit  -all_violators -pba_mode exhaustive >  $REPORTS_DIR/${DESIGN_NAME}_report_constrain_mxacap.${VIEW}.pba.report
report_constraint -max_delay          -nosplit  -all_violators -pba_mode exhaustive >  $REPORTS_DIR/${DESIGN_NAME}_report_constrain_max_delay.${VIEW}.pba.report
report_constraint -max_transition     -nosplit  -all_violators -pba_mode exhaustive >  $REPORTS_DIR/${DESIGN_NAME}_report_constrain_max_tran.${VIEW}.pba.report
report_constraint -min_pulse_width    -nosplit  -all_violators -pba_mode exhaustive >  $REPORTS_DIR/${DESIGN_NAME}_report_constrain_min_pulse.${VIEW}.pba.report
report_constraint -min_period         -nosplit  -all_violators -pba_mode exhaustive >  $REPORTS_DIR/${DESIGN_NAME}_report_constrain_min_period.${VIEW}.pba.report
report_constraint -max_fanout         -nosplit  -all_violators -pba_mode exhaustive >  $REPORTS_DIR/${DESIGN_NAME}_report_constrain_max_fanout.${VIEW}.pba.report


source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/sta_check/global_sta_post_report.tcl

##source /eda_files/proj/ict2100/backend/arm6p5t_test/wenjie/chip_top_fdp/tweaker/etc/scripts/tcl/pt/dump_pt_to_tweaker_pba_pocv.tcl

#write_sdf -version  3.0 -no_edge -context verilog -significant_digits 5 -compress gzip -include  "SETUPHOLD RECREM" -exclude { no_condelse clock_tree_path_models } -no_negative_values timing_checks  -no_internal_pins    ${current_dir}/../../dsn/sdf/${DESIGN_NAME}.${mode}_${corner}_${check}.${VIEW}.sdf
###
if {0} {
if {(($corner == "wcl_cworst_t") && ($check == "setup")) ||(($corner == "ml_rcworst") && ($check == "hold"))  } {
#write_sdf  -version  3.0 -no_edge -context verilog -significant_digits 5 -compress gzip -include  "SETUPHOLD   RECREM"   -input_port_nets  -output_port_nets -no_internal_pins  ${current_dir}/../dsn/sdf/${DESIGN_NAME}.${mode}_${corner}_${check}.${VIEW}.sdf
#write_sdf -significant_digits 4 -version 3.0 -context verilog -no_edge -exclude { no_condelse clock_tree_path_models } -compress gzip  ${current_dir}/../../dsn/sdf/${DESIGN_NAME}.${mode}_${corner}_${check}.${VIEW}.sdf

write_sdf -version  3.0 -no_edge -context verilog -significant_digits 5 -compress gzip -include  "SETUPHOLD RECREM" -exclude { no_condelse clock_tree_path_models } -no_negative_values timing_checks  -no_internal_pins    ${current_dir}/../../dsn/sdf/${DESIGN_NAME}.${mode}_${corner}_${check}.${VIEW}_v1.sdf
write_sdf -version  3.0 -no_edge -context verilog -significant_digits 5 -compress gzip -include  "SETUPHOLD RECREM" -exclude { no_condelse clock_tree_path_models }  -no_internal_pins    -instance  pd_core_top_inst/psram_adb400_wrapper_inst/ict_psram_phy_top_inst ${current_dir}/../../dsn/sdf/ict_psram_phy_top_ict_pad_${mode}_${corner}_${check}.${VIEW}.sdf
write_sdf -version  3.0 -no_edge -context verilog -significant_digits 5 -compress gzip -include  "SETUPHOLD RECREM" -exclude { no_condelse clock_tree_path_models } -no_negative_values timing_checks  -no_internal_pins    -instance pd_core_top_inst/modem_icb_adb_wrapper_inst  ${current_dir}/../../dsn/sdf/modem_icb_adb_wrapper_${mode}_${corner}_${check}.${VIEW}.sdf
write_sdf -version  3.0 -no_edge -context verilog -significant_digits 5 -compress gzip -include  "SETUPHOLD RECREM" -exclude { no_condelse clock_tree_path_models }  -no_internal_pins    -instance pd_core_top_inst/cpu_matrix_mem_subsys_inst/n300_ps_cpu_top_inst  ${current_dir}/../../dsn/sdf/n300_ps_cpu_top_${mode}_${corner}_${check}.${VIEW}.sdf
write_sdf -version  3.0 -no_edge -context verilog -significant_digits 5 -compress gzip -include  "SETUPHOLD RECREM" -exclude { no_condelse clock_tree_path_models }  -no_internal_pins    -instance sby_aon_top_inst  ${current_dir}/../../dsn/sdf/sby_aon_top_${mode}_${corner}_${check}.${VIEW}.sdf

}
}

if {1} {
#source  /eda_files/proj/ict2100/archive/common_script/pt_util2.tcl
source /eda_files/proj/ict8810/archive/common_script/sta_common_script/pt_util2.tcl
set XTOP_DIR ${current_dir}/rpt/xtop/${VIEW}
file mkdir $XTOP_DIR
#set_false_path -thr [get_ports *]
report_scenario_data_for_icexplorer  -scenario_name  ${mode}_${corner}_${check} -dir  ${XTOP_DIR} 
report_pba_data_for_icexplorer -scenario_name ${mode}_${corner}_${check} -dir  ${XTOP_DIR}
#-parallel
}
##################################################################
#   Writing an Reduced Resource ECO design                       #
##################################################################
# PrimeTime has the capability to write out an ECO design which 
# is a smaller version of the orginal design ECO can be performed
# with fewer compute resources.
#
# Writes an ECO design  that  preserves  the  specified  violation
# types  compared to those in the original design. You can specify
#  one or more of the following violation types:
#              o setup - Preserves setup timing results.
#              o hold - Preserves hold timing results.
#              o max_transistion - Preserves max_transition results.
#              o max_capacitance - Preserves max_capacitance results.
#              o max_fanout - Preserves max_fanout results.
#              o noise - Preserves noise results.
#              o timing - Preserves setup and hold timing results.
#              o drc  -  Preserves  max_transition,  max_capacitance,  
#                and max fanout results.
# There is also capability to write out specific endpoints with
# the -endpoints options.
#
# In DMSA analyis the RRECO design is written out relative to all
# scenarios enabled for analysis.
# 
# To create a RRECO design the user should perform the following 
# command and include violations types which the user is interested
# in fixing, for example for setup and hold.
# 
# write_eco_design  -type {setup hold} my_RRECO_design
#
# Once the RRECO design is created, the user then would invoke 
# PrimeTIme ECO in a seperate session and access the appropriate
# resourses and then read in the RRECO to perform the ECO
# 
# set_host_options ....
# start_hosts
# read_eco_design my_RRECO_design
# fix_eco...
#
# For more details please see man pages for write_eco_design
# and read_eco design.


##################################################################
#    Report_timing Section                                       #
##################################################################
#==============================================================================
#Cover through reporting from 2018.06* version
#get_timing_paths and report_timing commands are enhanced with a new option, -cover_through through_list, which collects the single worst violating path through    each of the objects specified in a list. 
#For example,
#pt_shell> remote_execute {get_timing_paths -cover_through {n1 n2 n3} }
#This command creates a collection containing the worst path through n1, the worst path
#through n2, and the worst path through n3, resulting in a collection of up to three paths.
#=======================================================================



# Noise Settings

# Noise Reporting
report_noise -nosplit -above -below  -all_violators > $REPORTS_DIR/${DESIGN_NAME}_report_noise_all_viol.${VIEW}.report

print_message_info
#report_si_double_switching  -nosplit  > $REPORTS_DIR/${DESIGN_NAME}_report_double_switch_viol.${VIEW}.report
#source  /eda_files/proj/ict2100/archive/common_script/get_vio.tcl >    $REPORTS_DIR/vio_summary.${VIEW}

source /eda_files/proj/ict8810/archive/common_script/sta_common_script/get_vio.tcl  >    $REPORTS_DIR/vio_summary.${VIEW}
#source /eda_files/proj/ict8810/backend/be8803/scripts/get_pba_vio.tcl  >    $REPORTS_DIR/vio_pba_summary.${VIEW}.csv
#source /eda_files/proj/ict8810/backend/be8803/scripts/get_gba_vio.tcl  >    $REPORTS_DIR/vio_summary.${VIEW}

source  /eda_files/proj/ict8810/archive/common_script/sta_common_script/vio.rpt
#Leon: hang here! comment out
#sh cp ${multi_scenario_working_directory}/${mode}_${corner}_${check}/out.log  $REPORTS_DIR/../../log/${mode}_${corner}_${check}.${VIEW}.log 
puts "test"
}
remote_execute {
puts "test1"
report_ocvm -type aocvm > $REPORTS_DIR/${DESIGN_NAME}_report_pocvm.report
report_timing_derate -increment > $REPORTS_DIR/${DESIGN_NAME}_report_timing_derate.report
#report_timing_derate -pocvm_subtract_sigma_factor_from_nominal > $REPORTS_DIR/${DESIGN_NAME}_report_timing_derate_pocvm_subtract_sigma_factor_from_nominal.report
}

##################################################################
#    Link To TetraMAX Section                                    #
##################################################################

#remote_execute {
#source $PT2TMAX_SCRIPT_FILE
#write_exceptions_from_violations -delay_type min_max -output $RESULTS_DIR/${DESIGN_NAME}_tmax_exceptions.sdc
#report_global_slack -max -nosplit > $REPORTS_DIR/${DESIGN_NAME}_tmax_slacks.report

## The write_delay_paths command invocation may need to be customized to meet your design's test goals.
## See the TetraMAX User Guide for details on this command.
#write_delay_paths -max_paths 1000 $REPORTS_DIR/${DESIGN_NAME}_tmax_paths.report
#}

##################################################################
#    Power Analysis Section                                      #
##################################################################

## set power analysis options      
#set_power_analysis_options -waveform_format fsdb -waveform_output $REPORTS_DIR/wave

## run power analysis
#check_power   > $REPORTS_DIR/${DESIGN_NAME}_check_power.report
#update_power 

## report_power
#report_power > $REPORTS_DIR/${DESIGN_NAME}_dmsa_power.report

##################################################################
#    Fix ECO Comments                                            #
##################################################################
# You can use -current_library option of fix_eco_drc and fix_eco_timing to use
# library cells only from the current library that the cell belongs to when sizing
#
# You can control the allowable area increase of the cell during sizing by setting the
# eco_alternative_area_ratio_threshold variable
#
# You can restrict sizing within a group of cells by setting the
# eco_alternative_cell_attribute_restrictions variable
#
# Refer to man page for more details

##################################################################
#    Physically Aware ECO Options Section                        #
##################################################################
#remote_execute {
#  set_eco_options -physical_lib_path $LEF_FILES -physical_design_path $DEF_FILES -log_file lef_def.log
#}
##################################################################
#    Physically Aware check_eco Section                          #
##################################################################
#remote_execute {
#  check_eco 
#}

##################################################################
#    Fix ECO Power Cell Downsize Section                         #
##################################################################
# Note if power attributes flow is desired fix_eco_power -power_attribute
# then attribute file needs to be provided for lib cells.
# See 2014.12 update training for examples
#
# PBA mode can be enabled by changing the -pba_mode option
# See fix_eco_power man page for more details on PBA based fixing
# Additional PBA controls are also available with -pba_path_selection_options
# Reporting options should be changed to reflect PBA based ECO
#
#fix_eco_power -pba_mode none -verbose

##################################################################
#    Fix ECO Power Buffer Removal                                #
##################################################################
# Power recovery also has buffer removal capability.  
# Buffer removal usage is as follows:
# fix_eco_power -method remove_buffer
# When can specify -method remove_buffer, it cannot be used in conjunction 
# with size_cell, so buffer removal needs to be done in a separate 
# fix_eco_power command.  Please see the man page for additional details.

##################################################################
#    Power-Analysis-driven Power Recovery (Total Power Recovery) #
##################################################################
# Expects power analysis data to be available.  An update_power or report_power
# step is required prior to fix_eco_power -power_mode
# Follow the PrimePower guidelines for conducting power analysis on your design with the appropriate
# activity file for dynamic power analysis and with the appropriate libraries containing
# cell leakage power information 
# Note: the report_power/update_power commands requires a PrimePower license
#remote_execute { set power_enable_analysis true }

# Reporting power: Since power recovery affects the datapath cells, include internal power of register
# clock pin within "register" group of report_power 
#remote_execute {
#set power_clock_network_include_register_clock_pin_power false
#report_power > $REPORTS_DIR/${DESIGN_NAME}_pre_power_eco.report
#}
# Power analysis based power recovery is controlled by the -power_mode option of fix_eco_power command.
# It cannot be combined with -power_attribute, -pattern_priority or -method remove_buffer options.
# Refer to man pages of fix_eco_power and update_training materials for more details.
#
#
# PBA mode can be enabled by changing the -pba_mode option
# See fix_eco_power man page for more details on PBA based fixing
#
#fix_eco_power -pba_mode none -power_mode total -verbose
#remote_execute { report_power > $REPORTS_DIR/${DESIGN_NAME}_post_power_eco.report }
 


##################################################################
#    Fix ECO DRC Section                                         #
##################################################################
# Additional setup and hold margins can be preserved while fixing DRC with -setup_margin and -hold_margin
# Refer to man page for more details
# fix max transition 
#fix_eco_drc -type max_transition -method { size_cell insert_buffer } -verbose -buffer_list $eco_drc_buf_list -physical_mode open_site 

##################################################################
#    Fix ECO Timing Section                                      #
##################################################################
# Path Based Analysis is supported for setup and hold fixing
#
# You can use -setup_margin and -hold_margin to add margins during 
# setup and hold fixing
#
# DRC can be ignored while fixing timing violations with -ignore_drc
#
# Refer to man page for more details
#
# Path specific and PBA based ECO can enabled via -path_selection_options
# See fix_eco_timing man page for more details path specific on PBA based timing fixing
# Reporting options should be changed to reflect path specific and PBA based ECO
#
# fix setup 
#fix_eco_timing -type setup -verbose -slack_lesser_than 0 -physical_mode open_site -estimate_unfixable_reasons 
# fix hold 
#fix_eco_timing -type hold -verbose -buffer_list $eco_hold_buf_list -slack_lesser_than 0 -hold_margin 0 -setup_margin 0 -physical_mode open_site -estimate_unfixable_reasons 

##################################################################
#    Fix ECO Leakage Section                                     #
##################################################################
#remote_execute {
# Note: the report_power command requires a PrimeTime PX license
#set power_enable_analysis true
#report_cell_usage -pattern_priority $leakage_pattern_priority_list > $REPORTS_DIR/${DESIGN_NAME}_pre_leakage_eco_report_cell_usage.report
#report_power -threshold -pattern_priority $leakage_pattern_priority_list -group "combinational register sequential" > $REPORTS_DIR/${DESIGN_NAME}_pre_leakage_eco_report_power.report
#}

# fix leakage
# refer to man page for more details
#
# use the following example for lib cells that don't have common naming notation
# INV1XH is high vt
# INV1XN is normal vt
# INV1X is low vt
# define_user_attribute vt_swap_priority -type string -class lib_cell
# set_user_attr -class lib_cell lib/INV1XH vt_swap_priority INV1X_best
# set_user_attr -class lib_cell lib/INV1XN vt_swap_priority INV1X_ok
# set_user_attr -class lib_cell lib/INV1X  vt_swap_priority INV1X_worst
# ...
# fix_eco_leakage -pattern "best ok worst" -attribute vt_swap_priority
# PBA mode can be enabled by changing the -pba_mode option
# See fix_eco_power man page for more details on PBA based fixing
# Additional PBA controls are also available with -pba_path_selection_options
# Reporting options should be changed to reflect PBA based ECO
#
#fix_eco_power -pba_mode none -pattern_priority $leakage_pattern_priority_list -verbose

#remote_execute {
#report_cell_usage -pattern_priority $leakage_pattern_priority_list > $REPORTS_DIR/${DESIGN_NAME}_post_leakage_eco_report_cell_usage.report
#report_power -threshold -pattern_priority $leakage_pattern_priority_list -group "combinational register sequential" > $REPORTS_DIR/${DESIGN_NAME}_post_leakage_eco_report_power.report
#}

##################################################################
#    Fix ECO Output Section                                      #
##################################################################
# write netlist changes
#remote_execute {
#write_changes -format icctcl -output $RESULTS_DIR/eco_changes.tcl
#}
#
##################################################################
#    Apply ECO Data to ICC                                       #
##################################################################
# Launch ICC to apply the ECO changes
#apply_eco_data -wait





##################################################################
#    Generation of Hierarchical Model Section                    #
#                                                                #
#  Extracted Timing Model (ETM) will contain composite current   #
#  source (CCS) timing models, if design libraries contains both #
#  CCS timing and noise data along with design for which model   #
#  is extracted has waveform propogation enable using variable   #
#  'set delay_calc_waveform_analysis_mode full_design'           #
##################################################################

#remote_execute {  
#extract_model -library_cell -test_design -output ${RESULTS_DIR}/${DESIGN_NAME} -format {lib db}    
#write_interface_timing ${REPORTS_DIR}/${DESIGN_NAME}_etm_netlist_interface_timing.report 
#}  
#remote_execute {
#extract_model -library_cell -output ${REPORTS_DIR}/${DESIGN_NAME}_${corner} -format {lib db}
#write_interface_timing ${REPORTS_DIR}/${DESIGN_NAME}_etm_netlist_interface_timing.report 
#}
#


##################################################################
#    Save_Session Section                                        #
##################################################################
remote_execute {
if { ( "${mode}_${corner}_${check}" == "func_typ_85_setup") || ( "${mode}_${corner}_${check}" == "func_ml_cworst_hold") || ( "${mode}_${corner}_${check}" == "func_wcl_cworst_t_setup") } {
set_input_transition -max 0.20 [all_inputs]
set_input_transition -min 0.20 [all_inputs]
 write_rh_file -filetype irdrop -output  $REPORTS_DIR/${DESIGN_NAME}.${mode}_${corner}_${check}.${VIEW}_timing_forir.gz
 exec touch $REPORTS_DIR/timing_forir.ready
}
        
        [exec touch test] }



puts "RM-Info: Completed script [info script]\n"
#userRunTimeCalculation -end

echo [date] >> runtime

exit
