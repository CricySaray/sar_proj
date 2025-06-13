#############
clearDrc
deletePlaceBlockage -all
deleteEmptyModule
deleteAllCellPad
deleteInstPad -all
setPlaceMode -place_detail_eco_max_distance 200
######import ECO###############################################
if {[file exists $vars(dbs_dir)/$vars(design).$vars(step).$vars(view_from).enc]} {
	loadECO /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8814/chip_top_idp/sub_proj/lb_ddr4_top/dsn/eco/xtop_opt_innovus_atomic_$vars(view_rpt)_netlist_$vars(design).txt
	source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8814/chip_top_idp/sub_proj/lb_ddr4_top/dsn/eco/xtop_opt_innovus_atomic_$vars(view_rpt)_physical_$vars(design).txt
}
if {[file exists $vars(dbs_dir)/$vars(design).$vars(step).$vars(view_from).enc]} {
	deleteFiller -prefix DCAP_FILL
	deleteFiller -prefix FILL
    setEcoMode -reset
	#ecoPlace
	refinePlace -eco


    checkPlace
    if {[dbget [dbget top.markers {.subType == "SPOverlapViolation" || .subType == "SPPinAccessViolation" || .subType == "SPOrientationViolation" || .subType == "SPPinTrackMaskMismatchVio" || .subType == "SPSpacingRuleViolation" || .subType == "SPImpltAreaViolation" || .subType == "SPContextConstraintViolation" || .subType == "SPTPOLayerViolation" || .subType == "SPRFViolation" || .subType == "SPTechSiteViolation"} ].box ] != "0x0"} {
        set all [dbQuery -areas [dbget [dbget top.markers {.subType == "SPOverlapViolation" || .subType == "SPPinAccessViolation" || .subType ==  "SPOrientationViolation" || .subType == "SPPinTrackMaskMismatchVio" || .subType == "SPSpacingRuleViolation" || .subType == "SPImpltAreaViolation" || .subType == "SPContextConstraintViolation" || .subType == "SPTPOLayerViolation" || .subType == "SPRFViolation"  || .subType == "SPTechSiteViolation"}].box] -objType inst]
        set cell   [dbget [dbget  -p $all.isPhysOnly 0].name]
    }
    
    deselectAll
    selectInst $cell
    set std_cell  [dbget -p2 selected.cell.subClass core]
    deselectAll
    selectInst $std_cell
    set cts_fixed  [dbget -p selected.pstatusCTS fixed ]
    set cts_unset  [dbget -p selected.pstatusCTS unset ]
    set fixed_cell [dbget -p selected.pstatus fixed ]
    
    deselectAll
    
    selectInst $std_cell
    set MEM [dbGet -p2 top.insts.cell.name AU28HPCP*]
    deselectInst $MEM
    dbSet selected.pstatus  placed
    refinePlace -inst  [dbget selected.name ]
	dbSet selected.pStatus fixed
    checkPlace
	deselectAll
	ecoRoute	
}
#del filler 
#eco 
#refienplace
#checkplace
#get overlap marker()

source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8814/chip_top_idp/sub_proj/lb_ddr4_top/pv_clb/scr/genDummyBlk.tcl
