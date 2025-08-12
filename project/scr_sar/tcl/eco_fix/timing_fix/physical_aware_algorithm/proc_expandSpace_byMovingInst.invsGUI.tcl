#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/12 12:36:44 Tuesday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This procedure expands a specified gap by moving rectangles to create required free space, considering group-based 
# 						movement for contiguous blocks. It generates a movement list ordered by distance from the gap (farthest first) with 
# 						all moves on one side grouped together before the other.
# return    : [list $result_flag $expandedRegionLoc $move_list]
#             consist of:
#             $result_flag: yes|no
#             $expandedRegionLoc : {x y}
#             $move_list : {{instname1 {left 1.4}} {instname2 {right 2.8}} ...}
# TODO      : (U001) cantMoveList: [list IP mem physicalCell(endcap welltap[can move small distance]) ...]
# ref       : link url
# --------------------------
source ./proc_get_objRect.invs.tcl; # get_objRect
source ../lut_build/operateLUT.tcl; # operateLUT
proc expandSpace_byMovingInst {total_area target_insert_loc target_size {filterMovementPrecision 0.005} {debug 0} {verbose 0}} {
  # Parameters:
  #   total_area - Total space area in format {x y x1 y1}
  #   target_insert_loc - Bottom-left coordinate of desired free space, format {x y}
  #   target_size - Required free space size in format {w h}
  #   filterMovementPrecision - usually is manufacturing grid [dbget head.mfgGrid]
  #   debug - Debug switch (0=off, 1=on), default 0
  #   verbose - Verbose output switch (0=off, 1=on), default 0
  
  # Get minimum movement unit from lookup dictionary
  set minWidth [operateLUT -type read -attr {mainCoreSiteWidth}]

  # Initialize return values
  set result_flag "no"
  set free_region [list]
  set move_list [list]

  # Extract key parameters
  lassign $target_insert_loc insert_x insert_y
  lassign $target_size target_w target_h
  lassign $total_area total_x total_y total_x1 total_y1
  
  # Calculate total area dimensions
  set total_width [expr {$total_x1 - $total_x}]
  set total_height [expr {$total_y1 - $total_y}]

  # Multiples check for critical dimensions
  set critical_dimensions [list \
    [list "total area width" $total_width] \
    [list "total area height" $total_height] \
    [list "target width" $target_w] \
    [list "target height" $target_h] \
  ]
  
  # Check all critical dimensions are multiples of minWidth
  foreach dim $critical_dimensions {
    lassign $dim name value
    if {fmod($value, $minWidth) != 0} {
      error "$name ($value) is not a multiple of minimum width ($minWidth)"
    }
  }

  if {$debug} {
    puts "===== Initial Parameters ====="
    puts "Total area: $total_area (width: $total_width, height: $total_height)"
    puts "Target insert location: ($insert_x, $insert_y)"
    puts "Target free space size: w=$target_w, h=$target_h"
    puts "Minimum movement unit: $minWidth"
    puts "=============================="
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

  # Check rectangle dimensions are multiples of minWidth
  foreach rect $obj_rects {
    lassign $rect instname coords
    lassign $coords r_x r_y r_x1 r_y1
    set rect_width [expr {$r_x1 - $r_x}]
    set rect_height [expr {$r_y1 - $r_y}]
    
    if {fmod($rect_width, $minWidth) != 0} {
      error "Rectangle $instname width ($rect_width) is not a multiple of minimum width ($minWidth)"
    }
    if {fmod($rect_height, $minWidth) != 0} {
      error "Rectangle $instname height ($rect_height) is not a multiple of minimum width ($minWidth)"
    }
  }

  # Extract rectangle coordinates (insts_box) for dbShape command
  set insts_box [lmap rect $obj_rects {lindex $rect 1}]
  if {$verbose} {puts "Extracted rectangle boxes: $insts_box"}

  # Calculate existing free space using dbShape
  set searchingBox $total_area
  set freeSpaceRect [dbShape -output hrect $searchingBox ANDNOT $insts_box]
  if {$debug} {puts "Calculated free space rectangles: $freeSpaceRect"}

  # Check gap dimensions are multiples of minWidth
  foreach gap $freeSpaceRect {
    lassign $gap g_x g_y g_x1 g_y1
    set gap_width [expr {$g_x1 - $g_x}]
    set gap_height [expr {$g_y1 - $g_y}]
    
    if {fmod($gap_width, $minWidth) != 0} {
      error "Gap width ($gap_width) at ($g_x, $g_y) is not a multiple of minimum width ($minWidth)"
    }
    if {fmod($gap_height, $minWidth) != 0} {
      error "Gap height ($gap_height) at ($g_x, $g_y) is not a multiple of minimum width ($minWidth)"
    }
  }

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

  # Check for overlapping rectangles in original positions
  set overlap_found 0
  set rect_count [llength $target_row_rects]
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
          puts "Original overlapping rectangles: [lindex $target_row_rects $i 0] and [lindex $target_row_rects $j 0]"
        }
        set overlap_found 1
        break
      }
    }
    if {$overlap_found} break
  }
  
  if {$overlap_found} {
    error "Overlapping rectangles detected in original target row"
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
  set left_gap_width [expr {$first_rect_x - $total_x}]
  lappend gaps [list 0 $left_gap_width "left" 0 $left_gap_bl]
  
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
  set right_gap_width [expr {$total_x1 - $last_rect_x1}]
  lappend gaps [list $n $right_gap_width "right" $n $right_gap_bl]

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
    lassign $bl gap_x gap_y
    if {$gap_x <= $insert_x && $insert_x < [expr $gap_x + $width]} {
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
  
  # Verify delta is multiple of minWidth
  if {fmod($delta, $minWidth) != 0} {
    error "Required expansion ($delta) is not a multiple of minimum width ($minWidth)"
  }
  
  if {$delta <= 0} {
    if {$debug} {puts "Target gap is already sufficient (no movement needed)"}
    set result_flag "yes"
    set free_region $target_insert_loc
    return [list $result_flag $free_region $move_list]
  }

  # Use exact value without rounding for unit calculations
  set total_units [expr {$delta / $minWidth}]
  if {$debug} {
    puts "===== Movement Requirements ====="
    puts "Target gap width: $gap_width"
    puts "Required width: $target_w"
    puts "Need to expand by: $delta ($total_units units of $minWidth)"
    puts "=================================="
  }

  # Check if expansion is possible with flexible movement strategy
  set valid 0
  set move_left_list [list]  ;# {instname max_move original_x1}
  set move_right_list [list] ;# {instname max_move original_x}
  set total_left_possible 0.0  ;# total left movable distance
  set total_right_possible 0.0 ;# total right movable distance

  # Precompute maximum possible moves for each rectangle based on adjacent gaps
  set max_movements [dict create]
  
  # Calculate max left and right moves for each rectangle
  for {set i 0} {$i < [llength $sorted_rects]} {incr i} {
    set rect [lindex $sorted_rects $i]
    lassign $rect instname coords is_left is_right width
    lassign $coords r_x r_y r_x1 r_y1
    
    # Calculate maximum left move: limited by left neighbor or left boundary
    if {$i == 0} {
      # First rectangle - left move limited by total area left boundary
      set left_limit $total_x
    } else {
      # Limited by previous rectangle's right edge
      set prev_rect [lindex $sorted_rects [expr {$i - 1}]]
      set prev_x1 [lindex $prev_rect 1 2]
      set left_limit $prev_x1
    }
    set max_left_move [expr {$r_x - $left_limit}]
    
    # Calculate maximum right move: limited by right neighbor or right boundary
    if {$i == [expr {[llength $sorted_rects] - 1}]} {
      # Last rectangle - right move limited by total area right boundary
      set right_limit $total_x1
    } else {
      # Limited by next rectangle's left edge
      set next_rect [lindex $sorted_rects [expr {$i + 1}]]
      set next_x [lindex $next_rect 1 0]
      set right_limit $next_x
    }
    set max_right_move [expr {$right_limit - $r_x1}]
    
    # Store in dictionary
    dict set max_movements $instname [list $max_left_move $max_right_move]
    
    if {$debug} {
      puts "Calculated max moves for $instname: left=$max_left_move, right=$max_right_move"
    }
  }

  if {$pos eq "left"} {
    # Left gap: can only move right rectangles (non-right-boundary)
    foreach rect $sorted_rects {
      set instname [lindex $rect 0]
      set coords [lindex $rect 1]
      lassign $coords r_x r_y r_x1 r_y1
      set is_right_boundary [lindex $rect 3]
      
      # Get precomputed max right move, but cannot exceed delta needed
      lassign [dict get $max_movements $instname] max_left max_right
      set max_move [expr {$is_right_boundary ? 0.0 : min($max_right, $delta)}]
      
      lappend move_right_list [list $instname $max_move $r_x] ;# store original x for proximity
      set total_right_possible [expr {$total_right_possible + $max_move}]
      if {$debug && $max_move > 0} {
        puts "Right-movable rectangle: $instname (max move: $max_move)"
      }
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
      set coords [lindex $rect 1]
      lassign $coords r_x r_y r_x1 r_y1
      set is_left_boundary [lindex $rect 2]
      
      # Get precomputed max left move, but cannot exceed delta needed
      lassign [dict get $max_movements $instname] max_left max_right
      set max_move [expr {$is_left_boundary ? 0.0 : min($max_left, $delta)}]
      
      lappend move_left_list [list $instname $max_move $r_x1] ;# store original x1 for proximity
      set total_left_possible [expr {$total_left_possible + $max_move}]
      if {$debug && $max_move > 0} {
        puts "Left-movable rectangle: $instname (max move: $max_move)"
      }
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
      set coords [lindex $rect 1]
      lassign $coords r_x r_y r_x1 r_y1
      set is_left_boundary [lindex $rect 2]
      
      # Get precomputed max left move, but cannot exceed delta needed
      lassign [dict get $max_movements $instname] max_left max_right
      set max_move [expr {$is_left_boundary ? 0.0 : min($max_left, $delta)}]
      
      lappend move_left_list [list $instname $max_move $r_x1] ;# x1 for proximity
      set total_left_possible [expr {$total_left_possible + $max_move}]
      if {$debug && $max_move > 0} {
        puts "Left-movable rectangle: $instname (max move: $max_move)"
      }
    }
    # Sort left rectangles by proximity to gap (descending x1 = closer)
    set move_left_list [lsort -decreasing -real -index 2 $move_left_list]
    
    # Calculate right movable rectangles and total distance (store x for proximity)
    foreach rect [lrange $sorted_rects $left_count end] {
      set instname [lindex $rect 0]
      set coords [lindex $rect 1]
      lassign $coords r_x r_y r_x1 r_y1
      set is_right_boundary [lindex $rect 3]
      
      # Get precomputed max right move, but cannot exceed delta needed
      lassign [dict get $max_movements $instname] max_left max_right
      set max_move [expr {$is_right_boundary ? 0.0 : min($max_right, $delta)}]
      
      lappend move_right_list [list $instname $max_move $r_x] ;# x for proximity
      set total_right_possible [expr {$total_right_possible + $max_move}]
      if {$debug && $max_move > 0} {
        puts "Right-movable rectangle: $instname (max move: $max_move)"
      }
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

  # Generate movement list with alternating proximity-based strategy
  # Track total movement for each instance using dict
  set total_moves [dict create]
  
  if {$pos eq "between"} {
    if {$debug} {puts "\n===== Starting Between-Gap Alternating Movement ====="}
    # Between gap: alternate between sides with most available movement
    set remaining_distance $delta
    set left_group [list]  ;# current left group (instnames)
    set right_group [list] ;# current right group (instnames)
    set left_idx 0         ;# index for next left rectangle to add to group
    set right_idx 0        ;# index for next right rectangle to add to group
    set step 1

    # Initialize with closest rectangles to gap
    if {[llength $move_left_list] > 0} {
      set left_inst [lindex $move_left_list 0 0]
      lappend left_group $left_inst
      if {$debug} {puts "Initial left group: $left_inst"}
      set left_idx 1
    }
    if {[llength $move_right_list] > 0} {
      set right_inst [lindex $move_right_list 0 0]
      lappend right_group $right_inst
      if {$debug} {puts "Initial right group: $right_inst"}
      set right_idx 1
    }

    while {$remaining_distance > 0} {
      if {$debug} {
        puts "\n----- Movement Step $step -----"
        puts "Remaining distance needed: $remaining_distance"
        puts "Current left group: $left_group"
        puts "Current right group: $right_group"
      }

      # Calculate group-level available movement (treating group as a single unit)
      set left_available 0.0
      if {[llength $left_group] > 0} {
        # For left group (moving left), max distance is determined by leftmost rectangle
        set leftmost_inst [lindex $left_group 0]
        lassign [dict get $max_movements $leftmost_inst] max_left _
        set used_move [expr {[dict exists $total_moves $leftmost_inst] ? [dict get $total_moves $leftmost_inst] : 0.0}]
        set left_available [expr {$max_left - $used_move}]
      }
      
      set right_available 0.0
      if {[llength $right_group] > 0} {
        # For right group (moving right), max distance is determined by rightmost rectangle
        set rightmost_inst [lindex $right_group end]
        lassign [dict get $max_movements $rightmost_inst] _ max_right
        set used_move [expr {[dict exists $total_moves $rightmost_inst] ? [dict get $total_moves $rightmost_inst] : 0.0}]
        set right_available [expr {$max_right - $used_move}]
      }
      
      if {$debug} {
        puts "Left group available movement (based on leftmost): $left_available"
        puts "Right group available movement (based on rightmost): $right_available"
      }
      
      # Determine movement direction using explicit flag
      set direction ""
      if {$left_available > 0 && $right_available > 0} {
        # Both sides available - choose one with more available movement
        if {$left_available >= $right_available} {
          set direction "left"
        } else {
          set direction "right"
        }
      } elseif {$left_available > 0} {
        # Only left available
        set direction "left"
      } elseif {$right_available > 0} {
        # Only right available
        set direction "right"
      } else {
        # No immediate movement available - try to expand groups
        if {$debug} {puts "No immediate movement available, attempting to expand groups"}
        
        # Try to expand left group first if possible
        if {$left_idx < [llength $move_left_list]} {
          set next_left [lindex $move_left_list $left_idx 0]
          lappend left_group $next_left
          if {$debug} {puts "Expanded left group with $next_left (now: $left_group)"}
          incr left_idx
          
          # Recalculate left available movement with new group
          set leftmost_inst [lindex $left_group 0]
          lassign [dict get $max_movements $leftmost_inst] max_left _
          set used_move [expr {[dict exists $total_moves $leftmost_inst] ? [dict get $total_moves $leftmost_inst] : 0.0}]
          set left_available [expr {$max_left - $used_move}]
          set direction "left"
        # If left group can't expand, try right group
        } elseif {$right_idx < [llength $move_right_list]} {
          set next_right [lindex $move_right_list $right_idx 0]
          lappend right_group $next_right
          if {$debug} {puts "Expanded right group with $next_right (now: $right_group)"}
          incr right_idx
          
          # Recalculate right available movement with new group
          set rightmost_inst [lindex $right_group end]
          lassign [dict get $max_movements $rightmost_inst] _ max_right
          set used_move [expr {[dict exists $total_moves $rightmost_inst] ? [dict get $total_moves $rightmost_inst] : 0.0}]
          set right_available [expr {$max_right - $used_move}]
          set direction "right"
        }
      }
      
      if {$debug} {puts "Selected movement direction: $direction"}

      if {$direction eq "left"} {
        # Calculate how much we can move this group
        set move_distance [expr {min($left_available, $remaining_distance)}]
        
        # Move all rectangles in left group by this distance
        foreach inst $left_group {
          set current_move [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
          set new_move [expr {$current_move + $move_distance}]
          dict set total_moves $inst $new_move
          if {$debug} {puts "Updated $inst left move: $new_move (total)"}
        }
        
        # Update remaining distance
        set remaining_distance [expr {$remaining_distance - $move_distance}]
        if {$debug} {
          puts "Moved left group by $move_distance"
          puts "Remaining distance after move: $remaining_distance"
        }
        
        # Check if left group has reached maximum movement (based on leftmost)
        set leftmost_inst [lindex $left_group 0]
        lassign [dict get $max_movements $leftmost_inst] max_left _
        set current_move [dict get $total_moves $leftmost_inst]
        set group_maxed [expr {$current_move >= $max_left ? 1 : 0}]
        
        # If group is maxed out and we still need more distance, add next rectangle to group
        if {$group_maxed && $remaining_distance > 0 && $left_idx < [llength $move_left_list]} {
          set next_left [lindex $move_left_list $left_idx 0]
          lappend left_group $next_left
          if {$debug} {puts "Added $next_left to left group (now group: $left_group)"}
          incr left_idx
        }
      } else {
        # Calculate how much we can move this group
        set move_distance [expr {min($right_available, $remaining_distance)}]
        
        # Move all rectangles in right group by this distance
        foreach inst $right_group {
          set current_move [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
          set new_move [expr {$current_move + $move_distance}]
          dict set total_moves $inst $new_move
          if {$debug} {puts "Updated $inst right move: $new_move (total)"}
        }
        
        # Update remaining distance
        set remaining_distance [expr {$remaining_distance - $move_distance}]
        if {$debug} {
          puts "Moved right group by $move_distance"
          puts "Remaining distance after move: $remaining_distance"
        }
        
        # Check if right group has reached maximum movement (based on rightmost)
        set rightmost_inst [lindex $right_group end]
        lassign [dict get $max_movements $rightmost_inst] _ max_right
        set current_move [dict get $total_moves $rightmost_inst]
        set group_maxed [expr {$current_move >= $max_right ? 1 : 0}]
        
        # If group is maxed out and we still need more distance, add next rectangle to group
        if {$group_maxed && $remaining_distance > 0 && $right_idx < [llength $move_right_list]} {
          set next_right [lindex $move_right_list $right_idx 0]
          lappend right_group $next_right
          if {$debug} {puts "Added $next_right to right group (now group: $right_group)"}
          incr right_idx
        }
      }
      
      incr step
    }
    if {$debug} {puts "===== Completed Between-Gap Alternating Movement ====="}
  } elseif {$pos eq "left"} {
    if {$debug} {puts "\n===== Starting Left-Gap Sequential Movement ====="}
    # Left gap: move right, starting with closest rectangle
    set remaining_distance $delta
    set current_group [list] ;# {instnames}
    set idx 0
    set step 1

    # Initialize with closest rectangle to gap
    if {[llength $move_right_list] > 0} {
      set first_inst [lindex $move_right_list 0 0]
      lappend current_group $first_inst
      if {$debug} {puts "Initial right group: $first_inst"}
      set idx 1
    }

    while {$remaining_distance > 0} {
      if {$debug} {
        puts "\n----- Movement Step $step -----"
        puts "Remaining distance needed: $remaining_distance"
        puts "Current right group: $current_group"
      }

      # Calculate group-level available movement (based on rightmost rectangle)
      set group_available 0.0
      if {[llength $current_group] > 0} {
        set rightmost_inst [lindex $current_group end]
        lassign [dict get $max_movements $rightmost_inst] _ max_right
        set used_move [expr {[dict exists $total_moves $rightmost_inst] ? [dict get $total_moves $rightmost_inst] : 0.0}]
        set group_available [expr {$max_right - $used_move}]
      }
      
      if {$debug} {puts "Group available movement (based on rightmost): $group_available"}
      
      # If no available movement, try to expand the group
      if {$group_available <= 0 && $idx < [llength $move_right_list]} {
        set next_inst [lindex $move_right_list $idx 0]
        lappend current_group $next_inst
        if {$debug} {puts "Expanded group with $next_inst (now: $current_group)"}
        incr idx
        
        # Recalculate available movement with new group
        set rightmost_inst [lindex $current_group end]
        lassign [dict get $max_movements $rightmost_inst] _ max_right
        set used_move [expr {[dict exists $total_moves $rightmost_inst] ? [dict get $total_moves $rightmost_inst] : 0.0}]
        set group_available [expr {$max_right - $used_move}]
      }

      # Calculate how much we can move this group
      set move_distance [expr {min($group_available, $remaining_distance)}]
      
      # Move all rectangles in group by this distance
      foreach inst $current_group {
        set current_move [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
        set new_move [expr {$current_move + $move_distance}]
        dict set total_moves $inst $new_move
        if {$debug} {puts "Updated $inst move: $new_move (total)"}
      }
      
      # Update remaining distance
      set remaining_distance [expr {$remaining_distance - $move_distance}]
      if {$debug} {
        puts "Moved group by $move_distance"
        puts "Remaining distance after move: $remaining_distance"
      }
      
      # Check if group has reached maximum movement (based on rightmost)
      set rightmost_inst [lindex $current_group end]
      lassign [dict get $max_movements $rightmost_inst] _ max_right
      set current_move [dict get $total_moves $rightmost_inst]
      set group_maxed [expr {$current_move >= $max_right ? 1 : 0}]
      
      # If group is maxed out and we still need more distance, add next rectangle to group
      if {$group_maxed && $remaining_distance > 0 && $idx < [llength $move_right_list]} {
        set next_inst [lindex $move_right_list $idx 0]
        lappend current_group $next_inst
        if {$debug} {puts "Added $next_inst to group (now group: $current_group)"}
        incr idx
      }
      
      incr step
    }
    if {$debug} {puts "===== Completed Left-Gap Sequential Movement ====="}
  } elseif {$pos eq "right"} {
    if {$debug} {puts "\n===== Starting Right-Gap Sequential Movement ====="}
    # Right gap: move left, starting with closest rectangle
    set remaining_distance $delta
    set current_group [list] ;# {instnames}
    set idx 0
    set step 1

    # Initialize with closest rectangle to gap
    if {[llength $move_left_list] > 0} {
      set first_inst [lindex $move_left_list 0 0]
      lappend current_group $first_inst
      if {$debug} {puts "Initial left group: $first_inst"}
      set idx 1
    }

    while {$remaining_distance > 0} {
      if {$debug} {
        puts "\n----- Movement Step $step -----"
        puts "Remaining distance needed: $remaining_distance"
        puts "Current left group: $current_group"
      }

      # Calculate group-level available movement (based on leftmost rectangle)
      set group_available 0.0
      if {[llength $current_group] > 0} {
        set leftmost_inst [lindex $current_group 0]
        lassign [dict get $max_movements $leftmost_inst] max_left _
        set used_move [expr {[dict exists $total_moves $leftmost_inst] ? [dict get $total_moves $leftmost_inst] : 0.0}]
        set group_available [expr {$max_left - $used_move}]
      }
      
      if {$debug} {puts "Group available movement (based on leftmost): $group_available"}
      
      # If no available movement, try to expand the group
      if {$group_available <= 0 && $idx < [llength $move_left_list]} {
        set next_inst [lindex $move_left_list $idx 0]
        lappend current_group $next_inst
        if {$debug} {puts "Expanded group with $next_inst (now: $current_group)"}
        incr idx
        
        # Recalculate available movement with new group
        set leftmost_inst [lindex $current_group 0]
        lassign [dict get $max_movements $leftmost_inst] max_left _
        set used_move [expr {[dict exists $total_moves $leftmost_inst] ? [dict get $total_moves $leftmost_inst] : 0.0}]
        set group_available [expr {$max_left - $used_move}]
      }

      # Calculate how much we can move this group
      set move_distance [expr {min($group_available, $remaining_distance)}]
      
      # Move all rectangles in group by this distance
      foreach inst $current_group {
        set current_move [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
        set new_move [expr {$current_move + $move_distance}]
        dict set total_moves $inst $new_move
        if {$debug} {puts "Updated $inst move: $new_move (total)"}
      }
      
      # Update remaining distance
      set remaining_distance [expr {$remaining_distance - $move_distance}]
      if {$debug} {
        puts "Moved group by $move_distance"
        puts "Remaining distance after move: $remaining_distance"
      }
      
      # Check if group has reached maximum movement (based on leftmost)
      set leftmost_inst [lindex $current_group 0]
      lassign [dict get $max_movements $leftmost_inst] max_left _
      set current_move [dict get $total_moves $leftmost_inst]
      set group_maxed [expr {$current_move >= $max_left ? 1 : 0}]
      
      # If group is maxed out and we still need more distance, add next rectangle to group
      if {$group_maxed && $remaining_distance > 0 && $idx < [llength $move_left_list]} {
        set next_inst [lindex $move_left_list $idx 0]
        lappend current_group $next_inst
        if {$debug} {puts "Added $next_inst to group (now group: $current_group)"}
        incr idx
      }
      
      incr step
    }
    if {$debug} {puts "===== Completed Right-Gap Sequential Movement ====="}
  }

  # Format move_list with cumulative directions and distances
  # First separate movements by side
  set left_moves [list]
  set right_moves [list]
  
  # Get gap position and coordinates for distance calculation
  lassign $target_gap idx gap_width gap_pos left_count gap_bl
  lassign $gap_bl gap_x gap_y

  # Separate moves into left and right groups and calculate distance from gap
  foreach inst [dict keys $total_moves] {
    # Determine direction
    set dir "left"
    foreach item $move_right_list {
      if {[lindex $item 0] eq $inst} {
        set dir "right"
        break
      }
    }
    
    # Find original coordinates to calculate distance from gap
    set orig_x 0
    set orig_x1 0
    foreach rect $target_row_rects {
      if {[lindex $rect 0] eq $inst} {
        lassign [lindex $rect 1] rx ry rx1 ry1
        set orig_x $rx
        set orig_x1 $rx1
        break
      }
    }
    
    # Calculate distance from gap based on direction
    if {$dir eq "left"} {
      # Distance for left-moving rectangles is gap_x - original x1
      set distance [expr {$gap_x - $orig_x1}]
      lappend left_moves [list $inst [list $dir [dict get $total_moves $inst]] $distance]
    } else {
      # Distance for right-moving rectangles is original x - gap_x (minus gap width)
      set distance [expr {$orig_x - ($gap_x + $gap_width)}]
      lappend right_moves [list $inst [list $dir [dict get $total_moves $inst]] $distance]
    }
  }

  # Sort each side by distance from gap (farthest first)
  set sorted_left [lsort -decreasing -real -index 2 $left_moves]
  set sorted_right [lsort -decreasing -real -index 2 $right_moves]

  # Combine into final move list: all left moves first (sorted), then all right moves (sorted)
  # Only include moves with distance > 0
  set move_list [list]
  foreach move $sorted_left {
    set inst [lindex $move 0]
    set data [lindex $move 1]
    lassign $data dir dist
    if {$dist > $filterMovementPrecision} {
      lappend move_list [list $inst $data]
    }
  }
  foreach move $sorted_right {
    set inst [lindex $move 0]
    set data [lindex $move 1]
    lassign $data dir dist
    if {$dist > $filterMovementPrecision} {
      lappend move_list [list $inst $data]
    }
  }

  if {$debug} {
    puts "\n===== Final Movement List (sorted by distance from gap) ====="
    foreach move $move_list {
      lassign $move inst data
      lassign $data dir dist
      puts "$inst: $dir by $dist (total)"
    }
    puts "==========================================================="
  }

  # --------------------------
  # Post-movement overlap check
  # --------------------------
  if {$debug} {puts "\n===== Starting Post-Movement Overlap Check ====="}
  
  # Create list of moved rectangles with updated coordinates
  set moved_rects [list]
  foreach rect $target_row_rects {
    lassign $rect instname coords is_left is_right width
    lassign $coords x y x1 y1
    
    # Check if this rectangle was moved
    set moved 0
    foreach move $move_list {
      lassign $move m_inst m_data
      lassign $m_data m_dir m_dist
      
      if {$m_inst eq $instname} {
        # Update coordinates based on movement
        if {$m_dir eq "right"} {
          set new_x [expr {$x + $m_dist}]
          set new_x1 [expr {$x1 + $m_dist}]
        } else {
          set new_x [expr {$x - $m_dist}]
          set new_x1 [expr {$x1 - $m_dist}]
        }
        lappend moved_rects [list $instname [list $new_x $y $new_x1 $y1]]
        if {$debug} {
          puts "Moved $instname: original ($x, $x1) → new ($new_x, $new_x1)"
        }
        set moved 1
        break
      }
    }
    
    # Add original coordinates if not moved
    if {!$moved} {
      lappend moved_rects [list $instname $coords]
      if {$debug} {
        puts "Unmoved $instname: ($x, $x1)"
      }
    }
  }

  # Check for overlaps in moved rectangles
  set post_overlap 0
  set moved_count [llength $moved_rects]
  set moved_indices [list]
  for {set i 0} {$i < $moved_count} {incr i} {
    lappend moved_indices $i
  }
  
  foreach i $moved_indices {
    set r1 [lindex $moved_rects $i 1]
    lassign $r1 x1 y1 x1_1 y1_1
    set inst1 [lindex $moved_rects $i 0]
    
    foreach j [lrange $moved_indices [expr {$i + 1}] end] {
      set r2 [lindex $moved_rects $j 1]
      lassign $r2 x2 y2 x2_1 y2_1
      set inst2 [lindex $moved_rects $j 0]
      
      if {!($x1_1 <= $x2 || $x2_1 <= $x1)} {
        if {$debug} {
          puts "OVERLAP DETECTED: $inst1 ($x1, $x1_1) and $inst2 ($x2, $x2_1)"
        }
        set post_overlap 1
        break
      }
    }
    if {$post_overlap} break
  }
  
  if {$post_overlap} {
    if {$debug} {puts "===== Post-Movement Check Failed: Overlaps Detected ====="}
    return [list "no" [list] [list]]
  } else {
    if {$debug} {puts "===== Post-Movement Check Passed: No Overlaps ====="}
  }

  # Calculate free region position, adjusting for left movements
  set target_gap_bl [lindex $target_gap end]
  lassign $target_gap_bl original_gap_x original_gap_y
  set left_shift 0.0
  
  # Get left shift amount from closest left-moving rectangle (all left-moving rectangles shift equally)
  if {[llength $sorted_left] > 0} {
    # Closest left-moving rectangle is first in sorted_left list (farthest first, take any for shift value)
    set closest_left_inst [lindex $sorted_left 0 0]
    foreach move $move_list {
      lassign $move inst data
      if {$inst eq $closest_left_inst} {
        lassign $data dir shift
        set left_shift $shift
        break
      }
    }
  }
  
  # Calculate new free region position
  set new_gap_x [expr {$original_gap_x - $left_shift}]
  set free_region [list $new_gap_x $original_gap_y]
  
  set result_flag "yes"

  if {$debug} {
    puts "\nFinal Result: Success"
    puts "Original gap position: $target_insert_loc"
    puts "Left shift amount: $left_shift"
    puts "Adjusted free region: $free_region"
  }

  # Return results
  return [list $result_flag $free_region $move_list]
}
    
