####################################################################
# Innovus Foundation Flow Code Generator, Fri Jun  9 10:36:04 CST 2023
# Version : 19.11-s001_1
####################################################################
set vars(pre_step) postcts_hold
set vars(step) route
set vars(route,start_time) [clock seconds]
source ../scr/setup.tcl -e -v

set vars(rpt_dir) "$vars(rpt_dir)/$vars(step)"
exec mkdir -p $vars(rpt_dir)



restoreDesign $vars(dbs_dir)/$vars(design).$vars(pre_step).enc.dat $vars(design) -mmmcFile ../scr/view_definition.tcl


um::enable_metrics -on
um::push_snapshot_stack
set_analysis_view -setup $vars(route,active_setup_views) -hold $vars(route,active_hold_views)
set_interactive_constraint_modes [all_constraint_modes -active]
set_propagated_clock [all_clocks ]
source ../scr/PLUG/always_source.tcl -e -v

source ../scr/util/timingderate.sdc
source ../scr/util/dont_use.tcl -e -v

if {$vars(use_sdc_uncertainty) == "true"} {
	source ../scr/util/postcts_uncertainty.tcl -e -v
} else {
	set_clock_uncertainty  -setup  $vars(clk_uncertainty_setup_prects)  [all_clocks]
	set_clock_uncertainty  -hold   $vars(clk_uncertainty_hold_prects)   [all_clocks]
}


setAnalysisMode -cppr both
setDelayCalMode -siAware true -engine aae

setNanoRouteMode -drouteUseMultiCutViaEffort high -routeWithLithoDriven FALSE
setNanoRouteMode -routeWithViaInPin true
setNanoRouteMode -routeWithViaOnlyForStandardCellPin 1:1

source ../scr/PLUG/pre_route.tcl
#setDontUse *HVT false

setAnalysisMode -analysisType onChipVariation
setNanoRouteMode -droutePostRouteSpreadWire false
getNanoRouteMode
getOptMode
getAnalysisMode
routeDesign
setExtractRCMode -engine postRoute -effortLevel high
source ../scr/PLUG/post_route.tcl

#------------------------report-------------------------------------
timeDesign -expandedViews -numPaths 100 -postRoute -prefix [dbgDesignName].$vars(step) -outDir $vars(rpt_dir)
timeDesign -expandedViews -numPaths 100 -postRoute -hold  -prefix [dbgDesignName].$vars(step) -outDir $vars(rpt_dir)

verifyConnectivity -noAntenna -error 10000 -warning 10000 -report $vars(rpt_dir)/$vars(design).Connectivity.rpt
verify_drc -limit 10000 -report $vars(rpt_dir)/$vars(design).drc.rpt
invs_Count_Vt -out $vars(rpt_dir)/[dbgDesignName].$vars(step).invs_Count_Vt.rpt

um::pop_snapshot_stack
create_snapshot -name route -categories {flow design setup hold route}
um::write_metric -file $vars(rpt_dir)/$vars(step).json
um::report_metric -file $vars(rpt_dir)/$vars(step).html -format html

saveDesign $vars(dbs_dir)/$vars(design).route.enc 

exit

