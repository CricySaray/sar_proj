source ./get_objRect.tcl; # get_objRect

proc expandSpace_byMovingInst {total_area target_insert_loc target_size {debug 0} {verbose 0}} {
  # Parameters:
  #   total_area - Total space area in format {x y x1 y1}
  #   target_insert_loc - Bottom-left coordinate of desired free space, format {x y}
  #   target_size - Required free space size in format {w h}
  #   debug - Debug switch (0=off, 1=on), default 0
  #   verbose - Verbose output switch (0=off, 1=on), default 0

  # Initialize return values
  set result_flag "no"
  set free_region [list]
  set move_list [list]

  # Extract key parameters
  lassign $target_insert_loc insert_x insert_y
  lassign $target_size target_w target_h
  lassign $total_area total_x total_y total_x1 total_y1

  if {$debug} {
    puts "Total area: $total_area"
    puts "Target insert location: ($insert_x, $insert_y)"
    puts "Target free space size: w=$target_w, h=$target_h"
  }

  # Validate target insert location is within total area
  if {$insert_x < $total_x || $insert_x >= $total_x1 || 
      $insert_y < $total_y || $insert_y >= $total_y1} {
    if {$debug} {puts "Target insert location is outside total area"}
    return [list $result_flag $free_region $move_list]
  }

  # Get all rectangles in total area using get_objRect
  set obj_rects [get_objRect $total_area]
  if {[llength $obj_rects] == 0} {
    if {$debug} {puts "No rectangles found in total area"}
    return 0
  }

  # Extract rectangle coordinates (insts_box) for dbShape command
  set insts_box [lmap rect $obj_rects {lindex $rect 1}]
  if {$verbose} {puts "Extracted rectangle boxes: $insts_box"}

  # Calculate existing free space using dbShape
  set searchingBox $total_area
  set freeSpaceRect [dbShape -output hrect $searchingBox ANDNOT $insts_box]
  if {$debug} {puts "Calculated free space rectangles: $freeSpaceRect"}

  # Extract row height from the first rectangle
  set first_rect [lindex $obj_rects 0 1]
  lassign $first_rect x y x1 y1
  set row_height [expr {$y1 - $y}]
  
  # Verify target height matches row height using expr difference
  if {[expr {$target_h - $row_height}]} {
    if {$debug} {
      puts "Target height does not match row height: target=$target_h, row=$row_height"
    }
    return [list $result_flag $free_region $move_list]
  }

  # Determine target row based on insert location
  set target_row_y $insert_y
  set target_row_y1 [expr {$insert_y + $row_height}]
  
  # Filter rectangles in target row and check their position restrictions
  set target_row_rects [list]
  foreach rect $obj_rects {
    lassign $rect instname coords
    lassign $coords r_x r_y r_x1 r_y1
    
    # Check if rectangle is in target row (same y range)
    if {$r_y <= $target_row_y && $r_y1 >= $target_row_y1} {
      # Determine movement restrictions (only for boundary rectangles)
      set is_left_boundary [expr {$r_x == $total_x ? 1 : 0}]  ;# Left boundary can't move left
      set is_right_boundary [expr {$r_x1 == $total_x1 ? 1 : 0}]  ;# Right boundary can't move right
      
      if {$verbose && ($is_left_boundary || $is_right_boundary)} {
        puts "Boundary rectangle $instname - left boundary: $is_left_boundary, right boundary: $is_right_boundary"
      }
      
      lappend target_row_rects [list $instname $coords $is_left_boundary $is_right_boundary]
    }
  }
  
  if {[llength $target_row_rects] == 0} {
    if {$debug} {puts "No rectangles found in target row"}
    return [list $result_flag $free_region $move_list]
  }

  # Check for overlapping rectangles using foreach with index
  set overlap_found 0
  set rect_list [llength $target_row_rects]
  foreach i [dict keys [lrepeat $rect_list 1]] {
    set r1 [lindex $target_row_rects $i 1]
    lassign $r1 x1 y1 x1_1 y1_1
    
    foreach j [dict keys [lrepeat [expr {$rect_list - $i - 1}] 1]] {
      set j [expr {$j + $i + 1}]
      if {$j >= $rect_list} break
      
      set r2 [lindex $target_row_rects $j 1]
      lassign $r2 x2 y2 x2_1 y2_1
      
      # Check x-axis overlap
      if {!($x1_1 <= $x2 || $x2_1 <= $x1)} {
        if {$debug} {
          puts "Overlapping rectangles: [lindex $target_row_rects $i 0] and [lindex $target_row_rects $j 0]"
        }
        set overlap_found 1
        break
      }
    }
    if {$overlap_found} break
  }
  
  if {$overlap_found} {
    error "Overlapping rectangles detected in target row"
  }

  # Sort rectangles by x coordinate with valid return values (-1, 0, 1)
  set sorted_rects [lsort -command {
    apply {{a b} {
      set x1 [lindex $a 1 0]
      set x2 [lindex $b 1 0]
      if {$x1 < $x2} {return -1}
      if {$x1 > $x2} {return 1}
      return 0
    }}
  } $target_row_rects]

  if {$verbose} {
    puts "Sorted rectangles in target row:"
    foreach rect $sorted_rects {
      puts "  [lindex $rect 0]: [lindex $rect 1]"
    }
  }

  # Calculate all gaps with their bottom-left coordinates using foreach
  set gaps [list]
  set n [llength $sorted_rects]
  
  # Leftmost gap
  set first_rect_x [lindex $sorted_rects 0 1 0]
  set left_gap_bl [list $total_x $target_row_y]
  lappend gaps [list 0 [expr {$first_rect_x - $total_x}] "left" 0 $left_gap_bl]
  
  # Middle gaps using foreach with index
  set idx 1
  foreach rect $sorted_rects next_rect [lrange $sorted_rects 1 end] {
    set curr_rect_x1 [lindex $rect 1 2]
    set next_rect_x [lindex $next_rect 1 0]
    set gap_width [expr {$next_rect_x - $curr_rect_x1}]
    set gap_bl [list $curr_rect_x1 $target_row_y]
    lappend gaps [list $idx $gap_width "between" $idx $gap_bl]
    incr idx
  }
  
  # Rightmost gap
  set last_rect_x1 [lindex $sorted_rects end 1 2]
  set right_gap_bl [list $last_rect_x1 $target_row_y]
  lappend gaps [list $n [expr {$total_x1 - $last_rect_x1}] "right" $n $right_gap_bl]

  if {$verbose} {
    puts "Calculated gaps with bottom-left coordinates:"
    foreach gap $gaps {
      lassign $gap idx width pos left_count bl
      puts "  Gap $idx: width=$width, position=$pos, bottom-left=$bl"
    }
  }

  # Find target gap by comparing bottom-left coordinates
  set target_gap [list]
  foreach gap $gaps {
    lassign $gap idx width pos left_count bl
    if {$bl eq $target_insert_loc} {
      set target_gap $gap
      break
    }
  }

  if {[llength $target_gap] == 0} {
    if {$debug} {puts "Target insert location not found in any gap's bottom-left coordinates"}
    return [list $result_flag $free_region $move_list]
  }

  if {$verbose} {
    lassign $target_gap idx width pos left_count bl
    puts "Found target gap $idx at position $pos with width $width (bottom-left: $bl)"
  }

  # Calculate required expansion for target gap
  lassign $target_gap idx gap_width pos left_count bl
  set right_count [expr {$n - $left_count}]
  set delta [expr {$target_w - $gap_width}]
  
  if {$delta <= 0} {
    if {$debug} {puts "Target gap is already sufficient (no movement needed)"}
    set result_flag "yes"
    set free_region $target_insert_loc
    return [list $result_flag $free_region $move_list]
  }

  # Check if expansion is possible with flexible movement strategy
  set valid 1
  set move_left_list [list]
  set move_right_list [list]
  set left_possible 0
  set right_possible 0
  set total_possible 0

  if {$pos eq "left"} {
    # Left gap - can only move right rectangles (non-right-boundary)
    foreach rect [lrange $sorted_rects 0 end] {
      set instname [lindex $rect 0]
      set is_right_boundary [lindex $rect 3]
      
      if {$is_right_boundary} {
        if {$verbose} {puts "Gap $idx invalid: Right boundary rectangle $instname can't move right"}
        set valid 0
        break
      }
      lappend move_right_list $instname
    }
    if {$valid} {
      set right_possible $delta
    }
  } elseif {$pos eq "right"} {
    # Right gap - can only move left rectangles (non-left-boundary)
    foreach rect [lrange $sorted_rects 0 [expr {$left_count - 1}]] {
      set instname [lindex $rect 0]
      set is_left_boundary [lindex $rect 2]
      
      if {$is_left_boundary} {
        if {$verbose} {puts "Gap $idx invalid: Left boundary rectangle $instname can't move left"}
        set valid 0
        break
      }
      lappend move_left_list $instname
    }
    if {$valid} {
      set left_possible $delta
    }
  } else {
    # Middle gap - can move left rectangles left AND right rectangles right
    # Check left movement possibility (non-left-boundary)
    foreach rect [lrange $sorted_rects 0 [expr {$left_count - 1}]] {
      set instname [lindex $rect 0]
      set is_left_boundary [lindex $rect 2]
      
      if {$is_left_boundary} {
        if {$verbose} {puts "Left movement restricted by boundary rectangle $instname"}
        set left_possible 0
        break
      }
      lappend move_left_list $instname
      set left_possible $delta  ;# All non-boundary can move full delta left
    }
    
    # Check right movement possibility (non-right-boundary)
    foreach rect [lrange $sorted_rects $left_count end] {
      set instname [lindex $rect 0]
      set is_right_boundary [lindex $rect 3]
      
      if {$is_right_boundary} {
        if {$verbose} {puts "Right movement restricted by boundary rectangle $instname"}
        set right_possible 0
        break
      }
      lappend move_right_list $instname
      set right_possible $delta  ;# All non-boundary can move full delta right
    }
    
    # Total possible expansion is sum of both directions
    set total_possible [expr {$left_possible + $right_possible}]
    if {$total_possible >= $delta} {
      set valid 1
    } else {
      if {$verbose} {
        puts "Insufficient expandable space: need $delta, can get $total_possible"
      }
      set valid 0
    }
  }

  if {!$valid} {
    if {$debug} {puts "No valid movement possible for required expansion"}
    return [list $result_flag $free_region $move_list]
  }

  # Generate movement list with flexible distribution
  if {$pos eq "middle"} {
    # Distribute delta between left and right movements
    set left_move [expr {min($delta, $left_possible)}]
    set right_move [expr {$delta - $left_move}]
    
    foreach instname $move_left_list {
      lappend move_list [list $instname [list left $left_move]]
    }
    foreach instname $move_right_list {
      lappend move_list [list $instname [list right $right_move]]
    }
  } elseif {$pos eq "left" && $valid} {
    foreach instname $move_right_list {
      lappend move_list [list $instname [list right $delta]]
    }
  } elseif {$pos eq "right" && $valid} {
    foreach instname $move_left_list {
      lappend move_list [list $instname [list left $delta]]
    }
  }

  # Set free region
  set free_region $target_insert_loc
  set result_flag "yes"

  if {$debug} {
    puts "Successfully found solution with delta=$delta"
    puts "Free region: $free_region"
    puts "Movement list: $move_list"
  }

  # Return results
  return [list $result_flag $free_region $move_list]
}
    
