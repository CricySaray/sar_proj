proc add_annotations {coordinates min_line_length annotation_size} {
  # Store the result list
  set result [list]
  
  # Get annotation rectangle dimensions from parameter
  set rect_width [lindex $annotation_size 0]
  set rect_height [lindex $annotation_size 1]
  
  # Get the number of coordinate points
  set num_points [llength $coordinates]
  
  # Process each coordinate point
  for {set i 0} {$i < $num_points} {incr i} {
    set point [lindex $coordinates $i]
    set x [lindex $point 0]
    set y [lindex $point 1]
    
    # Try different directions to find suitable annotation position
    set directions [list {1 0} {-1 0} {0 1} {0 -1} {1 1} {1 -1} {-1 1} {-1 -1}]
    set found 0
    
    # Try different directions and distances
    foreach dir $directions {
      set dx [lindex $dir 0]
      set dy [lindex $dir 1]
      
      # Start from minimum distance and increase gradually
      for {set dist $min_line_length} {$dist <= 200} {incr dist 10} {
        # Calculate annotation rectangle position
        set rect_x [expr {$x + $dx * $dist}]
        set rect_y [expr {$y + $dy * $dist}]
        set rect_x1 [expr {$rect_x + $rect_width}]
        set rect_y1 [expr {$rect_y + $rect_height}]
        set rect [list $rect_x $rect_y $rect_x1 $rect_y1]
        
        # Check if rectangle overlaps with any coordinate point
        set overlap 0
        foreach p $coordinates {
          set px [lindex $p 0]
          set py [lindex $p 1]
          if {[_point_in_rect $px $py $rect]} {
            set overlap 1
            break
          }
        }
        if {$overlap} {
          continue
        }
        
        # Check if rectangle intersects with any connecting line
        for {set j 0} {$j < [expr {$num_points - 1}]} {incr j} {
          set p1 [lindex $coordinates $j]
          set p2 [lindex $coordinates [expr {$j + 1}]]
          if {[_line_intersects_rect $p1 $p2 $rect]} {
            set overlap 1
            break
          }
        }
        if {$overlap} {
          continue
        }
        
        # Find closest corner of the rectangle to the point
        set corners [list \
          [list $rect_x $rect_y] \       ;# bottom-left
          [list $rect_x1 $rect_y] \      ;# bottom-right
          [list $rect_x $rect_y1] \      ;# top-left
          [list $rect_x1 $rect_y1] \     ;# top-right
        ]
        
        set closest_corner [_find_closest_point $corners [list $x $y]]
        
        # Calculate distance from point to closest corner
        set corner_dist [expr {sqrt(
          ([lindex $closest_corner 0] - $x)*([lindex $closest_corner 0] - $x) +
          ([lindex $closest_corner 1] - $y)*([lindex $closest_corner 1] - $y)
        )}]
        
        # Ensure distance meets minimum requirement
        if {$corner_dist >= $min_line_length} {
          # Add to result list in new format
          lappend result [list [list $point $closest_corner] $rect]
          set found 1
          break
        }
      }
      if {$found} {
        break
      }
    }
    
    # If no suitable position found, use default (fallback)
    if {!$found} {
      set rect_x [expr {$x + $min_line_length}]
      set rect_y [expr {$y + $min_line_length}]
      set rect_x1 [expr {$rect_x + $rect_width}]
      set rect_y1 [expr {$rect_y + $rect_height}]
      set rect [list $rect_x $rect_y $rect_x1 $rect_y1]
      set closest_corner [list $rect_x $rect_y]
      
      # Add fallback to result list
      lappend result [list [list $point $closest_corner] $rect]
    }
  }
  
  return $result
}

# Helper function: Check if a point is inside a rectangle
proc _point_in_rect {x y rect} {
  set rx1 [lindex $rect 0]
  set ry1 [lindex $rect 1]
  set rx2 [lindex $rect 2]
  set ry2 [lindex $rect 3]
  
  # Ensure coordinates are in correct order
  if {$rx1 > $rx2} {
    set temp $rx1
    set rx1 $rx2
    set rx2 $temp
  }
  if {$ry1 > $ry2} {
    set temp $ry1
    set ry1 $ry2
    set ry2 $temp
  }
  
  return [expr {($x >= $rx1 && $x <= $rx2) && ($y >= $ry1 && $y <= $ry2)}]
}

# Helper function: Check if a line segment intersects with a rectangle
proc _line_intersects_rect {p1 p2 rect} {
  set x1 [lindex $p1 0]
  set y1 [lindex $p1 1]
  set x2 [lindex $p2 0]
  set y2 [lindex $p2 1]
  
  set rx1 [lindex $rect 0]
  set ry1 [lindex $rect 1]
  set rx2 [lindex $rect 2]
  set ry2 [lindex $rect 3]
  
  # Ensure coordinates are in correct order
  if {$rx1 > $rx2} {
    set temp $rx1
    set rx1 $rx2
    set rx2 $temp
  }
  if {$ry1 > $ry2} {
    set temp $ry1
    set ry1 $ry2
    set ry2 $temp
  }
  
  # Check intersection with each edge of the rectangle
  set rect_edges [list \
    [list [list $rx1 $ry1] [list $rx2 $ry1]] \
    [list [list $rx2 $ry1] [list $rx2 $ry2]] \
    [list [list $rx2 $ry2] [list $rx1 $ry2]] \
    [list [list $rx1 $ry2] [list $rx1 $ry1]] \
  ]
  
  foreach edge $rect_edges {
    if {[_segments_intersect $p1 $p2 [lindex $edge 0] [lindex $edge 1]]} {
      return 1
    }
  }
  
  # Check if segment is completely inside rectangle
  if {[_point_in_rect $x1 $y1 $rect] && [_point_in_rect $x2 $y2 $rect]} {
    return 1
  }
  
  return 0
}

# Helper function: Check if two line segments intersect
proc _segments_intersect {a1 a2 b1 b2} {
  set a1x [lindex $a1 0]
  set a1y [lindex $a1 1]
  set a2x [lindex $a2 0]
  set a2y [lindex $a2 1]
  
  set b1x [lindex $b1 0]
  set b1y [lindex $b1 1]
  set b2x [lindex $b2 0]
  set b2y [lindex $b2 1]
  
  # Cross product helper
  proc ccw {x1 y1 x2 y2 x3 y3} {
    return [expr {($x3 - $x1)*($y2 - $y1) - ($y3 - $y1)*($x2 - $x1)}]
  }
  
  set o1 [ccw $a1x $a1y $a2x $a2y $b1x $b1y]
  set o2 [ccw $a1x $a1y $a2x $a2y $b2x $b2y]
  set o3 [ccw $b1x $b1y $b2x $b2y $a1x $a1y]
  set o4 [ccw $b1x $b1y $b2x $b2y $a2x $a2y]
  
  # General case
  if {($o1 * $o2 < 0) && ($o3 * $o4 < 0)} {
    return 1
  }
  
  # Special cases (collinear and overlapping)
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

# Helper function: Find closest point from a list to a target point
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

