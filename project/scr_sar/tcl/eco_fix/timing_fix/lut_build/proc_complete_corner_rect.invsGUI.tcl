proc complete_corner_rect {rect_list args} {
  # Parse debug flag (default: 0)
  set debug 0
  if {[lsearch -exact $args "-debug"] != -1} {
    set debug 1
  }

  # --------------------------
  # Error Defense Mechanisms
  # --------------------------
  # Check if input is a list
  if {![llength $rect_list]} {
    error "Error: Input must be a non-empty nested list of rectangles"
  }
  # Validate each rectangle
  foreach rect $rect_list {
    if {[llength $rect] != 4} {
      error "Error: Invalid rectangle format '$rect' (must be {x y x1 y1})"
    }
    foreach coord $rect {
      if {![string is double -strict $coord]} {
        error "Error: Non-numeric coordinate '$coord' in rectangle '$rect'"
      }
    }
puts "point 1: $rect"
    lassign $rect x y x1 y1
    if {$x >= $x1 || $y >= $y1} {
      error "Error: Invalid rectangle bounds '$rect' (x >= x1 or y >= y1)"
    }
  }

  # --------------------------
  # Identify Horizontal/Vertical Strips
  # --------------------------
  set horizontal {}  
  set vertical {}   
  foreach rect $rect_list {
    lassign $rect x y x1 y1
    if {[llength $horizontal] == 0} {
      lappend horizontal $rect
    } else {
      lassign [lindex $horizontal 0] hx hy hx1 hy1
      if {$y == $hy} {
        lappend horizontal $rect
      } else {
        lappend vertical $rect
      }
    }
  }

  # --------------------------
  # Calculate Missing Corner
  # --------------------------
  if {[llength $horizontal] == 0 || [llength $vertical] == 0} {
    if {$debug} {puts "Debug: No horizontal/vertical strip pair found"}
    return [list]
  }

  # Get rightmost of horizontal strip (x1 is max)
  set h_rect [lindex $horizontal 0]
  lassign $h_rect hx hy hx1 hy1
  foreach rect $horizontal {
    lassign $rect x y x1 y1
    if {$x1 > $hx1} {
      set h_rect $rect
      lassign $rect hx hy hx1 hy1
    }
  }

  # Get topmost of vertical strip (y1 is max)
  set v_rect [lindex $vertical 0]
  lassign $v_rect vx vy vx1 vy1
  foreach rect $vertical {
    lassign $rect x y x1 y1
    if {$y1 > $vy1} {
      set v_rect $rect
      lassign $rect vx vy vx1 vy1
    }
  }

  # Compute missing corner:
  # Left=x of vertical strip, Bottom=y of horizontal strip
  # Right=x1 of horizontal strip, Top=y1 of vertical strip
  set corner_x $vx
  set corner_y $hy

  set corner_x $hy
  set corner_y $vx
  set corner_x1 $hx1
  set corner_y1 $vy1

puts "point 2: $corner_x $corner_y $corner_x1 $corner_y1"
  # Validate the corner is a valid rectangle
  if {$corner_x >= $corner_x1 || $corner_y >= $corner_y1} {
    if {$debug} {puts "Debug: Calculated corner is invalid (bounds error)"}
    return [list]
  }

  # Debug output
  if {$debug} {
    puts "Debug: Horizontal strip rightmost = $h_rect"
    puts "Debug: Vertical strip topmost = $v_rect"
    puts "Debug: Missing corner = {$corner_x $corner_y $corner_x1 $corner_y1}"
  }

  # Return the missing corner
  return [list [list $corner_x $corner_y $corner_x1 $corner_y1]]
}

# 输入矩形（红色区域）
set input_rects {
  {0 0 2 2}   
  {2 2 4 4}  
}

# 调用（开启调试）
set missing [complete_corner_rect $input_rects -debug]

# 输出缺失的拐角矩形（黄色区域）
puts "Missing corner: $missing"
