####################################################################################
#                              ALWAYS_SOURCE PLUG-IN 
#####################################################################################
#
# This plug-in script is called from all flow scripots after loading the setup.tcl 
# but after to loading the design data.  It can be used to set variables that affect 
# non-persistent information
#
#####################################################################################

###design mode
setDesignMode -process $vars(process)
setOptMode -powerEffort low

######global vars
set_global timing_disable_library_data_to_data_checks false
set_global timing_disable_user_data_to_data_checks false
set_global timing_case_analysis_for_sequential_propagation 0
set_global timing_enable_uncertainty_for_pulsewidth_checks true
set_global timing_enable_derating_for_pulsewidth_checks true
set_global timing_apply_default_primary_input_assertion false ;#default true
set_table_style -no_frame_fix_width -name report_timing
set_table_style -no_frame_fix_width -name report_timing_summary
set_global report_timing_format {instance cell arc fanout incr_delay load slew delay arrival user_derate  power_domain}


####delay calucation mode
setDelayCalMode -engine aae
setDelayCalMode -siAware true
setDelayCalMode -equivalent_waveform_model propagation

####analysis mode
setAnalysisMode -analysisType onChipVariation 
setAnalysisMode -cppr both


##### opt mode
setOptMode -leakageToDynamicRatio 1
setOptMode -maxDensity 0.65
#setOptMode -maxLocalDensity 0.75 ;#add by clemence ,issue : high local density after hold opt
setOptMode -detailDrvFailureReason true
setOptMode -timeDesignNumPaths 2000
setOptMode -maxLength $vars(opt_max_length)
setOptMode -verbose true


#####place mode
setPlaceMode -place_detail_legalization_inst_gap 2 
setPlaceMode -place_global_clock_gate_aware true
setPlaceMode -place_detail_use_check_drc true
setPlaceMode -place_detail_check_cut_spacing true
#setPlaceMode -place_global_uniform_density true; #add by clemence ,issue : high local density after hold opt

#####route mode
setDesignMode -topRoutingLayer $vars(max_route_layer)
setDesignMode -bottomRoutingLayer $vars(min_route_layer)

#######source tcl
source ../scr/util/path_group.tcl 

####cts option
set_max_fanout $vars(max_fanout) [current_design ]
set_max_transition $vars(data_slew) [current_design ]
set_max_transition -clock $vars(clk_slew) [all_clocks]



if {$vars(size_only_file) != ""} {
       set fc [open $vars(size_only_file)]
               while {[gets $fc line] >=0} {
                       dbSet [dbGet top.insts.name  $line -p].DontTouch sizeok
               }
       close $fc
}

