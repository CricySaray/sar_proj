#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/24 21:13:17 Wednesday
# label     : atomic_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : Connect the lines according to the coordinates of the pins and their order, and add annotations to them. This proc is used to provide processed coordinates and text rectangles for annotation positions.
# return    : list { {{x y} {x1 y1} {x y x1 y1}} ... }
# ref       : link url
# --------------------------
proc add_markers_and_text_for_point_list {coordinates {min_line_length 0.7} {max_line_length 6} {annotation_size {2 1}} {debug 0}} {
  # Validate input parameters
  if {![string is double -strict $min_line_length] || $min_line_length <= 0} {
    error "min_line_length must be a positive number"
  }
  
  if {![string is double -strict $max_line_length] || $max_line_length <= $min_line_length} {
    error "max_line_length must be a positive number greater than min_line_length"
  }
  
  if {[llength $annotation_size] != 2} {
    error "annotation_size must be a list with two elements {width height}"
  }
  
  set rect_width [lindex $annotation_size 0]
  set rect_height [lindex $annotation_size 1]
  
  if {![string is double -strict $rect_width] || $rect_width <= 0 ||
      ![string is double -strict $rect_height] || $rect_height <= 0} {
    error "annotation_size elements must be positive numbers"
  }
  
  if {![llength $coordinates]} {
    error "coordinates list cannot be empty"
  }
  
  # Validate coordinate points format
  foreach point $coordinates {
    if {[llength $point] != 2} {
      error "Invalid coordinate format: $point. Each coordinate must be a list {x y}"
    }
    set x [lindex $point 0]
    set y [lindex $point 1]
    if {![string is double -strict $x] || ![string is double -strict $y]} {
      error "Coordinate values must be numbers: $point"
    }
  }
  
  # Store results and tracking lists
  set result [list]
  set placed_rects [list]
  set annotation_lines [list]
  
  # Get number of coordinate points
  set num_points [llength $coordinates]
  
  if {$debug} {
    puts "Processing $num_points coordinates with:"
    puts "  min_line_length = $min_line_length"
    puts "  max_line_length = $max_line_length"
    puts "  annotation_size = $annotation_size"
  }
  
  # Process each coordinate point in order
  for {set i 0} {$i < $num_points} {incr i} {
    set point [lindex $coordinates $i]
    set x [lindex $point 0]
    set y [lindex $point 1]
    
    if {$debug} {
      puts "\nProcessing point $i: ($x, $y)"
    }
    
    # Determine placement side (alternating left/right)
    set target_side [expr {$i % 2 == 0 ? "right" : "left"}]
    if {$debug} {
      puts "  Target side for this point: $target_side"
    }
    
    # Calculate primary direction based on path segment
    set primary_dirs [list]
    if {$num_points > 1} {
      set next_i [expr {($i + 1) % $num_points}]
      set next_point [lindex $coordinates $next_i]
      
      # Calculate direction vector to next point
      set dx [expr {[lindex $next_point 0] - $x}]
      set dy [expr {[lindex $next_point 1] - $y}]
      
      # Calculate left and right perpendicular directions
      set right_dir [list [expr {-$dy}] [expr {$dx}]]  ;# Right perpendicular
      set left_dir [list [expr {$dy}] [expr {-$dx}]]   ;# Left perpendicular
      
      # Prioritize target side
      if {$target_side eq "right"} {
        lappend primary_dirs $right_dir $left_dir
      } else {
        lappend primary_dirs $left_dir $right_dir
      }
    }
    
    # Add basic directions as fallbacks
    set base_directions [list {1 0} {-1 0} {0 1} {0 -1}]
    set search_directions [concat $primary_dirs $base_directions]
    
    set found 0
    
    # Try each search direction
    foreach dir $search_directions {
      set base_dx [lindex $dir 0]
      set base_dy [lindex $dir 1]
      
      if {$base_dx == 0 && $base_dy == 0} {
        continue
      }
      
      if {$debug} {
        puts "  Trying direction: ($base_dx, $base_dy)"
      }
      
      # Generate distance candidates with 0.1 increments (shortest first)
      set distances [list]
      set d $min_line_length
      while {[expr {$d <= $max_line_length + 1e-9}]} {  ;# Add epsilon to handle floating point precision
        lappend distances $d
        set d [expr {$d + 0.1}]
        
        # Prevent infinite loop in case of floating point precision issues
        if {[llength $distances] > 10000} {
          break
        }
      }
      
      # Check each distance
      foreach dist $distances {
        # Fine-tune direction with small angle variations
        set angle_steps [list -10 0 10]
        foreach angle $angle_steps {
          set rad [expr {$angle * 3.1415926535 / 180}]
          
          # Rotate direction vector
          set dx [expr {$base_dx * cos($rad) - $base_dy * sin($rad)}]
          set dy [expr {$base_dx * sin($rad) + $base_dy * cos($rad)}]
          
          # Normalize direction
          set len [expr {sqrt($dx*$dx + $dy*$dy)}]
          if {$len > 0} {
            set dx [expr {$dx / $len}]
            set dy [expr {$dy / $len}]
          }
          
          # Calculate rectangle position
          set rect_x [expr {$x + $dx * $dist}]
          set rect_y [expr {$y + $dy * $dist}]
          set rect_x1 [expr {$rect_x + $rect_width}]
          set rect_y1 [expr {$rect_y + $rect_height}]
          set rect [list $rect_x $rect_y $rect_x1 $rect_y1]
          
          if {$debug && $angle == 0 && [expr {int(fmod($dist, 1.0) * 10)}] == 0} {
            puts "    Checking distance $dist, rect: $rect"
          }
          
          # Perform constraint checks
          set valid 1
          
          # Check 1: Overlap with coordinate points
          foreach p $coordinates {
            set px [lindex $p 0]
            set py [lindex $p 1]
            if {[_point_in_rect $px $py $rect]} {
              set valid 0
              if {$debug} {
                puts "    Invalid: Overlap with point ($px, $py)"
              }
              break
            }
          }
          if {!$valid} continue
          
          # Check 2: Intersection with connecting lines
          set line_indices [list]
          for {set j 0} {$j < [expr {$num_points - 1}]} {incr j} {
            lappend line_indices $j
          }
          
          foreach j $line_indices {
            set p1 [lindex $coordinates $j]
            set p2 [lindex $coordinates [expr {$j + 1}]]
            if {[_line_intersects_rect $p1 $p2 $rect]} {
              set valid 0
              if {$debug} {
                puts "    Invalid: Intersection with line from $p1 to $p2"
              }
              break
            }
          }
          if {!$valid} continue
          
          # Check 3: Overlap with existing annotations
          foreach placed_rect $placed_rects {
            if {[_rectangles_overlap $rect $placed_rect]} {
              set valid 0
              if {$debug} {
                puts "    Invalid: Overlap with existing rect: $placed_rect"
              }
              break
            }
          }
          if {!$valid} continue
          
          # Find closest corner of rectangle to point
          set corners [list \
            [list $rect_x $rect_y] \
            [list $rect_x1 $rect_y] \
            [list $rect_x $rect_y1] \
            [list $rect_x1 $rect_y1] \
          ]
          
          set closest_corner [_find_closest_point $corners [list $x $y]]
          set current_line [list $closest_corner $point]
          
          # Check 4: Line crossing with existing annotation lines
          foreach existing_line $annotation_lines {
            if {[_segments_intersect [lindex $current_line 0] [lindex $current_line 1] \
                 [lindex $existing_line 0] [lindex $existing_line 1]]} {
              set valid 0
              if {$debug} {
                puts "    Invalid: Crosses existing annotation line"
              }
              break
            }
          }
          if {!$valid} continue
          
          # Check 5: Line crossing with input segments
          foreach j $line_indices {
            set seg_p1 [lindex $coordinates $j]
            set seg_p2 [lindex $coordinates [expr {$j + 1}]]
            if {[_segments_intersect [lindex $current_line 0] [lindex $current_line 1] $seg_p1 $seg_p2]} {
              set valid 0
              if {$debug} {
                puts "    Invalid: Crosses input segment from $seg_p1 to $seg_p2"
              }
              break
            }
          }
          if {!$valid} continue
          
          # Check 6: Minimum distance requirement
          set corner_dist [expr {sqrt(
            ([lindex $closest_corner 0] - $x)*([lindex $closest_corner 0] - $x) +
            ([lindex $closest_corner 1] - $y)*([lindex $closest_corner 1] - $y)
          )}]
          
          if {$corner_dist >= $min_line_length} {
            lappend result [list $current_line $rect]
            lappend placed_rects $rect
            lappend annotation_lines $current_line
            set found 1
            
            if {$debug} {
              puts "    Found valid position. Corner distance: $corner_dist"
              puts "    Result entry: [list $current_line $rect]"
            }
            
            break
          }
        }
        if {$found} break
      }
      if {$found} break
    }
    
    if {!$found} {
      error "Could not find suitable position for annotation at point ($x, $y) on $target_side side within distance range ($min_line_length to $max_line_length)"
    }
  }
  
  if {$debug} {
    puts "\nProcessing complete. Returning [llength $result] results."
  }
  
  return $result
}

# All helper functions remain unchanged
proc _segments_intersect {p1 p2 p3 p4} {
  set a1x [lindex $p1 0]
  set a1y [lindex $p1 1]
  set a2x [lindex $p2 0]
  set a2y [lindex $p2 1]
  
  set b1x [lindex $p3 0]
  set b1y [lindex $p3 1]
  set b2x [lindex $p4 0]
  set b2y [lindex $p4 1]
  
  proc ccw {x1 y1 x2 y2 x3 y3} {
    return [expr {($x3 - $x1)*($y2 - $y1) - ($y3 - $y1)*($x2 - $x1)}]
  }
  
  set o1 [ccw $a1x $a1y $a2x $a2y $b1x $b1y]
  set o2 [ccw $a1x $a1y $a2x $a2y $b2x $b2y]
  set o3 [ccw $b1x $b1y $b2x $b2y $a1x $a1y]
  set o4 [ccw $b1x $b1y $b2x $b2y $a2x $a2y]
  
  if {($o1 * $o2 < 0) && ($o3 * $o4 < 0)} {
    return 1
  }
  
  proc on_segment {x1 y1 x2 y2 x3 y3} {
    return [expr {min($x1,$x2) <= $x3 && $x3 <= max($x1,$x2) &&
                  min($y1,$y2) <= $y3 && $y3 <= max($y1,$y2)}]
  }
  
  if {$o1 == 0 && [on_segment $a1x $a1y $a2x $a2y $b1x $b1y]} { return 1 }
  if {$o2 == 0 && [on_segment $a1x $a1y $a2x $a2y $b2x $b2y]} { return 1 }
  if {$o3 == 0 && [on_segment $b1x $b1y $b2x $b2y $a1x $a1y]} { return 1 }
  if {$o4 == 0 && [on_segment $b1x $b1y $b2x $b2y $a2x $a2y]} { return 1 }
  
  return 0
}

proc _rectangles_overlap {rect1 rect2} {
  set r1x1 [lindex $rect1 0]
  set r1y1 [lindex $rect1 1]
  set r1x2 [lindex $rect1 2]
  set r1y2 [lindex $rect1 3]
  
  set r2x1 [lindex $rect2 0]
  set r2y1 [lindex $rect2 1]
  set r2x2 [lindex $rect2 2]
  set r2y2 [lindex $rect2 3]
  
  if {$r1x1 > $r1x2} { set temp $r1x1; set r1x1 $r1x2; set r1x2 $temp }
  if {$r1y1 > $r1y2} { set temp $r1y1; set r1y1 $r1y2; set r1y2 $temp }
  if {$r2x1 > $r2x2} { set temp $r2x1; set r2x1 $r2x2; set r2x2 $temp }
  if {$r2y1 > $r2y2} { set temp $r2y1; set r2y1 $r2y2; set r2y2 $temp }
  
  return [expr {($r1x1 < $r2x2 && $r1x2 > $r2x1 && $r1y1 < $r2y2 && $r1y2 > $r2y1)}]
}

proc _point_in_rect {x y rect} {
  set rx1 [lindex $rect 0]
  set ry1 [lindex $rect 1]
  set rx2 [lindex $rect 2]
  set ry2 [lindex $rect 3]
  
  if {$rx1 > $rx2} { set temp $rx1; set rx1 $rx2; set rx2 $temp }
  if {$ry1 > $ry2} { set temp $ry1; set ry1 $ry2; set ry2 $temp }
  
  return [expr {($x >= $rx1 && $x <= $rx2) && ($y >= $ry1 && $y <= $ry2)}]
}

proc _line_intersects_rect {p1 p2 rect} {
  set x1 [lindex $p1 0]
  set y1 [lindex $p1 1]
  set x2 [lindex $p2 0]
  set y2 [lindex $p2 1]
  
  set rx1 [lindex $rect 0]
  set ry1 [lindex $rect 1]
  set rx2 [lindex $rect 2]
  set ry2 [lindex $rect 3]
  
  if {$rx1 > $rx2} { set temp $rx1; set rx1 $rx2; set rx2 $temp }
  if {$ry1 > $ry2} { set temp $ry1; set ry1 $ry2; set ry2 $temp }
  
  set rect_edges [list \
    [list [list $rx1 $ry1] [list $rx2 $ry1]] \
    [list [list $rx2 $ry1] [list $rx2 $ry2]] \
    [list [list $rx2 $ry2] [list $rx1 $ry2]] \
    [list [list $rx1 $ry2] [list $rx1 $ry1]] \
  ]
  
  foreach edge $rect_edges {
    if {[_segments_intersect [lindex $edge 0] [lindex $edge 1] $p1 $p2]} {
      return 1
    }
  }
  
  if {[_point_in_rect $x1 $y1 $rect] && [_point_in_rect $x2 $y2 $rect]} {
    return 1
  }
  
  return 0
}

proc _find_closest_point {points target} {
  set tx [lindex $target 0]
  set ty [lindex $target 1]
  set min_dist [expr {1e18}]
  set closest ""
  
  foreach p $points {
    set px [lindex $p 0]
    set py [lindex $p 1]
    set dist [expr {sqrt(($px - $tx)*($px - $tx) + ($py - $ty)*($py - $ty))}]
    if {$dist < $min_dist} {
      set min_dist $dist
      set closest $p
    }
  }
  
  return $closest
}

