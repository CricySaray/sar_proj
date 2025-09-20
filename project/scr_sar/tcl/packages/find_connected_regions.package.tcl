#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/19 12:21:45 Friday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : This procedure identifies connected regions of rectangles from a nested list, where connectivity is defined by overlapping areas or shared edge segments, 
#             and returns the number of such regions along with their constituent rectangles.
# input     : $rectangles: {{x y x1 y1} {x y x1 y1} ...}
# return    : list {$GroupNum {{x y x1 y1} ...} {{x y x1 y1} ...} ...}
#             for example: divided by 2 groups:
#                 {2 {{x y x1 y1} ...} {{x y x1 y1} ...}}
#             you can get only rects using: set rects [lrange $result 1 end] -> {{{x y x1 y1} ...} {{x y x1 y1} ...}}
# ref       : link url
# --------------------------
proc find_connected_regions {rectangles {debug 0}} {
  set rectangles [dbShape -output hrect {0 0 0 0} OR $rectangles]
  # Debug helper procedure
  proc debug_print {msg} {
    upvar debug debug
    if {$debug} {
      puts "DEBUG: $msg"
    }
  }
  
  # Check if input is a valid list
  if {![llength $rectangles]} {
    error "proc find_connected_regions: Invalid input: not a valid list"
  }
  debug_print "Received [llength $rectangles] rectangles for processing"
  
  # Store valid rectangles and validate each one
  set valid_rectangles [list]
  set index 0
  
  foreach rect $rectangles {
    debug_print "Processing rectangle at index $index: $rect"
    
    # Check if rectangle has exactly 4 coordinates
    if {[llength $rect] != 4} {
      error "proc find_connected_regions: Invalid rectangle format at index $index: must contain 4 coordinates"
    }
    
    # Extract coordinates
    lassign $rect x y x1 y1
    
    # Check if coordinates are valid numbers
    if {![string is double -strict $x] || ![string is double -strict $y] || 
        ![string is double -strict $x1] || ![string is double -strict $y1]} {
      error "proc find_connected_regions: Invalid coordinate format at index $index: coordinates must be numbers"
    }
    
    # Check if coordinates form a valid rectangle (x < x1 and y < y1)
    if {$x >= $x1 || $y >= $y1} {
      error "proc find_connected_regions: Invalid coordinates at index $index: must have x < x1 and y < y1"
    }
    
    lappend valid_rectangles [list $x $y $x1 $y1]
    debug_print "Validated rectangle: ($x, $y) to ($x1, $y1)"
    incr index
  }
  
  # Handle empty input case
  if {[llength $valid_rectangles] == 0} {
    debug_print "No valid rectangles found"
    return [list 0]
  }
  
  # Create adjacency list to represent connections between rectangles
  set num_rects [llength $valid_rectangles]
  set adjacency [list]
  
  for {set i 0} {$i < $num_rects} {incr i} {
    lappend adjacency [list]
  }
  debug_print "Created adjacency list for $num_rects rectangles"
  
  # Check connectivity between each pair of rectangles
  for {set i 0} {$i < $num_rects} {incr i} {
    set rect1 [lindex $valid_rectangles $i]
    lassign $rect1 x1 y1 x2 y2
    
    for {set j [expr {$i + 1}]} {$j < $num_rects} {incr j} {
      set rect2 [lindex $valid_rectangles $j]
      lassign $rect2 x3 y3 x4 y4
      
      debug_print "Checking connectivity between rectangle $i ($x1,$y1)-($x2,$y2) and $j ($x3,$y3)-($x4,$y4)"
      
      set connected 0
      
      # Check 1: If rectangles overlap (existing logic)
      set x_overlap [expr {!($x2 <= $x3 || $x1 >= $x4)}]
      set y_overlap [expr {!($y2 <= $y3 || $y1 >= $y4)}]
      
      if {$x_overlap && $y_overlap} {
        # Calculate overlap dimensions
        set overlap_width [expr {min($x2, $x4) - max($x1, $x3)}]
        set overlap_height [expr {min($y2, $y4) - max($y1, $y3)}]
        
        debug_print "Overlap detected - width: $overlap_width, height: $overlap_height"
        
        # Overlapping rectangles are connected
        if {$overlap_width > 0 && $overlap_height > 0} {
          set connected 1
          debug_print "Rectangles $i and $j are connected (overlap)"
        }
      }
      
      # Check 2: If rectangles have edge connections (new logic)
      if {!$connected} {
        # Case 1: rect1 right edge connects to rect2 left edge
        if {$x2 == $x3} {
          set y_overlap_start [expr {max($y1, $y3)}]
          set y_overlap_end [expr {min($y2, $y4)}]
          if {$y_overlap_start < $y_overlap_end} {
            set connected 1
            debug_print "Rectangles $i and $j are connected (right-left edge)"
          }
        # Case 2: rect1 left edge connects to rect2 right edge
        } elseif {$x1 == $x4} {
          set y_overlap_start [expr {max($y1, $y3)}]
          set y_overlap_end [expr {min($y2, $y4)}]
          if {$y_overlap_start < $y_overlap_end} {
            set connected 1
            debug_print "Rectangles $i and $j are connected (left-right edge)"
          }
        # Case 3: rect1 top edge connects to rect2 bottom edge
        } elseif {$y2 == $y3} {
          set x_overlap_start [expr {max($x1, $x3)}]
          set x_overlap_end [expr {min($x2, $x4)}]
          if {$x_overlap_start < $x_overlap_end} {
            set connected 1
            debug_print "Rectangles $i and $j are connected (top-bottom edge)"
          }
        # Case 4: rect1 bottom edge connects to rect2 top edge
        } elseif {$y1 == $y4} {
          set x_overlap_start [expr {max($x1, $x3)}]
          set x_overlap_end [expr {min($x2, $x4)}]
          if {$x_overlap_start < $x_overlap_end} {
            set connected 1
            debug_print "Rectangles $i and $j are connected (bottom-top edge)"
          }
        }
      }
      
      # If connected, add to adjacency list
      if {$connected} {
        lset adjacency $i [lappend [lindex $adjacency $i] $j]
        lset adjacency $j [lappend [lindex $adjacency $j] $i]
      } else {
        debug_print "Rectangles $i and $j are not connected"
      }
    }
  }
  
  # Find all connected components using BFS
  set visited [dict create]
  set components [list]
  set component_id 0
  
  for {set i 0} {$i < $num_rects} {incr i} {
    if {![dict exists $visited $i]} {
      debug_print "Starting new component search from rectangle $i"
      # Start BFS from unvisited rectangle
      set queue [list $i]
      dict set visited $i 1
      set component [list]
      
      while {[llength $queue] > 0} {
        set current [lindex $queue 0]
        set queue [lrange $queue 1 end]
        
        lappend component [lindex $valid_rectangles $current]
        debug_print "Added rectangle $current to component $component_id"
        
        # Add all unvisited neighbors to queue
        foreach neighbor [lindex $adjacency $current] {
          if {![dict exists $visited $neighbor]} {
            debug_print "Found new neighbor $neighbor, adding to queue"
            dict set visited $neighbor 1
            lappend queue $neighbor
          }
        }
      }
      
      lappend components $component
      debug_print "Completed component $component_id with [llength $component] rectangles"
      incr component_id
    }
  }
  
  # Construct the result in required format
  set num_components [llength $components]
  debug_print "Total components found: $num_components"
  
  set result [list $num_components]
  lappend result {*}$components
  
  return $result
}

