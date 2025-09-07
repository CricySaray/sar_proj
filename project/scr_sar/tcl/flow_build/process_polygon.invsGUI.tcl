#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/06 15:34:27 Saturday
# label     : gui_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : processes a polygon vertex list by adjusting vertex order (clockwise/counter-clockwise), reordering the starting point to a specified corner 
#             (top-left/top-right/bottom-right/bottom-left), segmenting edges longer than twice the given step, and returning coordinates formatted to 3 
#             decimal places.
# input     : $polygon: polygon shapeList, for example: {{0 0} {0 1} {1 1} {1 0}}
#             $order  : clockwise|counter_clockwise
#             $start_pos: top_left|top_right|bottom_right|bottom_left
#             $step   : A non-negative number that triggers edge segmentation when edge length exceeds twice this value, 
#                       with each segment being at least this length.
#                       if it is 0, it will not check length of every segment
# return    : polygon shapeList, like input: $polygon
# ref       : link url
# --------------------------
proc process_polygon {polygon {order "clockwise"} {start_pos "top_left"} {step 0} {debug 0}} {
  # --------------------------
  # Helper function to format numbers to 3 decimal places
  # --------------------------
  proc format_3dec {num} {
    # Use TCL's format command to ensure 3 decimal places
    return [expr {double([format "%.3f" $num])}]
  }
  
  # --------------------------
  # Error checking for inputs
  # --------------------------
  if {![llength $polygon] || [llength $polygon] < 3} {
    error "proc process_polygon: Invalid polygon list: must contain at least 3 coordinate pairs"
  }
  foreach point $polygon {
    if {[llength $point] != 2} {
      error "proc process_polygon: Invalid point format: '$point' - must be a list of two numbers {x y}"
    }
    set x [lindex $point 0]
    set y [lindex $point 1]
    if {![string is double -strict $x] || ![string is double -strict $y]} {
      error "proc process_polygon: Invalid coordinate values in '$point': must be numeric"
    }
  }
  
  if {$order ni {clockwise counter_clockwise}} {
    error "proc process_polygon: Invalid order: '$order' - must be 'clockwise' or 'counter_clockwise'"
  }
  
  if {$start_pos ni {top_left top_right bottom_right bottom_left}} {
    error "proc process_polygon: Invalid start_pos: '$start_pos' - must be 'top_left', 'top_right', 'bottom_right', or 'bottom_left'"
  }
  
  if {![string is double -strict $step] || $step < 0} {
    error "proc process_polygon: Invalid step: '$step' - must be a non-negative number"
  }
  
  if {$debug ni {0 1}} {
    error "proc process_polygon: Invalid debug: '$debug' - must be 0 (off) or 1 (on)"
  }
  
  if {$debug} {
    puts "===== Debug Mode Enabled ====="
    puts "Original polygon: $polygon"
    puts "Requested order: $order"
    puts "Requested start position: $start_pos"
    puts "Segment step: $step"
    puts "=============================="
  }
  
  # --------------------------
  # Determine current order
  # --------------------------
  set area 0
  set num_points [llength $polygon]
  for {set i 0} {$i < $num_points} {incr i} {
    set j [expr {($i + 1) % $num_points}]
    set xi [lindex [lindex $polygon $i] 0]
    set yi [lindex [lindex $polygon $i] 1]
    set xj [lindex [lindex $polygon $j] 0]
    set yj [lindex [lindex $polygon $j] 1]
    set area [expr {$area + ($xi * $yj - $xj * $yi)}]
  }
  
  set current_order [expr {$area > 0 ? "counter_clockwise" : "clockwise"}]
  if {$debug} {
    puts "Calculated current order: $current_order (area sign: [expr {$area >= 0 ? "+" : "-"}])"
  }
  
  # --------------------------
  # Adjust order if needed
  # --------------------------
  set adjusted_points $polygon
  if {$current_order ne $order} {
    set adjusted_points [lreverse $adjusted_points]
    if {$debug} {
      puts "Order adjusted to $order (reversed polygon)"
      puts "Adjusted polygon: $adjusted_points"
    }
  }
  
  # --------------------------
  # Calculate bounding rectangle
  # --------------------------
  set min_x [lindex [lindex $adjusted_points 0] 0]
  set max_x $min_x
  set min_y [lindex [lindex $adjusted_points 0] 1]
  set max_y $min_y
  
  foreach point $adjusted_points {
    set x [lindex $point 0]
    set y [lindex $point 1]
    if {$x < $min_x} { set min_x $x }
    if {$x > $max_x} { set max_x $x }
    if {$y < $min_y} { set min_y $y }
    if {$y > $max_y} { set max_y $y }
  }
  
  if {$debug} {
    puts "Bounding rectangle: min_x=$min_x, max_x=$max_x, min_y=$min_y, max_y=$max_y"
  }
  
  # --------------------------
  # Determine target corner for start position
  # --------------------------
  switch $start_pos {
    "top_left" {
      set target_x $min_x
      set target_y $max_y
    }
    "top_right" {
      set target_x $max_x
      set target_y $max_y
    }
    "bottom_right" {
      set target_x $max_x
      set target_y $min_y
    }
    "bottom_left" {
      set target_x $min_x
      set target_y $min_y
    }
  }
  
  if {$debug} {
    puts "Target start corner: ($target_x, $target_y) for $start_pos"
  }
  
  # --------------------------
  # Find closest point to target corner
  # --------------------------
  set min_dist [expr {pow([lindex [lindex $adjusted_points 0] 0] - $target_x, 2) + pow([lindex [lindex $adjusted_points 0] 1] - $target_y, 2)}]
  set start_idx 0
  set i 0
  
  foreach point $adjusted_points {
    set x [lindex $point 0]
    set y [lindex $point 1]
    set dist [expr {pow($x - $target_x, 2) + pow($y - $target_y, 2)}]
    
    if {$debug} {
      puts "  Point ($x,$y) distance to target: [expr {sqrt($dist)}]"
    }
    
    if {$dist < $min_dist} {
      set min_dist $dist
      set start_idx $i
      if {$debug} {
        puts "  New closest point at index $i (distance [expr {sqrt($dist)}])"
      }
    }
    incr i
  }
  
  set start_point [lindex $adjusted_points $start_idx]
  if {$debug} {
    puts "Selected start point: $start_point (original index $start_idx)"
  }
  
  # --------------------------
  # Reorder polygon from start index
  # --------------------------
  set ordered_points [concat [lrange $adjusted_points $start_idx end] [lrange $adjusted_points 0 [expr {$start_idx - 1}]]]
  if {$debug} {
    puts "New start index: $start_idx"
    puts "Points after reordering by start position: $ordered_points"
  }
  
  # --------------------------
  # Segment edges if needed (修正分割逻辑)
  # --------------------------
  if {$step > 0} {
    set segmented_points [list]
    set num_points [llength $ordered_points]
    
    for {set i 0} {$i < $num_points} {incr i} {
      set p1 [lindex $ordered_points $i]
      # Format original point to 3 decimal places
      set x1_fmt [format_3dec [lindex $p1 0]]
      set y1_fmt [format_3dec [lindex $p1 1]]
      lappend segmented_points [list $x1_fmt $y1_fmt]
      
      # Get next point (last connects to first)
      if {$i == [expr {$num_points - 1}]} {
        set p2 [lindex $ordered_points 0]
      } else {
        set p2 [lindex $ordered_points [expr {$i + 1}]]
      }
      
      # Calculate edge length and direction
      set x1 [lindex $p1 0]
      set y1 [lindex $p1 1]
      set x2 [lindex $p2 0]
      set y2 [lindex $p2 1]
      set dx [expr {$x2 - $x1}]
      set dy [expr {$y2 - $y1}]
      set length [expr {sqrt(pow($dx, 2) + pow($dy, 2))}]
      
      # Unit vector for direction
      set ux [expr {$dx / $length}]
      set uy [expr {$dy / $length}]
      
      if {$debug} {
        puts "Processing edge from ($x1,$y1) to ($x2,$y2): length = $length"
      }
      
      # Segment if length > 2*step (使用新的分割逻辑)
      if {$length > 2 * $step} {
        if {$debug} {
          puts "  Edge needs segmentation: length $length > 2*$step"
          puts "  Segment details:"
        }
        
        # Track current position along the edge
        set current_length 0
        set segment_count 1
        set prev_x $x1
        set prev_y $y1
        set prev_x_fmt $x1_fmt
        set prev_y_fmt $y1_fmt
        
        # Continue segmentation while remaining length > 2*step
        while {($length - $current_length) > 2 * $step} {
          # Add a segment of exactly step length
          set current_length [expr {$current_length + $step}]
          set x [expr {$x1 + $current_length * $ux}]
          set y [expr {$y1 + $current_length * $uy}]
          
          # Format to 3 decimal places
          set x_fmt [format_3dec $x]
          set y_fmt [format_3dec $y]
          lappend segmented_points [list $x_fmt $y_fmt]
          
          # Calculate and display segment length
          if {$debug} {
            set seg_len [expr {sqrt(pow($x - $prev_x, 2) + pow($y - $prev_y, 2))}]
            puts "    Segment $segment_count: ($prev_x_fmt,$prev_y_fmt) to ($x_fmt,$y_fmt) - length: $seg_len"
          }
          
          # Update tracking variables
          set prev_x $x
          set prev_y $y
          set prev_x_fmt $x_fmt
          set prev_y_fmt $y_fmt
          incr segment_count
        }
        
        # Display last segment (remaining part)
        if {$debug && $current_length > 0} {
          set x2_fmt [format_3dec $x2]
          set y2_fmt [format_3dec $y2]
          set seg_len [expr {sqrt(pow($x2 - $prev_x, 2) + pow($y2 - $prev_y, 2))}]
          puts "    Segment $segment_count: ($prev_x_fmt,$prev_y_fmt) to ($x2_fmt,$y2_fmt) - length: $seg_len"
        }
      }
    }
    
    set ordered_points $segmented_points
    if {$debug} {
      puts "Final polygon after segmentation: $ordered_points"
    }
  } else {
    # Format original polygon to 3 decimal places when no segmentation
    set formatted_points [list]
    foreach point $ordered_points {
      set x_fmt [format_3dec [lindex $point 0]]
      set y_fmt [format_3dec [lindex $point 1]]
      lappend formatted_points [list $x_fmt $y_fmt]
    }
    set ordered_points $formatted_points
  }
  
  if {$debug} {
    puts "===== Debug Mode Ended ====="
  }
  
  return $ordered_points
}

