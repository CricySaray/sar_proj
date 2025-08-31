#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/31 20:26:07 Sunday
# label     : flow_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
# descrip   : Create the core and die area sizes of a simple Floorplan through various parameters, with the ability to specify the coreToDie distance.
# return    : string of floorplan cmd
# ref       : link url
# --------------------------
source ./createRectangle.invs.tcl; # createRectangle
source ../packages/adjust_rectangle.package.tcl; # adjust_rectangle
source ../packages/adjust_to_multiple_of_num.package.tcl; # adjust_to_multiple_of_num
proc createFloorplanCmd {{memAndIPsubClass block} {IOinstSubClassName padAreaIO} {coreAreaSiteName "sc9mc_cln40lp"} {coreDensity 0.55} {coreAspectRatio 1} {specifyWidthOrHeight {die height 2285.54}} {adjustPolicy "roundUp"} {adjustForDieOfMultiple 1.00}} {
  set allIPmemInst [dbget [dbget -regexp top.insts.cell.subClass $memAndIPsubClass -p2].name]
  set padHeight [lindex {*}[dbget [dbget top.insts.cell.subClass $IOinstSubClassName -p].size -u] 1]
  set coreToDieDistance [expr $padHeight + 27]
  set siteHW {*}[dbget [dbget head.sites.name $coreAreaSiteName -p].size]
  set rectangleInfo [createRectangle -instsSpecialSuchAsIPAndMem $allIPmemInst -coreWHMultipliers $siteHW -coreToDieDistance $coreToDieDistance -coreInstsCellsubClass {core} -coreDensity $coreDensity -coreAspectRatio $coreAspectRatio -fixedDim $specifyWidthOrHeight -adjustPolicy $adjustPolicy]
  lassign $rectangleInfo dieAreaLeftBottomPointAndRightTopPoint coreAreaLeftBottomPointAndRightTopPoint finalCoreToDie
  set die_box [lmap tempNum [join $dieAreaLeftBottomPointAndRightTopPoint] { adjust_to_multiple_of_num $tempNum $adjustForDieOfMultiple roundUp }]
  set core_box [join $coreAreaLeftBottomPointAndRightTopPoint]
  set off_value [expr 0 - $padHeight]
  set io_box [adjust_rectangle $die_box $off_value]
  set floorplan_b [list {*}$die_box {*}$io_box {*}$core_box]
  set floorplan_cmd "floorplan -noSnapToGrid -flip f -b \{$floorplan_b\}"
  return $floorplan_cmd
}
