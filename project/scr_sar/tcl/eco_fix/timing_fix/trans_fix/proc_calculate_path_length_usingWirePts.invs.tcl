#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/26 18:32:42 Tuesday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This proc calculates the total length of a path composed of horizontal and vertical segments, validating the input format to 
#               ensure it contains properly formatted coordinate pairs and valid segments, while summing the lengths of all segments in the path.
# return    : length num
# input     : {{{x y} {x1 y1}} {{x y} {x1 y1}} ...}
# ref       : link url
# --------------------------
proc calculate_path_length_usingWirePts {path} {
  # Check if input is a valid list
  if {![llength $path]} {
    error "Invalid path: Empty input provided"
  }
  
  if {![string is list -strict $path]} {
    error "Invalid path: Input is not a valid list"
  }
  
  set total_length 0.0
  
  # Iterate through each segment in the path
  foreach seg $path {
    # Check segment is a valid list with two points
    if {[llength $seg] != 2} {
      error "Invalid segment format: Segment must contain exactly two points - $seg"
    }
    
    # Extract the two points of the segment
    set p1 [lindex $seg 0]
    set p2 [lindex $seg 1]
    
    # Validate first point format
    if {[llength $p1] != 2} {
      error "Invalid point format: First point must be a coordinate pair - $p1"
    }
    if {![string is double -strict [lindex $p1 0]] || ![string is double -strict [lindex $p1 1]]} {
      error "Invalid coordinates: First point contains non-numeric values - $p1"
    }
    
    # Validate second point format
    if {[llength $p2] != 2} {
      error "Invalid point format: Second point must be a coordinate pair - $p2"
    }
    if {![string is double -strict [lindex $p2 0]] || ![string is double -strict [lindex $p2 1]]} {
      error "Invalid coordinates: Second point contains non-numeric values - $p2"
    }
    
    # Extract coordinates
    set x1 [lindex $p1 0]
    set y1 [lindex $p1 1]
    set x2 [lindex $p2 0]
    set y2 [lindex $p2 1]
    
    # Check if segment is horizontal or vertical (as required by original problem)
    if {$x1 != $x2 && $y1 != $y2} {
      error "Invalid segment: Segment is not horizontal or vertical - $seg"
    }
    
    # Calculate segment length (horizontal: x difference, vertical: y difference)
    if {$x1 == $x2} {
      # Vertical segment
      set length [expr {abs($y2 - $y1)}]
    } else {
      # Horizontal segment
      set length [expr {abs($x2 - $x1)}]
    }
    
    # Add to total length
    set total_length [expr {$total_length + $length}]
  }
  
  return $total_length
}

