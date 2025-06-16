set start [clock seconds]
source ../scr/setup.invs
set vars(view_from) $env(view_from)
set vars(view_rpt) $env(view_rpt)
set vars(step) postroute
set vars(pre_step) route
source ../scr/defineInput.tcl
set vars(rpt_dir) "$vars(rpt_dir)/$vars(step)/$vars(view_rpt)"
exec mkdir -p $vars(rpt_dir)

puts "run $vars(step) step start..."
userRunTimeCalculation -start
##restore route database

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
#set_clock_uncertainty -hold 0.032 [all_clocks ]


if {$vars(timing_cri_mode) == "true"} {
	setLimitedAccessFeature flow_effort_xtreme 1
	setDesignMode -flowEffort extreme
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

deletePlaceBlockage  iocell_BLK

if {$vars(cong_cri_mode) == "true"} {
	setPlaceMode -congEffort high
	setPlaceMode -autoModulePadding true
}

if {$vars(lp_mode) == "true"} {
	setPlaceMode -fixedShifter true
	setPlaceMode -maxShifterDepth $vars(max_shifter_depth)
	setPlaceMode -maxShifterRowDepth $vars(max_shifter_depth)
	setPlaceMode -maxShifterColDepth $vars(max_shifter_depth)
}

##setOptMode

setOptMode -addInstancePrefix POSTROUTE_SETUP_
setOptMode -fixFanoutLoad true
setOptMode -expLayerAwareOpt true
setOptMode -allEndPoints true
setOptMode -maxLength $vars(opt_max_length)
setOptMode -checkRoutingCongestion true
#setOptMode -preserveModuleFunction true
setOptMode -usefulSkew false
#setUsefulSkewMode -noBoundary true
#add by cjy,used to report more timing path
#setOptMode -timeDesignNumPaths 100

#donot use ndr rule when timing critical opt
#if {$vars(timing_cri_mode) == "true"} {
#	if {[info exists vars(cts_ndr)] && $vars(cts_ndr) !=""} {
#		setOptMode -ndrAwareOpt $vars(cts_ndr)
#	}
#}

if {$vars(cts_hold_fix_mode) == "true"} {
	setOptMode -postRouteAreaReclaim holdAndSetupAware; #keep the previous hold fix buffer and reduce density for routing drc
}

if {$vars(lp_mode) == "true"} {
		setOptMode -resizeShifterAndIsoInsts true
		setOptMode -keepPort ../../dsn/constr/keepPort
}

if {$vars(top_or_block) == "top"} {
	setOptMode -usefulSkew false
}

#setPowerAnalysisView

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

##setAnalysisMode
setAnalysisMode -cppr both
setAnalysisMode -analysisType onChipVariation

if { $vars(ocv) == "socv" } {
	setAnalysisMode -socv true
} elseif { $vars(ocv) == "aocv" } {
	setAnalysisMode -aocv true
} else {
	puts "use flat ocv!"
}

##setTrialRouteMode

#setMaxRouteLayer $vars(max_route_layer)
#setTrialRouteMode -maxRouteLayer $vars(max_route_layer)
#setTrialRouteMode -minRouteLayer $vars(min_route_layer)
#setTrialRouteMode -honorClockSpecNDR true

#if {$vars(cong_cri_mode) == "true"} {
#	setTrialRouteMode -highEffort true
#}
#if {$vars(lp_mode) == "true"} {
#	setTrialRouteMode -handlePDComplex true -handleEachPD true
#}

##set nanoroute mode

setNanoRouteMode -routeWithViaInPin true
setNanoRouteMode -routeTopRoutingLayer $vars(max_route_layer)
setNanoRouteMode -routeBottomRoutingLayer $vars(min_route_layer)
setNanoRouteMode -routeWithViaInPin 1:1
setNanoRouteMode -routeAutoTuneOptionsForAdvancedDesign true
setNanoRouteMode -routeConcurrentMinimizeViaCountEffort high
setNanoRouteMode -routeReserveSpaceForMultiCut false
setNanoRouteMode -droutePostRouteSwapVia false
setNanoRouteMode -routeWithTimingDriven true
setNanoRouteMode -routeWithSiDriven true
setNanoRouteMode -routeSiEffort high
setNanoRouteMode -routeWithLithoDriven true
setNanoRouteMode -dbViaWeight $vars(via_weight)
setNanoRouteMode -drouteExpSwapViaAfterEcoRoute false
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

##setSIMode

setSIMode -report_si_slew_max_transition true -acceptableWNS 0
setSIMode -analysisType aae -separate_delta_delay_on_data true -delta_delay_annotation_mode lumpedOnNet -enable_glitch_report true -si_reselection all

##other setting

set cmd "set_analysis_view $vars(postroute_analysis_view)"
eval $cmd
report_analysis_view > $vars(rpt_dir)/[dbgDesignName].$vars(step).analysisView.$vars(view_rpt).rpt

set_interactive_constraint_modes [all_constraint_modes -active]

setDontUse * false
foreach cell $vars(dont_use_cells) {
	setDontUse $cell true
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
source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/scripts_1220/uncertainty_invs.tcl

#set timing derate
source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/timing_derate_latest.tcl
report_timing_derate
###0202johnny
set_interactive_constraint_modes [all_constraint_modes -active]
#set_interactive_constraint_modes {scan}
set_propagated_clock [all_clocks]

##create path group

reset_path_group -all
source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/path_group.tcl
source -e -v ../scr/user_path_group.tcl
deleteFiller -keepFixed -prefix FILL
deleteFiller -keepFixed -prefix DCAP

##user defined
source -e -v ../scr/pre_postRoute.tcl
##postRoute opt setup

###opt crucial path
source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/scripts/util/ZZL_CrucialOpt.tcl	

optdesign -postRoute -expandedViews -outDir $vars(rpt_dir) -prefix [dbgDesignName].postrouteOptSetup1.$vars(view_rpt)
#timeDesign -expandedViews -numPaths 5000 -postRoute -expandReg2Reg -prefix [dbgDesignName].postRouteOptsetup1.$vars(view_rpt) -outDir $vars(rpt_dir)
saveDesign $vars(dbs_dir)/[dbgDesignName].postRouteOptSetup1.$vars(view_rpt).enc
if {$vars(timing_cri_mode) == "true"} {
	#setOptMode -usefulSkew true
	optdesign -incr -postRoute -expandedViews -outDir $vars(rpt_dir) -prefix [dbgDesignName].postrouteOptsetup2.$vars(view_rpt)
	saveDesign $vars(dbs_dir)/[dbgDesignName].postRouteOptSetup2.$vars(view_rpt).enc
}

##postRoute opt leakage
setOptMode -addInstancePrefix POSTROUTE_FIX_LEAKAGE_
if { $vars(leakage_opt_mode) == "true"} {
	#opt leakage power
	setOptMode -powerEffort high
	setOptMode -leakageToDynamicRatio 1.0
	setOptMode -allowOnlyCellSwapping true
	set pwrRptView [lindex [all_hold_analysis_views] 0]
	set_power_analysis_mode -analysis_view $pwrRptView
	report_power -leakage -view $pwrRptView -outfile $vars(rpt_dir)/[dbgDesignName].$vars(step).leakageBeforeOpt.$vars(view_rpt).rpt
	optPower -postroute -effortLevel high -allowResizing
	report_power -leakage -view $pwrRptView -outfile $vars(rpt_dir)/[dbgDesignName].$vars(step).leakageAfterOpt.$vars(view_rpt).rpt
	setOptMode -allowOnlyCellSwapping false

	#perform only cell vt swap for timing improvements
	#setOptMode -allowOnlyCellSwapping true
	#optDesign -postRoute -expandedViews -outDir $vars(rpt_dir) -prefix [dbgDesignName].$vars(step).afterLeakageOpt.$vars(view_rpt)
	#report_power -leakage -outfile $vars(rpt_dir)/[dbgDesignName].$vars(step).leakageAfterFixTiming.rpt
	#setOptMode -allowOnlyCellSwapping false
	#saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step).optLeakage.$vars(view_rpt).enc
}

##postRoute opt hold


if {$vars(hold_fix_mode) == "true" } {
	set cmd "set_analysis_view $vars(postroute_analysis_view)"
	eval $cmd
	report_analysis_view > $vars(rpt_dir)/[dbgDesignName].postroutehold.$vars(step).analysisView.$vars(view_rpt).rpt
	set_interactive_constraint_modes [all_constraint_modes -active]
	#set path hold opt 
	#reset_path_group -all
	#createBasicPathGroups -expanded 
	#setPathGroupOptions reg2reg -effortLevel high
	#setPathGroupOptions in2reg -effortLevel low
	#setPathGroupOptions reg2out -effortLevel low
	#setPathGroupOptions in2out -effortLevel low
	#setPathGroupOptions reg2cgate -effortLevel high 

	setOptMode -holdFixingEffort high
	setOptMode -addInstancePrefix POSTROUTE_FIXHOLD_
	setOptMode -fixHoldAllowSetupTnsDegrade false
	setOptMode -ignorePathGroupsForHold {in2reg reg2out in2out}
	setOptMode -setupTargetSlack 0.01 -holdTargetSlack 0.0
	setOptMode -maxLocalDensity 0.9
	#setOptMode -holdInterleavedFlow setupAndDRV
	setAnalysisMode -checkType hold
	#setOptMode -fixHoldAllowResizing auto
	#setOptMode -fixHoldSearchRadius 20
	#setOptMode -holdSlackFixingThreshold <slack>
	#setOptMode -holdFixingCells <list_of_buffers>
	
	foreach cc $vars(hold_fix_cells) {
		setDontUse $cc false
		set_dont_touch $cc false
	}

	if {[info exists vars(hold_fix_cells)] && $vars(hold_fix_cells) != ""} {
		setOptMode -holdFixingCells $vars(hold_fix_cells)
	}

	optdesign -postRoute -hold -expandedViews -outDir $vars(rpt_dir) -prefix [dbgDesignName].postRouteOptHold.$vars(view_rpt)
	#timeDesign -expandedViews -numPaths 5000 -postRoute -hold -expandReg2Reg -prefix [dbgDesignName].$vars(step).postRouteOpthold.$vars(view_rpt) -outDir $vars(rpt_dir)
	foreach cc $vars(hold_fix_cells) {
		setDontUse $cc true
		set_dont_touch $cc true
	}

	setAnalysisMode -checkType setup
	
	saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step).hold.$vars(view_rpt).enc
}

	
#setOptMode -addInstancePrefix POSTROUTE_POSTHOLD_SETUP_
#
#setAnalysisMode -checkType setup
#optdesign -postRoute -expandedViews -outDir $vars(rpt_dir) -prefix [dbgDesignName].postHold_setupOpt.$vars(view_rpt)
##timeDesign -expandedViews -numPaths 5000 -postRoute -reportOnly -prefix [dbgDesignName].postHold_setupOpt.$vars(view_rpt) -outDir $vars(rpt_dir)
#saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step).postHold_setupOpt.$vars(view_rpt).enc

##DFM wire/via opt
#DFM VIA Naming Style
#
# *FBD*		:	Priority 1,
# *FBS*		:	Priority 2,
# *PBD*		:	Priority 3,
# *PBS*		:	Priority 4,
# *2cut_p1*	:	Priority 5-1,
# *2cut_p2*	:	Priority 5-2,
# *2cut_p3*	:	Priority 5-3,
# *FAT*	:	Priority 6,
#source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/path_group.tcl
if { $vars(dfm_opt_mode) == "true" } {
	setNanoRouteMode -dbViaWeight $vars(via_weight_dfm)
	setNanoRouteMode -routeWithTimingDrive true
	setNanoRouteMode -droutePostRouteSpreadWire true -drouteMinLengthForWireSpreading 2
	setNanoRouteMode -droutePostRouteSwapVia none
	setNanoRouteMode -drouteMinSlackForWireOptimization 0.1
	setNanoRouteMode -routeDesignFixClockNets true
	routeDesign -wireOpt

	setNanoRouteMode -routeWithTimingDrive false
	setNanoRouteMode -droutePostRouteSpreadWire false 
	setNanoRouteMode -drouteMinSlackForWireOptimization 0
	setNanoRouteMode -droutePostRouteWidenWire none
	setNanoRouteMode -droutePostRouteSwapVia multiCut
	setNanoRouteMode -drouteUseMultiCutViaEffort high
	setNanoRouteMode -drouteExpAllowNonPreferApa true
	routeDesign -viaOpt

	setNanoRouteMode -droutePostRouteSwapVia none
	setNanoRouteMode -drouteUseMultiCutViaEffort low
	setNanoRouteMode -routeWithTimingDrive true
	setNanoRouteMode -routeDesignFixClockNets false
	
	#reset_path_group -all
	#if {1} {
	#	createBasicPathGroups -expanded
	#	group_path -from [get_cells -hier * -filter "@is_memory_cell == true"] -to [all_registers] -name m2r
	#	group_path -to [get_cells -hier * -filter "@is_memory_cell == true"] -from [all_registers] -name r2m
	#	group_path -from [remove_from_collection [all_registers] [get_cells -hier * -filter "@is_memory_cell == true"]] -to [remove_from_collection [all_registers] [get_cells -hier * -filter "@is_memory_cell == true"]] -name r2r
	#	setPathGroupOptions m2r -effortLevel high
	#	setPathGroupOptions r2m -effortLevel high
	#	setPathGroupOptions r2r -effortLevel high
	#	setPathGroupOptions reg2reg -effortLevel high
	#	setPathGroupOptions reg2cgate -effortLevel high
	#	setPathGroupOptions in2reg -effortLevel low
	#	setPathGroupOptions reg2out -effortLevel low
	#	setPathGroupOptions in2out -effortLevel low
	#} else {
	#	createBasicPathGroups -expanded
	#	setPathGroupOptions reg2reg -effortLevel high
	#	setPathGroupOptions reg2cgate -effortLevel high
	#	setPathGroupOptions in2reg -effortLevel low
	#	setPathGroupOptions reg2out -effortLevel low
	#	setPathGroupOptions in2out -effortLevel low
	#}
	
	setOptMode -addInstancePrefix POSTROUTE_DFM_SETUP_
	setAnalysisMode -checkType setup
	optDesign -postRoute -incr -expandedViews -outDir $vars(rpt_dir) -prefix [dbgDesignName].postDFM_setupOpt.$vars(view_rpt)
	#timeDesign -expandedViews -numPaths 5000 -postRoute -reportOnly -prefix [dbgDesignName].postDFM_setupOpt.$vars(view_rpt) -outDir $vars(rpt_dir)
	saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step).postDFM_setupOpt.$vars(view_rpt).enc
	timeDesign -expandedViews -postRoute -hold -prefix [dbgDesignName].postDFM_setupOpt.$vars(view_rpt) -outDir $vars(rpt_dir)
}


## check filler

#if {[checkFiller -reportGap [expr $vars(min_gap)/2]] == "0"} {
#	addFillerGap $vars(min_gap) -effort high
#	ecoRoute
#}


##verify drc

checkRoute
verifyConnectivity -noAntenna -error 10000 -warning 1000 -report $vars(rpt_dir)/[dbgDesignName].$vars(step).verifyConnectivity.$vars(view_rpt).rpt
verify_drc -limit 10000 -report $vars(rpt_dir)/[dbgDesignName].$vars(step).verify_drc.$vars(view_rpt).rpt

##power reports

report_power -outfile $vars(rpt_dir)/[dbgDesignName].$vars(step).power_final.$vars(view_rpt).r
report_power -leakage -outfile $vars(rpt_dir)/[dbgDesignName].$vars(step).leakage_final.$vars(view_rpt).rpt

### lower power report

if {$vars(lp_mode) == "true"} {
	verifyPowerDomain -allInstInPD -bind -isoNetPD $vars(rpt_dir)/[dbgDesignName].$vars(step).lpIsoNetVio.$vars(view_rpt).rpt \
		-xNetPD $vars(rpt_dir)/[dbgDesignName].$vars(step).lpShifterNetVio.$vars(view_rpt).rpt \
		-place -place_rpt $vars(rpt_dir)/[dbgDesignName].$vars(step).lpPlaceVio.$vars(view_rpt).rpt
	reportPowerDomainCrossingNets -ignoreMinGap -file $vars(rpt_dir)/[dbgDesignName].$vars(step).lpCrossingNets.rpt
}

## collect rpt

userRunTimeCalculation -end

#summary design
summarizeDesign $vars(rpt_dir)/[dbgDesignName].$vars(step).design_summary.$vars(view_rpt).rpt
###user defined
source -e -v ../scr/post_postRoute.tcl

##save database
um::pop_snapshot_stack
create_snapshot -name $vars(step) -categories design
report_metric -file $vars(rpt_dir)/metrics.html -format html
saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step).$vars(view_rpt).enc
redirect  -file $vars(rpt_dir)/runtime.rpt   {runTime $vars(step) $start}

## extract lib/lef

source ../scr/util/userExtractLibLef.tcl
#userExtractLibLef


puts " ending $vars(step) step..."
exit
