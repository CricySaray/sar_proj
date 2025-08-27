#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/26 18:25:15 Tuesday
# label     : gui_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This proc finds the shortest path in a tree or cyclic structure of horizontal and vertical segments, 
#             handling cycles by ensuring BFS doesn't enter infinite loops and selecting the shortest path when cycles exist.
#             Added function: Prevent start and end from mapping to the same closest point; handle cycles in path structure.
#             Added debug information with control switch.
# return    : list {{{x y} {x1 y1}} {{x y} {x1 y1}} ...}
# ref       : link url
# --------------------------
proc find_shortest_path_with_offset {start end segments {debug 0}} {
  # Debug: Print function call and input parameters
  if {$debug} {
    puts "\n======================================"
    puts "Starting find_shortest_path_with_offset"
    puts "Start point: $start"
    puts "End point: $end"
    puts "Total segments to process: [llength $segments]"
    puts "Debug mode enabled: [expr {$debug ? "Yes" : "No"}]"
    puts "======================================"
  }
  
  # Validate input format
  if {[llength $start] != 2 || [llength $end] != 2} {
    error "Start and end points must be coordinate pairs"
  }
  
  foreach seg $segments {
    if {[llength $seg] != 2 || [llength [lindex $seg 0]] != 2 || [llength [lindex $seg 1]] != 2} {
      error "Invalid segment format: $seg. Each segment must be in the format {{x y} {x1 y1}}"
    }
  }
  
  # Find closest points on the structure for start and end (initial calculation)
  lassign [find_closest_segment_and_point $start $segments] start_closest start_seg start_seg_idx start_dist
  lassign [find_closest_segment_and_point $end $segments] end_closest end_seg end_seg_idx end_dist
  
  # Debug: Print initial closest points
  if {$debug} {
    puts "\nInitial closest points calculation:"
    puts "Start closest point: $start_closest (distance: $start_dist)"
    puts "Start segment: $start_seg (index: $start_seg_idx)"
    puts "End closest point: $end_closest (distance: $end_dist)"
    puts "End segment: $end_seg (index: $end_seg_idx)"
  }

  # Handle case where start and end map to the same closest point
  if {$start_closest eq $end_closest} {
    if {$debug} {
      puts "\nWarning: Start and end map to the same closest point. Recalculating..."
    }
    
    # Compare distances from start/end to the common closest point
    set start_to_common_dist $start_dist
    set end_to_common_dist $end_dist
    
    # Strategy: Keep the point with smaller distance to common point; re-calculate the other
    if {$start_to_common_dist <= $end_to_common_dist} {
      if {$debug} {
        puts "Keeping start point (closer: $start_to_common_dist <= $end_to_common_dist), recalculating end point"
      }
      
      # Keep start_closest, re-calculate end_closest (exclude segments containing common point)
      set filtered_segments [list]
      foreach seg $segments {
        if {$seg ne $start_seg && $seg ne $end_seg} {
          lappend filtered_segments $seg
        }
      }
      
      if {$debug} {
        puts "Filtered segments count after excluding common point segments: [llength $filtered_segments]"
      }
      
      if {[llength $filtered_segments] == 0} {
        error "No valid segments left after excluding common point's segments; cannot find valid end point"
      }
      
      # Re-calculate end's closest point from filtered segments
      lassign [find_closest_segment_and_point $end $filtered_segments] new_end_closest new_end_seg dummy new_end_dist
      set new_end_seg_idx [lsearch $segments $new_end_seg]
      if {$new_end_seg_idx == -1} {
        error "Re-calculated end segment not found in original segments; invalid state"
      }
      
      # Update end-related variables
      set end_closest $new_end_closest
      set end_seg $new_end_seg
      set end_seg_idx $new_end_seg_idx
      set end_dist $new_end_dist
      
      if {$debug} {
        puts "Recalculated end closest point: $end_closest (distance: $end_dist)"
        puts "Recalculated end segment: $end_seg (index: $end_seg_idx)"
      }
    } else {
      if {$debug} {
        puts "Keeping end point (closer: $end_to_common_dist < $start_to_common_dist), recalculating start point"
      }
      
      # Keep end_closest, re-calculate start_closest
      set filtered_segments [list]
      foreach seg $segments {
        if {$seg ne $start_seg && $seg ne $end_seg} {
          lappend filtered_segments $seg
        }
      }
      
      if {$debug} {
        puts "Filtered segments count after excluding common point segments: [llength $filtered_segments]"
      }
      
      if {[llength $filtered_segments] == 0} {
        error "No valid segments left after excluding common point's segments; cannot find valid start point"
      }
      
      # Re-calculate start's closest point from filtered segments
      lassign [find_closest_segment_and_point $start $filtered_segments] new_start_closest new_start_seg dummy new_start_dist
      set new_start_seg_idx [lsearch $segments $new_start_seg]
      if {$new_start_seg_idx == -1} {
        error "Re-calculated start segment not found in original segments; invalid state"
      }
      
      # Update start-related variables
      set start_closest $new_start_closest
      set start_seg $new_start_seg
      set start_seg_idx $new_start_seg_idx
      set start_dist $new_start_dist
      
      if {$debug} {
        puts "Recalculated start closest point: $start_closest (distance: $start_dist)"
        puts "Recalculated start segment: $start_seg (index: $start_seg_idx)"
      }
    }
  }
  
  # Create modified segments list by splitting segments if needed
  set modified_segments $segments
  
  # Split start segment if closest point is not an endpoint
  if {$start_closest ne [lindex $start_seg 0] && $start_closest ne [lindex $start_seg 1]} {
    if {$debug} {
      puts "\nSplitting start segment at closest point (not an endpoint)"
    }
    lassign [split_segment $start_seg $start_closest] new_seg1 new_seg2
    set modified_segments [lreplace $modified_segments $start_seg_idx $start_seg_idx $new_seg1 $new_seg2]
    
    # Adjust end segment index if needed
    if {$end_seg_idx > $start_seg_idx} {
      incr end_seg_idx
      if {$debug} {
        puts "Adjusted end segment index to: $end_seg_idx"
      }
    }
    
    if {$debug} {
      puts "New start segments: $new_seg1 and $new_seg2"
      puts "Modified segments count: [llength $modified_segments]"
    }
  }
  
  # Split end segment if closest point is not an endpoint
  if {$end_closest ne [lindex $end_seg 0] && $end_closest ne [lindex $end_seg 1]} {
    if {$debug} {
      puts "\nSplitting end segment at closest point (not an endpoint)"
    }
    lassign [split_segment $end_seg $end_closest] new_seg1 new_seg2
    set modified_segments [lreplace $modified_segments $end_seg_idx $end_seg_idx $new_seg1 $new_seg2]
    
    if {$debug} {
      puts "New end segments: $new_seg1 and $new_seg2"
      puts "Modified segments count: [llength $modified_segments]"
    }
  }
  
  # Build graph structure with unique node identifiers
  array set graph {}
  array set segment_map {}
  array set node_to_segments {}  ;# Map nodes to connected segments for verification
  
  # Process each segment to build the graph
  foreach seg $modified_segments {
    set p1 [lindex $seg 0]
    set p2 [lindex $seg 1]
    # Use formatted strings to ensure unique node identification
    set p1_str [format "%.6f,%.6f" [lindex $p1 0] [lindex $p1 1]]
    set p2_str [format "%.6f,%.6f" [lindex $p2 0] [lindex $p2 1]]
    
    # Add points to graph with bidirectional connections
    lappend graph($p1_str) $p2_str
    lappend graph($p2_str) $p1_str
    
    # Save segment mapping with both possible key orders
    set key1 "$p1_str|$p2_str"
    set key2 "$p2_str|$p1_str"
    set segment_map($key1) $seg
    set segment_map($key2) $seg
    
    # Map nodes to their connected segments
    lappend node_to_segments($p1_str) $seg
    lappend node_to_segments($p2_str) $seg
  }
  
  # Collect all unique nodes and segments for completeness check
  set all_nodes [array names graph]
  set total_node_count [llength $all_nodes]
  set all_segment_ids [lsort -unique [array names segment_map]]
  set total_segment_count [expr {[llength $all_segment_ids] / 2}]  ;# Each segment counted twice
  
  # Debug: Print graph information
  if {$debug} {
    puts "\nGraph construction complete:"
    puts "Total nodes in graph: $total_node_count"
    puts "Total unique segments in graph: $total_segment_count"
    puts "Start node string: [format "%.6f,%.6f" [lindex $start_closest 0] [lindex $start_closest 1]]"
    puts "End node string: [format "%.6f,%.6f" [lindex $end_closest 0] [lindex $end_closest 1]]"
    if {$debug > 1} {
      puts "All nodes in graph: $all_nodes"
    }
  }
  
  # BFS algorithm with strict complete branch processing
  array set visited {}       ;# Stores shortest distance to each node
  array set parent {}        ;# Stores path history
  array set cycle_entry {}   ;# Tracks entry point when entering a cycle
  array set processed {}     ;# Tracks all processed nodes
  array set processed_segs {};# Tracks all processed segments
  
  set start_str [format "%.6f,%.6f" [lindex $start_closest 0] [lindex $start_closest 1]]
  set end_str [format "%.6f,%.6f" [lindex $end_closest 0] [lindex $end_closest 1]]
  
  # Check if start and end points exist in the graph
  if {![info exists graph($start_str)]} {
    error "Start point $start_closest is not in the graph"
  }
  if {![info exists graph($end_str)]} {
    error "End point $end_closest is not in the graph"
  }
  
  # Initialize queue with start node and distance 0
  set queue [list [list $start_str 0]]
  set visited($start_str) 0
  set found 0
  set shortest_distance Inf
  set processed_node_count 0
  set processed_segment_count 0
  
  if {$debug} {
    puts "\nStarting BFS search with strict branch processing:"
    puts "Initial queue: $queue"
    puts "Searching from $start_str to $end_str"
    puts "Total nodes to process: $total_node_count"
    puts "Total segments to process: $total_segment_count"
    puts "--------------------------------------"
  }
  
  # Process until queue is completely empty (all reachable nodes processed)
  while {[llength $queue] > 0} {
    # Get the node with current shortest distance
    set current_entry [lindex $queue 0]
    set queue [lrange $queue 1 end]
    set current [lindex $current_entry 0]
    set current_dist [lindex $current_entry 1]
    
    # Mark node as processed if not already marked
    if {![info exists processed($current)]} {
      set processed($current) 1
      incr processed_node_count
      
      # Mark all segments connected to this node as processed
      foreach seg $node_to_segments($current) {
        set seg_id [join $seg "|"]
        if {![info exists processed_segs($seg_id)]} {
          set processed_segs($seg_id) 1
          incr processed_segment_count
        }
      }
    }
    
    if {$debug} {
      puts "\nBFS Step:"
      puts "Processing node: $current (distance: $current_dist)"
      puts "Remaining queue length: [llength $queue]"
      puts "Processed nodes: $processed_node_count/$total_node_count"
      puts "Processed segments: $processed_segment_count/$total_segment_count"
    }
    
    # Check if we found the end node
    if {$current eq $end_str && !$found} {
      set found 1
      set shortest_distance $current_dist
      if {$debug} {
        puts "Found end node! Current shortest distance: $shortest_distance"
        puts "Continuing to process all remaining branches..."
      }
    }
    
    # Skip if we've already found a shorter path to this node
    if {$current_dist > $visited($current)} {
      if {$debug} {
        puts "Skipping node $current - found shorter path ($visited($current)) already"
      }
      continue
    }
    
    # Explore all neighbors (even if end node is found)
    foreach neighbor $graph($current) {
      set new_dist [expr {$current_dist + 1}]
      
      if {$debug} {
        puts "Checking neighbor: $neighbor (new distance: $new_dist)"
      }
      
      # Check if this neighbor connection indicates entering a cycle
      set entering_cycle 0
      if {[info exists visited($neighbor)] && $new_dist == $visited($neighbor)} {
        set entering_cycle 1
        if {$debug} {
          puts "Detected potential cycle entry at $current -> $neighbor"
        }
      }
      
      # Visit neighbor if:
      # 1. It hasn't been visited yet, or
      # 2. We found a shorter path to it than previously known
      if {![info exists visited($neighbor)] || $new_dist < $visited($neighbor)} {
        set visited($neighbor) $new_dist
        set parent($neighbor) $current
        
        # Track cycle entry point if we're entering a new cycle
        if {![info exists cycle_entry($neighbor)] && $entering_cycle} {
          set cycle_entry($neighbor) $current
          if {$debug} {
            puts "Recorded cycle entry: $current -> $neighbor"
          }
        }
        
        lappend queue [list $neighbor $new_dist]
        
        if {$debug} {
          puts "Added neighbor $neighbor to queue. Parent set to $current"
        }
      } else {
        if {$debug} {
          puts "Neighbor $neighbor already visited with shorter or equal distance ($visited($neighbor))"
          puts "Still processing to ensure all branches are explored"
        }
      }
    }
  }
  
  # Verify all reachable nodes and segments have been processed
  set unprocessed_nodes [list]
  foreach node $all_nodes {
    if {![info exists processed($node)]} {
      lappend unprocessed_nodes $node
    }
  }
  
  set unprocessed_segments [list]
  foreach seg $modified_segments {
    set seg_id [join $seg "|"]
    if {![info exists processed_segs($seg_id)]} {
      lappend unprocessed_segments $seg
    }
  }
  
  # Debug: Complete search verification
  if {$debug} {
    puts "\nBFS search complete. Queue is empty."
    puts "Processed nodes: $processed_node_count/$total_node_count"
    puts "Processed segments: $processed_segment_count/$total_segment_count"
    
    if {[llength $unprocessed_nodes] > 0} {
      puts "Unreachable nodes (not processed): [llength $unprocessed_nodes]"
      if {$debug > 1} {
        puts "List of unreachable nodes: $unprocessed_nodes"
      }
    } else {
      puts "All nodes in graph were processed"
    }
    
    if {[llength $unprocessed_segments] > 0} {
      puts "Unreachable segments (not processed): [llength $unprocessed_segments]"
      if {$debug > 1} {
        puts "List of unreachable segments: $unprocessed_segments"
      }
    } else {
      puts "All segments in graph were processed"
    }
  }
  
  # Check if there are reachable but unprocessed segments (should not happen)
  if {[llength $unprocessed_segments] > 0 && $processed_node_count > 0} {
    if {$debug} {
      puts "Warning: Some reachable segments were not processed - this indicates a logic error"
    }
  }
  
  # Only return no path if all reachable nodes/segments were processed
  if {!$found} {
    if {$debug} {
      puts "\nNo path exists between start and end after complete processing of all reachable segments"
      if {[llength $unprocessed_nodes] > 0} {
        puts "Note: Some nodes/segments were unreachable from the start point"
      }
    }
    return [list]
  }
  
  # Backtrack to build the path from end to start
  set path [list]
  set current $end_str
  set in_cycle 0
  
  if {$debug} {
    puts "\nBacktracking to build path from end to start:"
    puts "Starting at end node: $end_str"
    if {[array size cycle_entry] > 0} {
      puts "Detected cycles with entries: [array get cycle_entry]"
    }
  }
  
  while {$current ne $start_str} {
    set prev $parent($current)
    
    # Check if we're exiting a cycle
    if {[info exists cycle_entry($current)] && !$in_cycle} {
      set in_cycle 1
      if {$debug} {
        puts "Exiting cycle at node: $current"
      }
    } elseif {!$in_cycle && [info exists cycle_entry($prev)]} {
      set in_cycle 1
      if {$debug} {
        puts "Entering cycle at node: $prev"
      }
    } elseif {$in_cycle && ![info exists cycle_entry($current)]} {
      set in_cycle 0
      if {$debug} {
        puts "Completely exited cycle"
      }
    }
    
    set key "$prev|$current"
    lappend path $segment_map($key)
    
    if {$debug} {
      puts "Moving from $current to parent $prev (segment: $segment_map($key))"
    }
    
    set current $prev
  }
  
  # Reverse path to get from start to end
  set path [lreverse $path]
  
  if {$debug} {
    puts "\nPath reversed to start->end order. Path length: [llength $path]"
  }
  
  # Ensure all segments are properly connected in sequence
  set path_length [llength $path]
  if {$path_length > 0} {
    # Ensure first segment starts with start_closest
    set first_seg [lindex $path 0]
    if {[lindex $first_seg 0] ne $start_closest} {
      set path [lreplace $path 0 0 [list [lindex $first_seg 1] [lindex $first_seg 0]]]
      if {$debug} {
        puts "Reversed first segment to start with start_closest: [lindex $path 0]"
      }
    }
    
    # Check each consecutive segment pair
    for {set i 1} {$i < $path_length} {incr i} {
      set prev_seg [lindex $path [expr {$i - 1}]]
      set curr_seg [lindex $path $i]
      
      set prev_end [lindex $prev_seg 1]
      set curr_start [lindex $curr_seg 0]
      set curr_end [lindex $curr_seg 1]
      
      # Reverse segment if needed to maintain connection
      if {$curr_start ne $prev_end} {
        if {$curr_end eq $prev_end} {
          set reversed_seg [list $curr_end $curr_start]
          set path [lreplace $path $i $i $reversed_seg]
          if {$debug} {
            puts "Reversed segment $i to maintain connection: $reversed_seg"
          }
        } else {
          error "Segment connection error: Previous end ($prev_end) doesn't match current start ($curr_start) or end ($curr_end)"
        }
      }
    }
    
    # Ensure last segment ends with end_closest
    set last_seg [lindex $path end]
    if {[lindex $last_seg 1] ne $end_closest} {
      set path [lreplace $path end end [list [lindex $last_seg 1] [lindex $last_seg 0]]]
      if {$debug} {
        puts "Reversed last segment to end with end_closest: [lindex $path end]"
      }
    }
  }
  
  if {$debug} {
    puts "\nFinal path constructed with [llength $path] segments:"
    for {set i 0} {$i < [llength $path]} {incr i} {
      puts "  Segment $i: [lindex $path $i]"
    }
    puts "\nExiting find_shortest_path_with_offset"
    puts "======================================"
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
    # Check if point's projection is on the segment
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
  } else {
    # Check if point's projection is on the segment
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
  
  # Return two new segments that maintain horizontal/vertical property
  return [list [list $p1 $point] [list $point $p2]]
}

