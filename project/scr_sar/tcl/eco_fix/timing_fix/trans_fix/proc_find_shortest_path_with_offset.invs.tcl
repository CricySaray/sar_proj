proc find_shortest_path {start end segments} {
  # Validate input format
  if {[llength $start] != 2 || [llength $end] != 2} {
    error "Start and end points must be coordinate pairs"
  }
  
  foreach seg $segments {
    if {[llength $seg] != 2 || [llength [lindex $seg 0]] != 2 || [llength [lindex $seg 1]] != 2} {
      error "Invalid segment format: $seg. Each segment must be in the format {{x y} {x1 y1}}"
    }
  }
  
  # Find closest points on the tree for start and end
  lassign [find_closest_segment_and_point $start $segments] start_closest start_seg start_seg_idx start_dist
  lassign [find_closest_segment_and_point $end $segments] end_closest end_seg end_seg_idx end_dist
  
  # Create modified segments list by splitting segments if needed
  set modified_segments $segments
  
  # Split start segment if closest point is not an endpoint
  if {$start_closest ne [lindex $start_seg 0] && $start_closest ne [lindex $start_seg 1]} {
    lassign [split_segment $start_seg $start_closest] new_seg1 new_seg2
    set modified_segments [lreplace $modified_segments $start_seg_idx $start_seg_idx $new_seg1 $new_seg2]
    
    # If end segment was after start segment, adjust its index
    if {$end_seg_idx > $start_seg_idx} {
      incr end_seg_idx
    }
  }
  
  # Split end segment if closest point is not an endpoint
  if {$end_closest ne [lindex $end_seg 0] && $end_closest ne [lindex $end_seg 1]} {
    lassign [split_segment $end_seg $end_closest] new_seg1 new_seg2
    set modified_segments [lreplace $modified_segments $end_seg_idx $end_seg_idx $new_seg1 $new_seg2]
  }
  
  # Build graph structure: each point connected to other points
  array set graph {}
  
  # Save segment mapping for later lookup
  array set segment_map {}
  
  # Process each segment to build the graph
  foreach seg $modified_segments {
    set p1 [lindex $seg 0]
    set p2 [lindex $seg 1]
    set p1_str [join $p1 ,]
    set p2_str [join $p2 ,]
    
    # Add points to graph
    lappend graph($p1_str) $p2_str
    lappend graph($p2_str) $p1_str
    
    # Save segment mapping with both possible key orders
    set key1 "$p1_str|$p2_str"
    set key2 "$p2_str|$p1_str"
    set segment_map($key1) $seg
    set segment_map($key2) $seg
  }
  
  # BFS algorithm to find shortest path
  array set visited {}
  array set parent {}
  
  set start_str [join $start_closest ,]
  set end_str [join $end_closest ,]
  
  # Check if start and end points exist in the graph
  if {![info exists graph($start_str)]} {
    error "Start point $start_closest is not in the graph"
  }
  if {![info exists graph($end_str)]} {
    error "End point $end_closest is not in the graph"
  }
  
  set queue [list $start_str]
  set visited($start_str) 1
  set found 0
  
  while {[llength $queue] > 0 && !$found} {
    set current [lindex $queue 0]
    set queue [lrange $queue 1 end]
    
    if {$current eq $end_str} {
      set found 1
      break
    }
    
    foreach neighbor $graph($current) {
      if {![info exists visited($neighbor)]} {
        set visited($neighbor) 1
        set parent($neighbor) $current
        lappend queue $neighbor
      }
    }
  }
  
  # If no path found, return empty list
  if {!$found} {
    return [list]
  }
  
  # Backtrack to build the path
  set path [list]
  set current $end_str
  
  while {$current ne $start_str} {
    set prev $parent($current)
    set key "$prev|$current"
    lappend path $segment_map($key)
    set current $prev
  }
  
  # Reverse path to get from start to end
  set path [lreverse $path]
  
  # If start point is not directly on the first segment, add connection
  if {[distance_between_points $start $start_closest] > 1e-9} {
    set path [linsert $path 0 [list $start $start_closest]]
  }
  
  # If end point is not directly on the last segment, add connection
  if {[distance_between_points $end $end_closest] > 1e-9} {
    lappend path [list $end_closest $end]
  }
  
  return $path
}

proc distance_between_points {p1 p2} {
  set x1 [lindex $p1 0]
  set y1 [lindex $p1 1]
  set x2 [lindex $p2 0]
  set y2 [lindex $p2 1]
  
  set dx [expr {$x2 - $x1}]
  set dy [expr {$y2 - $y1}]
  
  return [expr {sqrt($dx*$dx + $dy*$dy)}]
}

proc closest_point_on_segment {point segment} {
  set p [lindex $point 0]
  set q [lindex $point 1]
  
  set a [lindex $segment 0 0]
  set b [lindex $segment 0 1]
  set c [lindex $segment 1 0]
  set d [lindex $segment 1 1]
  
  # Horizontal line (y is constant)
  if {$b == $d} {
    # Check if point's y is on the segment's y
    if {$q == $b} {
      set x_clamped [expr {max(min($p, max($a, $c)), min($a, $c))}]
      return [list $x_clamped $b]
    } else {
      # Distance to endpoints
      set d1 [distance_between_points [list $p $q] [list $a $b]]
      set d2 [distance_between_points [list $p $q] [list $c $d]]
      
      if {$d1 <= $d2} {
        return [list $a $b]
      } else {
        return [list $c $d]
      }
    }
  }
  # Vertical line (x is constant)
  else {
    # Check if point's x is on the segment's x
    if {$p == $a} {
      set y_clamped [expr {max(min($q, max($b, $d)), min($b, $d))}]
      return [list $a $y_clamped]
    } else {
      # Distance to endpoints
      set d1 [distance_between_points [list $p $q] [list $a $b]]
      set d2 [distance_between_points [list $p $q] [list $c $d]]
      
      if {$d1 <= $d2} {
        return [list $a $b]
      } else {
        return [list $c $d]
      }
    }
  }
}

proc find_closest_segment_and_point {point segments} {
  set min_dist Inf
  set closest_point ""
  set closest_segment ""
  set closest_segment_index -1
  
  set i 0
  foreach seg $segments {
    set cp [closest_point_on_segment $point $seg]
    set dist [distance_between_points $point $cp]
    
    if {$dist < $min_dist} {
      set min_dist $dist
      set closest_point $cp
      set closest_segment $seg
      set closest_segment_index $i
    }
    incr i
  }
  
  return [list $closest_point $closest_segment $closest_segment_index $min_dist]
}

proc split_segment {segment point} {
  set p1 [lindex $segment 0]
  set p2 [lindex $segment 1]
  
  # Return two new segments
  return [list [list $p1 $point] [list $point $p2]]
}

