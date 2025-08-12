#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/08 08:22:09 Friday
# label     : test_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : test and debug the correction of proc(judge_ifHaveSpaceToInsertBuffer_findNearestPosition) 
# return    : message prompt
# ref       : link url
# --------------------------
source ./proc_judge_ifHaveSpaceToInsertBuffer_findNearestPosition.invsGUI.tcl; # judge_ifHaveSpaceToInsertBuffer_findNearestPosition
source ./proc_get_blank_box.invs.tcl; # get_blank_box
source ./proc_expandSpace_byMovingInst.invsGUI.tcl; # expandSpace_byMovingInst
source ../../../packages/logic_AND_OR.package.tcl; #
source ../lut_build/operateLUT.tcl; # operateLUT
proc findSpaceToInsertRepeater {instname {multiHeightOfRow 20} {multiWidthOfSite 180} {debug 1}} {
  set inst_ptr [dbget top.insts.name $instname -p]
  set instWidth [dbget $inst_ptr.box_sizex]
  set instHeight [dbget $inst_ptr.box_sizey]
  set instPt [lindex [dbget $inst_ptr.pt] 0]
  set instBox [lindex [dbget $inst_ptr.box] 0]
  set instPtCenter [db_rect -center $instBox]
  set blankBoxList [lindex [get_blank_box $instPt $multiHeightOfRow $multiWidthOfSite] 0]
  set blankBoxList_forceInsert [lindex [get_blank_box $instPt [expr $multiHeightOfRow / 2] [expr $multiWidthOfSite / 2]] 0]
  set blankWidthHeight [lmap temp $blankBoxList { db_rect -size $temp }]
  set ifHaveSufficientSpaceToInsertRepeater [judge_ifHaveSpaceToInsertBuffer_findNearestPosition $instPtCenter [list $instWidth $instHeight] $blankBoxList 1 $blankBoxList_forceInsert $debug]
  er $debug { puts "instWidth: $instWidth | instHeight: $instHeight | instPt : $instPt \n ifHaveSufficientSpaceToInsertRepeater: [lindex $ifHaveSufficientSpaceToInsertRepeater 0] position: [lindex $ifHaveSufficientSpaceToInsertRepeater 1] with distance: [lindex $ifHaveSufficientSpaceToInsertRepeater 2]" }
  lassign $ifHaveSufficientSpaceToInsertRepeater spaceType positionFirstRound distanceFirstRound
  if {$spaceType == "sufficient"} {
    set findType "sufficient"
    set position $positionFirstRound
    set distance $distanceFirstRound
  } elseif {$spaceType == "forceInsert"} {
    set baseInsertRectLoc [lindex $ifHaveSufficientSpaceToInsertRepeater 1]
    lassign $baseInsertRectLoc base_x base_y
    set boxMovingInst [list [expr $base_x - ([operateLUT -type read -attr {mainCoreSiteWidth}] * $multiWidthOfSite * 1.5)] [expr $base_y + 0] [expr $base_x + $instWidth + ([operateLUT -type read -attr {mainCoreSiteWidth}] * $multiWidthOfSite * 1.5)] [expr $base_y + [operateLUT -type read -attr {mainCoreRowHeight}]]]
    set mfgGrid [dbget head.mfgGrid]
    set expandedSpace [expandSpace_byMovingInst $boxMovingInst $baseInsertRectLoc [list $instWidth $instHeight] $mfgGrid $debug $debug]
    lassign $expandedSpace ifMovingInstSuccess leftBottomPositionOfCanInsert movingActions
    er $debug { puts "moving result: \n ifMovingInstSuccess: $ifMovingInstSuccess \n leftBottomPositionOfCanInsert: $leftBottomPositionOfCanInsert \n movingActions: [join $movingActions \n]" }
    if {$ifMovingInstSuccess == "yes"} {
      set findType "expandSpace"
      set position $leftBottomPositionOfCanInsert
      set distance $distanceFirstRound
      set movementList $movingActions
    } elseif {$ifMovingInstSuccess == "no"} {
      set findType "forceInsert"
      set position $positionFirstRound 
      set distance $distanceFirstRound
    }
  } elseif {$spaceType == "noSpace"} {
    set findType "noSpace"
    set position $positionFirstRound 
    set distance 0
  }
  if {$findType == "expandSpace"} {
    return [list $findType $position $distance $movementList]
  } else {
    return [list $findType $position $distance]
  }
}
