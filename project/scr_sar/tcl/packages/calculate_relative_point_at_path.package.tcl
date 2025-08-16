#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/14 12:28:10 Thursday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : calculate relative point for one2one path!!! it is same as option of ecoAddRepeater: -relativeDistToSink
# update    : (U001) Added logic to handle small branches near start/end points by selecting the longest branch if their total 
#             length is ≤20% of the total path length, otherwise throwing an error.
# update    : (U002) The algorithm initiates with the longest segment as the initial main trunk and expands bidirectionally from its two endpoints.
#                    At junctions, only the longest branch is retained, with branch lengths calculated precisely by tracing only segments belonging 
#                    to each branch to avoid duplicates.
#             AT001 : Optimize small branches into a single branch-free path. IMPORTANT
# return    : point {x y}
# ref       : link url
# --------------------------
proc calculate_relative_point_at_path {start_point end_point segments rel_dist {threshold 0.2}} {
  # Validate input format
  if {[llength $start_point] != 2 || [llength $end_point] != 2} {
    error "proc calculate_relative_point_at_path: Invalid start or end point format. Expected {x y}"
  }
  if {![string is double -strict $rel_dist] || $rel_dist < 0 || $rel_dist > 1} {
    error "proc calculate_relative_point_at_path: Relative distance must be a float between 0 and 1"
  }
  if {![string is double -strict $threshold] || $threshold < 0 || $threshold > 1} {
    error "proc calculate_relative_point_at_path: Threshold must be a float between 0 and 1"
  }
  if {[llength $segments] == 0} {
    error "proc calculate_relative_point_at_path: No segments provided in path"
  }
  
  # Check if all segments form a single connected path
  set connected_segments [check_and_get_connected_segments $segments] ; # U002
  if {[llength $connected_segments] != [llength $segments]} {
    error "proc calculate_relative_point_at_path: Segments form multiple disconnected paths. Found [expr {[llength $segments] - [llength $connected_segments]}] disconnected segments."
  }
  
  # Step 1: Find the longest segment as initial main trunk
  set longest_segment [find_longest_segment $connected_segments] ; # U002
  if {[llength $longest_segment] == 0} {
    error "proc calculate_relative_point_at_path: Could not identify longest segment"
  }
  
  # Get two endpoints of the longest segment (main trunk start)
  set trunk_p1 [lindex $longest_segment 0]
  set trunk_p2 [lindex $longest_segment 1]
  
  # Step 2: Expand main trunk from both ends, handling branches at junctions
  # Expand from first end of longest segment
  set expanded_from_p1 [expand_trunk $connected_segments $trunk_p1 $trunk_p2 $threshold] ; # U002
  # Expand from second end of longest segment
  set expanded_from_p2 [expand_trunk $connected_segments $trunk_p2 $trunk_p1 $threshold]
  
  # Combine expanded segments (ensure no duplicates)
  set main_trunk [lsort -unique [concat $expanded_from_p1 $expanded_from_p2 [list $longest_segment]]] ; # AT001
  
  # Verify trunk is valid (has no junctions)
  set trunk_junctions [find_junctions $main_trunk]
  if {[llength $trunk_junctions] > 0} {
    error "proc calculate_relative_point_at_path: Final trunk still contains junctions. Incomplete branch pruning."
  }
  
  # Extract endpoints from final main trunk
  set endpoint_counts [dict create]
  foreach seg $main_trunk {
    set p1 [lindex $seg 0]
    set p2 [lindex $seg 1]
    dict incr endpoint_counts $p1
    dict incr endpoint_counts $p2
  }
  
  # Find path endpoints (should be exactly 2)
  set path_endpoints [list]
  dict for {ep count} $endpoint_counts {
    if {$count == 1} {
      lappend path_endpoints $ep
    }
  }
  if {[llength $path_endpoints] != 2} {
    error "proc calculate_relative_point_at_path: Path should have exactly 2 endpoints after pruning, found [llength $path_endpoints]"
  }
  
  # Match path endpoints with input start/end points
  set ep1 [lindex $path_endpoints 0]
  set ep2 [lindex $path_endpoints 1]
  
  set d1_start [distance_forPath $ep1 $start_point]
  set d1_end [distance_forPath $ep1 $end_point]
  set d2_start [distance_forPath $ep2 $start_point]
  set d2_end [distance_forPath $ep2 $end_point]
  
  # Determine path direction
  if {$d1_start < $d1_end && $d2_end < $d2_start} {
    set path_start $ep1
    set path_end $ep2
  } elseif {$d1_end < $d1_start && $d2_start < $d2_end} {
    set path_start $ep2
    set path_end $ep1
  } else {
    error "proc calculate_relative_point_at_path: Could not determine path direction"
  }
  
  # Handle edge cases for relative distance
  if {$rel_dist == 1.0} {
    return $start_point
  }
  if {$rel_dist == 0.0} {
    return $end_point
  }
  
  # Order segments from path_start to path_end
  set ordered_segments [order_segments $main_trunk $path_start]
  if {[llength $ordered_segments] == 0} {
    error "proc calculate_relative_point_at_path: Could not order segments correctly"
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
      return [point_along_segment $p1 $p2 $remaining_dist]
    } else {
      set remaining_dist [expr {$remaining_dist - $seg_len}]
    }
  }
  
  # If we reach here, something went wrong
  error "proc calculate_relative_point_at_path: Calculated point not found on path segments"
}

# Find the longest segment in the list
proc find_longest_segment {segments} {
  set max_length 0.0
  set longest_seg [list]
  
  foreach seg $segments {
    set p1 [lindex $seg 0]
    set p2 [lindex $seg 1]
    set len [distance_forPath $p1 $p2]
    
    if {$len > $max_length} {
      set max_length $len
      set longest_seg $seg
    }
  }
  
  return $longest_seg
}

# Expand trunk from current end, handling branches at junctions
proc expand_trunk {all_segments current_end previous_point threshold} {
  set expanded_segments [list]
  set visited_points [list $previous_point]
  set current_point $current_end
  set max_expansions [llength $all_segments] ;# Prevent infinite expansion
  set expansions 0
  
  while {$expansions < $max_expansions} {
    incr expansions
    lappend visited_points $current_point
    
    # Find all segments connected to current point (excluding previous point)
    set connected_segs [list]
    foreach seg $all_segments {
      set p1 [lindex $seg 0]
      set p2 [lindex $seg 1]
      
      if {($p1 eq $current_point && $p2 ne $previous_point) || 
          ($p2 eq $current_point && $p1 ne $previous_point)} {
        lappend connected_segs $seg
      }
    }
    
    # No more segments to expand - end of path
    if {[llength $connected_segs] == 0} {
      break
    }
    
    # Single connected segment - continue expanding trunk
    if {[llength $connected_segs] == 1} {
      set next_seg [lindex $connected_segs 0]
      lappend expanded_segments $next_seg
      
      # Update points for next iteration
      set previous_point $current_point
      if {[lindex $next_seg 0] eq $current_point} {
        set current_point [lindex $next_seg 1]
      } else {
        set current_point [lindex $next_seg 0]
      }
      continue
    }
    
    # Multiple connected segments - junction found, need to select longest branch
    set junction $current_point
    set branches [list]
    
    # Collect all branches from this junction (excluding trunk direction)
    foreach seg $connected_segs {
      set p1 [lindex $seg 0]
      set p2 [lindex $seg 1]
      
      # Determine branch start point
      if {$p1 eq $junction} {
        set branch_start $p2
      } else {
        set branch_start $p1
      }
      
      # Trace complete branch from junction
      set branch [trace_branch_from_junction $all_segments $junction $branch_start $visited_points]
      lappend branches [list [branch_length $branch] $branch]
    }
    
    # Sort branches by length (descending)
    set sorted_branches [lsort -decreasing -index 0 $branches]
    
    # Calculate total length of all branches
    set total_branch_length 0.0
    foreach branch $sorted_branches {
      set total_branch_length [expr {$total_branch_length + [lindex $branch 0]}]
    }
    
    # Check if remaining branches exceed threshold
    set longest_branch [lindex [lindex $sorted_branches 0] 1]
    set longest_length [lindex [lindex $sorted_branches 0] 0]
    set remaining_length [expr {$total_branch_length - $longest_length}]
    set max_allowed [expr {$total_branch_length * $threshold}]
    
    if {$remaining_length > $max_allowed} {
      error "proc expand_trunk: Remaining branches ($remaining_length) exceed threshold ($max_allowed) at junction $junction"
    }
    
    # Add longest branch to trunk and continue expansion
    lappend expanded_segments {*}$longest_branch
    
    # Update points for next iteration (last point of longest branch)
    set last_seg [lindex $longest_branch end]
    set previous_point $junction
    if {[lindex $last_seg 0] eq $junction} {
      set current_point [lindex $last_seg 1]
    } else {
      set current_point [lindex $last_seg end]
    }
  }
  
  return $expanded_segments
}

# Trace a single branch from junction, excluding visited points
proc trace_branch_from_junction {all_segments junction start_point visited_points} {
  set branch [list]
  set current_point $start_point
  set previous_point $junction
  set max_steps [llength $all_segments]
  set steps 0
  
  while {$steps < $max_steps} {
    incr steps
    set found 0
    
    # Find next segment in this branch
    foreach seg $all_segments {
      set p1 [lindex $seg 0]
      set p2 [lindex $seg 1]
      
      # Check if segment connects current point and isn't backtracking
      if {(($p1 eq $current_point && $p2 ne $previous_point) || 
          ($p2 eq $current_point && $p1 ne $previous_point)) &&
          ![lsearch -exact $visited_points $current_point] >= 0} {
        
        lappend branch $seg
        set previous_point $current_point
        
        # Update current point
        if {$p1 eq $current_point} {
          set current_point $p2
        } else {
          set current_point $p1
        }
        
        set found 1
        break
      }
    }
    
    # No more segments in this branch
    if {!$found} {
      break
    }
  }
  
  return $branch
}

# Calculate total length of a branch
proc branch_length {branch} {
  set len 0.0
  foreach seg $branch {
    set p1 [lindex $seg 0]
    set p2 [lindex $seg 1]
    set len [expr {$len + [distance_forPath $p1 $p2]}]
  }
  return $len
}

# Find junctions in a set of segments (points with >2 connections)
proc find_junctions {segments} {
  set endpoint_counts [dict create]
  foreach seg $segments {
    set p1 [lindex $seg 0]
    set p2 [lindex $seg 1]
    dict incr endpoint_counts $p1
    dict incr endpoint_counts $p2
  }
  
  set junctions [list]
  dict for {ep count} $endpoint_counts {
    if {$count > 2} {
      lappend junctions $ep
    }
  }
  
  return $junctions
}

# Helper procedure to check if all segments form a single connected path
proc check_and_get_connected_segments {segments} {
  if {[llength $segments] == 0} {
    return [list]
  }
  
  # Start with the first segment
  set connected [list [lindex $segments 0]]
  set remaining [lrange $segments 1 end]
  set max_attempts [llength $segments]
  set changed 1
  
  # Use foreach with max attempts to prevent infinite loop
  foreach _ [lrepeat $max_attempts 1] {
    if {!$changed} break
    
    set changed 0
    set new_remaining [list]
    
    foreach seg $remaining {
      set p1 [lindex $seg 0]
      set p2 [lindex $seg 1]
      set is_connected 0
      
      # Check if this segment connects to any in the connected list
      foreach cseg $connected {
        set cp1 [lindex $cseg 0]
        set cp2 [lindex $cseg 1]
        
        if {$p1 eq $cp1 || $p1 eq $cp2 || $p2 eq $cp1 || $p2 eq $cp2} {
          lappend connected $seg
          set is_connected 1
          set changed 1
          break
        }
      }
      
      if {!$is_connected} {
        lappend new_remaining $seg
      }
    }
    
    set remaining $new_remaining
  }
  
  return $connected
}

# Helper procedure to calculate distance between two points
proc distance_forPath {p1 p2} {
  set x1 [lindex $p1 0]
  set y1 [lindex $p1 1]
  set x2 [lindex $p2 0]
  set y2 [lindex $p2 1]
  
  if {$x1 == $x2} {
    # Vertical segment
    return [expr {abs($y2 - $y1)}]
  } elseif {$y1 == $y2} {
    # Horizontal segment
    return [expr {abs($x2 - $x1)}]
  } else {
    # Non vertical or horizontal segment
    return [expr sqrt(($x2-$x1)**2 + ($y2-$y1)** 2)]
  }
}

# Helper procedure to order segments from start point to end point
proc order_segments {segments start_point} {
  set ordered [list]
  set current_point $start_point
  set remaining_segments $segments
  
  # Use foreach with segment count limit
  foreach _ [lrepeat [llength $segments] 1] {
    if {[llength $remaining_segments] == 0} break
    
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
    
    if {!$found} break
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
    error "proc calculate_relative_point_at_path: Segment $start to $end is neither horizontal nor vertical"
  }
}

