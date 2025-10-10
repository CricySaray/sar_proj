puts "RM-Info: Running script [info script]\n"

#################################################################################
# PrimeTime Reference Methodology Script
# Script: dmsa_mc.tcl
# Version: F-2011.06 (June 27, 2011)
# Copyright (C) 2009-2011 Synopsys All rights reserved.
#################################################################################


# make REPORTS_DIR
file mkdir $REPORTS_DIR

# make RESULTS_DIR
file mkdir $RESULTS_DIR 

# Under normal circumstances, when executing a script with source, Tcl
# errors (syntax and semantic) cause the execution of the script to terminate.
# Uncomment the following line to set sh_continue_on_error to true to allow
# processing to continue when errors occur.
set sh_continue_on_error true
set si_enable_analysis true 
set si_xtalk_double_switching_mode clock_network 
set timing_clock_gating_propagate_enable false
set timing_report_use_worst_parallel_cell_arc true
set timing_save_pin_arrival_and_slack true
set si_xtalk_delay_analysis_mode all_path_edges
set sdc_save_source_file_information true

set report_default_significant_digits 4
set sh_source_uses_search_path true
set timing_report_unconstrained_paths true
set timing_remove_clock_reconvergence_pessimism true
set timing_early_launch_at_borrowing_latches false
set timing_crpr_threshold_ps 1
set access_internal_pins true
set timing_enable_max_capacitance_set_case_analysis true
set read_parasitics_load_locations true
set link_create_black_boxes false

# Only enable power analysis in typical corner
#if { $mode == "func" && $corner == "tc_typ" } {
#  set power_enable_analysis true 
#  set power_analysis_mode averaged 
#  #set power_analysis_mode time_based
#}

#suppress_message {SDF-036 SDF-039 UITE-121 UITE-316 UPF-027 UPF-048 PWR-303}


echo "Checking $dmsa_corner_library_files($corner)"

set select_dmsa_corner_libs "";

foreach dml $dmsa_corner_library_files($corner)  {
    lappend select_dmsa_corner_libs $dml
}

echo "select_dmsa_corner_libs $select_dmsa_corner_libs"

set link_path "* $select_dmsa_corner_libs"

read_verilog $NETLIST_FILES
current_design $DESIGN_NAME
link

# When you want to set scaling library, please change the value from 0 to 1
if { 0 } {
  foreach scaling_lib1 $dmsa_mv_scaling_library1($corner) {
    echo "Info: scaling lib group: $scaling_lib1"
    define_scaling_lib_group [list $scaling_lib1]
  }
  report_lib_groups -scaling -show {voltage temp process}
}

#set galibs [get_libs *]
#
#foreach_in_collection gg $galibs {
# set ename [get_attribute $gg extended_name]
# if { [regexp $dmsa_mv_scaling_library1($corner) $ename ] == 1 } {
#    set libstring $ename
# }
#}
#
#create_operating_conditions -name $dmsa_mv_voltage($corner)_oc -library [get_lib $libstring] -process $dmsa_mv_process($corner) -temperature $dmsa_mv_temperature($corner) -volt $dmsa_mv_voltage($corner)
#
#set_operating_conditions $dmsa_mv_voltage($corner)_oc





##################################################################
#    UPF Section                                                 #
##################################################################

#load_upf $dmsa_UPF_FILE


#source -echo set_voltage.tcl


##################################################################
#    Back Annotation Section                                     #
##################################################################

if {[info exists PARASITIC_PATHS] && [info exists PARASITIC_FILES] } {
foreach para_file $PARASITIC_FILES($corner) {
#   if {[string compare $PARASITIC_PATHS $DESIGN_NAME] == 0} {
      read_parasitics -keep_capacitive_coupling -format spef $para_file 
#   } else {
#      read_parasitics -path $PARASITIC_PATHS -keep_capacitive_coupling -format spef $para_file 
#   }
}
report_annotated_parasitics -check > $REPORTS_DIR/${DESIGN_NAME}_report_annotated_parasitics.report
#}


######################################
# reading design constraints
######################################

if {[info exists dmsa_mode_constraint_files($mode)]} {
        foreach dmcf $dmsa_mode_constraint_files($mode) {
 #               if {[file extension $dmcf] eq ".sdc"} {
 #                       read_sdc -echo $dmcf
  #              } else {
                        source -echo $dmcf
    #            }
        }
}






##################################################################  
#    Power Switching Activity Annotation Section                 #  
##################################################################  
#if { $mode == "func" && $corner == "tc_typ" } {
#  read_vcd $ACTIVITY_FILE -strip_path $STRIP_PATH         
#  report_switching_activity -list_not_annotated           
#}




##################################################################
#    DMSA Derate Section - Based on Mode and Corner		 #
##################################################################

	if {[info exists dmsa_derate_clock_early_value(${corner})]} {
        	echo "clock early: Mode $mode : Corner $corner : Derate Value : $dmsa_derate_clock_early_value(${corner})"
        	set_timing_derate -clock -early -cell_delay $dmsa_derate_clock_early_value(${corner}) 
        	set_timing_derate -data  -early -cell_delay $dmsa_derate_data_early_value(${corner}) 
		set_timing_derate -clock -early -net_delay  $dmsa_derate_clk_net_early_value(${corner}) 
		set_timing_derate -data  -early -net_delay  $dmsa_derate_data_net_early_value(${corner}) 
		set_timing_derate -early 1 [get_cells u_afe_core]
	}
	if {[info exists dmsa_derate_clock_late_value(${corner})]} {
        	echo "clock late: Mode $mode : Corner $corner : Derate Value : $dmsa_derate_clock_late_value(${corner})"
        	set_timing_derate -clock -late -cell_delay $dmsa_derate_clock_late_value(${corner}) 
        	set_timing_derate -data  -late -cell_delay $dmsa_derate_data_late_value(${corner})
		set_timing_derate -clock -late -net_delay  $dmsa_derate_clk_net_late_value(${corner})
		set_timing_derate -data  -late -net_delay  $dmsa_derate_data_net_late_value(${corner})
		set_timing_derate -late 1 [get_cells u_afe_core]
	}


##################################################################
#    Clock Tree Synthesis Section                                #
##################################################################

set_propagated_clock [all_clocks] 

puts "RM-Info: Completed script [info script]\n"

