#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/15 17:59:32 Friday
# label     : gui_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : get rects of inner area that is enclosed by boundary cell(endcap cell)
# return    : rects {{1 1 2 2} {2 2 3 3} ...}
# ref       : link url
# --------------------------
source ./operateLUT.tcl; # operateLUT
source ../trans_fix/proc_attachToGridOfRowSiteLeftBottomPoint.invsGUI.tcl; # attachToGridOfRowSiteLeftBottomPoint
source ../trans_fix/proc_ifInBoxes.invs.tcl; # ifInBoxes
proc getRect_innerAreaEnclosedByEndcap {{boundaryOrEndCapCellName "ENDCAP"} {shrinkOff -1}} {
  # if $shrinkOff == -1 or < 0, it will use mainCoreRowHeight to shrink coreArea
  set coreRects [operateLUT -type read -attr {core_rects}]
  set mainCoreRowHeight [operateLUT -type read -attr {mainCoreRowHeight}]
  set instsHaveHalo_ptr [dbget top.insts.isHaloBlock 1 -p]
  set allRects [lmap inst_ptr $instsHaveHalo_ptr {
    set temp_hrect [dbShape -output hrect [dbget $inst_ptr.pHaloPoly]] 
    if {$shrinkOff != -1 || $shrinkOff >= 0} { 
      set temp_hrect [dbShape -output hrect $temp_hrect SIZE $shrinkOff]
    } else {
      set temp_hrect [dbShape -output hrect $temp_hrect SIZE $mainCoreRowHeight]
    }
  }]
  set boundaryInnerRects [dbShape -output hrect $coreRects ANDNOT $allRects]
  set attachedGridBoundaryInnerRects [lmap temp_rect $boundaryInnerRects {
    set leftBottomPoint [lrange $temp_rect 0 1]
    set rightTopPoint [lrange $temp_rect 2 3]
    if {[ifInBoxes $leftBottomPoint $coreRects]} {
      set leftBottomPoint [attachToGridOfRowSiteLeftBottomPoint $leftBottomPoint]
    }
    if {[ifInBoxes $rightTopPoint $coreRects]} {
      set rightTopPoint [attachToGridOfRowSiteLeftBottomPoint $rightTopPoint]
    }
    set temp_attached_rect [list {*}$leftBottomPoint {*}$rightTopPoint]
  }]
  set boundaryCells_ptr [dbget top.insts.name *$boundaryOrEndCapCellName* -p]
  set boundaryRects [lmap temp_boundary_ptr $boundaryCells_ptr { ;  # boundary is always rect!!!, so it can open list.
    set temp_rect {*}[dbget $temp_boundary_ptr.box]
  }]
  set OR_exp "{[join $attachedGridBoundaryInnerRects "} OR {"]}"
  set attachedMergedGridBoundaryInnerRects [dbShape -output hrect {*}$OR_exp]
  set attachedRemoveBoundaryCellRectAndMergedGridBoundaryInnerRects [dbShape -output hrect $attachedMergedGridBoundaryInnerRects ANDNOT $boundaryRects]
  return $attachedRemoveBoundaryCellRectAndMergedGridBoundaryInnerRects
}
