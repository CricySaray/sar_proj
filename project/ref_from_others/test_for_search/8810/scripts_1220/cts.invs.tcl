##begin--------------------------------------------------------------------------------------------------------------------------------------------
set start [clock seconds]
source ../scr/setup.invs
set vars(view_from) $env(view_from)
set vars(view_rpt) $env(view_rpt)
set vars(pre_step) place
set vars(step) cts
source ../scr/defineInput.tcl
set vars(rpt_dir) "$vars(rpt_dir)/$vars(step)/$vars(view_rpt)"
exec mkdir -p $vars(rpt_dir)

puts "run $vars(step) step start..."
userRunTimeCalculation -start
puts "ccopt flow is selected"

if {[info exists vars(debug_mode)] && $vars(debug_mode)=="false"} {
	restoreDesign $vars(dbs_dir)/$vars(design).$vars(pre_step).$vars(view_from).enc.dat $vars(design)
}

um::enable_metrics -on
um::push_snapshot_stack


##reset all option

setPlaceMode -reset
setOptMode -reset
setUsefulSkewMode -reset
setCTSMode -reset
setTrialRouteMode -reset
setNanoRouteMode -reset
setSIMode -reset
setExtractRCMode -reset
setDelayCalMode -reset
setAnalysisMode -reset

###fence set
setOptMode -honorFence true

source  /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/invs_check/invs_common_setting.tcl
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/common_setting.tcl
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/ndr.tcl

#socv low voltage setting
if {$vars(low_v) == "true"} {
	#enable pocv with 3sigmasource  
	setDelayCalMode -ewm_type simulation -equivalent_waveform_model propagation
	setDelayCalMode -socv_lvf_mode early_late -socv_delay_slew_correlation_mode 2 -siAware true
	setAnalysisMode -socv true -analysisType onChipVariation -cppr both
	set timing_socv_statistical_min_max_mode mean_and_three_sigma_bounded
	set_global timing_socv_view_based_nsigma_multiplier_mode true
	set_socv_reporting_nsigma_multiplier -setup 3 -hold 3
	set timing_report_enable_verbose_ssta_mode true
	setDelayCalMode -eng_useEWMForTimingCheckDelay true
	#Enable max transition constraint variation (n + 3 sigma)
	source setSOCVMultiplierForDRC.tcl
	set_socv_reporting_nsigma_multiplier -setup 3 -hold 3
	set_global timing_report_drv_nsigma_multiplier_reporting true
	set_global timing_report_max_transition_check_using_nsigma_slew true
	set_socv_reporting_nsigma_multiplier –transition 3
	#Delay 3 / Hold 4 / Linear Sum: Hold slack = μslack – (3*σdelay + 4*σhold)
	setDelayCalMode -socv_use_lvf_tables {delay slew constraint}
	set_timing_derate 0 -sigma -cell_check -early [get_lib_cells */*] -delay_corner $delay_corner
	set_delay_cal_mode -socv_use_lvf_tables {delay slew constraint}
	set_socv_reporting_nsigma_multiplier -hold 3
	#Improve P&R to STA Correlation (please configure prior to optimization in post-route stage)
	setLimitedAccessFeature socv_accuracy_mode_high 1
	setDelayCalMode -socv_accuracy_mode high
}

##setPlaceMode

#setFillerMode -core $vars(filler_cells) -fitGap true -keepFixed true
#setPlaceMode -fillerGapEffort high -fillerGapMinGap $vars(min_gap) ;#40/28
setPlaceMode -place_detail_legalization_inst_gap 2
setPlaceMode -place_detail_preserve_routing true
setPlaceMode -place_global_reorder_scan false
setPlaceMode -place_global_place_io_pins false
#add by cjy,used to fix pg cut spacing violation with obs in std cell
setPlaceMode -place_detail_use_check_drc true
setPlaceMode -place_detail_check_cut_spacing true
#for arm lib
setPlaceMode -checkImplantWidth true
setPlaceMode -honorImplantSpacing true
setPlaceMode -checkImplantMinArea true

###clock uncertainty set
#set_clock_uncertainty -setup 0.085 [all_clocks ]
#set_clock_uncertainty -hold 0.04 [all_clocks ]

if {$vars(timing_cri_mode) == "true"} {
	setLimitedAccessFeature flow_effort_xtreme 1
	setDesignMode -flowEffort extreme
}

if {$vars(cong_cri_mode) == "true"} {
	setPlaceMode -autoModulePadding true
	setPlaceMode -congEffort high
}

if {$vars(lp_mode) == "true"} {
	setPlaceMode -place_detail_fixed_shifter  true
	setPlaceMode -place_detail_max_shifter_depth $vars(max_shifter_depth)
	setPlaceMode -place_detail_max_shifter_row_depth $vars(max_shifter_depth)
	setPlaceMode -place_detail_max_shifter_column_depth $vars(max_shifter_depth)
}

if {$vars(cellPad_mode) == "true"} {
	#	User add CellPadding
	set i 0
	foreach cell [lindex $vars(padding_cells) $i] {
		incr i
		specifyCellPad $cell -left [lindex $vars(padding_cells) $i] -right [lindex $vars(padding_cells) $i]
		incr i
	}

	# User add InstPadding
	#	specifyInstPad <instName> <padding>

	#	 User add ModulePadding
	#	setPlaceMode -modulePadding <module> < actor>
}

##setOptMode

setOptMode -addInstancePrefix CCOPT_
setOptMode -reclaimArea true 
setOptMode -fixFanoutLoad true
setOptMode -clkGateAware force
setOptMode -allEndPoints true
setOptMode -maxLength $vars(opt_max_length)
#setOptMode -preserveModuleFunction true
if {$vars(userfulSkew_mode) == "true"} {
	setOptMode -usefulSkew true
}
#setUsefulSkewMode -noBoundary true
#setOptMode -maxLocalDensity 0.75
#add by cjy,used to report more timing path

#donot use ndr rule when timing critical opt
#if {$vars(timing_cri_mode) == "true"} {
#	if {[info exists vars(cts_ndr)] && $vars(cts_ndr) !=""} {
#		setOptMode -ndrAwareOpt $vars(cts_ndr)
#	}
#}

if {$vars(lp_mode) == "true"} {
	setOptMode -resizeShifterAndIsoInsts true
    set files [open ../../dsn/constrains/keepPort w]
	foreach pd [dbGet [dbGet -p top.pds.isDefault 0].name] {
        puts $files [dbGet [dbGet -p top.pds.name ${pd}].group.members.name]
    }
    close $files
	setOptMode -keepPort ../../dsn/constrains/keepPort
}

##set power analysis view


if { $vars(optPower_mode) == "true" } {
	set pwrRptView [lindex [all_hold_analysis_views] 0]
	set_power_analysis_mode -analysis_view $pwrRptView
	setDesignMode -powerEffort high
	setOptMode -powerEffort low
	setOptMode -leakageToDynamicRatio 0.2
	setPlaceMode -place_global_activity_power_driven true
	setPlaceMode -place_global_activity_power_driven_effort high
	setPlaceMode -place_global_clock_power_driven true
	setPlaceMode -place_global_clock_power_driven_effort high
	set_default_switching_activity -input_activity 0.2 -seq_activity 0.2
}

##setExtractRCMode

##setDelayCalMode

setDelayCalMode -honorSlewPropConstraint true
setDelayCalMode -equivalent_waveform_model_type ecsm
setDelayCalMode -equivalent_waveform_model propagation
if {$vars(ocv) == "socv"} {
	setDelayCalMode -socv_accuracy_mode low -sgs2set {useNdwOnPBAStartPoint:true} -enable_quiet_receivers_for_hold true -equivalent_waveform_model_type ecsm -equivalent_waveform_model propagation -socv_lvf_mode early_late -honorSlewPropConstraint true
  set_global timing_report_max_transition_check_using_nsigma_slew true
	set_socv_reporting_nsigma_multiplier -transition 3
} elseif {$vars(ocv) == "aocv"} {
	set timing_aocvm_analysis_mode combined_launch_capture_depth
	set timing_aocv_use_cell_depth_for_net false
	setDelayCalMode -ewm_type simulation -equivalent_waveform_model propagation -SIAware true
	set_global timing_derate_aocv_dynamic_delays false
	set_global timing_enable_si_cppr true
	set_global timing_library_read_ccs_noise_data true
	set_global timing_disable_library_data_to_data_checks false
	set_global timing_disable_library_tiehi_tielo false
	set timing_disable_lib_pulsewidth_checks false
}

##setTrialRouteMode

#setMaxRouteLayer $vars(max_route_layer)
#setTrialRouteMode -maxRouteLayer $vars(max_route_layer)
#setTrialRouteMode -minRouteLayer $vars(min_route_layer)
#setTrialRouteMode -honorClockSpecNDR true

if {$vars(cong_cri_mode) == "true"} {
	setTrialRouteMode -highEffort true
}

if {$vars(lp_mode) == "true"} {
	setTrialRouteMode -handlePDComplex true -handleEachPD true
}

#set_global timing_defer_mmmc_object_updates true
#update_constraint_mode -name func -sdc_files $vars(sdc_func)
#set_analysis_view -update_timing
#set_global timing_defer_mmmc_object_updates false

##other setting

set cmd "set_analysis_view $vars(cts_analysis_view)"
eval $cmd
report_analysis_view > $vars(rpt_dir)/[dbgDesignName].$vars(step).analysisView.$vars(view_rpt).rpt

set_interactive_constraint_modes [all_constraint_modes -active]

setDontUse * false
foreach cell $vars(dont_use_cells) {
	setDontUse $cell true
}

###using lvt cells on clktree
#setDontUse *ZTL* false
set ctscellist "$vars(ccopt_logic_cells) $vars(ccopt_icg_cells) $vars(cts_driver_cells) $vars(assign_buffer_cell) $vars(io_attach_cell) $vars(cts_buf_cells) $vars(ccopt_buf_cells) $vars(cts_icg_cells) $vars(cts_icg_cells)"
foreach celltype [lsort -u $ctscellist] {
	setDontUse $celltype false
}

if {[file exists $vars(func_dontch_list)] && $vars(func_dontch_list) != ""} {
	set fileId [open $vars(func_dontch_list) r]
	while {[gets $fileId line] >= 0} {
		#set_dont_touch [lindex $line 0] true
		dbSet [dbGet -p top.insts.name [lindex $line 0]].dontTouch sizeOk
	}
	close $fileId
}

if {[file exists $vars(dft_dontch_list)] && $vars(dft_dontch_list) != ""} {
	set fileId [open $vars(dft_dontch_list) r]
	while {[gets $fileId line] >= 0} {
		#set_dont_touch [lindex $line 0] true
		dbSet [dbGet -p top.insts.name [lindex $line 0]].dontTouch sizeOk
	}
	close $fileId
}

if {$vars(process) == 65 || $vars(process) == 55} {
	set_max_fanout 32 [current_design]
	set_max_transition 0.6 [current_design]
} elseif {$vars(process) == 45 || $vars(process) == 40} {
	set_max_fanout 24 [current_design]
	set_max_transition 0.4 [current_design]
} elseif {$vars(process) <= 28} {
	set_max_fanout 32 [current_design]
	set_max_transition 0.5 [current_design]
}

source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/set_max_transition.tcl
source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/last/uncertainty_invs.tcl
source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/timing_derate_latest.tcl
setAnalysisMode -cppr both
setAnalysisMode -analysisType onChipVariation

if { $vars(ocv) == "socv" } {
	setAnalysisMode -socv true
} elseif { $vars(ocv) == "aocv" } {
	setAnalysisMode -aocv true
} else {
	puts "use flat ocv!"
}

#set_clock_gating_check -setup $vars(clock_gating_margin)
#set_clock_gating_check -setup $vars(clock_gating_margin) [get_pins -hier */E -filter "is_hierarchical==false"]
#set_clock_gating_check -setup $vars(clock_gating_margin) [get_pins -hier */TE -filter "is_hierarchical==false"]
set_interactive_constraint_modes [all_constraint_modes -active]
reset_clock_gating_check
#reset_clock_gating_check [get_pins -hier */E]
reset_clock_gating_check [get_pins -hier */E -filter "!is_hierarchical"]
reset_clock_gating_check [get_pins -hier */TE -filter "!is_hierarchical"]

## edi 14 will update io latency auto##
#if {$vars(ccopt) == "true"} {
#	set_propagated_clock [all_clocks]
#}

##cts setting
#set_ccopt_mode -intergration native
#set_ccopt_mode -edi_cts_spec_for_macro_models <file>
set_ccopt_property buffer_cells $vars(ccopt_buf_cells)
set_ccopt_property inverter_cells $vars(ccopt_inv_cells)
set_ccopt_property clock_gating_cells $vars(ccopt_icg_cells)
set_ccopt_property logic_cells $vars(ccopt_logic_cells)
set_ccopt_property add_driver_cell $vars(cts_driver_cells)
#foreach cell "$vars(ccopt_buf_cells) $vars(ccopt_inv_cells)" {
#	set_ccopt_property cell_halo_x 3 -cell $cell
#	set_ccopt_property cell_halo_y [dbget [dbGetCellByName $cell].size_y] -cell $cell
#}
set_ccopt_property use_inverters true
set_ccopt_property cell_density 0.5
set_ccopt_property target_max_trans $vars(cts_tran)
set_ccopt_property max_source_to_sink_net_length $vars(cts_length)
set_ccopt_property cts_max_fanout $vars(cts_faout)
set_ccopt_property add_exclusion_drivers true
set_ccopt_property recluster_to_reduce_power true
set_ccopt_property allow_clustering_with_weak_drivers true
set_ccopt_property ccopt_auto_limit_insertion_delay_factor 1.1
#set_ccopt_property route_type_autotrim false
set_ccopt_property move_clock_gates true
set_ccopt_property move_logic true
set_ccopt_property clone_clock_gates true
set_ccopt_property routing_top_min_fanout 2000
#donot merge clock gate both ccopt/ccopt -cts
set_ccopt_property ccopt_merge_clock_gates false
set_ccopt_property merge_clock_gates false

if {$vars(top_or_block) == "top"} {
	set_ccopt_property update_io_latency false
} else {
	set_ccopt_property update_io_latency true
}

#if {1} {
#	set inReg [get_object_name  [get_pins -of_objects [get_cells -of_objects [get_pins [all_fanout -from [get_ports -filter "is_clock_used_as_clock == false && direction == in && net_name !~ *dft*"] -endpoints_only] -filter "lib_pin_name != SE && lib_pin_name != CD && lib_pin_name != CP"] -filter "is_sequential == true"] -filter "lib_pin_name =~ CP*"]]
#	set outReg [get_object_name [get_pins -of_objects [get_cells -of_objects [get_pins [all_fanin -to [get_ports -filter "is_clock_used_as_clock == false && direction == out && net_name !~ *dft*"] -startpoints_only]] -filter "is_sequential == true"] -filter "lib_pin_name =~ CP*"]]
#	foreach EachPin [concat $inReg $outReg] {
#		set_ccopt_property schedule -pin $EachPin off
#	}
#}
#
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/disable_boundary_dffs_useful_skew.tcl
#setOptMode -skewClockPreserveLatencyTermList [concat $inReg $outReg]

##
#set_ccopt_property insertion_delay 0.25 -delay_corner delay_func_wcl_cworst -pin aa/clk

#set clock_gen_module_list [list top_crpm]
#foreach module $clock_gen_module_list {
#	foreach_in_collection pin [get_pins -of [filter_collection]
#		set_ccopt_property sink_type min -pin [get_object_name $pin]
#}
## set Nano mode


setNanoRouteMode -routeWithViaInPin true
setNanoRouteMode -routeTopRoutingLayer $vars(max_route_layer)
setNanoRouteMode -routeBottomRoutingLayer $vars(min_route_layer)
setNanoRouteMode -routeWithTimingDriven true
setNanoRouteMode -routeWithSiDriven true
setNanoRouteMode -routeSiEffort high
setNanoRouteMode -drouteUseMultiCutViaEffort high
setNanoRouteMode -routeConcurrentMinimizeViaCountEffort high
setNanoRouteMode -routeDesignRouteClockNetsFirst true
setNanoRouteMode -routeStrictlyHonorNonDefaultRule true
setNanoRouteMode -dbViaWeight $vars(via_weight)
setNanoRouteMode -routeWithViaOnlyForStandardCellPin 1:1
setNanoRouteMode -drouteVerboseViolationSummary 1
setNanoRouteMode -routeReserveSpaceForMultiCut true

#for arm lib
setNanoRouteMode -routeWithViaOnlyForStandardCellPin true
#Leon fix @ 05/09
set var(cell_height) [dbGet top.fplan.coresite.size_y]
if { $var(cell_height) == 0.65 || $var(cell_height) == 0.7 } {
    setNanoRouteMode -routeWithViaInPin 1:1
    setNanoRouteMode -routeWithViaOnlyForStandardCellPin 1:1
}


#setNanoRouteMode -routeWithViaOnlyForStandardCellPin false
#setNanoRouteMode -routeSpreadWireEffort 3
#setNanoRouteMode -routeExtraSpaceUseDefaultSpacing true
#setNanoRouteMode -drouteExpAdvanceViolationFix "Minstp Mar"
#setNanoRouteMode -drouteExpEnableMetalPatching "Minstp Mar"

if {$vars(lp_mode) == "true"} {
	setNanoRouteMode -routeHonorPowerDomain true
}

#source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/timing_derate.tcl
source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/timing_derate_latest.tcl
report_timing_derate

reset_path_group -all
source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/path_group.tcl
source -e -v ../scr/user_path_group.tcl

###user defined
source -e -v ../scr/modify_cts.tcl

source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/last/cts/early_for_handshake.tcl


## user defined
source ../scr/pre_cts.tcl

## spec
create_ccopt_clock_tree_spec -file ${dsn_csf_dir}/$vars(design).$env(view_rpt).ccopt.spec
source  ${dsn_csf_dir}/$vars(design).$env(view_rpt).ccopt.spec

## edt balance
source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/last/cts/edt_scan_balance.tcl

###user defined
source -e -v ../scr/mid_cts.tcl

if {$vars(userfulSkew_mode) == "true"} {
    ccopt_design -outDir $vars(rpt_dir) -prefix [dbgDesignName].$vars(step).$vars(view_rpt)
} else {
    ccopt_design -outDir $vars(rpt_dir) -prefix [dbgDesignName].$vars(step).$vars(view_rpt) -cts
}
saveDesign $vars(dbs_dir)/[dbgDesignName].ccopt.$vars(view_rpt).enc

report_ccopt_clock_trees -summary -file $vars(rpt_dir)/[dbgDesignName].ccopt_clock_tree.rpt
report_ccopt_skew_groups -summary -local_skew -file $vars(rpt_dir)/[dbgDesignName].ccopt_skew_groups.summary.rpt

##if {![regexp cpu [dbget top.name]]} {}
#set_global timing_defer_mmmc_object_updates true
#update_constraint_mode -name funcasyn -sdc_files $vars(sdc_funcasyn)
#set_analysis_view -update_timing
#set_global timing_defer_mmmc_object_updates false


if {$vars(userfulSkew_mode) != "true"} {
    timeDesign -postcts -outDir $vars(rpt_dir) -prefix [dbgDesignName].$vars(step).$vars(view_rpt) -expandedViews
}
timeDesign -hold -postcts -outDir $vars(rpt_dir) -prefix [dbgDesignName].$vars(step).$vars(view_rpt) -expandedViews

##incr opt
optDesign -incr -postCTS -expandedViews -outDir $vars(rpt_dir) -prefix [dbgDesignName].ccoptPostctsOpt.$vars(view_rpt)


report_constraint -check_type {pulse_width clock_period pulse_clock_max_width pulse_clock_min_width} > $vars(rpt_dir)/$vars(design).report_constraint.rpt
##hold fix mode
if { $vars(cts_hold_fix_mode) == "true" } {
	set cmd "set_analysis_view $vars(cts_analysis_view)"
	eval $cmd
	report_analysis_views > $vars(rpt_dir)/[dbgDesignName].$vars(step).holdAnalysisView.$vars(view_rpt).rpt
	set_interactive_constraint_modes [all_constraint_modes -active]
	
	#reset_path_group -all
	#createBasicPathGroups -expanded
	#setPathGroupOptions reg2reg -effortLevel high
	#setPathGroupOptions reg2cgate -effortLevel high
	#setPathGroupOptions in2reg -effortLevel low
	#setPathGroupOptions reg2out -effortLevel low
	#setPathGroupOptions in2out -effortLevel low

	setOptMode -addInstancePrefix CTS_HOLD_
	#setOptMode -holdSlackFixingThreshold 0
	setOptMode -fixHoldAllowSetupTnsDegrade false
	setOptMode -ignorePathGroupsForHold {in2reg reg2out in2out}
	setOptMode -holdTargetSlack 0 -setupTargetSlack 0
	setOptMode -maxLocalDensity 0.9

	setAnalysisMode -checkType hold
	if { [info exists vars(hold_fix_cells)] && $vars(hold_fix_cells) != "" } {
		setOptMode -holdFixingCells $vars(hold_fix_cells)
	}

	foreach cc $vars(delay_cells) {
		setDontUse $cc false
	}

	optDesign -postCTS -hold -expandedViews -outDir $vars(rpt_dir) -prefix [dbgDesignName].ctsOptHold.$vars(view_rpt)

	setAnalysisMode -checkType setup

	foreach cc $vars(delay_cells) {
		setDontUse $cc true
	}
}
#checkFiller -reportGap [expr $vars(min_gap)/2] -file $vars(rpt_dir)/[dbgDesignName].$vars(step).checkFiller_gap.$vars(view_rpt).rpt
#addFillerGap $vars(min_gap) -effort high
#clearDrc

#check no-ck cell
##eg userCheckCKTree ehvt
userCheckCKTree

## extract lib/lef
set cmd "set_analysis_view $vars(cts_analysis_view)"
eval $cmd
source ../scr/util/userGenIolatencyRpt


#source ../scr/util/userExtractLibLef.tcl
#userExtractLibLef


## collect rpt

userRunTimeCalculation -end

#summarizeDesign	
summarizeDesign $vars(rpt_dir)/[dbgDesignName].$vars(step).design_summary.$vars(view_rpt).rpt

###user defined
source -e -v ../scr/post_cts.tcl

## saveDesign
um::pop_snapshot_stack 
create_snapshot -name $vars(step) -categories design
report_metric -file $vars(rpt_dir)/metrics.html -format html
saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step).$vars(view_rpt).enc -compress
redirect  -file $vars(rpt_dir)/runtime.rpt   {runTime $vars(step) $start}


puts " ending $vars(step) step..."
exit
