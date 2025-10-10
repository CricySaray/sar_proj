####################################################################
# Innovus Foundation Flow Code Generator, Sun Jun 11 00:07:17 CST 2023
# Version : 19.11-s001_1
####################################################################
set vars(pre_step) floorplan
set vars(step) place
set vars(place,start_time) [clock seconds]
source ../scr/setup.tcl -e -v

set vars(rpt_dir) "$vars(rpt_dir)/$vars(step)"
exec mkdir -p $vars(rpt_dir)

set restore_db_file_check 0
restoreDesign $vars(dbs_dir)/$vars(design).$vars(pre_step).enc.dat $vars(design) -mmmcFile ../scr/view_definition.tcl



um::enable_metrics -on
um::push_snapshot_stack
set_analysis_view -setup $vars(place,active_setup_views) -hold $vars(place,active_hold_views)

#set_power_analysis_mode -analysis_view $vars(power_analysis_view)
#report_analysis_views > $vars(rpt_dir)/[dbgDesignName].$vars(step).analysis_view.rpt

set_interactive_constraint_modes [all_constraint_modes -active]
source ../scr/PLUG/always_source.tcl -e -v

source ../scr/util/timingderate.sdc
source ../scr/util/dont_use.tcl -e -v


if {$vars(use_sdc_uncertainty) == "true"} {
	source ../scr/util/prects_uncertainty.tcl -e -v
} else {
	set_clock_uncertainty  -setup  $vars(clk_uncertainty_setup_prects)  [all_clocks]
	set_clock_uncertainty  -hold   $vars(clk_uncertainty_hold_prects)   [all_clocks]
}


setPlaceMode -place_global_cong_effort medium \
   -place_global_clock_gate_aware FALSE \
   -place_global_place_io_pins FALSE
setOptMode -usefulSkew FALSE

source ../scr/PLUG/pre_place.tcl  -e -v
setPlaceMode -place_opt_post_place_tcl ../scr/PLUG/place_opt_plug.tcl

getPlaceMode
getOptMode
place_opt_design -out_dir $vars(rpt_dir) -prefix [dbgDesignName].$vars(step) -expanded_views
saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step)_opt.enc

setDontUse PTBUFF* false
setDontUse PTINV* false
optDesign -drv -selectedNets aon_nets.tcl -precTS
saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step)_incr.enc
##################################
##add by clemence 2025/07/18 for aon long net slack fix , case : prects drv fix crush
#set f1 [open aon_nets.tcl r]
#set aon_nets [read $f1]
#setEcoMode -reset
#setEcoMode -honorDontTouch false -honorDontUse false -honorFixedStatus false -refinePlace false -updateTiming false -batchMode true -prefixName slkdrvfix_for_long_aon_net -honorPowerIntent true
#foreach net $aon_nets {
#       set input_cell [dbGet [dbGet top.insts.instTerms.net.name $net -p3].cell.name -u] 
#       if {![regexp "PTBUF" $input_cell]} {
#       puts "ecoAddRepeater -net $net -cell PTBUFFHDD4BWP7T40P140HVT -spreadDist 300"
#       catch {ecoAddRepeater -net $net -cell PTBUFFHDD4BWP7T40P140HVT -spreadDist 300}
#       } else {
#       puts "INFO: NET: $net already has aon buffer driver/load ,if need fix drv ,pls double check"
#       }
#}
#setEcoMode -reset
#close $f1
##################################
setDontUse PT* true

source ../scr/PLUG/post_place.tcl -e -v

source ../scr/util/addTieCell.tcl -e -v

#----------------------------report---------------------------------
checkPlace $vars(rpt_dir)/[dbgDesignName].$vars(step).checkPlace.rpt
reportIgnoredNets -outfile $vars(rpt_dir)/[dbgDesignName].$vars(step).optIgnoredNets.rpt
report_net -min_fanout 100 -output $vars(rpt_dir)/[dbgDesignName].$vars(step).netFanout_list.rpt
invs_Count_Vt -out $vars(rpt_dir)/[dbgDesignName].$vars(step).invs_Count_Vt.rpt
verifyPowerDomain -allInstInPD -bind \
	-place -place_rpt $vars(rpt_dir)/[dbgDesignName].$vars(step).lp.PlaceVio.rpt \
	-isoNetPD $vars(rpt_dir)/[dbgDesignName].$vars(step).lp.IsoNetVio.rpt \
	-xNetPD $vars(rpt_dir)/[dbgDesignName].$vars(step).lp.ShifterNetVio.rpt \
	-retention $vars(rpt_dir)/[dbgDesignName].$vars(step).lp.retention.rpt \
	-powerSwitch $vars(rpt_dir)/[dbgDesignName].$vars(step).lp.powerSwitch.rpt


um::pop_snapshot_stack
create_snapshot -name place -categories {flow design setup}
um::write_metric -file $vars(rpt_dir)/$vars(step).json
um::report_metric -file $vars(rpt_dir)/place.html -format html

saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step).enc

exit

