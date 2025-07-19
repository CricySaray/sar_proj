#begin------------------------------------------------------------------------------------------------------------------
set start [clock seconds]
source ../scr/setup.invs
set vars(view_from) $env(view_from)
set vars(view_rpt) $env(view_rpt)
set vars(pre_step) floorplan
set vars(step) place
source ../scr/defineInput.tcl

set vars(rpt_dir) "$vars(rpt_dir)/$vars(step)/$vars(view_rpt)"
exec mkdir -p $vars(rpt_dir)

puts "Begin run $vars(step) step start..."
date

userRunTimeCalculation -start
##restore floorplan database

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
##set timing report fromat

source  /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/invs_check/invs_common_setting.tcl
source  /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/common_setting.tcl
source  /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/ndr.tcl

##set place mode

#setFillerMode -core $vars(filler_cells) -fitGap true
#setPlaceMode -fillerGapEffort high -fillerGapMinGap $vars(min_gap) ;#40/28
setPlaceMode -place_detail_legalization_inst_gap 2
setPlaceMode -place_detail_preserve_routing true
setPlaceMode -placeIoPins false
setPlaceMode -place_global_uniform_density true
#add by cjy,used to fix pg cut spacing violation with obs in std cell
setPlaceMode -place_detail_use_check_drc true
setPlaceMode -place_detail_check_cut_spacing true
#for arm lib
setPlaceMode -checkImplantWidth true
setPlaceMode -honorImplantSpacing true
setPlaceMode -checkImplantMinArea true
#for soft_guide
setPlaceMode -place_global_soft_guide_strength medium

#NP block set 
editDelete -net vdd09 -layer ME1 -shape FOLLOWPIN


##timing critical setting

if {$vars(timing_cri_mode) == "true"} {
	setLimitedAccessFeature flow_effort_xtreme 1
	setDesignMode -flowEffort extreme
}

##VP setting

if {$vars(vp_mode) == "true"} {
}

##congestion setting

if {$vars(cong_cri_mode) == "true"} {
	setPlaceMode -autoModulePadding true
	setPlaceMode -congEffort high
}

##quick cts flow setting

if {$vars(early_cts_mode) == "true"} {
	setPlaceMode -quickCTS true
	set_ccopt_property buffer_cells $vars(ccopt_buf_cells)
	set_ccopt_property inverter_cells $vars(ccopt_inv_cells)
	set_ccopt_property add_driver_cell $vars(cts_driver_cells)
	set_ccopt_property use_inverters auto
	set_ccopt_property cell_density 0.3
	set_ccopt_property target_skew $vars(cts_skew)
	set_ccopt_property target_max_trans $vars(cts_tran)
	set_ccopt_property max_source_to_sink_net_length $vars(cts_length)
	set_ccopt_property max_fanout $vars(cts_faout)
	create_route_type -name specialRoute -top_preferred_layer $vars(leaf_top_pref_layer) -bottom_preferred_layer $vars(leaf_btm_pref_layer) -non_default_rule $vars(cts_ndr)
	set_ccopt_property route_type -net_type leaf specialRoute
	set_ccopt_property route_type -net_type trunk specialRoute
}

##lowpower flow setting
if {$vars(lp_mode) == "true"} {
	setPlaceMode -place_detail_fixed_shifter true
	setPlaceMode -maxShifterDepth $vars(max_shifter_depth)
	setPlaceMode -maxShifterRowDepth $vars(max_shifter_depth)
	setPlaceMode -maxShifterRowDepth $vars(max_shifter_depth)
	setPlaceMode -maxShifterColDepth $vars(max_shifter_depth)
}

##MB flow setting

if {$vars(merge_ffs) == "true"} {
	#mb flow
	setLimitedAccessFeature FlipFlopMergeAndSplit 1
	#setOptMode -MBFFMergeEvaluateTiming true; #default false
	setOptMode -multiBitFlopOpt true
	setOptMode -multiBitFlopOptIgnoreSDC false
}


#Leon fix @03/23
if {$vars(cellPad_mode) == "true"} {
        foreach {cell num} $vars(padding_cells) {
        if {[dbGet -e head.libCells.name $cell] != "" } {
                    specifyCellPad $cell -left $num -right $num
        }
        }
}


##setOptMode

setOptMode -addInstancePrefix Place_Setup
setOptMode -reclaimArea true ;
setOptMode -fixFanoutLoad true
setOptMode -expLayerAwareOpt true
setOptMode -allEndPoints true
setOptMode -maxLength $vars(opt_max_length)
setOptMode -bufferAssignNets true
setOptMode -simplifyNetlist $vars(simplify_mode)
setOptMode -usefulSkew false -usefulSkewPreCTS false
#setOptMode -preserveModuleFunction true; #Enables preserving logical functions at hierarchical ports
setOptMode -powerEffort none
#setOptMode -leakageToDynamicRatio 1.0
setOptMode -maxLocalDensity 0.8
#setOptMode -maxLocalDensity 0.8
#setOptMode -maxDensity 0.95
#setOptMode -preserveModuleFunction true
#add by cjy,used to report more timing path
#setOptMode -timeDesignNumPaths 1000

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

##setDelayCalMode

setDelayCalMode -honorSlewPropConstraint true
setDelayCalMode -equivalent_waveform_model_type ecsm
setDelayCalMode -equivalent_waveform_model propagation
if {$vars(ocv) == "socv"} {
	setDelayCalMode -socv_accuracy_mode low -sgs2set {useNdwOnPBAStartPoint:true} -enable_quiet_receivers_for_hold true -equivalent_waveform_model_type ecsm -equivalent_waveform_model propagation -socv_lvf_mode early_late -honorSlewPropConstraint true
    set_global timing_report_max_transition_check_using_nsigma_slew true
	set_socv_reporting_nsigma_multiplier -transition 3
}

##setTrialRouteMode

#setMaxRouteLayer $vars(max_route_layer)
#setTrialRouteMode -maxRouteLayer $vars(max_route_layer)
#setTrialRouteMode -honorClockSpecNDR true

if {$vars(cong_cri_mode) == "true"} {
	setTrialRouteMode -highEffort true
}

if {$vars(lp_mode) == "true"} {
#	specifySelectiveBlkgGate -cell $vars(pso_cell)
	setTrialRouteMode -handlePDComplex true -handleEachPD true
}

## ISO buffer for port
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/invs_check/design_invs.tcl
if {[regexp A7P $vars(io_attach_cell)]} {
	design::insert_iso_buffer -input "BUF_X4B_A7PP140ZTS_C30 4" -output "BUF_X4B_A7PP140ZTS_C30 4" -clock "$vars(io_attach_cell) 6"
} else {
	design::insert_iso_buffer -input "BUF_X4B_A9PP140ZTS_C30 4" -output "BUF_X4B_A9PP140ZTS_C30 4" -clock "$vars(io_attach_cell) 6"
}


#handel occ soft_guide
#userHandleOcc

### sdc update

#set_global timing_defer_mmmc_object_updates true
#update_constraint_mode -name func -sdc_files $vars(sdc_func)
#set_analysis_view -update_timing
#set_global timing_defer_mmmc_object_updates false

set cmd "set_analysis_view $vars(place_analysis_view)"
eval $cmd
report_analysis_view > $vars(rpt_dir)/[dbgDesignName].$vars(step).analysisView.$vars(view_rpt).rpt

set_interactive_constraint_modes [all_constraint_modes -active]
#set_clock_uncertainty -setup 0.1 [all_clocks]
if {$vars(feed_through)} {
	create_clock -name vir_FEED_clk -period 40 -waveform { 0 20 }
	foreach portPtr [dbGet [dbGet -p top.terms.name *BE_FEED*]] {
		if { [dbGet $portPtr.direction] == "input" } {
			set_input_delay -add_delay 0.1  -clock [get_clocks {vir_FEED_clk}] [get_ports [dbGet $portPtr.name]]
		} else {
			set_output_delay -add_delay 0.1  -clock [get_clocks {vir_FEED_clk}] [get_ports [dbGet $portPtr.name]]
		}
	}
	set_max_delay 0.2 -through *BE_FEED*
	source ../work/[dbgDesignName]_feedthroughclockport.rpt -v
}

set_clock_gating_check -setup $vars(clock_gating_margin)
set_clock_gating_check -setup $vars(clock_gating_margin) [get_pins -hier */E -filter "is_hierarchical==false"]
set_clock_gating_check -setup $vars(clock_gating_margin) [get_pins -hier */TE -filter "is_hierarchical==false"]

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
source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/last/uncertainty_invs.tcl

source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/timing_derate_latest.tcl

setAnalysisMode -cppr both
setAnalysisMode -analysisType onChipVariation

if { $vars(ocv) == "socv" } {
	setAnalysisMode -socv true
} elseif { $vars(ocv) == "aocv" } {
	setAnalysisMode -aocv true
} else {
	puts "flat ocv!"
}
#specify clock spec
#userNetWeight ISO I 15

##create path groups

reset_path_group -all

source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/path_group.tcl
source -e -v ../scr/user_path_group.tcl

setAnalysisMode -checkType setup

## pre_place std close to block

#selectInstByCellName RAM*
#set ram_list [dbGet selected.name]
#place_connected -attractor $ram_list -attractor_pin xxx* -ignore_soft_blockage -sequential all_connected -move_fixed

##reorder scan

if {$vars(scan_reoder_mode) == "true" && [file exists $vars(scan_def)]} {
	setPlaceMode -reorderScan true
	setPlaceMode -place_global_reorder_scan true
	setScanReorderMode -scanEffort high -skipMode skipBuffer
#	defIn $vars(scan_def)
} else {
	#defIn $vars(scan_def)
	if { [regexp ^15 [getVersion]] } {
		setPlaceMode -ignoreScan false; #innovus 15.26
	} else {
		setPlaceMode -place_global_ignore_scan false
        setPlaceMode -place_global_exp_allow_missing_scan_chain true
	}
}

###user defined
source -e -v ../scr/pre_place.tcl

##execute script bettween global place and placeOpt

#setPlaceMode -place_opt_post_place_tcl ../scr/unplaceRegion
setPlaceMode -place_opt_post_place_tcl ../scr/place_opt_plug.tcl
##place_design
place_opt_design -expanded_views -out_dir $vars(rpt_dir) -prefix [dbgDesignName].$vars(step).$vars(view_rpt)

##check and report
setLayerPreference net -isVisible 0
setLayerPreference power -isVisible 0
setLayerPreference pg -isVisible 0
setLayerPreference metalFill -isVisible 0
setLayerPreference congest -isVisible 1
setDrawView place
clearDrc
dumpToGIF $vars(rpt_dir)/[dbgDesignName].$vars(step).congestionMap.$vars(view_rpt).gif
checkPlace $vars(rpt_dir)/[dbgDesignName].$vars(step).checkPlace.$vars(view_rpt).rpt

##insert spare cell
if {$vars(early_cts_mode) == "true"} {
	delete_ccopt_clock_tree_spec
}


## report ignore net and big fanout

reportIgnoredNets -outfile $vars(rpt_dir)/[dbgDesignName].$vars(step).optIgnoreNets.$vars(view_rpt).rpt
report_net -min_fanout 100 -output $vars(rpt_dir)/[dbgDesignName].$vars(step).netFanout_list.$vars(view_rpt).rpt

##add tie cell

set_interactive_constraint_modes [all_constraint_modes -active]
userAddTieCells
#addTieHiLo  -cell  $vars(tie_cells)

## secondary Poewr/Ground routing
# set low power cell status

if {[info exists vars(route_secondary_pg)] && $vars(route_secondary_pg) == "true"} {
	#globalNetConnect VDD_CORE -type pgpin -pin VDDL -inst * -powerDomain PD_CPU
	foreach n $vars(route_secondary_pg_nets) {
		setAttribute -net $n -avoid_detour true -bottom_preferred_routing_layer $vars(route_secondary_bottomLayer) \
			-top_preferred_routing_layer $vars(route_secondary_topLayer)
	}
	setNanoRouteMode -dbViaWeight $vars(via_weight)
	setPGPinUseSignalRoute $vars(route_secondary_PGPin)
	routePGPinUseSignalRoute -nets $vars(route_secondary_pg_nets) -pattern $vars(route_secondary_pg_pattern) \
				-nonDefaultRule $vars(route_secondary_pg_ndr) -maxFanout $vars(route_secondary_pg_maxFanout)
	foreach n $vars(route_secondary_pg_nets) {
		dbSetNetWireStatus [dbGetNetByName $n] dbcFixedWire
	}

	set cell_list ""
	foreach cc $vars(route_secondary_PGPin) {
		regsub ":.*" $cc  cc
		foreach_in_collection ccPtr [get_lib_cells $cc] {
			lappend cell_list [get_property $ccPtr name]
		}
	}

	dbForEachCellInst [dbgTopCell] instPtr {
		set InstName [dbget $instPtr.name]
		set cell [dbget [dbInstCell $instPtr].name]
		if {[lsearch $cell_list $cell] != -1} {
			dbset $instPtr.isDontTouch 1
		}
	}
	#convertNetToSNet -nets $vars(route_secondary_pg_nets)
}

if {$vars(lp_mode)=="true"} {
	userFixIsoPlacement
	userFixAonBufferPlacement
	userFixShifterPlacement
	userFixRetentionPlacement
}

### report

report_power -outfile $vars(rpt_dir)/[dbgDesignName].$vars(step).power.$vars(view_rpt).rpt
report_power -leakage -outfile $vars(rpt_dir)/[dbgDesignName].$vars(step).leakage.$vars(view_rpt).rpt

# lower power report

if {$vars(lp_mode) == "true"} {
	verifyPowerDomain -allInstInPD -bind -isoNetPD $vars(rpt_dir)/[dbgDesignName].$vars(step).lpIsoNetVio.$vars(view_rpt).rpt \
			-xNetPD $vars(rpt_dir)/[dbgDesignName].$vars(step).lpShifterNetVio.$vars(view_rpt).rpt \
			-place -place_rpt $vars(rpt_dir)/[dbgDesignName].$vars(step).lpPlaceVio.$vars(view_rpt).rpt
	reportPowerDomainCrossingNets -ignoreMinGap -file $vars(rpt_dir)/[dbgDesignName].$vars(step).lpCrossingNets.rpt
}

#density map

setPlaceMode -includeFixed true
reportDensityMap -threshold 0
setPlaceMode -reset -includeFixed 

## summary report

#summarizeDesign $vars(rpt_dir)/summary.rpt

# check filler

checkFiller -reportGap [expr $vars(min_gap)/2] -file $vars(rpt_dir)/[dbgDesignName].$vars(step).checkFiller_gap.$vars(view_rpt).rpt
addFillerGap $vars(min_gap) -effort high
clearDrc

#summary design
userRunTimeCalculation -end
summarizeDesign $vars(rpt_dir)/[dbgDesignName].$vars(step).design_summary.$vars(view_rpt).rpt
## extract lib/lef

#source ../scr/util/userExtractLibLef.tcl
#userExtractLibLef
## save database
um::pop_snapshot_stack
create_snapshot -name $vars(step) -categories design
report_metric -file $vars(rpt_dir)/metrics.html -format html
saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step).$vars(view_rpt).enc
redirect  -file $vars(rpt_dir)/runtime.rpt   {runTime $vars(step) $start}


###user defined
source -e -v ../scr/post_place.tcl

puts " ending $vars(step) step..."
exit
