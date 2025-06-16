set start [clock seconds]
source ../scr/setup.invs
set vars(view_from) $env(view_from)
set vars(view_rpt) $env(view_rpt)
set vars(pre_step) cts
set vars(step) route
source ../scr/defineInput.tcl
set vars(rpt_dir) "$vars(rpt_dir)/$vars(step)/$vars(view_rpt)"
exec mkdir -p $vars(rpt_dir)

puts "run $vars(step) step start..."
userRunTimeCalculation -start

##restore cts databse
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

if {$vars(ocv) == "socv"} {
	setDelayCalMode -socv_accuracy_mode low -sgs2set {useNdwOnPBAStartPoint:true} -enable_quiet_receivers_for_hold true -equivalent_waveform_model_type ecsm -equivalent_waveform_model propagation -socv_lvf_mode early_late -honorSlewPropConstraint true
    set_global timing_report_max_transition_check_using_nsigma_slew true
	set_socv_reporting_nsigma_multiplier -transition 3
}

#pocv low voltage setting
if {$vars(low_v) == "true"} {
	#enable pocv with 3sigma
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
#setFillerMode -core $vars(filler_cells) -fitGap true
#setPlaceMode -fillerGapEffort high -fillerGapMinGap $vars(min_gap) ;#40/28
setPlaceMode -place_detail_legalization_inst_gap 2
setPlaceMode -place_detail_preserve_routing true
setPlaceMode -reorderScan false
setPlaceMode -placeIoPins false
#add by cjy,used to fix pg cut spacing violation with obs in std cell
setPlaceMode -place_detail_use_check_drc true
setPlaceMode -place_detail_check_cut_spacing true
#for arm lib
setPlaceMode -checkImplantWidth true
setPlaceMode -honorImplantSpacing true
setPlaceMode -checkImplantMinArea true

###clock_uncertainty set
#set_clock_uncertainty -setup 0.075 [all_clocks ]
#set_clock_uncertainty -hold 0.035 [all_clocks ]

#add by cjy,used to report more timing path

##delete cellpadding
if {$vars(cellPad_mode) == "true"} {
	deleteAllCellPad
}

##setTrailRouteMode
setMaxRouteLayer $vars(max_route_layer)
setTrialRouteMode -maxRouteLayer $vars(max_route_layer)
setTrialRouteMode -minRouteLayer $vars(min_route_layer)
setTrialRouteMode -honorClockSpecNDR true

if {$vars(cong_cri_mode) == "true"} {
	setTrialRouteMode -highEffort true
}
if {$vars(lp_mode) == "true"} {
	setTrialRouteMode -handlePDComplex true -handleEachPD true
}

##set power analysis view
set pwrRptView [lindex [all_hold_analysis_views] 0]
set_power_analysis_mode -analysis_view $pwrRptView

if { $vars(optPower_mode) == "true" } {
	setDesignMode -powerEffort high
	setOptMode -powerEffort low
	setOptMode -leakageToDynamicRatio 0.2
	setPlaceMode -place_global_activity_power_driven true
	setPlaceMode -place_global_activity_power_driven_effort high
	setPlaceMode -place_global_clock_power_driven true
	setPlaceMode -place_global_clock_power_driven_effort high
	set_default_switching_activity -input_activity 0.2 -seq_activity 0.2
}

##set nanoroute mode
setNanoRouteMode -routeWithViaInPin true
setNanoRouteMode -routeTopRoutingLayer $vars(max_route_layer)
setNanoRouteMode -routeBottomRoutingLayer $vars(min_route_layer)
setNanoRouteMode -routeWithTimingDriven true
setNanoRouteMode -routeWithSiDriven true
setNanoRouteMode -routeSiEffort high
setNanoRouteMode -routeWithLithoDriven true
setNanoRouteMode -routeStrictlyHonorNonDefaultRule true
setNanoRouteMode -routeReserveSpaceForMultiCut false ;#true
setNanoRouteMode -routeInsertAntennaDiode false
setNanoRouteMode -drouteFixAntenna true
setNanoRouteMode -dbViaWeight $vars(via_weight)
setNanoRouteMode -routeConcurrentMinimizeViaCountEffort high
setNanoRouteMode -drouteVerboseViolationSummary 1
setNanoRouteMode -drouteUseMultiCutViaEffort default
setNanoRouteMode -droutePostRouteSwapVia false

#for arm lib
setNanoRouteMode -routeWithViaOnlyForStandardCellPin true
#Leon fix @ 05/09
set var(cell_height) [dbGet top.fplan.coresite.size_y]
if { $var(cell_height) == 0.65 || $var(cell_height) == 0.7 } {
    setNanoRouteMode -routeWithViaInPin 1:1
    setNanoRouteMode -routeWithViaOnlyForStandardCellPin 1:1
}

#setNanoRouteMode -drouteUseMultiCutViaEffort high
#setNanoRouteMode -routeWithViaOnlyForStandardCellPin true
#setNanoRouteMode -routeSpreadWireEffort 3
#setNanoRouteMode -routeExtraSpaceUseDefaultSpacing true
#setNanoRouteMode -drouteExpAdvanceViolationFix "Minstp Mar"
#setNanoRouteMode -drouteExpEnableMetalPatching "Minstp Mar"
#setNanoRouteMode -droutePostRouteSwapVia multiCut
#setNanoRouteMode -routeDesignRouteClockNetsFirst true
#setNanoRouteMode -extractThirdPartyCompatible true
#setNanoRouteMode -routeAntennaCellName <cellname>
#setNanoRouteMode -routeWithEco true
#setNanoRouteMode -routeEcoOnlyInLayers 3:5
#setNanoRouteMode -routeReverseDirection <x1 y1 x2 y2>
#setNanoRouteMode -drouteExpNumCutsBlockPin {( 2 *)}

if {$vars(lp_mode) == "true"} {
	setNanoRouteMode -routeHonorPowerDomain false
}


### set annlysis mode
setAnalysisMode -cppr both
setAnalysisMode -analysisType onChipVariation

if { $vars(ocv) == "socv" } {
	setAnalysisMode -socv true
} elseif { $vars(ocv) == "aocv" } {
	setAnalysisMode -aocv true
} else {
	puts "use flat ocv!"
}

### drc option
set cmd "set_analysis_view $vars(route_analysis_view)"
eval $cmd
report_analysis_view > $vars(rpt_dir)/[dbgDesignName].$vars(step).analysisView.$vars(view_rpt).rpt

set_interactive_constraint_modes [all_constraint_modes -active]

setDontUse * false
foreach cell $vars(dont_use_cells) {
	setDontUse $cell true
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
source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/scripts_1220/uncertainty_invs.tcl


#set timing derate
source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/timing_derate_latest.tcl
report_timing_derate

## tie cell
setTieHiLoMode -cell $vars(tie_cells) -maxDistance 5 -maxFanout 2
foreach cell $vars(tie_cells) {  setDontUse $cell false}
addTieHiLo
foreach cell $vars(tie_cells) {  setDontUse $cell true}


###user defined
source -e -v ../scr/pre_route.tcl

#reset_path_group -all

source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/path_group.tcl
source -e -v ../scr/user_path_group.tcl
#createBasicPathGroups -expanded

###add filer cells
#userAddFillerCells

###routeDesgin

routeDesign

#if {$vars(timing_cri_mode) == "true} {
#	setDelayCalMode -SIAware true
#	routeDesign -trackOpt
#} else {
#	routeDesign
#}


#globalDetailRoute
#changeClockStatus -all -noFixedNetWires
#ecoRoute
#changeClockStatus -all -FixedNetWires

##setEXtract Mode
setExtractRCMode -effortLevel medium -engine postroute
setExtractRCMode -coupled true

##setDelayCalMode

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

#save databse
saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step).$vars(view_rpt).enc

timeDesign -expandedViews -postRoute -prefix [dbgDesignName].$vars(step).$vars(view_rpt) -outDir $vars(rpt_dir)
timeDesign -expandedViews -postRoute -prefix [dbgDesignName].$vars(step).$vars(view_rpt) -outDir $vars(rpt_dir) -hold


##veirfy
#verifyConnectivity -noAntenna -error 10000 -warning 1000 -report $vars(rpt_dir)/[dbgDesignName].$vars(step).verifyConnectivity.$vars(view_rpt).rpt
#verify_drc -limit 10000 -report $vars(rpt_dir)/[dbgDesignName].$vars(step).verify_drc.$vars(view_rpt).rpt
#
## check filler
#checkFiller -reportGap [expr $vars(min_gap)/2] -file $vars(rpt_dir)/[dbgDesignName].$vars(step).checkFiller_gap.$vars(view_rpt).rpt
#addFillerGap $vars(min_gap) -effort high
# collect rpt
userRunTimeCalculation -end
#summarizeDesign	
summarizeDesign $vars(rpt_dir)/[dbgDesignName].$vars(step).design_summary.$vars(view_rpt).rpt

###user defined
source -e -v ../scr/post_route.tcl
reportGateCount
reportGateCount -stdCellOnly

um::pop_snapshot_stack
create_snapshot -name $vars(step) -categories design
report_metric -file $vars(rpt_dir)/metrics.html -format html

#save databse
saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step).$vars(view_rpt).enc
redirect  -file $vars(rpt_dir)/runtime.rpt   {runTime $vars(step) $start}

puts " ending $vars(step) step..."

exit
