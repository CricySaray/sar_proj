#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/15 17:59:32 Friday
# label     : gui_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : get rects of inner area that is enclosed by boundary cell(endcap cell)
# return    : rects {{1 1 2 2} {2 2 3 3} ...}
# tag       : DEPRECATED: you can use proc:findCoreRectsInsideBoundary at ./proc_findCoreRectInsideBoeBoundary.invsGUI.tcl, which 
#                         features a more reasonable and simpler calculation method, with better results.
# ref       : link url
# --------------------------
source ./operateLUT.tcl; # operateLUT
source ../trans_fix/proc_attachToGridOfRowSiteLeftBottomPoint.invsGUI.tcl; # attachToGridOfRowSiteLeftBottomPoint_forRect
source ../trans_fix/proc_ifInBoxes.invs.tcl; # ifInBoxes
proc getRect_innerAreaEnclosedByEndcap {{boundaryOrEndCapCellName "ENDCAP"} {shrinkOff -1}} {
  # if $shrinkOff == -1 or < 0, it will use mainCoreRowHeight to shrink coreArea
  set coreRects [operateLUT -type read -attr {core_rects}]
  set mainCoreRowHeight [operateLUT -type read -attr {mainCoreRowHeight}]
  set instsHaveHalo_ptr [dbget top.insts.isHaloBlock 1 -p]
  set allRects [lmap inst_ptr $instsHaveHalo_ptr {
    set temp_hrect [dbShape -output hrect [dbget $inst_ptr.pHaloPoly]] 
    set temp_hrect [lmap ttemp_hrect $temp_hrect {
      attachToGridOfRowSiteLeftBottomPoint_forRect $ttemp_hrect
    }]
    if {$shrinkOff != -1 || $shrinkOff >= 0} { 
      set temp_hrect [dbShape -output hrect $temp_hrect SIZE $shrinkOff]
    } else {
      set temp_hrect [dbShape -output hrect $temp_hrect SIZE $mainCoreRowHeight]
    }
    set temp_hrect [lmap ttemp_hrect $temp_hrect {
      attachToGridOfRowSiteLeftBottomPoint_forRect $ttemp_hrect
    }]
  }]
  set boundaryInnerRects [dbShape -output hrect $coreRects ANDNOT $allRects]
  set attachedGridBoundaryInnerRects [lmap temp_rect $boundaryInnerRects {
    attachToGridOfRowSiteLeftBottomPoint_forRect $temp_rect
  }]
  set boundaryCells_ptr [dbget top.insts.name *$boundaryOrEndCapCellName* -p]
  set boundaryRects [lmap temp_boundary_ptr $boundaryCells_ptr { ;  # boundary is always rect!!!, so it can open list.
    set temp_rect {*}[dbget $temp_boundary_ptr.box]
  }]
  set OR_exp "{[join $attachedGridBoundaryInnerRects "} OR {"]}"
  set attachedMergedGridBoundaryInnerRects [dbShape -output hrect {*}$OR_exp]
  set RemoveBoundaryCellRectAndMergedGridBoundaryInnerRects [dbShape -output hrect $attachedMergedGridBoundaryInnerRects ANDNOT $boundaryRects]

  set attachedRemoveBoundaryCellRectAndMergedGridBoundaryInnerRects [lmap temp_rect $RemoveBoundaryCellRectAndMergedGridBoundaryInnerRects {
    attachToGridOfRowSiteLeftBottomPoint_forRect $temp_rect
  }]
  set attachedRemoveBoundaryCellRectAndMergedGridBoundaryInnerRects [dbShape -output hrect $attachedRemoveBoundaryCellRectAndMergedGridBoundaryInnerRects]
  return $attachedRemoveBoundaryCellRectAndMergedGridBoundaryInnerRects
}
