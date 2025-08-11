source ./get_objRect.tcl; # get_objRect

proc expandSpace_byMovingInst {total_area target_insert_loc target_size {debug 0} {verbose 0}} {
  # Parameters:
  #   total_area - Total space area in format {x y x1 y1}
  #   target_insert_loc - Bottom-left coordinate of desired free space, format {x y}
  #   target_size - Required free space size in format {w h}
  #   debug - Debug switch (0=off, 1=on), default 0
  #   verbose - Verbose output switch (0=off, 1=on), default 0
  
  # Declare global dictionary for site parameters
  global lutDict
  
  # Get minimum movement unit from lookup dictionary
  set minWidth [dict get $lutDict mainCoreSiteWidth]

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
    puts "Minimum movement unit: $minWidth"
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
  if {[expr $target_h - $row_height]} {
    if {$debug} {
      puts "Target height does not match row height: target=$target_h, row=$row_height"
    }
    return [list $result_flag $free_region $move_list]
  }

  # Determine target row based on insert location
  set target_row_y $insert_y
  set target_row_y1 [expr {$insert_y + $row_height}]
  
  # Filter rectangles in target row and identify boundary rectangles
  # Boundary rectangles: (1) adhere to total area boundary or (2) partially inside/outside
  set target_row_rects [list]
  foreach rect $obj_rects {
    lassign $rect instname coords
    lassign $coords r_x r_y r_x1 r_y1
    
    # Check if rectangle is in target row (same y range)
    if {$r_y <= $target_row_y && $r_y1 >= $target_row_y1} {
      # Check left boundary condition
      set is_left_boundary [expr {($r_x == $total_x) || ($r_x < $total_x && $r_x1 > $total_x) ? 1 : 0}]
      # Check right boundary condition
      set is_right_boundary [expr {($r_x1 == $total_x1) || ($r_x < $total_x1 && $r_x1 > $total_x1) ? 1 : 0}]
      
      if {$verbose && ($is_left_boundary || $is_right_boundary)} {
        puts "Boundary rectangle $instname - left: $is_left_boundary, right: $is_right_boundary (cannot move)"
      }
      
      lappend target_row_rects [list $instname $coords $is_left_boundary $is_right_boundary [expr {$r_x1 - $r_x}]]
    }
  }
  
  if {[llength $target_row_rects] == 0} {
    if {$debug} {puts "No rectangles found in target row"}
    return [list $result_flag $free_region $move_list]
  }

  # Check for overlapping rectangles
  set overlap_found 0
  set rect_count [llength $target_row_rects]
  # Generate indices from 0 to rect_count-1
  set rect_indices [list]
  for {set i 0} {$i < $rect_count} {incr i} {
    lappend rect_indices $i
  }
  
  foreach i $rect_indices {
    set r1 [lindex $target_row_rects $i 1]
    lassign $r1 x1 y1 x1_1 y1_1
    
    foreach j [lrange $rect_indices [expr {$i + 1}] end] {
      set r2 [lindex $target_row_rects $j 1]
      lassign $r2 x2 y2 x2_1 y2_1
      
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

  # Sort rectangles by x coordinate
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
      puts "  [lindex $rect 0]: [lindex $rect 1] (width: [lindex $rect 4])"
    }
  }

  # Calculate all gaps with their bottom-left coordinates
  set gaps [list]
  set n [llength $sorted_rects]
  
  # Leftmost gap
  set first_rect_x [lindex $sorted_rects 0 1 0]
  set left_gap_bl [list $total_x $target_row_y]
  lappend gaps [list 0 [expr {$first_rect_x - $total_x}] "left" 0 $left_gap_bl]
  
  # Middle gaps
  for {set i 0} {$i < [expr {$n - 1}]} {incr i} {
    set rect [lindex $sorted_rects $i]
    set next_rect [lindex $sorted_rects [expr {$i + 1}]]
    set curr_rect_x1 [lindex $rect 1 2]
    set next_rect_x [lindex $next_rect 1 0]
    set gap_width [expr {$next_rect_x - $curr_rect_x1}]
    set gap_bl [list $curr_rect_x1 $target_row_y]
    lappend gaps [list [expr {$i + 1}] $gap_width "between" [expr {$i + 1}] $gap_bl]
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
  
  # Verify delta is multiple of minWidth (as per problem constraints)
  if {fmod($delta, $minWidth) != 0} {
    error "Delta ($delta) is not multiple of minWidth ($minWidth) - violates problem constraints"
  }
  
  if {$delta <= 0} {
    if {$debug} {puts "Target gap is already sufficient (no movement needed)"}
    set result_flag "yes"
    set free_region $target_insert_loc
    return [list $result_flag $free_region $move_list]
  }

  # Convert delta to units of minWidth for precise distribution
  set total_units [expr {int($delta / $minWidth)}]

  # Check if expansion is possible with flexible movement strategy
  set valid 0
  set move_left_list [list]  ;# {instname max_move} - only non-boundary rectangles
  set move_right_list [list] ;# {instname max_move} - only non-boundary rectangles
  set total_left_possible 0.0  ;# total left movable distance
  set total_right_possible 0.0 ;# total right movable distance

  if {$pos eq "left"} {
    # Left gap: can only move right rectangles (non-right-boundary)
    foreach rect $sorted_rects {
      set instname [lindex $rect 0]
      set is_right_boundary [lindex $rect 3]
      
      # Right boundary rectangles cannot move, others can move up to delta
      set max_move [expr {$is_right_boundary ? 0.0 : $delta}]
      lappend move_right_list [list $instname $max_move [lindex $rect 1 0]] ;# store x coordinate for proximity
      set total_right_possible [expr {$total_right_possible + $max_move}]
    }
    # Sort right rectangles by proximity to gap (ascending x = closer)
    set move_right_list [lsort -real -index 2 $move_right_list]
    # Valid if total movable distance ≥ delta
    if {$total_right_possible >= $delta} {
      set valid 1
    }
  } elseif {$pos eq "right"} {
    # Right gap: can only move left rectangles (non-left-boundary)
    foreach rect [lrange $sorted_rects 0 [expr {$left_count - 1}]] {
      set instname [lindex $rect 0]
      set is_left_boundary [lindex $rect 2]
      
      # Left boundary rectangles cannot move, others can move up to delta
      set max_move [expr {$is_left_boundary ? 0.0 : $delta}]
      lappend move_left_list [list $instname $max_move [lindex $rect 1 2]] ;# store x1 for proximity
    }
    # Sort left rectangles by proximity to gap (descending x1 = closer)
    set move_left_list [lsort -decreasing -real -index 2 $move_left_list]
    # Valid if total movable distance ≥ delta
    if {$total_left_possible >= $delta} {
      set valid 1
    }
  } elseif {$pos eq "between"} {
    # Middle gap: left rectangles move left + right rectangles move right (non-boundary only)
    # Calculate left movable rectangles and total distance (store x1 for proximity)
    foreach rect [lrange $sorted_rects 0 [expr {$left_count - 1}]] {
      set instname [lindex $rect 0]
      set is_left_boundary [lindex $rect 2]
      
      set max_move [expr {$is_left_boundary ? 0.0 : $delta}]
      lappend move_left_list [list $instname $max_move [lindex $rect 1 2]] ;# x1 for proximity
      set total_left_possible [expr {$total_left_possible + $max_move}]
    }
    # Sort left rectangles by proximity to gap (descending x1 = closer)
    set move_left_list [lsort -decreasing -real -index 2 $move_left_list]
    
    # Calculate right movable rectangles and total distance (store x for proximity)
    foreach rect [lrange $sorted_rects $left_count end] {
      set instname [lindex $rect 0]
      set is_right_boundary [lindex $rect 3]
      
      set max_move [expr {$is_right_boundary ? 0.0 : $delta}]
      lappend move_right_list [list $instname $max_move [lindex $rect 1 0]] ;# x for proximity
      set total_right_possible [expr {$total_right_possible + $max_move}]
    }
    # Sort right rectangles by proximity to gap (ascending x = closer)
    set move_right_list [lsort -real -index 2 $move_right_list]
    
    # Valid if total movable distance ≥ delta
    if {[expr {$total_left_possible + $total_right_possible}] >= $delta} {
      set valid 1
    }
  }

  if {!$valid} {
    if {$debug} {puts "No valid movement possible for required expansion (delta=$delta)"}
    return [list $result_flag $free_region $move_list]
  }

  # Generate movement list with proximity-based strategy
  # Track total movement for each instance using dict instead of array
  set total_moves [dict create]
  
  if {$pos eq "between"} {
    # Between gap: prioritize closest left and right rectangles, move in minWidth units
    set remaining_units $total_units
    set left_group [list]  ;# track current left group (instnames)
    set right_group [list] ;# track current right group (instnames)
    set left_idx 0
    set right_idx 0

    while {$remaining_units > 0} {
      # Get next left candidate if needed
      if {[llength $left_group] == 0 && $left_idx < [llength $move_left_list]} {
        lappend left_group [lindex $move_left_list $left_idx 0]
        incr left_idx
      }
      
      # Get next right candidate if needed
      if {[llength $right_group] == 0 && $right_idx < [llength $move_right_list]} {
        lappend right_group [lindex $move_right_list $right_idx 0]
        incr right_idx
      }

      # Calculate available units from each side
      set left_available_units [expr {int($total_left_possible / $minWidth)}]
      set right_available_units [expr {int($total_right_possible / $minWidth)}]
      set total_available_units [expr {$left_available_units + $right_available_units}]

      # Calculate proportional units using integer arithmetic
      if {$total_available_units > 0} {
        set left_ratio_num $left_available_units
        set left_units [expr {int(($remaining_units * $left_ratio_num) / $total_available_units)}]
        set right_units [expr {$remaining_units - $left_units}]
        
        # Ensure no negative values
        if {$left_units < 0} { set left_units 0 }
        if {$right_units < 0} { set right_units 0 }
        
        # Adjust if one side has no available units
        if {$left_available_units == 0} {
          set left_units 0
          set right_units $remaining_units
        }
        if {$right_available_units == 0} {
          set right_units 0
          set left_units $remaining_units
        }
      } else {
        set left_units 0
        set right_units 0
      }

      # Convert units to actual distance
      set left_move [expr {$left_units * $minWidth}]
      set right_move [expr {$right_units * $minWidth}]

      # Apply left movement to current group
      if {$left_move > 0 && [llength $left_group] > 0} {
        foreach inst $left_group {
          if {[dict exists $total_moves $inst]} {
            dict set total_moves $inst [expr {[dict get $total_moves $inst] + $left_move}]
          } else {
            dict set total_moves $inst $left_move
          }
        }
        set remaining_units [expr {$remaining_units - $left_units}]
      }
      
      # Apply right movement to current group
      if {$right_move > 0 && [llength $right_group] > 0} {
        foreach inst $right_group {
          if {[dict exists $total_moves $inst]} {
            dict set total_moves $inst [expr {[dict get $total_moves $inst] + $right_move}]
          } else {
            dict set total_moves $inst $right_move
          }
        }
        set remaining_units [expr {$remaining_units - $right_units}]
      }

      # If still remaining, expand groups
      if {$remaining_units > 0} {
        # Add next left rectangle to group if available
        if {$left_idx < [llength $move_left_list]} {
          lappend left_group [lindex $move_left_list $left_idx 0]
          incr left_idx
        }
        # Add next right rectangle to group if available
        if {$right_idx < [llength $move_right_list]} {
          lappend right_group [lindex $move_right_list $right_idx 0]
          incr right_idx
        }
      }
    }
  } elseif {$pos eq "left"} {
    # Left gap: prioritize closest right rectangles, move in groups
    set remaining_units $total_units
    set current_group [list]
    set idx 0

    while {$remaining_units > 0} {
      # Add next closest rectangle to group if needed
      if {[llength $current_group] == 0 && $idx < [llength $move_right_list]} {
        lappend current_group [lindex $move_right_list $idx 0]
        incr idx
      }

      # Calculate movement in minWidth units
      set move_units [expr {min($remaining_units, int([lindex $move_right_list [expr {$idx - 1}] 1] / $minWidth))}]
      set move [expr {$move_units * $minWidth}]

      # Apply movement to current group
      foreach inst $current_group {
        if {[dict exists $total_moves $inst]} {
          dict set total_moves $inst [expr {[dict get $total_moves $inst] + $move}]
        } else {
          dict set total_moves $inst $move
        }
      }
      set remaining_units [expr {$remaining_units - $move_units}]

      # Expand group if still remaining
      if {$remaining_units > 0 && $idx < [llength $move_right_list]} {
        lappend current_group [lindex $move_right_list $idx 0]
        incr idx
      }
    }
  } elseif {$pos eq "right"} {
    # Right gap: prioritize closest left rectangles, move in groups
    set remaining_units $total_units
    set current_group [list]
    set idx 0

    while {$remaining_units > 0} {
      # Add next closest rectangle to group if needed
      if {[llength $current_group] == 0 && $idx < [llength $move_left_list]} {
        lappend current_group [lindex $move_left_list $idx 0]
        incr idx
      }

      # Calculate movement in minWidth units
      set move_units [expr {min($remaining_units, int([lindex $move_left_list [expr {$idx - 1}] 1] / $minWidth))}]
      set move [expr {$move_units * $minWidth}]

      # Apply movement to current group
      foreach inst $current_group {
        if {[dict exists $total_moves $inst]} {
          dict set total_moves $inst [expr {[dict get $total_moves $inst] + $move}]
        } else {
          dict set total_moves $inst $move
        }
      }
      set remaining_units [expr {$remaining_units - $move_units}]

      # Expand group if still remaining
      if {$remaining_units > 0 && $idx < [llength $move_left_list]} {
        lappend current_group [lindex $move_left_list $idx 0]
        incr idx
      }
    }
  }

  # Format move_list with directions
  foreach inst [dict keys $total_moves] {
    set dir "left"
    # Check if instance is in right move list
    foreach item $move_right_list {
      if {[lindex $item 0] eq $inst} {
        set dir "right"
        break
      }
    }
    lappend move_list [list $inst [list $dir [dict get $total_moves $inst]]]
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
    
