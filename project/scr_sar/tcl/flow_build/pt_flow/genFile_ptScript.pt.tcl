#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/01/04 10:32:04 Sunday
# label     : 
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
source ../../packages/timer.tcl; # start_timer, end_timer
proc genFile_ptScript {args} {
  set genFilename "./pt.tcl"
  set tmp_dir "./pt_tmp_dir"
  set max_cores 8
  set rpt_dir "./rpts/"
  set proc_dir "~/scr_sar/tcl/"
  set current_scenario "func_tt0p8v85c_typical_85c_hold"
  set db_list [list]
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set fo [open $genFilename w] 
  puts $fo {
start_timer
file mkdir $tmp_dir
set_app_var pt_tmp_dir $tmp_dir
set_host_options -max_cores $max_cores
set_app_var report_default_significant_digits 3
set_app_var link_create_black_boxes false
set_app_var sh_continue_on_error false
set_app_var si_enable_analysis true
set_app_var delay_calc_waveform_analysis_mode full_design
set_app_var delay_calc_waveform_analysis_constraint_arcs_compatibility false

# pt setting: 
set_app_var delay_calc_enhanced_ccsn_waveform_analysis true
set_app_var rc_cache_min_max_rise_fall_ceff true
set_app_var rc_degrade_min_slew_when_rd_less_than_rnet true
set_app_var report_default_significant_digits 5
set_app_var sdc_save_source_file_information true
set_app_var sh_continue_on_error true
set_app_var sh_message_limit 0
set_app_var si_enable_multi_input_switching_analysis false
set_app_var si_noise_composite_aggr_mode statistical
set_app_var si_noise_update_status_level high
set_app_var si_xtalk_composite_aggr_mode statistical
set_app_var si_xtalk_delay_analysis_mode all_path_edges
set_app_var si_xtalk_double_switching_mode clock_network
#set_app_var timing_clock_reconvergence_pessimism same_transition
set_app_var timing_clock_reconvergence_pessimism normal
set_app_var timing_crpr_remove_clock_to_data_crp true
set_app_var timing_crpr_remove_muxed_clock_crp true
set_app_var timing_crpr_threshold_ps 5
set_app_var timing_enable_constraint_variation true
set_app_var timing_enable_culmulative_incremental_derate true
set_app_var timing_enable_data_check_default_group true
set_app_var timing_enable_max_capacitance_set_case_analysis true
set_app_var timing_enable_max_transition_set_case_analysis true
set_app_var timing_enable_voltage_swing true
set_app_var timing_pocvm_corner_sigma 3
set_app_var timing_pocvm_enable_extended_moments true
set_app_var timing_pocvm_max_transition_sigma 3
set_app_var timing_pocvm_precedence library
set_app_var timing_pocvm_report_sigma 3
set_app_var timing_report_unconstrained_paths_from_nontimed_startpoints false
set_app_var timing_save_pin_arrival_and_slack true
set_app_var timing_update_status_level medium
set_app_var si_enable_analysis true
set_app_var si_xtalk_exit_on_max_iteration_count 2
set_app_var si_analysis_logical_correlation_mode false
set_app_var si_filter_per_aggr_noise_peak_ratio 0.01
#set si_delay_analysis_ignore_arrival_lists [get_nets -hier *]
#set si_delay_analysis_select_nets [get_nets -hier *]
printvar -application > $rpt_dir/prerun_setting.list

foreach file [glob -nocomplain $proc_dir/*] {
  puts "loading default proc: $file"
  source $file 
}

set current_scenario $current_scenario

set_app_var link_path [concat "*" $db_list]

puts [end_timer "string"]
   
  }
  close $fo
}
define_proc_attributes genFile_ptScript \
  -info "whatFunction"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
