#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/14 12:28:10 Thursday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : calculate relative point for one2one path!!! it is same as option of ecoAddRepeater: -relativeDistToSink
# return    : 
# ref       : link url
# --------------------------
proc calculate_relative_point_at_path {start_point end_point segments rel_dist} {
  # Validate input format
  if {[llength $start_point] != 2 || [llength $end_point] != 2} {
    error "Invalid start or end point format. Expected {x y}"
  }
  if {![string is double -strict $rel_dist] || $rel_dist < 0 || $rel_dist > 1} {
    error "Relative distance must be a float between 0 and 1"
  }
  if {[llength $segments] == 0} {
    error "No segments provided in path"
  }
  
  # Extract all endpoints from segments and count occurrences using dict
  set endpoint_counts [dict create]
  foreach seg $segments {
    if {[llength $seg] != 2} {
      error "Invalid segment format: $seg. Expected {{x y} {x1 y1}}"
    }
    set p1 [lindex $seg 0]
    set p2 [lindex $seg 1]
    if {[llength $p1] != 2 || [llength $p2] != 2} {
      error "Invalid point in segment $seg. Expected {x y}"
    }
    # Update counts for p1
    if {[dict exists $endpoint_counts $p1]} {
      dict incr endpoint_counts $p1
    } else {
      dict set endpoint_counts $p1 1
    }
    # Update counts for p2
    if {[dict exists $endpoint_counts $p2]} {
      dict incr endpoint_counts $p2
    } else {
      dict set endpoint_counts $p2 1
    }
  }
  
  # Find path endpoints (appear exactly once)
  set path_endpoints [list]
  dict for {ep count} $endpoint_counts {
    if {$count == 1} {
      lappend path_endpoints $ep
    }
  }
  if {[llength $path_endpoints] != 2} {
    error "Path should have exactly 2 endpoints, found [llength $path_endpoints]"
  }
  
  # Calculate distances to match path endpoints with input points
  set ep1 [lindex $path_endpoints 0]
  set ep2 [lindex $path_endpoints 1]
  
  set d1_start [distance_forPath $ep1 $start_point]
  set d1_end [distance_forPath $ep1 $end_point]
  set d2_start [distance_forPath $ep2 $start_point]
  set d2_end [distance_forPath $ep2 $end_point]
  
  # Determine which path endpoint matches start and which matches end
  if {$d1_start < $d1_end && $d2_end < $d2_start} {
    set path_start $ep1
    set path_end $ep2
  } elseif {$d1_end < $d1_start && $d2_start < $d2_end} {
    set path_start $ep2
    set path_end $ep1
  } else {
    error "Could not determine path direction. Endpoint and Startpoint of path matching failed."
  }
  
  # Handle edge cases for relative distance
  if {$rel_dist == 1.0} {
    return $start_point
  }
  if {$rel_dist == 0.0} {
    return $end_point
  }
  
  # Order segments from path_start to path_end
  set ordered_segments [order_segments $segments $path_start]
  if {[llength $ordered_segments] == 0} {
    error "Could not order segments correctly"
  }
  
  # Calculate total path length
  set total_length 0.0
  foreach seg $ordered_segments {
    set p1 [lindex $seg 0]
    set p2 [lindex $seg 1]
    set total_length [expr {$total_length + [distance_forPath $p1 $p2]}]
  }
  
  # Calculate target distance from path_end
  set target_dist [expr {$total_length * (1.0 - $rel_dist)}]
  
  # Find the point at target distance from path_end
  set remaining_dist $target_dist
  foreach seg $ordered_segments {
    set p1 [lindex $seg 0]
    set p2 [lindex $seg 1]
    set seg_len [distance_forPath $p1 $p2]
    
    if {$remaining_dist <= $seg_len} {
      # The point is on this segment
      return [point_along_segment $p1 $p2 $remaining_dist]
    } else {
      set remaining_dist [expr {$remaining_dist - $seg_len}]
    }
  }
  
  # If we reach here, something went wrong
  error "Calculated point not found on path segments"
}

# Helper procedure to calculate distance between two points
proc distance_forPath {p1 p2} {
  set x1 [lindex $p1 0]
  set y1 [lindex $p1 1]
  set x2 [lindex $p2 0]
  set y2 [lindex $p2 1]
  
  # Since segments are either horizontal or vertical, we can optimize
  if {$x1 == $x2} {
    # Vertical segment
    return [expr {abs($y2 - $y1)}]
  } elseif {$y1 == $y2} {
    # Horizontal segment
    return [expr {abs($x2 - $x1)}]
  } else {
    # non vertical or horizontal segment, calculate normal distance
    return [expr sqrt(($x2-$x1)**2 + ($y2-$y1)**2)]
    #error "Segment $p1 to $p2 is neither horizontal nor vertical"
  }
}

# Helper procedure to order segments from start point to end point
proc order_segments {segments start_point} {
  set ordered [list]
  set current_point $start_point
  set remaining_segments $segments
  
  while {[llength $remaining_segments] > 0} {
    set found 0
    set new_remaining [list]
    
    foreach seg $remaining_segments {
      set p1 [lindex $seg 0]
      set p2 [lindex $seg 1]
      
      if {$p1 eq $current_point} {
        lappend ordered $seg
        set current_point $p2
        set found 1
      } elseif {$p2 eq $current_point} {
        # Reverse the segment
        lappend ordered [list $p2 $p1]
        set current_point $p1
        set found 1
      } else {
        lappend new_remaining $seg
      }
    }
    
    if {!$found} {
      error "Could not find next segment. Path may be disconnected."
    }
    set remaining_segments $new_remaining
  }
  
  return $ordered
}

# Helper procedure to find a point along a segment at a given distance from start
proc point_along_segment {start end distance} {
  set x1 [lindex $start 0]
  set y1 [lindex $start 1]
  set x2 [lindex $end 0]
  set y2 [lindex $end 1]
  
  if {$x1 == $x2} {
    # Vertical segment
    set direction [expr {$y2 > $y1 ? 1 : -1}]
    set y [expr {$y1 + $direction * $distance}]
    return [list $x1 $y]
  } elseif {$y1 == $y2} {
    # Horizontal segment
    set direction [expr {$x2 > $x1 ? 1 : -1}]
    set x [expr {$x1 + $direction * $distance}]
    return [list $x $y1]
  } else {
    error "Segment $start to $end is neither horizontal nor vertical"
  }
}

