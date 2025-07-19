setMultiCpuUsage -localCpu 16
set start [clock seconds]
source ../scr/setup.invs
set vars(view_from) $env(view_from)
set vars(view_rpt) $env(view_rpt)
source ../scr/defineInput.tcl
set vars(step) ecopr
set vars(pre_step) postroute
set vars(rpt_dir) "$vars(rpt_dir)/$vars(step)/$vars(view_rpt)"
exec mkdir -p $vars(rpt_dir)

puts "run $vars(step) step start..."
userRunTimeCalculation -start
##restore route database

if {[info exists vars(debug_mode)] && $vars(debug_mode)=="false" && [file exists $vars(dbs_dir)/$vars(design).$vars(pre_step).$vars(view_from).enc]} {
	restoreDesign $vars(dbs_dir)/$vars(design).$vars(pre_step).$vars(view_from).enc.dat $vars(design)
} else {
    restoreDesign $vars(dbs_dir)/$vars(design).$vars(step).$vars(view_from).enc.dat $vars(design)
}

um::enable_metrics -on
um::push_snapshot_stack

set cmd "set_analysis_view $vars(postroute_analysis_view)"
eval $cmd


source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/invs_check/invs_common_setting.tcl
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/common_setting.tcl
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/ndr.tcl

setNanoRouteMode -routeBottomRoutingLayer 2
setNanoRouteMode -routeTopRoutingLayer $vars(max_route_layer)
setNanoRouteMode -routeWithTimingDriven false
setNanoRouteMode -dbViaWeight $vars(via_weight)
setNanoRouteMode -routeConcurrentMinimizeViaCountEffort high
setNanoRouteMode -drouteVerboseViolationSummary 1
setNanoRouteMode -routeWithViaInPin true
setNanoRouteMode -routeWithViaInPin 1:1
setNanoRouteMode -droutePostRouteSwapVia false
setNanoRouteMode -routeWithEco true

## user defined 
source -e -v ../scr/pre_ecopr.tcl

## add filler
userSaveDesign  -view $vars(view_rpt) -type all -pwr_net $vars(power_nets) -gnd_net $vars(gnd_nets) -addfiller

source -e -v ../scr/post_ecopr.tcl
##save database
um::pop_snapshot_stack
create_snapshot -name $vars(step) -categories design
report_metric -file $vars(rpt_dir)/metrics.html -format html
saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step).$vars(view_rpt).enc
redirect  -file $vars(rpt_dir)/runtime.rpt   {runTime $vars(step) $start}
exit
