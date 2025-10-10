####################################################################
# Innovus Foundation Flow Code Generator, Sun Jun 11 00:07:17 CST 2023
# Version : 19.11-s001_1
####################################################################
set vars(pre_step) init
set vars(step) floorplan
set vars(floorplan,start_time) [clock seconds]
source ../scr/setup.tcl -e -v

set vars(rpt_dir) "$vars(rpt_dir)/$vars(step)"
exec mkdir -p $vars(rpt_dir)

set restore_db_file_check 0
restoreDesign $vars(dbs_dir)/$vars(design).$vars(pre_step).enc.dat $vars(design)

return
defIn $vars(def_files)

generateTracks -honorPitch
source ../scr/util/create_io_row.tcl -e -v
cutRow

source ../scr/PLUG/pre_floorplan.tcl -e -v

setObjFPlanBoxList Group PD_ANA [join [dbGet [dbGet top.insts.name u_afe_core -p].boxes]]
setObjFPlanBoxList Group PD_AON {148.035 2566.0 210 2635.3}
setObjFPlanBoxList Group PD_AON_SLP {148.035 2381.9 210 2564.6}
setObjFPlanBoxList Group PD_AON_IO {129.975 2381.9 146.775 2874.9935}
setObjFPlanBoxList Group PD_DBB {1008.055 664.8 1979.935 2360.2} {1225.615 142.6 1979.935 664.8}

fixAllIos
setInstancePlacementStatus -allHardMacros -status fixed 

set boxes {{835.435 730.6 913.555 809.0} {835.435 950.4 913.555 1029.5} {835.155 1169.5 913.275 1248.6} {835.435 1297.6 913.555 1376.0} {835.435 1492.9 913.555 1572.0} {835.435 1603.5 913.555 1681.9} {835.435 1713.4 913.555 1791.8} {845.655 2076.0 923.775 2154.4} {845.515 2283.2 923.635 2361.6} }
foreach box $boxes {
	createPlaceBlockage -type hard -box $box -name pad_blk
}

source  ../scr/util/lp/lp_config.tcl -echo -verbose 
source ../scr/util/add_endCap.tcl -echo -verbose
source ../scr/util/add_wellTap.tcl -echo -verbose

verifyEndCap -report $vars(rpt_dir)/[dbgDesignName].$vars(step).endcap.rpt
verifyWellTap -report $vars(rpt_dir)/[dbgDesignName].$vars(step).welltap.rpt

placeInstance  u_aon_top/u_pd_aon_top/u_dft_pd_aon_pad_power_switch_mux/CKMUX2__dont_touch  {150.135 2568.1}
placeInstance  u_aon_top/u_pd_aon_top/u_dft_pd_slp_power_switch_mux/CKMUX2__dont_touch      {203.475 2568.1}

createRouteBlk -boxList  [join [dbShape [dbGet [dbGet top.insts.name -regexp {esd_a|esd_b|u_core_top/u_efuse_ctrl_sys/u_64x32_efuse|u_core_top/u_cc312_wrapper/u_efuse_ctrl_cc312/u_64x32_efuse} -p].boxes] SIZE 30]]  -layer {M1 M2 M3 M4 M5 M6} -name efuse_power_rlk -spacing 0

source  ../scr/util/lp/lp_config.tcl -echo -verbose 
redirect -tee pg_connect.log {source  ../scr/util/lp/pg_connection.tcl -v -e}
#source  ../scr/util/lp/pg_connection.tcl    -echo  -verbose
redirect -tee add_pso.log {source  ../scr/util/lp/add_powerSwitch.tcl  -v -e}
source  ../scr/util/lp/add_power.tcl        -echo  -verbose
deleteRouteBlk -name efuse_power_rlk
source  ../scr/util/lp/add_powerVia.tcl     -echo  -verbose

set boxes "{129.975 2379.1 280.195 3140.0} {130.115 2328.7 740.095 2380.5}"
foreach box $boxes {
        set box [join $box]
        lassign  $box llx lly urx ury 
        add_partial_lhy 50 30 $llx $lly $urx $ury
}
set boxes "{1356.375 1966.1 1628.815 2023.5} {835.435 1572.0 913.555 1603.5} {835.435 1681.9 913.555 1713.4} {845.515 2361.6 923.635 2380.0}"
foreach box $boxes {
        set box [join $box]
        lassign  $box llx lly urx ury 
        add_partial_lhy 60 30 $llx $lly $urx $ury
}

#lassign [join [join [dbGet [dbGet top.pds.name PD_AON_SLP -p].group.boxes]]] llx lly urx ury
#add_partial_lhy 60 10 $llx $lly $urx $ury
#
#lassign [join [join [dbGet [dbGet top.pds.name PD_AON -p].group.boxes]]] llx lly urx ury
#add_partial_lhy 60 10 $llx $lly $urx $ury

setFinishFPlanMode -activeObj {macro macroHalo core iopad iocell fence hardblkg softblkg partialblkg}
#finishFloorplan -fillPlaceBlockage partial 50 -density 5
finishFloorplan -fillPlaceBlockage soft 40

deleteRouteBlk -name efuse_power_rlk
createRouteBlk -boxList  [join [dbShape [dbGet [dbGet top.insts.name -regexp {esd_a|esd_b|u_core_top/u_efuse_ctrl_sys/u_64x32_efuse|u_core_top/u_cc312_wrapper/u_efuse_ctrl_cc312/u_64x32_efuse} -p].boxes] SIZE 30]]  -layer all -cutLayer all -name efuse_power_rlk -spacing 0


#######fix ana2dbb iso cell /added by lee####
saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step).before_fix_iso.enc -tcon
exec rm -rf ./aon_nets.tcl 
source ../scr/util/aon_nets.tcl
specifyCellPad ISO* 2
specifyCellPad PT* 2 
source ../scr/util/iso_fix_dbb.tcl -echo -verbose

##########add tie cell
addNet i_tx_dyn_pwr_ctrl_tx_pa
addInst -cell TIELBWP7T35P140 -inst TIELBWP7T35P140_i_tx_dyn_pwr_ctrl_tx_pa_LO -loc {1978.535 2014.4} -place_status fixed
attachTerm u_afe_core i_tx_dyn_pwr_ctrl_tx_pa i_tx_dyn_pwr_ctrl_tx_pa
attachTerm TIELBWP7T35P140_i_tx_dyn_pwr_ctrl_tx_pa_LO ZN i_tx_dyn_pwr_ctrl_tx_pa

addNet rx0_rfpll_paddr_tie_cell
addInst -cell TIELBWP7T35P140 -inst TIELBWP7T35P140_rx0_rfpll_paddr_LO -loc {1979 883.805} -place_status fixed
attachTerm u_afe_core rx0_rfpll_paddr[15] rx0_rfpll_paddr_tie_cell
attachTerm u_afe_core rx0_rfpll_paddr[14] rx0_rfpll_paddr_tie_cell
attachTerm u_afe_core rx0_rfpll_paddr[13] rx0_rfpll_paddr_tie_cell
attachTerm u_afe_core rx0_rfpll_paddr[12] rx0_rfpll_paddr_tie_cell
attachTerm TIELBWP7T35P140_rx0_rfpll_paddr_LO ZN rx0_rfpll_paddr_tie_cell

##########m7 route
#createRouteBlk -name m7_route_net_rlk -box [dbGet top.fPlan.box] -layer {M1 M2 M3 M4 M5 M6 }
#add_ndr -width {M7 0.5} -name M7_net_rule -generate_via
#foreach term [dbGet [dbGet top.insts.instTerms.layer.name M7 -p2].name] {
#	set net [get_object_name [get_nets -of_objects $term]]
#	setAttribute -net $net -non_default_rule M7_net_rule
#	}
#deselectAll
#foreach term [dbGet [dbGet top.insts.instTerms.layer.name M7 -p2].name] {
#	set net [get_object_name [get_nets -of_objects $term]]
#	selectNet $net
#	}
#setNanoRouteMode -routeSelectedNetOnly true
#setDesignMode -topRoutingLayer M7
#setDesignMode -bottomRoutingLayer M6
#ecoRoute
#deselectAll
#deleteRouteBlk -name m7_route_net_rlk
#setDesignMode -topRoutingLayer M6
#setDesignMode -bottomRoutingLayer M2
#foreach term [dbGet [dbGet top.insts.instTerms.layer.name M7 -p2].name] {
#	set net [get_object_name [get_nets -of_objects $term]]
#	set_dont_touch $net true
#	dbSet [dbGetNetByName $net].wires.status fixed
#	dbSet [dbGetNetByName $net].vias.status fixed
#	setAttribute -net $net -skip_routing true
#}
#setNanoRouteMode -routeSelectedNetOnly false
source ../scr/util/create_physical_pin.tcl -echo -verbose
source ../scr/util/global_tap.tcl

summaryReport -noHtml -outfile  $vars(rpt_dir)/[dbgDesignName].$vars(step).design_summary.rpt
invs_Count_Vt -out $vars(rpt_dir)/[dbgDesignName].$vars(step).invs_Count_Vt.rpt

#um::pop_snapshot_stack
#create_snapshot -name floorplan -categories {flow design setup}
#um::write_metric -file $vars(rpt_dir)/floorplan.json
#um::report_metric -file $vars(rpt_dir)/floorplan.html -format html
saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step).enc

win
#exit

