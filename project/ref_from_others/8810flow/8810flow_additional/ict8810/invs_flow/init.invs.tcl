#---------------------------------begin initial---------------------------------------------------
set start [clock seconds]
source ../scr/setup.invs
set vars(view_from) $env(view_from)
set vars(view_rpt) $env(view_rpt)
set vars(step) init
#source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/scripts/defineInput.tcl
source ../scr/defineInput.tcl
#source /eda_files/proj/ict8810/backend/be8803/scripts/util/proc
set vars(rpt_dir) "$vars(rpt_dir)/$vars(step)/$vars(view_rpt)"
exec mkdir -p $vars(rpt_dir)
##star time
puts "begin $vars(step) step"

setMultiCpuUsage -localCpu 16 -keepLicense true -threadinfo 2
setImportMode -reset
setLibraryUnit -cap 1pf -time 1ns
set init_remove_assigns 1
setDoAssign on -buffer $vars(assign_buffer_cell) -prefix assign_fix_

###user defined
source -e -v ../scr/pre_init.tcl

puts "import data"
source ../scr/global.invs
init_design

um::enable_metrics -on
um::push_snapshot_stack
setDesignMode -process $vars(process) -flowEffort standard

set_global timing_cppr_remove_clock_to_data_crp true ;
set_global report_timing_format {instance cell arc fanout load slew delay arrival}
set_global timing_clock_phase_propagation both
set_global timing_remove_clock_reconvergence_pessimism true
set_global timing_use_latch_time_borrow true
set_global timing_case_analysis_for_sequential_propagation false
set_global timing_case_analysis_for_icg_propagation false
set_global timing_use_latch_early_launch_edge false
set_global report_precision 3
source  /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/invs_check/invs_common_setting.tcl
source  /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/common_setting.tcl
source  /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/ndr.tcl



###globalNetConnect
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/Global_Net_Connection.tcl

## floorplan def
defIn $vars(fp_def)

## timing derate
#source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/timing_derate.tcl
source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/timing_derate_latest.tcl
redirect  -file $vars(rpt_dir)/$vars(design).timing_derate.rpt   {report_timing_derate}

## scan def
if {$vars(scan_reoder_mode) == "true" && [file exists $vars(scan_def)]} {
setFinishFPlanMode -drcRegionObj nonRowArea
defIn $vars(scan_def)
}


##dontuse
foreach cell $vars(dont_use_cells) {
	setDontUse $cell true
}
## path group
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/path_group.tcl

set cmd "set_analysis_view $vars(cts_analysis_view)"
eval $cmd

set_interactive_constraint_modes [all_constraint_modes -active]
timeDesign -preplace -expandedViews  -prefix [dbgDesignName].$vars(step).$vars(view_rpt) -outDir $vars(rpt_dir)
timeDesign -preplace -expandedViews -hold -prefix [dbgDesignName].$vars(step).hold.$vars(view_rpt) -outDir $vars(rpt_dir)

checkDesign -all -outdir $vars(rpt_dir)/checkDesign
redirect -file $vars(rpt_dir)/$vars(design).check_timing.rpt   {check_timing -verbose}

#eg userSwapCKTree ehvt
userSwapCKTree

reportGateCount
reportGateCount -stdCellOnly
source -e -v ../scr/post_init.tcl

um::pop_snapshot_stack
create_snapshot -name $vars(step) -categories design
report_metric -file $vars(rpt_dir)/metrics.html -format html
saveDesign $vars(dbs_dir)/[dbgDesignName].floorplan.$vars(view_rpt).enc
redirect  -file $vars(rpt_dir)/runtime.rpt   {runTime $vars(step) $start}
puts "end $vars(step) step"

exit
