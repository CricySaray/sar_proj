#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/14 14:49:10 Thursday
# label     : gui_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : Attach the coordinates that are not on the rowsite grid points to the grid points, that is, normalize these coordinates
# return    : {x y}
# ref       : link url
# --------------------------
source ../lut_build/operateLUT.tcl; # operateLUT
source ../../../eco_fix/timing_fix/trans_fix/proc_ifInBoxes.invs.tcl; # ifInBoxes
source ../../../packages/every_any.package.tcl; # every
proc attachToGridOfRowSiteLeftBottomPoint {{pointLoc {0 0}}} {
  set coreRect [operateLUT -type read -attr {core_rects}]
  if {![every x $pointLoc { string is double $x }] || ![ifInBoxes $pointLoc $coreRect]} {
    error "proc attachToGridOfRowSiteLeftBottomPoint: check your input: pointLoc($pointLoc) is not valid format(should {1.2 2.3}) or not in core rect($coreRect) !!!"
  } else {
    set sitetype_dict [operateLUT -type filter -attr {key sitetype}]
    lassign $pointLoc point_x point_y
    dict for {temp_sitetype temp_attr} [dict get $sitetype_dict sitetype] {
      set temp_rowrect [dict get $temp_attr row_rects]
      lassign [dict get $temp_attr size] temp_sizex temp_sizey
      set rectInRects [ifInBoxes_returnRect $pointLoc $temp_rowrect]
      if {$rectInRects != 0 && [llength $rectInRects] == 4} {
        lassign $rectInRects hitRect_x hitRect_y hitRect_x1 hitRect_y1
        set multi_x [expr floor(($point_x - $hitRect_x) / $temp_sizex)]
        set multi_y [expr floor(($point_y - $hitRect_y) / $temp_sizey)]
        set attached_x [expr $hitRect_x + ($multi_x * $temp_sizex)]
        set attached_y [expr $hitRect_y + ($multi_y * $temp_sizey)]
        return [list $attached_x $attached_y]
      }
    }
  }
}
