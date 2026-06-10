#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/06/02 11:46:00 Tuesday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : 
# return    : 
# ref       : link url
# --------------------------
# Proc to find the closest point inside boxes using Manhattan distance
proc get_closest_point_in_boxes {point boxes} {
  # Error defense 1: Validate input point format
  if {[llength $point] != 2} {
    error "Invalid point format: must be {x y}, got $point"
  }
  foreach coord $point {
    if {![string is double -strict $coord]} {
      error "Invalid point coordinate: must be numeric, got $coord"
    }
  }

  # Error defense 2: Validate boxes is a list
  if {![llength $boxes]} {
    error "Invalid boxes: empty list, must contain at least one rectangle"
  }

  # Error defense 3: Validate each rectangle in boxes
  set rect_idx 0
  foreach rect $boxes {
    if {[llength $rect] != 4} {
      error "Invalid rectangle $rect_idx format: must be {x y x1 y1}, got $rect"
    }
    foreach coord $rect {
      if {![string is double -strict $coord]} {
        error "Invalid rectangle $rect_idx coordinate: must be numeric, got $coord"
      }
    }
    lassign $rect rx ry rx1 ry1
    # Check rectangle validity (lower-left < upper-right)
    if {$rx >= $rx1 || $ry >= $ry1} {
      error "Invalid rectangle $rect_idx: lower-left($rx,$ry) must be smaller than upper-right($rx1,$ry1)"
    }
    incr rect_idx
  }

  # Parse input point
  lassign $point px py

  set min_dist Inf
  set closest_point {}

  # Iterate all rectangles to find closest point
  foreach rect $boxes {
    lassign $rect rx ry rx1 ry1

    # Calculate closest point in current rectangle (Manhattan distance projection)
    set cx [expr {max($rx, min($px, $rx1))}]
    set cy [expr {max($ry, min($py, $ry1))}]

    # Calculate Manhattan distance
    set dist [expr {abs($px - $cx) + abs($py - $cy)}]

    # Update minimum distance and closest point
    if {$dist < $min_dist} {
      set min_dist $dist
      set closest_point [list $cx $cy]
    }
  }

  return $closest_point
}
