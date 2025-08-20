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
#             $result_flag: yes|no|forceInsert
#             $expandedRegionLoc : {x y}
#             $move_list : {{instname1 {left 1.4}} {instname2 {right 2.8}} ...}
# update    : (U002) fix incorrect position returned when have movement to left
#             (U004) add forceInsert result flag for partial space expansion
#             (U005) fix variable name error (right_move_list -> move_right_list)
# TODO      : (U001) cantMoveList: [list IP mem physicalCell(endcap welltap[can move small distance]) ...]
#             (U003) Solve the problem of entering an infinite loop
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
    # Valid if total movable distance â‰¥ delta or there's partial movement possible
    set total_possible $total_right_possible
    if {$total_possible >= $delta} {
      set valid 1
    } elseif {$total_possible > 0} {
      set valid 1
      set force_insert 1
      set delta $total_possible ;# Adjust delta to actual possible movement
      if {$debug} {
        puts "Partial movement possible: $total_possible (needs $original_delta)"
      }
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
    # Valid if total movable distance â‰¥ delta or there's partial movement possible
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
    
    # Valid if total movable distance â‰¥ delta or there's partial movement possible
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
    }
  }
  
  if {!$valid} {
    if {$debug} {puts "No valid movement possible for required expansion (delta=$delta)"}
    return [list $result_flag $free_region $move_list]
  }

# Generate movement list with alternating proximity-based strategy
  # Track total movement for each instance using dict
  set total_moves [dict create]
  # Initialize force_insert flag (ensure compatibility with later code)
  set force_insert 0
  
  # --------------------------
  # Bundle-based movement logic
  # --------------------------
  
  if {$debug} {
    puts "\n===== Starting Bundle Initialization ====="
    puts "Total rectangles to process: [llength $sorted_rects]"
  }
  
  # Create bundles of adjacent rectangles
  set bundles [list]
  if {[llength $sorted_rects] == 0} {
    if {$debug} {puts "No rectangles available for bundling"}
  } else {
    set current_bundle [list [lindex $sorted_rects 0 0]]
    if {$debug} {
      puts "Initial bundle created with: [lindex $sorted_rects 0 0]"
    }
    
    # Iterate through sorted rectangles to create bundles
    for {set i 1} {$i < [llength $sorted_rects]} {incr i} {
      set prev_rect [lindex $sorted_rects [expr {$i - 1}]]
      set curr_rect [lindex $sorted_rects $i]
      set prev_x1 [lindex $prev_rect 1 2]
      set curr_x [lindex $curr_rect 1 0]
      set prev_inst [lindex $prev_rect 0]
      set curr_inst [lindex $curr_rect 0]
      
      # Check if current rectangle is adjacent to previous
      set gap [expr {abs($curr_x - $prev_x1)}]
      if {$debug} {
        puts "Checking adjacency: $prev_inst (x1=$prev_x1) and $curr_inst (x=$curr_x) - gap=$gap"
      }
      
      if {$gap < $filterMovementPrecision} {
        lappend current_bundle $curr_inst
        if {$debug} {
          puts "Added $curr_inst to current bundle. Bundle now: $current_bundle"
        }
      } else {
        lappend bundles $current_bundle
        if {$debug} {
          puts "Created new bundle: $current_bundle (gap too large: $gap)"
        }
        set current_bundle [list $curr_inst]
      }
    }
    lappend bundles $current_bundle
    if {$debug} {
      puts "Final bundle added: $current_bundle"
      puts "Total bundles created: [llength $bundles]"
      for {set i 0} {$i < [llength $bundles]} {incr i} {
        puts "  Bundle $i: [lindex $bundles $i]"
      }
    }
  }
  
  # Identify left and right bundles relative to target gap
  set left_bundles [list]
  set right_bundles [list]
  set target_reached 0
  set gap_x [lindex $gap_bl 0]  ;# Get gap x coordinate from gap bottom-left
  
  if {$debug} {
    puts "\n===== Classifying Bundles Relative to Gap ====="
    puts "Target gap position: x=$gap_x"
  }
  
  foreach rect $sorted_rects {
    set instname [lindex $rect 0]
    set rect_x [lindex $rect 1 0]
    set rect_x1 [lindex $rect 1 2]
    
    # Find which bundles are left/right of the target gap
    if {!$target_reached && $rect_x1 > $gap_x} {
      if {$debug} {
        puts "Crossed target gap: $instname (x1=$rect_x1) exceeds gap x=$gap_x"
      }
      set target_reached 1
    }
    
    foreach bundle $bundles {
      if {[lsearch $bundle $instname] != -1} {
        if (!$target_reached) {
          lappend left_bundles $bundle
          if {$debug} {
            puts "Added bundle $bundle to left_bundles (contains $instname)"
          }
        } else {
          lappend right_bundles $bundle
          if {$debug} {
            puts "Added bundle $bundle to right_bundles (contains $instname)"
          }
        }
        break
      }
    }
  }
  
  # Reverse right bundles to process closest first
  set right_bundles [lreverse $right_bundles]
  if {$debug} {
    puts "\nRight bundles reversed for proximity processing:"
    for {set i 0} {$i < [llength $right_bundles]} {incr i} {
      puts "  Right bundle $i: [lindex $right_bundles $i]"
    }
    puts "Left bundles (closest last):"
    for {set i 0} {$i < [llength $left_bundles]} {incr i} {
      puts "  Left bundle $i: [lindex $left_bundles $i]"
    }
  }
  
  # Calculate maximum possible movement for each bundle
  proc get_bundle_max_move {bundle dir sorted_rects max_movements} {
    set max_move 0.0
    foreach inst $bundle {
      lassign [dict get $max_movements $inst] max_left max_right
      if {$dir eq "left"} {
        set inst_max $max_left
      } else {
        set inst_max $max_right
      }
      if {$max_move == 0.0 || $inst_max < $max_move} {
        set max_move $inst_max
      }
    }
    return $max_move
  }
  
  # Calculate total possible movement for left and right sides
  set total_left_possible 0.0
  foreach bundle $left_bundles {
    set bundle_max [get_bundle_max_move $bundle "left" $sorted_rects $max_movements]
    set total_left_possible [expr {$total_left_possible + $bundle_max}]
    if {$debug} {
      puts "Left bundle $bundle max move: $bundle_max (cumulative: $total_left_possible)"
    }
  }
  
  set total_right_possible 0.0
  foreach bundle $right_bundles {
    set bundle_max [get_bundle_max_move $bundle "right" $sorted_rects $max_movements]
    set total_right_possible [expr {$total_right_possible + $bundle_max}]
    if {$debug} {
      puts "Right bundle $bundle max move: $bundle_max (cumulative: $total_right_possible)"
    }
  }
  
  # Update valid flag and force_insert based on calculations
  set valid 0
  if {$total_left_possible + $total_right_possible >= $delta} {
    set valid 1
    if {$debug} {
      puts "\nTotal possible movement ($[expr {$total_left_possible + $total_right_possible}]) >= required ($delta) - valid movement"
    }
  } elseif {$total_left_possible + $total_right_possible > 0} {
    set valid 1
    set force_insert 1
    set delta [expr {$total_left_possible + $total_right_possible}]
    if {$debug} {
      puts "\nPartial movement possible: $delta (needs $original_delta) - setting force_insert=1"
    }
  } else {
    if {$debug} {
      puts "\nNo possible movement available (total=0) - invalid"
    }
  }
  
  if {!$valid} {
    if {$debug} {puts "No valid movement possible for required expansion (delta=$delta)"}
    return [list $result_flag $free_region $move_list]
  }
  
  # Initialize remaining distance and movement tracking
  set remaining_distance $delta
  set move_direction ""
  set iteration 0
  
  # Determine initial movement direction based on which side has more possible movement
  if {$total_left_possible > $total_right_possible && [llength $left_bundles] > 0} {
    set move_direction "left"
    if {$debug} {
      puts "\nChoosing initial direction: left (more possible movement: $total_left_possible > $total_right_possible)"
    }
  } else {
    set move_direction "right"
    if {$debug} {
      puts "\nChoosing initial direction: right (more possible movement: $total_right_possible >= $total_left_possible)"
    }
  }
  
  if {$debug} {
    puts "\n===== Starting Bundle-Based Movement ====="
    puts "Initial left bundles: [llength $left_bundles]"
    puts "Initial right bundles: [llength $right_bundles]"
    puts "Total possible movement: left=$total_left_possible, right=$total_right_possible"
    puts "Target movement: $delta"
    puts "Initial movement direction: $move_direction"
  }
  
  # Main movement loop
  while {$remaining_distance > 0} {
    incr iteration
    if {$debug} {
      puts "\n===== Movement Iteration $iteration ====="
      puts "Remaining distance: $remaining_distance"
      puts "Current direction: $move_direction"
      puts "Left bundles remaining: [llength $left_bundles]"
      puts "Right bundles remaining: [llength $right_bundles]"
    }
    
    if {$move_direction eq "right" && [llength $right_bundles] > 0} {
      # Move right bundles (closest to gap first)
      set current_bundle [lindex $right_bundles 0]
      set max_move [get_bundle_max_move $current_bundle "right" $sorted_rects $max_movements]
      set actual_move [expr {min($max_move, $remaining_distance)}]
      
      if {$debug} {
        puts "\nProcessing right bundle: $current_bundle"
        puts "Max possible move for bundle: $max_move"
        puts "Actual move (capped by remaining distance): $actual_move"
      }
      
      # Apply movement to all instances in bundle
      foreach inst $current_bundle {
        set current_total [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
        dict set total_moves $inst [expr {$current_total + $actual_move}]
        if {$debug} {
          puts "  Updated $inst: total movement = [dict get $total_moves $inst]"
        }
      }
      
      # Update remaining distance
      set remaining_distance [expr {$remaining_distance - $actual_move}]
      if {$debug} {
        puts "Remaining distance after move: $remaining_distance"
      }
      
      # Check if we've moved enough
      if {$remaining_distance <= 0} {
        if {$debug} {puts "Movement complete - reached target distance"}
        break
      }
      
      # Remove processed bundle from list
      set original_right_bundles $right_bundles
      set right_bundles [lrange $right_bundles 1 end]
      if {$debug} {
        puts "Removed processed bundle from right_bundles. New right_bundles: $right_bundles"
      }
      
      # If bundle list is empty, check if we can continue
      if {[llength $right_bundles] == 0} {
        if {$debug} {puts "No more right bundles to process"}
        # Check if we have left bundles to move
        if {[llength $left_bundles] == 0} {
          if {$debug} {puts "No more bundles available - exiting loop"}
          break
        }
      } else {
        # Check if we should merge with next bundle
        set next_bundle [lindex $right_bundles 0]
        if {$debug} {
          puts "Checking adjacency with next right bundle: $next_bundle"
        }
        
        # Find rightmost instance of current bundle and leftmost of next bundle
        set current_rightmost ""
        set current_rightmost_x1 -inf
        foreach inst $current_bundle {
          foreach rect $sorted_rects {
            if {[lindex $rect 0] eq $inst} {
              set x1 [lindex $rect 1 2]
              set moved [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
              set x1 [expr {$x1 + $moved}]
              if {$x1 > $current_rightmost_x1} {
                set current_rightmost $inst
                set current_rightmost_x1 $x1
              }
              break
            }
          }
        }
        
        set next_leftmost ""
        set next_leftmost_x inf
        foreach inst $next_bundle {
          foreach rect $sorted_rects {
            if {[lindex $rect 0] eq $inst} {
              set x [lindex $rect 1 0]
              set moved [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
              set x [expr {$x + $moved}]
              if {$x < $next_leftmost_x} {
                set next_leftmost $inst
                set next_leftmost_x $x
              }
              break
            }
          }
        }
        
        # Check if bundles are now adjacent
        set gap_between [expr {abs($current_rightmost_x1 - $next_leftmost_x)}]
        if {$debug} {
          puts "  Current rightmost: $current_rightmost at x1=$current_rightmost_x1"
          puts "  Next leftmost: $next_leftmost at x=$next_leftmost_x"
          puts "  Gap between bundles: $gap_between"
        }
        
        if {$gap_between < $filterMovementPrecision} {
          if {$debug} {puts "  Bundles are adjacent - merging"}
          set merged_bundle [concat $current_bundle $next_bundle]
          set right_bundles [lreplace $right_bundles 0 0 $merged_bundle]
          if {$debug} {
            puts "  Merged bundle: $merged_bundle"
            puts "  Updated right_bundles: $right_bundles"
          }
        }
      }
      
      # Switch direction to left for next iteration
      set move_direction "left"
      if {$debug} {puts "Switched direction to: $move_direction"}
      
    } elseif {$move_direction eq "left" && [llength $left_bundles] > 0} {
      # Move left bundles (closest to gap first)
      set current_bundle [lindex $left_bundles end]
      set max_move [get_bundle_max_move $current_bundle "left" $sorted_rects $max_movements]
      set actual_move [expr {min($max_move, $remaining_distance)}]
      
      if {$debug} {
        puts "\nProcessing left bundle: $current_bundle"
        puts "Max possible move for bundle: $max_move"
        puts "Actual move (capped by remaining distance): $actual_move"
      }
      
      # Apply movement to all instances in bundle
      foreach inst $current_bundle {
        set current_total [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
        dict set total_moves $inst [expr {$current_total + $actual_move}]
        if {$debug} {
          puts "  Updated $inst: total movement = [dict get $total_moves $inst]"
        }
      }
      
      # Update remaining distance
      set remaining_distance [expr {$remaining_distance - $actual_move}]
      if {$debug} {
        puts "Remaining distance after move: $remaining_distance"
      }
      
      # Check if we've moved enough
      if {$remaining_distance <= 0} {
        if {$debug} {puts "Movement complete - reached target distance"}
        break
      }
      
      # Remove processed bundle from list
      set left_bundles [lrange $left_bundles 0 end-1]
      if {$debug} {
        puts "Removed processed bundle from left_bundles. New left_bundles: $left_bundles"
      }
      
      # If bundle list is empty, check if we can continue
      if {[llength $left_bundles] == 0} {
        if {$debug} {puts "No more left bundles to process"}
        # Check if we have right bundles to move
        if {[llength $right_bundles] == 0} {
          if {$debug} {puts "No more bundles available - exiting loop"}
          break
        }
      } else {
        # Check if we should merge with previous bundle
        set prev_bundle [lindex $left_bundles end]
        if {$debug} {
          puts "Checking adjacency with previous left bundle: $prev_bundle"
        }
        
        # Find leftmost instance of current bundle and rightmost of previous bundle
        set current_leftmost ""
        set current_leftmost_x inf
        foreach inst $current_bundle {
          foreach rect $sorted_rects {
            if {[lindex $rect 0] eq $inst} {
              set x [lindex $rect 1 0]
              set moved [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
              set x [expr {$x - $moved}]
              if {$x < $current_leftmost_x} {
                set current_leftmost $inst
                set current_leftmost_x $x
              }
              break
            }
          }
        }
        
        set prev_rightmost ""
        set prev_rightmost_x1 -inf
        foreach inst $prev_bundle {
          foreach rect $sorted_rects {
            if {[lindex $rect 0] eq $inst} {
              set x1 [lindex $rect 1 2]
              set moved [expr {[dict exists $total_moves $inst] ? [dict get $total_moves $inst] : 0.0}]
              set x1 [expr {$x1 - $moved}]
              if {$x1 > $prev_rightmost_x1} {
                set prev_rightmost $inst
                set prev_rightmost_x1 $x1
              }
              break
            }
          }
        }
        
        # Check if bundles are now adjacent
        set gap_between [expr {abs($prev_rightmost_x1 - $current_leftmost_x)}]
        if {$debug} {
          puts "  Previous rightmost: $prev_rightmost at x1=$prev_rightmost_x1"
          puts "  Current leftmost: $current_leftmost at x=$current_leftmost_x"
          puts "  Gap between bundles: $gap_between"
        }
        
        if {$gap_between < $filterMovementPrecision} {
          if {$debug} {puts "  Bundles are adjacent - merging"}
          set merged_bundle [concat $prev_bundle $current_bundle]
          set left_bundles [lreplace $left_bundles end end $merged_bundle]
          if {$debug} {
            puts "  Merged bundle: $merged_bundle"
            puts "  Updated left_bundles: $left_bundles"
          }
        }
      }
      
      # Switch direction to right for next iteration
      set move_direction "right"
      if {$debug} {puts "Switched direction to: $move_direction"}
      
    } else {
      # No more bundles to move in current direction
      if {$debug} {
        puts "\nNo more bundles to move in $move_direction direction"
        puts "Left bundles remaining: [llength $left_bundles]"
        puts "Right bundles remaining: [llength $right_bundles]"
      }
      
      # Switch direction
      if {$move_direction eq "right"} {
        set move_direction "left"
      } else {
        set move_direction "right"
      }
      if {$debug} {
        puts "Switched direction to: $move_direction"
      }
      
      # If no bundles available in either direction, break
      if {([llength $left_bundles] == 0 && $move_direction eq "left") || 
          ([llength $right_bundles] == 0 && $move_direction eq "right")} {
        if {$debug} {puts "No bundles available in any direction - exiting loop"}
        # Set force_insert if we couldn't reach target distance
        if {$remaining_distance > 0} {
          set force_insert 1
          if {$debug} {
            puts "Could not reach target distance. Remaining: $remaining_distance - setting force_insert=1"
          }
        }
        break
      }
    }
  }
  
  # Final debug information
  if {$debug} {
    puts "\n===== Completed Bundle-Based Movement ====="
    puts "Total iterations: $iteration"
    puts "Final remaining distance: $remaining_distance"
    puts "force_insert flag: $force_insert"
    puts "Total moves recorded:"
    dict for {inst distance} $total_moves {
      puts "  $inst: $distance"
    }
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
          puts "Moved $instname: original ($x, $x1) â†’ new ($new_x, $new_x1)"
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
  if {$force_insert} {
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

