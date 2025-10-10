####################################################################
# Innovus Foundation Flow Code Generator, Sun Jun 11 18:09:34 CST 2023
# Version : 19.11-s001_1
####################################################################
set vars(pre_step) place
set vars(step) cts
set vars(cts,start_time) [clock seconds]
source ../scr/setup.tcl -e -v

set vars(rpt_dir) "$vars(rpt_dir)/$vars(step)"
exec mkdir -p $vars(rpt_dir)



restoreDesign $vars(dbs_dir)/$vars(design).$vars(pre_step).enc.dat $vars(design) -mmmcFile ../scr/view_definition.tcl


um::push_snapshot_stack
um::enable_metrics -on 
set_analysis_view -setup $vars(cts,active_setup_views) -hold $vars(cts,active_hold_views)

#set_power_analysis_mode -analysis_view $vars(power_analysis_view)
#report_analysis_views > $vars(rpt_dir)/[dbgDesignName].$vars(step).analysis_view.rpt

set_interactive_constraint_modes [all_constraint_modes -active]
source ../scr/PLUG/always_source.tcl -e -v


if {$vars(use_sdc_uncertainty) == "true"} {
	#source ../scr/util/cts_uncertainty.tcl -e -v
} else {
	set_clock_uncertainty  -setup  $vars(clk_uncertainty_setup_prects)  [all_clocks]
	set_clock_uncertainty  -hold   $vars(clk_uncertainty_hold_prects)   [all_clocks]
}

setDesignMode -process 28
setAnalysisMode -cppr both
set_ccopt_mode  -integration "native" -ccopt_modify_clock_latency true
setNanoRouteMode -drouteUseMultiCutViaEffort high -routeWithLithoDriven FALSE

source ../scr/util/timingderate.sdc -echo -verbose 
source ../scr/PLUG/pre_cts.tcl -echo -verbose 

create_ccopt_clock_tree_spec -file $vars(dbs_dir)/cts.spec
source $vars(dbs_dir)/cts.spec -e -v

getCTSMode
get_ccopt_mode
getOptMode
getAnalysisMode
ccopt_design -outDir $vars(rpt_dir) -prefix [dbgDesignName].$vars(step) -cts -expandedViews
setDontUse CK* true

#------------------------------report-------------------------------
report_ccopt_skew_groups -summary -file $vars(rpt_dir)/$vars(design)_skew_group.rpt
report_ccopt_clock_trees -summary -file $vars(rpt_dir)/$vars(design)_clock_tree.rpt
report_ccopt_clock_tree_structure -show_sinks -file $vars(rpt_dir)/$vars(design)_clock_tree_structure.rpt
report_constraint -all_violators -check_type {pulse_width clock_period pulse_clock_max_width pulse_clock_min_width} > $vars(rpt_dir)/$vars(design).report_constraint.rpt
invs_Count_Vt -out $vars(rpt_dir)/[dbgDesignName].$vars(step).invs_Count_Vt.rpt

timeDesign -expandedViews -numPaths 1000 -postCTS -prefix [dbgDesignName].$vars(step).setup -outDir $vars(rpt_dir)
timeDesign -expandedViews -numPaths 1000 -postCTS -hold  -prefix [dbgDesignName].$vars(step).hold -outDir $vars(rpt_dir)
source ../scr/PLUG/post_cts.tcl -e -v

um::pop_snapshot_stack
create_snapshot -name cts -categories {flow design setup hold clock}
um::write_metric -file $vars(rpt_dir)/$vars(step).json
um::report_metric -file $vars(rpt_dir)/$vars(step).html -format html

saveDesign $vars(dbs_dir)/[dbgDesignName].cts.enc

exit

