#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/31 20:18:56 Sunday
# label     : package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : A TCL procedure that adjusts a rectangle's coordinates (given as {x y x1 y1}) by expanding or shrinking it based on 
#             either a single offset value (applied to all directions) or a 4-element offset list (top, bottom, left, right), 
#             returning the new coordinates in the same format.
# return    : rect list {x y x1 y1}
# ref       : link url
# --------------------------
proc adjust_boxes {rects offset} {
  if {![llength $rects]} {
    error "proc adjust_boxes: check your input: rects($rects) is empty!!!"
  } else {
    return [lmap rect $rects { adjust_rectangle $rect $offset }]
  }
}
proc adjust_rectangle {rect offset} {
  # Check if rectangle has valid format
  if {[llength $rect] != 4} {
    error "proc adjust_rectangle: Invalid rectangle format. Expected {x y x1 y1}"
  }
  
  # Extract original coordinates
  lassign $rect x y x1 y1
  
  # Process offset parameter
  if {[llength $offset] == 1} {
    # Single value applies to all directions
    set top [lindex $offset 0]
    set bottom $top
    set left $top
    set right $top
  } elseif {[llength $offset] == 4} {
    # List of four values: top, bottom, left, right
    lassign $offset top bottom left right
  } else {
    error "proc adjust_rectangle: Invalid offset format. Expected single value or 4-element list"
  }
  
  # Calculate new coordinates
  set new_x [expr {$x - $left}]
  set new_y [expr {$y - $bottom}]
  set new_x1 [expr {$x1 + $right}]
  set new_y1 [expr {$y1 + $top}]
  
  # Return adjusted rectangle
  return [list $new_x $new_y $new_x1 $new_y1]
}

