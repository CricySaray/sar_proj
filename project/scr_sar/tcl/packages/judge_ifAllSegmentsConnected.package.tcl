#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/07 12:45:24 Thursday
# label     : package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : judge if all line segments are connected
# return    : 1: all connected
#             0: not connected
# ref       : link url
# --------------------------
proc judge_ifAllSegmentsConnected {segments {debug 0}} {
  # If there are no segments or only one segment, they are considered connected by default
  set n [llength $segments]
  if {$debug} {
    puts "Total number of segments: $n"
  }
  if {$n <= 1} {
    if {$debug} {
      puts "Less than 2 segments, considered connected"
    }
    return 1
  }
  # Build adjacency list to represent connections between segments
  array set adjacency {}
  for {set i 0} {$i < $n} {incr i} {
    set adjacency($i) [list]
  }
  # Check each pair of segments to see if they are connected
  for {set i 0} {$i < $n} {incr i} {
    set seg1 [lindex $segments $i]
    for {set j [expr {$i + 1}]} {$j < $n} {incr j} {
      set seg2 [lindex $segments $j]
      if {[if_connected $seg1 $seg2 $debug]} {
        lappend adjacency($i) $j
        lappend adjacency($j) $i
        if {$debug} {
          puts "Segments $i and $j are connected"
        }
      } elseif {$debug} {
        puts "Segments $i and $j are NOT connected"
      }
    }
  }
  # Use BFS to check if all segments are connected
  array set visited {}
  set queue [list 0]
  set visited(0) 1
  set count 1
  if {$debug} {
    puts "Starting BFS from segment 0"
  }
  while {[llength $queue] > 0} {
    set current [lindex $queue 0]
    set queue [lrange $queue 1 end]
    if {$debug} {
      puts "Processing segment $current, neighbors: $adjacency($current)"
    }
    foreach neighbor $adjacency($current) {
      if {![info exists visited($neighbor)]} {
        set visited($neighbor) 1
        incr count
        lappend queue $neighbor
        if {$debug} {
          puts "Discovered segment $neighbor, total visited: $count"
        }
      }
    }
  }
  # If all segments are visited, they are connected
  set result [expr {$count == $n ? 1 : 0}]
  if {$debug} {
    puts "Total visited segments: $count, total segments: $n"
    puts "Result: [expr {$result ? "Connected" : "Not connected"}]"
  }
  return $result
}
# Helper function: Check if two segments are connected
proc if_connected {seg1 seg2 {debug 0}} {
  set p1 [lindex $seg1 0]
  set p2 [lindex $seg1 1]
  set p3 [lindex $seg2 0]
  set p4 [lindex $seg2 1]
  set x1 [lindex $p1 0]
  set y1 [lindex $p1 1]
  set x2 [lindex $p2 0]
  set y2 [lindex $p2 1]
  set x3 [lindex $p3 0]
  set y3 [lindex $p3 1]
  set x4 [lindex $p4 0]
  set y4 [lindex $p4 1]
  if {$debug} {
    puts "Checking connection between segment ([list $x1 $y1] to [list $x2 $y2]) and ([list $x3 $y3] to [list $x4 $y4])"
  }
  # Ensure segment coordinates are in order
  if {$x1 > $x2} { set tmp $x1; set x1 $x2; set x2 $tmp }
  if {$y1 > $y2} { set tmp $y1; set y1 $y2; set y2 $tmp }
  if {$x3 > $x4} { set tmp $x3; set x3 $x4; set x4 $tmp }
  if {$y3 > $y4} { set tmp $y3; set y3 $y4; set y4 $tmp }
  # Determine if segment 1 is horizontal or vertical
  if {$y1 == $y2} {
    # Segment 1 is horizontal
    if {$debug} { puts "Segment 1 is horizontal (y=$y1)" }
    if {$y3 == $y4} {
      # Segment 2 is also horizontal - check if on the same level and x ranges overlap
      set result [expr {($y1 == $y3) && !($x2 < $x3 || $x4 < $x1)}]
      if {$debug} {
        puts "Segment 2 is horizontal (y=$y3). Same level: [expr {$y1 == $y3}], Overlapping x ranges: [expr {!($x2 < $x3 || $x4 < $x1)}]. Result: $result"
      }
      return $result
    } else {
      # Segment 2 is vertical - check if they intersect
      set result [expr {($y1 >= $y3 && $y1 <= $y4) && ($x3 >= $x1 && $x3 <= $x2)}]
      if {$debug} {
        puts "Segment 2 is vertical (x=$x3). y1 in range: [expr {($y1 >= $y3 && $y1 <= $y4)}], x3 in range: [expr {($x3 >= $x1 && $x3 <= $x2)}]. Result: $result"
      }
      return $result
    }
  } else {
    # Segment 1 is vertical
    if {$debug} { puts "Segment 1 is vertical (x=$x1)" }
    if {$x3 == $x4} {
      # Segment 2 is also vertical - check if on the same line and y ranges overlap
      set result [expr {($x1 == $x3) && !($y2 < $y3 || $y4 < $y1)}]
      if {$debug} {
        puts "Segment 2 is vertical (x=$x3). Same line: [expr {$x1 == $x3}], Overlapping y ranges: [expr {!($y2 < $y3 || $y4 < $y1)}]. Result: $result"
      }
      return $result
    } else {
      # Segment 2 is horizontal - check if they intersect
      set result [expr {($x1 >= $x3 && $x1 <= $x4) && ($y3 >= $y1 && $y3 <= $y2)}]
      if {$debug} {
        puts "Segment 2 is horizontal (y=$y3). x1 in range: [expr {($x1 >= $x3 && $x1 <= $x4)}], y3 in range: [expr {($y3 >= $y1 && $y3 <= $y2)}]. Result: $result"
      }
      return $result
    }
  }
}

if {0} {
  # 测试连通的线段
  set connected_segments {
      {{0 0} {0 2}}
      {{0 2} {2 2}}
      {{2 2} {2 4}}
  }
  puts [judge_ifAllSegmentsConnected $connected_segments]  ;# 输出 1
  # 测试不连通的线段
  set disconnected_segments {
      {{0 0} {0 2}}
      {{3 3} {3 5}}
  }
  puts [judge_ifAllSegmentsConnected $disconnected_segments]  ;# 输出 0
  
}
