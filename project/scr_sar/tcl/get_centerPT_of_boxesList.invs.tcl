#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 15:54:08 CST 2025
# descrip   : get center pt of boxes
# integrity check : check if box has 4 integer item and if item is floating
# ref       : link url
# --------------------------
# boxes like : {{1 1 2.2 2.2} {13.1 13.1 90.0 90.0}}
# also ok like : {1 1 2 2}
proc get_center_pt_of_boxes {{boxes {}}} {
  if {![llength $boxes] || [lindex [lindex $boxes 0] 0] == ""} {
    return "0x0:1"; # not input boxes
  } else {
    set falseItem 0
    foreach item $boxes {if {![string is double $item]} {set falseItem 1}}
    if {[llength $boxes] == 4 && !$falseItem} {
      return [calculate_center_pt $boxes]
    } else {
      foreach box $boxes {
        if {[llength $box] != 4} {
          return "0x0:2"; # box not have 4 item 
        } else {
          foreach item $box {
            if {![string is double $item]} {
              return "0x0:3"; # have no double box 
            } 
          }
        }
      }
    set centerPTs [lmap box $boxes {
      calculate_center_pt $box 
    }]
    return $centerPTs
    }
  }
}
proc calculate_center_pt {box} {
  set x1 [lindex $box 0]
  set y1 [lindex $box 1]
  set x2 [lindex $box 2]
  set y2 [lindex $box 3]
  set center_pt [list [expr ($x1 + $x2) / 2] [expr ($y1 +$y2) / 2]]
  return $center_pt
}
