#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/26 10:46:11 Saturday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : judge if the location pt is on specific area.
# update    : 2025/08/14 15:58:27 Thursday
#             (U001) can return exact box/rect
# ref       : link url
# --------------------------
# this proc can return the exact rect from rects!
source ../lut_build/operateLUT.tcl; # operateLUT
proc ifInBoxes_returnRect {{loc {0 0}} {boxes {{}}}} { ; # U001
  if {![llength [lindex $boxes 0]]} {
    set fplanBoxes [lindex [dbget top.fplan.boxes] 0]
    set boxes $fplanBoxes
  }
  set temp_loc_rect [list {*}$loc [expr {[lindex $loc 0] + 0.01}]  [expr {[lindex $loc 1] + 0.01}]]
  set result [dbShape $temp_loc_rect INSIDE $boxes]
  if {$result ne ""} {
    return $result
  } else {
    return ""
  }
}

proc ifInBoxes_returnRect_old {{loc {0 0}} {boxes {{}}}} { ; # U001
  if {![llength [lindex $boxes 0]]} {
    set fplanBoxes [lindex [dbget top.fplan.boxes] 0]
    set boxes $fplanBoxes
  }
  foreach box $boxes {
    if {[ifInBox $loc $box]} {
      return $box 
    }
  }
  return 0
}

proc ifInBoxes {{loc {0 0}} {boxes {{}}}} {
  if {![llength [lindex $boxes 0]]} {
    set fplanBoxes [lindex [dbget top.fplan.boxes] 0]
    set boxes $fplanBoxes
  }
  set temp_loc_rect [list {*}$loc [expr {[lindex $loc 0] + 0.01}]  [expr {[lindex $loc 1] + 0.01}]]
  if {[dbShape $temp_loc_rect INSIDE $boxes] ne ""} {
    return 1 
  } else {
    return 0
  }
}

proc ifInBoxes_old {{loc {0 0}} {boxes {{}}}} {
  if {![llength [lindex $boxes 0]]} {
    set fplanBoxes [lindex [dbget top.fplan.boxes] 0]
    set boxes $fplanBoxes
  }
  foreach box $boxes {
    if {[ifInBox $loc $box]} {
      return 1 
    }
  }
  return 0
}
proc ifInBox {{loc {0 0}} {box {0 0 10 10}}} {
  set xRange [list [lindex $box 0] [lindex $box 2]]
  set yRange [list [lindex $box 1] [lindex $box 3]]
  set x [lindex $loc 0]
  set y [lindex $loc 1]
  if {[lindex $xRange 0] <= $x && $x <= [lindex $xRange 1] && [lindex $yRange 0] <= $y && $y <= [lindex $yRange 1]} {
    return 1 
  } else {
    return 0 
  }
}
