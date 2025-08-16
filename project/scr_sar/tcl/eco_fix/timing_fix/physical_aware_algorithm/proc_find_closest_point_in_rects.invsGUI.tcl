#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/16 12:47:06 Saturday
# label     : gui_proc math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This proc checks if a given point lies within any of the provided rectangles using ifInBoxes; if not, it finds the 
#             closest point on any rectangle. It calculates and merges valid offset ranges for moving from this closest point along 
#             the direction to the original point, validates the input offset, and returns the adjusted point or throws an error with 
#             valid ranges for invalid offsets.
# return    : valid point: {x y}
# ref       : link url
# --------------------------
source ../../../eco_fix/timing_fix/trans_fix/proc_ifInBoxes.invs.tcl; # ifInBoxes
proc find_closest_point_in_rects {point rects {offset 1.4}} {
  # Validate input point format
  if {[llength $point] != 2} {
    error "Invalid point format. Expected {x y}, got: $point in proc find_closest_point_in_rects"
  }
  set x [lindex $point 0]
  set y [lindex $point 1]
  if {![string is double -strict $x] || ![string is double -strict $y]} {
    error "Point coordinates must be numbers. Got: $x, $y in proc find_closest_point_in_rects"
  }

  # Validate rectangles format
  if {[llength $rects] == 0} {
    error "No rectangles provided in rects list in proc find_closest_point_in_rects"
  }
  foreach rect $rects {
    if {[llength $rect] != 4} {
      error "Invalid rectangle format. Expected {x y x1 y1}, got: $rect in proc find_closest_point_in_rects"
    }
    lassign $rect rx ry rx1 ry1
    if {![string is double -strict $rx] || ![string is double -strict $ry] || 
        ![string is double -strict $rx1] || ![string is double -strict $ry1]} {
      error "Rectangle coordinates must be numbers. Got: $rect in proc find_closest_point_in_rects"
    }
    if {$rx >= $rx1 || $ry >= $ry1} {
      error "Invalid rectangle: x must be < x1 and y must be < y1. Got: $rect in proc find_closest_point_in_rects"
    }
  }

  # Validate offset is a number
  if {![string is double -strict $offset]} {
    error "Offset must be a number. Got: $offset in proc find_closest_point_in_rects"
  }

  # Check if point is inside any rectangle using ifInBoxes proc
  if {[ifInBoxes $point $rects]} {
    return $point
  }

  # Find closest point on any rectangle
  set min_dist [expr {inf}]
  set closest_point ""
  set closest_rect ""

  foreach rect $rects {
    lassign $rect rx ry rx1 ry1

    # Calculate closest point on rectangle to input point
    set proj_x [expr {max($rx, min($x, $rx1))}]
    set proj_y [expr {max($ry, min($y, $ry1))}]

    # Calculate distance
    set dist [expr {sqrt(pow($x - $proj_x, 2) + pow($y - $proj_y, 2))}]

    # Update closest point if this is closer
    if {$dist < $min_dist} {
      set min_dist $dist
      set closest_point [list $proj_x $proj_y]
      set closest_rect $rect
    }
  }

  # Determine direction vector from input point to closest point
  lassign $closest_point cx cy
  set dir_x [expr {$cx - $x}]
  set dir_y [expr {$cy - $y}]

  # Determine primary axis (x or y) based on direction vector
  set main_axis "x"
  if {abs($dir_y) > abs($dir_x)} {
    set main_axis "y"
  }

  # Calculate valid offset ranges
  set valid_ranges [list]

  if {$main_axis eq "x"} {
    # Movement along x-axis (perpendicular to vertical rectangle edge)
    set dir_sign [expr {$dir_x >= 0 ? 1 : -1}]
    
    # Find all rectangles intersected by the ray
    foreach rect $rects {
      lassign $rect r_x r_y r_x1 r_y1
      
      # Check if ray (y=cy) intersects the rectangle
      if {$cy >= $r_y && $cy <= $r_y1} {
        # Calculate x range within this rectangle along the ray
        set start_x [expr {$dir_sign > 0 ? max($cx, $r_x) : min($cx, $r_x1)}]
        set end_x [expr {$dir_sign > 0 ? $r_x1 : $r_x}]
        
        # Convert x range to offset range
        set start_off [expr {($start_x - $cx) / $dir_sign}]
        set end_off [expr {($end_x - $cx) / $dir_sign}]
        
        if {$start_off <= $end_off} {
          lappend valid_ranges [list $start_off $end_off]
        }
      }
    }
  } else {
    # Movement along y-axis (perpendicular to horizontal rectangle edge)
    set dir_sign [expr {$dir_y >= 0 ? 1 : -1}]
    
    # Find all rectangles intersected by the ray
    foreach rect $rects {
      lassign $rect r_x r_y r_x1 r_y1
      
      # Check if ray (x=cx) intersects the rectangle
      if {$cx >= $r_x && $cx <= $r_x1} {
        # Calculate y range within this rectangle along the ray
        set start_y [expr {$dir_sign > 0 ? max($cy, $r_y) : min($cy, $r_y1)}]
        set end_y [expr {$dir_sign > 0 ? $r_y1 : $r_y}]
        
        # Convert y range to offset range
        set start_off [expr {($start_y - $cy) / $dir_sign}]
        set end_off [expr {($end_y - $cy) / $dir_sign}]
        
        if {$start_off <= $end_off} {
          lappend valid_ranges [list $start_off $end_off]
        }
      }
    }
  }

  # Check if any valid ranges exist
  if {[llength $valid_ranges] == 0} {
    error "No valid offset ranges found in proc find_closest_point_in_rects"
  }

  # Check if provided offset is valid
  set is_valid 0
  foreach range $valid_ranges {
    lassign $range start end
    if {$offset >= $start && $offset <= $end} {
      set is_valid 1
      break
    }
  }

  # Throw error if offset is invalid
  if {!$is_valid} {
    set range_str ""
    foreach range $valid_ranges {
      append range_str "\[ [lindex $range 0], [lindex $range 1] \] "
    }
    error "Invalid offset $offset in proc find_closest_point_in_rects. Valid ranges: $range_str"
  }

  # Calculate final point after applying valid offset
  if {$main_axis eq "x"} {
    set dir_sign [expr {$dir_x >= 0 ? 1 : -1}]
    set new_x [expr {$cx + $offset * $dir_sign}]
    set new_y $cy
  } else {
    set dir_sign [expr {$dir_y >= 0 ? 1 : -1}]
    set new_x $cx
    set new_y [expr {$cy + $offset * $dir_sign}]
  }

  return [list $new_x $new_y]
}

