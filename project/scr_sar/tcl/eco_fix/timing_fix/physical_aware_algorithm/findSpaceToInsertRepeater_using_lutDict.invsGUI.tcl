#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/08 08:22:09 Friday
# label     : test_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : find space to insert repeater using some methods(searching, forceInserting and expandingSpace)
# return    : [list $findType $position $distance ($movementList)]
#             $findType: sufficient|expandSpace|forceInsert|noSpace
#             $position {1.1 2.2}
#             $distance 1.2
#             $movementList: if $findType is expandSpace, it will return inside list. format: {{instname1 {left 1.4}} {instname2 {right 2.1}} ...}
# ref       : link url
# --------------------------
source ./proc_judge_ifHaveSpaceToInsertBuffer_findNearestPosition.invsGUI.tcl; # judge_ifHaveSpaceToInsertBuffer_findNearestPosition
source ./proc_get_blank_box.invs.tcl; # get_blank_box
source ./proc_expandSpace_byMovingInst.invsGUI.tcl; # expandSpace_byMovingInst
source ../../../packages/logic_AND_OR.package.tcl; # er
source ../../../packages/every_any.package.tcl; # every
source ../lut_build/operateLUT.tcl; # operateLUT
source ../../../eco_fix/timing_fix/trans_fix/proc_ifInBoxes.invs.tcl; # ifInBoxes
proc findSpaceToInsertRepeater {args} {
  set testOrRun             "run"
  set inst                  ""
  set expandAreaWidthHeight {12.6 12.6}
  set divOfForceInsert      0.5
  set multipleOfExpandSpace 1.5
  set loc                   {}
  set celltype              ""
  set debug                 0
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set siteWidth [operateLUT -type read -attr {mainCoreSiteWidth}]
  set rowHeight [operateLUT -type read -attr {mainCoreRowHeight}]
  lassign $expandAreaWidthHeight widthOfExpand heightOfExpand
  set widthOfExpand [expr int([expr $widthOfExpand / $siteWidth]) * $siteWidth]
  set heightOfExpand [expr int([expr $heightOfExpand / $rowHeight]) * $rowHeight]
  if {$testOrRun == "test"} {
    if {$inst == "" || [dbget top.insts.name $inst -e] == "" || ![every x [concat $expandAreaWidthHeight $loc $divOfForceInsert] { string is double $x }]} {
      error "proc findSpaceToInsertRepeater: now type is test, check your input of -inst($inst): not found!!!"
    } else {
      set inst_ptr [dbget top.insts.name $inst -p]
      set repeaterWidth [dbget $inst_ptr.box_sizex]
      set repeaterHeight [dbget $inst_ptr.box_sizey]
      set repeaterPt [lindex [dbget $inst_ptr.pt] 0]
      # set repeaterBox [lindex [dbget $inst_ptr.box] 0]
      # set repeaterPtCenter [db_rect -center $repeaterBox]
    }
  } elseif {$testOrRun == "run"} {
    if {[every x [concat $expandAreaWidthHeight $loc $divOfForceInsert] { string is double $x }] && [operateLUT -type exists -attr [list celltype $celltype]] && [ifInBoxes $loc]} {
      set repeaterPt $loc
      lassign [operateLUT -type read -attr [list celltype $celltype size]] repeaterWidth repeaterHeight
    } else {
      error "proc findSpaceToInsertRepeater: now type is run, check your input of loc($loc), celltype($celltype), expandAreaWidthHeight($expandAreaWidthHeight) and divOfForceInsert($divOfForceInsert), have error!!!"
    }
  }
  set blankBoxList [lindex [get_blank_box $repeaterPt $widthOfExpand $heightOfExpand] 0]
  set blankBoxList_forceInsert [lindex [get_blank_box $repeaterPt [expr $widthOfExpand * $divOfForceInsert] [expr $heightOfExpand * $divOfForceInsert]] 0]
  set ifHaveSufficientSpaceToInsertRepeater [judge_ifHaveSpaceToInsertBuffer_findNearestPosition $repeaterPt [list $repeaterWidth $repeaterHeight] $blankBoxList 1 $blankBoxList_forceInsert $debug]
  er $debug { puts "repeaterWidth: $repeaterWidth | repeaterHeight: $repeaterHeight | repeaterPt : $repeaterPt \n ifHaveSufficientSpaceToInsertRepeater: [lindex $ifHaveSufficientSpaceToInsertRepeater 0] position: [lindex $ifHaveSufficientSpaceToInsertRepeater 1] with distance: [lindex $ifHaveSufficientSpaceToInsertRepeater 2]" }
  lassign $ifHaveSufficientSpaceToInsertRepeater spaceType positionFirstRound distanceFirstRound
  if {$spaceType == "sufficient"} {
    set findType "sufficient"
    set position $positionFirstRound
    set distance $distanceFirstRound
  } elseif {$spaceType == "forceInsert"} {
    set baseInsertRectLoc [lindex $ifHaveSufficientSpaceToInsertRepeater 1]
    lassign $baseInsertRectLoc base_x base_y
    set boxMovingInst [list [expr $base_x - ($widthOfExpand * $multipleOfExpandSpace)] [expr $base_y + 0] [expr $base_x + $repeaterWidth + ($widthOfExpand * $multipleOfExpandSpace)] [expr $base_y + $rowHeight]]
    set mfgGrid [dbget head.mfgGrid]
    set expandedSpace [expandSpace_byMovingInst $boxMovingInst $baseInsertRectLoc [list $repeaterWidth $repeaterHeight] $mfgGrid $debug $debug]
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
    set position $repeaterPt 
    set distance 0
  }
  if {$findType == "expandSpace"} {
    return [list $findType $position $distance $movementList]
  } else {
    return [list $findType $position $distance]
  }
}
define_proc_arguments findSpaceToInsertRepeater \
  -info "find space to insert Repeater" \
  -define_args {
    {-testOrRun "if test, you can specify instname using -inst. if run, it will need specify size of need-inserted repeater" oneOfString one_of_string {required value_type {values {test run}}}}
    {-inst "specify instname to test, it will get size of inst and location, set other args automatically" AString string optional}
    {-expandAreaWidthHeight "specify the width (and height) of searching space to expand it" AList list optional}
    {-multipleOfExpandSpace "sepcify the multiple number for area to expand when expanding space for repeater" AFloat float optional}
    {-divOfForceInsert "specify the multiple/div number of searching area" AFloat float optional}
    {-loc "specify the location to insert repeater" AList list optional}
    {-celltype "specify the celltype to insert, it can certain the size of inst" AString string optional}
    {-debug "print many debug info from interal of proc" "" boolean optional}
  }
