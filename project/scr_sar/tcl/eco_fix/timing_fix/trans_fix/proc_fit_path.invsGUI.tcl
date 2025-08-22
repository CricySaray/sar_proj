#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/22 17:29:09 Friday
# label     : gui_proc math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This 'fit_path' procedure finds the longest path in a graph of line segments, matches its endpoints with given 
#             start and end points, and returns the path segments in the correct direction.
#             Remove small branches of the path, retain the main trunk, and finally return the path segments of the main trunk.
# return    : {{{x y} {x1 y1}} {{x y} {x1 y1}} ...} fited segments list
# ref       : link url
# --------------------------
proc fit_path {start_point end_point segments} {
  # Step 1: Build graph structure from segments
  set graph [dict create]
  set all_points [list]
  
  foreach seg $segments {
    lassign $seg p1 p2
    lappend all_points $p1 $p2
    dict lappend graph $p1 $p2
    dict lappend graph $p2 $p1
  }
  
  # Verify graph connectivity
  if {![is_connected $graph]} {
    error "proc fit_path: Segments are disconnected - cannot form a continuous path"
  }
  
  # Step 2: Find the longest path in the graph
  set longest_path [find_longest_path $graph]
  
  if {[llength $longest_path] < 2} {
    error "proc fit_path: Could not find valid longest path"
  }
  
  # Step 3: Get endpoints of the longest path
  set path_endpoint1 [lindex $longest_path 0]
  set path_endpoint2 [lindex $longest_path end]
  
  # Step 4: Match input points to path endpoints
  set dist_start_to_1 [distance_to_point $start_point $path_endpoint1]
  set dist_start_to_2 [distance_to_point $start_point $path_endpoint2]
  
  # Determine direction based on closest match
  if {$dist_start_to_1 <= $dist_start_to_2} {
    set path_start $path_endpoint1
    set path_end $path_endpoint2
  } else {
    set path_start $path_endpoint2
    set path_end $path_endpoint1
  }
  
  # Step 5: Extract segments in order
  set final_segments [list]
  for {set i 0} {$i < [llength $longest_path]-1} {incr i} {
    set p1 [lindex $longest_path $i]
    set p2 [lindex $longest_path [expr {$i+1}]]
    lappend final_segments [list $p1 $p2]
  }
  
  return $final_segments
}

# Helper to find the longest path using DFS
proc find_longest_path {graph} {
  set all_points [dict keys $graph]
  set max_length 0
  set longest_path [list]
  
  foreach start $all_points {
    set visited [dict create]
    dict set visited $start 1
    set current_path [list $start]
    
    # Explore from this start point
    set result [dfs_longest $start $current_path $visited $graph]
    set candidate_path [lindex $result 0]
    set candidate_length [lindex $result 1]
    
    if {$candidate_length > $max_length} {
      set max_length $candidate_length
      set longest_path $candidate_path
    }
  }
  
  return $longest_path
}

# DFS helper for longest path search (fixed dictionary copy)
proc dfs_longest {current_node current_path visited graph} {
  set max_length [llength $current_path]
  set longest_path $current_path
  
  foreach neighbor [dict get $graph $current_node] {
    if {![dict exists $visited $neighbor]} {
      # TCL 中正确的字典复制方法：
      # 1. 用 {*} 展开原字典的键值对
      # 2. 用 dict create 重建新字典
      set new_visited [dict create {*}$visited]
      dict set new_visited $neighbor 1
      
      set new_path [concat $current_path [list $neighbor]]
      set result [dfs_longest $neighbor $new_path $new_visited $graph]
      set candidate_path [lindex $result 0]
      set candidate_length [lindex $result 1]
      
      if {$candidate_length > $max_length} {
        set max_length $candidate_length
        set longest_path $candidate_path
      }
    }
  }
  
  return [list $longest_path $max_length]
}

# Helper to check graph connectivity
proc is_connected {graph} {
  if {[dict size $graph] == 0} {
    return 1
  }
  
  set start_node [lindex [dict keys $graph] 0]
  set visited [dict create $start_node 1]
  set queue [list $start_node]
  
  while {[llength $queue] > 0} {
    set node [lindex $queue 0]
    set queue [lrange $queue 1 end]
    
    foreach neighbor [dict get $graph $node] {
      if {![dict exists $visited $neighbor]} {
        dict set visited $neighbor 1
        lappend queue $neighbor
      }
    }
  }
  
  return [expr {[dict size $visited] == [dict size $graph]}]
}

# Helper to calculate distance between two points
proc distance_to_point {p1 p2} {
  lassign $p1 x1 y1
  lassign $p2 x2 y2
  return [expr {sqrt(($x2 - $x1)*($x2 - $x1) + ($y2 - $y1)*($y2 - $y1))}]
}

