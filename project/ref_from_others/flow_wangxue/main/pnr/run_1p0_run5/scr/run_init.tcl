####################################################################
# Innovus Foundation Flow Code Generator, Fri Mar 15 14:38:02 CST 2024
# Version : 19.11-s001_1
####################################################################

set vars(step) init
set vars(init,start_time) [clock seconds]
source ../scr/setup.tcl -e -v

set vars(rpt_dir) "$vars(rpt_dir)/$vars(step)"
exec mkdir -p $vars(rpt_dir)


um::enable_metrics -on
um::push_snapshot_stack
source ../scr/PLUG/pre_init.tcl -e -v

source ../scr/global.tcl -e -v

init_design

set_analysis_view -setup $vars(place,active_setup_views) -hold $vars(place,active_hold_views)
set_interactive_constraint_modes [all_constraint_modes -active]
source ../scr/PLUG/always_source.tcl -e -v

if {$vars(use_sdc_uncertainty) == "true"} {
	#source ../scr/util/prects_uncertainty.tcl -e -v
} else {
	set_clock_uncertainty  -setup  $vars(clk_uncertainty_setup_prects)  [all_clocks]
	set_clock_uncertainty  -hold   $vars(clk_uncertainty_hold_prects)   [all_clocks]
}

#ff_procs::source_file
read_power_intent $vars(ieee1801_file) -1801
commit_power_intent -power_domain -keepRows -verbose
#set_power_analysis_mode -analysis_view $vars(power_analysis_view)

defIn $vars(scan_def) 

source ../scr/util/timingderate.sdc
source ../scr/util/dont_use.tcl -e -v


source ../scr/PLUG/post_init.tcl -e -v


#---------------------------report----------------------------------
checkUnique -verbose > $vars(rpt_dir)/[dbgDesignName].$vars(step).checkUnique.rpt
checkNetlist -outfile  $vars(rpt_dir)/[dbgDesignName].$vars(step).checkNetlist.rpt
checkDesign -danglingNet -netlist -physicalLibrary -timingLibrary -noHtml -outfile  $vars(rpt_dir)/[dbgDesignName].$vars(step).checkDesign.rpt
check_timing -verbose > $vars(rpt_dir)/[dbgDesignName].$vars(step).check_timing.rpt
timeDesign -prePlace -expandedViews -prefix [dbgDesignName].$vars(step).setup -outdir $vars(rpt_dir)
summaryReport -noHtml -outfile  $vars(rpt_dir)/[dbgDesignName].$vars(step).design_summary.rpt
invs_Count_Vt -out $vars(rpt_dir)/[dbgDesignName].$vars(step).invs_Count_Vt.rpt

um::pop_snapshot_stack
create_snapshot -name init -categories {flow design setup}
um::write_metric -file $vars(rpt_dir)/init.json
um::report_metric -file $vars(rpt_dir)/init.html -format html

saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step).enc

exit

