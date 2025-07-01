# API: 
set design      SC5018_TOP
set pre_step    eco
set step        eco
set startTime   [clock seconds]
set run_root_dir  run
set from_version 0630_invs
set version     0630_eco1
set setup_scenario ""
set hold_scenario  ""
set eco_files   ""

set rpt_dir     $run_root_dir/$version/rpt/$step
set log_dir     $run_root_dir/$version/log/$step
set db_dir      $run_root_dir/$version/db/$step 

# --------------------------------
# DONT CHANGE IT AT WILL
setMultiCpuUsage -localCpu 24
mkdir -p $rpt_dir $log_dir $db_dir
restoreDesign [pwd]/run/$from_version/db/$pre_step/$design.enc.dat $design

set_analysis_view -setup $setup_scenario -hold $hold_scenario
deleteFiller -prefix FILL
setNanoRouteMode -route_detail_end_iteration 50
setEcoMode -reset
setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false
foreach fi $eco_files {
  source -v $fi
}
setEcoMode -reset
setPlaceMode -place_detail_eco_max_distance 15
refinePlace -eco
ecoRoute
source -v addFiller.tcl
source -v dump_data.tcl
saveDesign $db_dir/[dbgDesignName].enc
puts "\nThe eco step ends at : [date] \n"
exit
