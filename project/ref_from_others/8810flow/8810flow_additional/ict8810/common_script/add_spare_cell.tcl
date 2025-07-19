####  TSMC
# SDFQNOMSBD1BWP210H6P51CNODULVTLL 1
# NR2D4BWP210H6P51CNODULVTLL 4
# ND2D4BWP210H6P51CNODULVTLL 4
# MUX2D3BWP210H6P51CNODULVTLL 2
# INVD6BWP210H6P51CNODULVTLL  6 
# BUFFD6BWP210H6P51CNODULVTLL 2
# TIELXNBWP210H6P51CNODLVT 1
# TIELXNBWP210H6P51CNODLVT 1
# GDCAP7DHXPBWP210H6P51CNODULVTLL 1

#### ARM 28
# ECOFABRICSDFF_A9PP140ZTS_C35   2
# ECOFABRICULDRV_A9PP140ZTS_C35  8
# ECOFABRICLDRV_A9PP140ZTS_C35   8
# ECOFABRICHDRV_A9PP140ZTS_C35   4
# ECOFABRICUHDRV_A9PP140ZTS_C35  2

if {[regexp A7P $vars(spare_cells)]} {
    set spare_buf "BUF_X4B_A7PP140ZTS_C35 4"
} else {
    set spare_buf "BUF_X4B_A9PP140ZTS_C35 4"
}

set enc_source_continue_on_error true
setEcoMode   -updateTiming false
setPlaceMode -place_detail_check_route true
setPlaceMode -place_detail_use_check_drc true
#########set Spare_module_num  
set dieBoxes     [dbGet -e top.fplan.boxes]
set core2Left    [dbGet -e top.fplan.core2Left]
set core2Bot     [dbGet -e top.fplan.core2Bot]
set coreBoxes    [dbShape $dieBoxes SIZEX -$core2Left SIZEY -$core2Bot]
set usefulBoxes $coreBoxes
set rowsBoxes    [dbShape [dbGet -e top.fplan.rows.box]]
set pblkgBoxes   [dbGet -e [dbGet -e top.fplan.pblkgs.type hard -p].boxes]
set pblkgBoxes   [dbShape $pblkgBoxes and $coreBoxes]
set blockBoxes   [dbGet -e [dbGet -e top.insts.cell.subClass block -p2].boxes]
set blockBoxes   [dbShape $blockBoxes and $coreBoxes]
set haloBlkBox   [dbGet -e top.insts.pHaloBox]
set usefulBoxes  [dbShape $usefulBoxes and    $rowsBoxes]
set usefulBoxes  [dbShape $usefulBoxes andnot $pblkgBoxes]
set usefulBoxes  [dbShape $usefulBoxes andnot $blockBoxes]
set placedArea   [dbShape $usefulBoxes -output area]
set Spare_module_num  ""
set Spare_module_num [expr int($placedArea/(100*100))]

###firstly, remove soft blockage; reason: tool assign spare cell by region.  
select_obj [dbGet top.FPlan.Pblkgs.type soft -p ]
defOut -selected   tmp.def
deletePlaceBlockage -type soft

deselectAll
#########create_Spare_cell for core area.
if {[get_cells -hierarchical -filter "is_macro_cell == true" -q] != ""} {
    ### create channel blockage
    set mem_names   [get_attribute [get_cells -hierarchical -filter "is_macro_cell == true"] full_name]
    foreach mem $mem_names {
      selectInst $mem
      set bbox  [ dbShape  [dbGet selected.box] SIZEY 10 SIZEX 10]
      createPlaceBlockage -type hard -name Blk_channel -box $bbox
      deselectInst $mem
    }
}
createSpareModule -cell  $vars(spare_cells) -useCellAsPrefix -moduleName [dbgDesignName]_mod_spare
placeSpareModule -moduleName [dbgDesignName]_mod_spare  -offsetx 10 -offsety 10 -prefix  spare_logic -numModules $Spare_module_num

####### create  spare_cell fore channel
if {[get_cells -hierarchical -filter "is_macro_cell == true" -q] != ""} {
      deletePlaceBlockage  Blk_channel
      createSpareModule -cell $spare_buf -useCellAsPrefix -moduleName [dbgDesignName]_mod_spare_channel
      placeSpareModule -moduleName [dbgDesignName]_mod_spare_channel -prefix  spare_channel  -channel -minWidth 3  -maxWidth 20   -minLen 21 -stepx 50 -stepy 50  -util 0.5
}

####### lega
specifySpareGate -inst *spare_logic*
dbSet [dbGet top.insts.name *spare_logic* -p ].pStatus placed
setPlaceMode -place_detail_eco_max_distance 50
refinePlace -inst *spare_logic*
#displaySpareCell
#### remove region of module and refineplace again.
set allmodules [dbGet top.hInst.hInsts.name *spare_logic*]
foreach modu $allmodules {
    unplaceGuide  $modu
}
refinePlace -inst *spare_logic*

#### remove spare out core.
set cells [dbGet [dbGet top.insts.name *spare_logic* -p].name ]
foreach cell $cells {
     set row [dbQuery -areas [dbGet [dbGet top.insts.name   $cell -p ].box ] -objType row]
     if {$row ==""} {deleteInst $cell}
}

defIn tmp.def
dbSet [dbGet top.insts.name *spare_logic* -p ].pStatus cover
setEcoMode -updateTiming true
setEcoMode -reset
setPlaceMode -reset -place_detail_eco_max_distance


dbSet [dbGet -p top.hinst.hinsts.name *spare_logic*].dontTouch true
dbGet [dbGet -p top.hinst.hinsts.name *spare_logic*].dontTouchHports true
