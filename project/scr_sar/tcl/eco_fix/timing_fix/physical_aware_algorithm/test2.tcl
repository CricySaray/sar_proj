#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/12 12:36:44 Tuesday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This procedure expands a specified gap by moving rectangles to create required free space, considering group-based 
#             movement for contiguous blocks. It generates a movement list ordered by distance from the gap (farthest first) with 
#             all moves on one side grouped together before the other.
# return    : [list $result_flag $expandedRegionLoc $move_list]
#             consist of:
#             $result_flag: yes|no|forceInsert
#                           yes: The existing movable space meets the requirements of the needed space and performs the movement operation.
#                           no : The existing movable space is zero and does not perform any movement operation.
#                           forceInsert: The existing movable space is not zero, but it does not meet the requirements of the needed space. 
#                                       It can only move all movable rectangles as much as possible to achieve the effect of freeing up the maximum space.
#             $expandedRegionLoc : {x y}
#             $move_list : {{instname1 {left 1.4}} {instname2 {right 2.8}} ...}
# update    : (U002) fix incorrect position returned when have movement to left
# update    : 2025/08/19 17:39:57 Tuesday
#             (U003) Solve the problem of entering an infinite loop
#             (U004) add forceInsert result flag for partial space expansion
# update    : 2025/08/20 Optimize movement logic with contiguous block grouping
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
  # Flag for force insert scenario
  set force_insert 0
  # Extract key parameters
  lassign $target_insert_loc insert_x insert_y
  lassign $target_size target_w target_h
  set coreRects_innerBoundaryArea [operateLUT -type read -attr {core_inner_boundary_rects}]
  set total_area {*}[dbShape -output hrect $total_area AND $coreRects_innerBoundaryArea]
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
  set original_delta [expr {$target_w - $gap_width}]
  set delta $original_delta
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
  # Calculate total possible movement
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
    # Valid if total movable distance ≥ delta or there's partial movement possible
    set total_possible $total_right_possible
    if {$total_possible >= $delta} { ; # U003
      set valid 1
    } elseif {$total_possible > 0} {
      set valid 1
      set force_insert 1
      set delta $total_possible ;# Adjust delta to actual possible movement
      if {$debug} {
        puts "Partial movement possible: $total_possible (needs $original_delta)"
      }
    } else {
      set valid 0 
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
    # Valid if total movable distance ≥ delta or there's partial movement possible
    set total_possible $total_left_possible
    if {$total_possible >= $delta} {
      set valid 1
    } elseif {$total_possible > 0} {
      set valid 1
      set force_insert 1
      set delta $total_possible ;# Adjust delta to actual possible movement
      if {$debug} {
        puts "Partial movement possible: $total_possible (needs $original_delta)"
      } 
    } else {
      set valid 0 
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
    # Valid if total movable distance ≥ delta or there's partial movement possible
    set total_possible [expr {$total_left_possible + $total_right_possible}]
    if {$total_possible >= $delta} {
      set valid 1
    } elseif {$total_possible > 0} {
      set valid 1
      set force_insert 1
      set delta $total_possible ;# Adjust delta to actual possible movement
      if {$debug} {
        puts "Partial movement possible: $total_possible (needs $original_delta)"
      }
    } else {
      set valid 0 
    }
  }
	# 修改后
	if {!$valid} {
		if {$debug} {puts "No valid movement possible for required expansion (delta=$delta)"}
		# 仅当完全无法移动时才返回空列表
		if {[expr {$total_possible <= 0}]} {
			return [list $result_flag $free_region $move_list]
		}
		# 即使总距离不足仍继续执行，尝试部分移动
		set force_insert 1
		set delta $total_possible
	}

  # --------------------------
  # New grouping logic for contiguous blocks
  # --------------------------
  set left_groups [list]
  set right_groups [list]

  # Helper procedure to create contiguous rectangle groups with direction awareness
  # Parameters:
  #   rects - List of rectangles to process
  #   sorted_rects - Globally sorted list of rectangles
  #   direction - "left" or "right" to determine comparison logic
  proc create_contiguous_groups {rects sorted_rects direction} {
    if {[llength $rects] == 0} {
      return [list]
    }
    set groups [list]
    
    # Initialize with first rectangle in processing order
    set current_group [list [lindex $rects 0 0]]
    set prev_inst [lindex $rects 0 0]
    
    # Find index of previous instance in sorted_rects
    set prev_idx [lsearch -index 0 $sorted_rects $prev_inst]
    lassign [lindex $sorted_rects $prev_idx 1] prev_x prev_y prev_x1 prev_y1

    # Process remaining rectangles based on direction
    for {set i 1} {$i < [llength $rects]} {incr i} {
      set curr_inst [lindex $rects $i 0]
      set curr_idx [lsearch -index 0 $sorted_rects $curr_inst]
      lassign [lindex $sorted_rects $curr_idx 1] curr_x curr_y curr_x1 curr_y1
      
      # Different comparison logic based on direction
      set is_contiguous 0
      if {$direction eq "right"} {
        # Right side grouping: check if previous right touches current left
        # (prev's bottom-right x == current's bottom-left x)
        if {$prev_x1 == $curr_x} {
          set is_contiguous 1
        }
      } else {
        # Left side grouping: check if previous left touches current right
        # (prev's bottom-left x == current's bottom-right x)
        if {$prev_x == $curr_x1} {
          set is_contiguous 1
        }
      }
      
      if {$is_contiguous} {
        # Contiguous, add to current group
        lappend current_group $curr_inst
      } else {
        # Not contiguous, start new group
        lappend groups $current_group
        set current_group [list $curr_inst]
      }
      
      # Update previous rectangle info to current rectangle
      set prev_inst $curr_inst
      set prev_idx $curr_idx
      lassign [lindex $sorted_rects $prev_idx 1] prev_x prev_y prev_x1 prev_y1
    }
    
    # Add the last group
    lappend groups $current_group
    return $groups
  }

			

  # Create groups based on gap position
  if {$pos eq "between"} {
    # Left groups (move left)
    set left_rects $move_left_list
    set left_groups [create_contiguous_groups $left_rects $sorted_rects "left"]
    # Right groups (move right)
    set right_rects $move_right_list
    set right_groups [create_contiguous_groups $right_rects $sorted_rects "right"]

    if {$debug} {
      puts "\n===== Contiguous Block Groups ====="
      puts "Left side groups ([llength $left_groups] total):"
      for {set i 0} {$i < [llength $left_groups]} {incr i} {
        puts "  Group $i: [join [lindex $left_groups $i] ", "]"
      }
      puts "Right side groups ([llength $right_groups] total):"
      for {set i 0} {$i < [llength $right_groups]} {incr i} {
        puts "  Group $i: [join [lindex $right_groups $i] ", "]"
      }
      puts "===================================="
    }
  } elseif {$pos eq "left"} {
    # Only right groups (move right)
    set right_rects $move_right_list
    set right_groups [create_contiguous_groups $right_rects $sorted_rects "left"]

    if {$debug} {
      puts "\n===== Contiguous Block Groups ====="
      puts "Right side groups ([llength $right_groups] total):"
      for {set i 0} {$i < [llength $right_groups]} {incr i} {
        puts "  Group $i: [join [lindex $right_groups $i] ", "]"
      }
      puts "===================================="
    }
  } elseif {$pos eq "right"} {
    # Only left groups (move left)
    set left_rects $move_left_list
    set left_groups [create_contiguous_groups $left_rects $sorted_rects "right"]

    if {$debug} {
      puts "\n===== Contiguous Block Groups ====="
      puts "Left side groups ([llength $left_groups] total):"
      for {set i 0} {$i < [llength $left_groups]} {incr i} {
        puts "  Group $i: [join [lindex $left_groups $i] ", "]"
      }
      puts "===================================="
    }
  }

  # --------------------------
  # Modified movement logic using contiguous groups
  # --------------------------
  set total_moves [dict create]
  set remaining_distance $delta

  if {$pos eq "between"} {
    if {$debug} {puts "\n===== Starting Between-Gap Group Movement ====="}
    set step 1
    while {$remaining_distance > 0 && ([llength $left_groups] > 0 || [llength $right_groups] > 0)} {
      # Calculate total possible movement for each side
      set left_total 0.0
      foreach group $left_groups {
        foreach inst $group {
          lassign [dict get $max_movements $inst] max_left _
          set used [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
          append left_total [expr {$max_left - $used}]
        }
      }
      set right_total 0.0
      foreach group $right_groups {
        foreach inst $group {
          lassign [dict get $max_movements $inst] _ max_right
          set used [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
          append right_total [expr {$max_right - $used}]
        }
      }

      # Determine which side to move
      set move_side ""
      if {$left_total <= 0 && $right_total <= 0} {
        break
      } elseif {$left_total >= $right_total} {
        set move_side "left"
      } else {
        set move_side "right"
      }

      # Move closest group to gap on selected side
      if {$move_side eq "left" && [llength $left_groups] > 0} {
        # Left side: closest group is first in list (sorted by proximity)
        set group [lindex $left_groups 0]
        # Get max possible move for this group (limited by leftmost instance)
        set leftmost_inst [lindex $group 0]
        lassign [dict get $max_movements $leftmost_inst] max_left _
        set used [expr {[dict exists $total_moves $leftmost_inst] ? [dict get $total_moves $leftmost_inst] : 0.0}]
        set max_move [expr {$max_left - $used}]
        set actual_move [expr {min($max_move, $remaining_distance)}]

        if {$actual_move <= 0} {
          # Remove group if no movement possible
          set left_groups [lrange $left_groups 1 end]
          continue
        }

        # Apply movement to all instances in group
        foreach inst $group {
          set curr [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
          dict set total_moves $inst [expr {$curr + $actual_move}]
        }

        if {$debug} {
          puts "Step $step: Moved left group [join $group ", "] by $actual_move"
          puts "  Remaining distance: [expr {$remaining_distance - $actual_move}]"
        }

        set remaining_distance [expr {$remaining_distance - $actual_move}]

        # Check if groups can be merged (left movement specific logic)
        if {[llength $left_groups] > 1} {
          set next_group [lindex $left_groups 1]
          # Current group is closer to gap, located to the right of next group
          set curr_rightmost [lindex $group end]  ;# Rightmost rect of current group
          set next_leftmost [lindex $next_group 0] ;# Leftmost rect of next group
          
          # Get original coordinates
          set curr_idx [lsearch -index 0 $sorted_rects $curr_rightmost]
          lassign [lindex $sorted_rects $curr_idx 1] curr_x _ _ _  ;# Left x of current rightmost
          set next_idx [lsearch -index 0 $sorted_rects $next_leftmost]
          lassign [lindex $sorted_rects $next_idx 1] _ _ next_x1 _ ;# Right x of next leftmost
          
          # Safe get movement distances
          set curr_move [expr {[dict exists $total_moves $curr_rightmost] ? [dict get $total_moves $curr_rightmost] : 0.0}]
          set next_move [expr {[dict exists $total_moves $next_leftmost] ? [dict get $total_moves $next_leftmost] : 0.0}]
          
          # Calculate positions after movement: left-moving reduces x coordinates
          set curr_x_moved [expr {$curr_x - $curr_move}]       ;# Current rightmost's left x after move
          set next_x1_moved [expr {$next_x1 - $next_move}]     ;# Next leftmost's right x after move
          
          # Merge only if positions are exactly contiguous
          if {$curr_x_moved == $next_x1_moved} {
            # Left movement: next group (farther from gap) goes to the left of current group
            set merged [concat $next_group $group]
            set left_groups [lreplace $left_groups 0 1 $merged]
            if {$debug} {
              puts "  Merged left groups (next → current): [join $merged ", "]"
            }
          }
        }

      } elseif {$move_side eq "right" && [llength $right_groups] > 0} {
        # Right side: closest group is first in list (sorted by proximity)
        set group [lindex $right_groups 0]
        # Get max possible move for this group (limited by rightmost instance)
        set rightmost_inst [lindex $group end]
        lassign [dict get $max_movements $rightmost_inst] _ max_right
        set used [expr {[dict exists $total_moves $rightmost_inst] ? [dict get $total_moves $rightmost_inst] : 0.0}]
        set max_move [expr {$max_right - $used}]
        set actual_move [expr {min($max_move, $remaining_distance)}]

        if {$actual_move <= 0} {
          # Remove group if no movement possible
          set right_groups [lrange $right_groups 1 end]
          continue
        }

        # Apply movement to all instances in group
        foreach inst $group {
          set curr [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
          dict set total_moves $inst [expr {$curr + $actual_move}]
        }

        if {$debug} {
          puts "Step $step: Moved right group [join $group ", "] by $actual_move"
          puts "  Remaining distance: [expr {$remaining_distance - $actual_move}]"
        }

        set remaining_distance [expr {$remaining_distance - $actual_move}]
        # Check if group can be merged with next group (if any)
        if {[llength $right_groups] > 1} {
          set next_group [lindex $right_groups 1]
          # Check if current group's rightmost touches next group's leftmost
          set curr_rightmost [lindex $group end]
          set curr_idx [lsearch -index 0 $sorted_rects $curr_rightmost]
          lassign [lindex $sorted_rects $curr_idx 1] _ _ curr_x1 _
          
          set next_leftmost [lindex $next_group 0]
          set next_idx [lsearch -index 0 $sorted_rects $next_leftmost]
          lassign [lindex $sorted_rects $next_idx 1] next_x _ _ _
          
          # Calculate positions after movement
          set curr_x1_moved [expr {$curr_x1 - [expr {[dict exists $total_moves $curr_rightmost] ? [dict get $total_moves $curr_rightmost] : 0.0}]}]
          set next_x_moved [expr {$next_x - [expr {[dict exists $total_moves $next_leftmost] ? [dict get $total_moves $next_leftmost] : 0.0}]}]
          
          if {$curr_x1_moved >= $next_x_moved} {
            # Merge groups
            set merged [concat $group $next_group]
            set right_groups [lreplace $right_groups 0 1 $merged]
            if {$debug} {
              puts "  Merged right groups into: [join $merged ", "]"
            }
          }
        }
      }
      incr step
    }
    if {$debug} {puts "===== Completed Between-Gap Group Movement ====="}
  } elseif {$pos eq "left"} {
    if {$debug} {puts "\n===== Starting Left-Gap Group Movement ====="}
    set step 1
    while {$remaining_distance > 0 && [llength $right_groups] > 0} {
      # Only move right groups
      set group [lindex $right_groups 0]
      # Get max possible move for this group (limited by rightmost instance)
      set rightmost_inst [lindex $group end]
      lassign [dict get $max_movements $rightmost_inst] _ max_right
      set used [expr {[dict exists $total_moves $rightmost_inst] ? [dict get $total_moves $rightmost_inst] : 0.0}]
      set max_move [expr {$max_right - $used}]
      set actual_move [expr {min($max_move, $remaining_distance)}]

      if {$actual_move <= 0} {
        # Remove group if no movement possible
        set right_groups [lrange $right_groups 1 end]
        continue
      }

      # Apply movement to all instances in group
      foreach inst $group {
        set curr [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
        dict set total_moves $inst [expr {$curr + $actual_move}]
      }

      if {$debug} {
        puts "Step $step: Moved right group [join $group ", "] by $actual_move"
        puts "  Remaining distance: [expr {$remaining_distance - $actual_move}]"
      }

      set remaining_distance [expr {$remaining_distance - $actual_move}]
      # Check if group can be merged with next group (if any)
      if {[llength $right_groups] > 1} {
        set next_group [lindex $right_groups 1]
        # Check if current group's rightmost touches next group's leftmost
        set curr_rightmost [lindex $group end]
        set curr_idx [lsearch -index 0 $sorted_rects $curr_rightmost]
        lassign [lindex $sorted_rects $curr_idx 1] _ _ curr_x1 _
        
        set next_leftmost [lindex $next_group 0]
        set next_idx [lsearch -index 0 $sorted_rects $next_leftmost]
        lassign [lindex $sorted_rects $next_idx 1] next_x _ _ _
        
        # Calculate positions after movement
        set curr_x1_moved [expr {$curr_x1 - [expr {[dict exists $total_moves $curr_rightmost] ? [dict get $total_moves $curr_rightmost] : 0.0}]}]
        set next_x_moved [expr {$next_x - [expr {[dict exists $total_moves $next_leftmost] ? [dict get $total_moves $next_leftmost] : 0.0}]}]
        
        if {$curr_x1_moved >= $next_x_moved} {
          # Merge groups
          set merged [concat $group $next_group]
          set right_groups [lreplace $right_groups 0 1 $merged]
          if {$debug} {
            puts "  Merged right groups into: [join $merged ", "]"
          }
        }
      }
      incr step
    }
    if {$debug} {puts "===== Completed Left-Gap Group Movement ====="}
  } elseif {$pos eq "right"} {
    if {$debug} {puts "\n===== Starting Right-Gap Group Movement ====="}
    set step 1
    while {$remaining_distance > 0 && [llength $left_groups] > 0} {
      # Only move left groups
      set group [lindex $left_groups 0]
      # Get max possible move for this group (limited by leftmost instance)
      set leftmost_inst [lindex $group 0]
      lassign [dict get $max_movements $leftmost_inst] max_left _
      set used [expr {[dict exists $total_moves $leftmost_inst] ? [dict get $total_moves $leftmost_inst] : 0.0}]
      set max_move [expr {$max_left - $used}]
      set actual_move [expr {min($max_move, $remaining_distance)}]

      if {$actual_move <= 0} {
        # Remove group if no movement possible
        set left_groups [lrange $left_groups 1 end]
        continue
      }

      # Apply movement to all instances in group
      foreach inst $group {
        set curr [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
        dict set total_moves $inst [expr {$curr + $actual_move}]
      }

      if {$debug} {
        puts "Step $step: Moved left group [join $group ", "] by $actual_move"
        puts "  Remaining distance: [expr {$remaining_distance - $actual_move}]"
      }

      set remaining_distance [expr {$remaining_distance - $actual_move}]
      # Check if group can be merged with next group (if any)
      if {[llength $left_groups] > 1} {
        set next_group [lindex $left_groups 1]
        # Check if current group's rightmost touches next group's leftmost
        set curr_rightmost [lindex $group end]
        set curr_idx [lsearch -index 0 $sorted_rects $curr_rightmost]
        lassign [lindex $sorted_rects $curr_idx 1] _ _ curr_x1 _
        
        set next_leftmost [lindex $next_group 0]
        set next_idx [lsearch -index 0 $sorted_rects $next_leftmost]
        lassign [lindex $sorted_rects $next_idx 1] next_x _ _ _
        
        # Calculate positions after movement
        set curr_x1_moved [expr {$curr_x1 - [expr {[dict exists $total_moves $curr_rightmost] ? [dict get $total_moves $curr_rightmost] : 0.0}]}]
        set next_x_moved [expr {$next_x - [expr {[dict exists $total_moves $next_leftmost] ? [dict get $total_moves $next_leftmost] : 0.0}]}]
        
        if {$curr_x1_moved >= $next_x_moved} {
          # Merge groups
          set merged [concat $group $next_group]
          set left_groups [lreplace $left_groups 0 1 $merged]
          if {$debug} {
            puts "  Merged left groups into: [join $merged ", "]"
          }
        }
      }
      incr step
    }
    if {$debug} {puts "===== Completed Right-Gap Group Movement ====="}
  }

  # Check if we couldn't achieve full distance
  if {$remaining_distance > 0 && [dict size $total_moves] > 0} {
    set force_insert 1
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
      set distance [format "%.3f" [expr {$gap_x - $orig_x1}]]
      lappend left_moves [list $inst [list $dir [dict get $total_moves $inst]] $distance]
    } else {
      # Distance for right-moving rectangles is original x - gap_x (minus gap width)
      set distance [format "%.3f" [expr {$orig_x - ($gap_x + $gap_width)}]]
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
  set sorted_left [lmap temp_left $sorted_left { ; # U002: remove zero movement instance items
    if {[expr {[lindex $temp_left 1 1] == 0.0}]} { continue } else { set temp_left }
  }]
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
  # Determine result flag based on force_insert
  if {$force_insert} { ; # U004
    set result_flag "forceInsert"
  } else {
    set result_flag "yes"
  }
  if {$debug} {
    puts "\nFinal Result: [expr {$force_insert ? "Force Insert" : "Success"}]"
    puts "Original gap position: $target_insert_loc"
    puts "Left shift amount: $left_shift"
    puts "Adjusted free region: $free_region"
    puts "Total movement made: [expr {$original_delta - $remaining_distance}] of $original_delta needed"
  }
  # Return results
  return [list $result_flag $free_region $move_list]
}
