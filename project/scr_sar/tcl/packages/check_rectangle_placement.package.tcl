#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/05/19 16:47:52 Tuesday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This TCL procedure verifies that input rectangles are arranged in a consistent fixed orientation such as left-right 
#             or top-bottom, and immediately throws an error once reverse placement occurs.
#               It also calculates Manhattan distances between adjacent rectangle centers, collects all out-of-limit pairs and 
#               reports them collectively while supporting comprehensive input format and data validity pre-checks.
# return    : string
# ref       : link url
# --------------------------
# Proc to check if rectangles are placed in a consistent direction
# Supports single or max 2 directions (multi_dir enabled by default)
# Validates max center distance, rectangle overlap and input data
proc check_rectangle_placement {rect_list {max_distance 200} {multi_dir 1}} {
  # --------------------------
  # Step 1: Basic Input Validation
  # --------------------------
  # Check if rect_list is a valid list
  if {![llength $rect_list]} {
    error "Input error: rectangle list is empty, please provide valid rectangle data"
  }
  if {![string is list $rect_list]} {
    error "Input error: first parameter must be a 2D list of rectangles"
  }
  # Check max_distance is a positive number
  if {![string is double $max_distance] || $max_distance <= 0} {
    error "Input error: max_distance must be a positive number (integer/double)"
  }
  # Check multi_dir is 0 or 1
  if {$multi_dir ni {0 1}} {
    error "Input error: multi_dir must be 1 (enabled) or 0 (disabled)"
  }

  # --------------------------
  # Step 2: Validate Each Rectangle Format
  # --------------------------
  set valid_rects [list]
  set rect_index 1
  foreach rect $rect_list {
    # Check each rectangle has exactly 4 coordinates
    if {[llength $rect] != 4} {
      error "Format error: rectangle $rect_index has [llength $rect] elements, required 4 {x y x1 y1}"
    }
    # Check all coordinates are numbers
    foreach coord $rect {
      if {![string is double $coord]} {
        error "Format error: rectangle $rect_index contains non-numeric coordinate: $coord"
      }
    }
    lassign $rect x y x1 y1
    # Check bottom-left < top-right (valid rectangle)
    if {$x >= $x1 || $y >= $y1} {
      error "Format error: rectangle $rect_index is invalid (x >= x1 or y >= y1): $rect"
    }
    lappend valid_rects $rect
    incr rect_index
  }

  # --------------------------
  # New: Step 2.5 Check All Rectangle Overlaps (Immediate Error)
  # --------------------------
  set total_rects [llength $valid_rects]
  for {set i 0} {$i < $total_rects} {incr i} {
    lassign [lindex $valid_rects $i] x1 y1 x2 y2
    for {set j [expr {$i + 1}]} {$j < $total_rects} {incr j} {
      lassign [lindex $valid_rects $j] a1 b1 a2 b2
      # Overlap check logic
      if {$x1 < $a2 && $x2 > $a1 && $y1 < $b2 && $y2 > $b1} {
        error "Overlap error: rectangle [expr {$i+1}] ($valid_rects[$i]) overlaps with rectangle [expr {$j+1}] ($valid_rects[$j])"
      }
    }
  }

  # --------------------------
  # Step 3: Calculate Center Points for All Rectangles
  # --------------------------
  set centers [list]
  foreach rect $valid_rects {
    lassign $rect x y x1 y1
    set cx [expr {($x + $x1) / 2.0}]
    set cy [expr {($y + $y1) / 2.0}]
    lappend centers [list $cx $cy]
  }

  # --------------------------
  # Step 4: Direction Check (Enhanced with Multi-Direction)
  # --------------------------
  if {$total_rects < 2} {
    puts "Warning: only one rectangle provided, skip direction check"
    return "Validation passed: single rectangle, no direction or distance issues"
  }

  # Track directions: max 2 allowed, no reverse
  set direction_list [list]
  set dir_change_count 0

  # Check consecutive rectangles one by one
  for {set i 1} {$i < $total_rects} {incr i} {
    set prev_idx [expr {$i - 1}]
    set curr_idx $i

    lassign [lindex $centers $prev_idx] prev_cx prev_cy
    lassign [lindex $centers $curr_idx] curr_cx curr_cy

    set curr_dx [expr {$curr_cx - $prev_cx}]
    set curr_dy [expr {$curr_cy - $prev_cy}]

    # Get current segment direction
    if {abs($curr_dx) > abs($curr_dy)} {
      # Horizontal type
      if {$curr_dx > 0} {
        set current_dir "HORIZONTAL_LEFT_TO_RIGHT"
      } else {
        set current_dir "HORIZONTAL_RIGHT_TO_LEFT"
      }
    } else {
      # Vertical type
      if {$curr_dy > 0} {
        set current_dir "VERTICAL_BOTTOM_TO_TOP"
      } else {
        set current_dir "VERTICAL_TOP_TO_BOTTOM"
      }
    }

    # First direction: initialize
    if {[llength $direction_list] == 0} {
      lappend direction_list $current_dir
    } else {
      set main_dir [lindex $direction_list 0]
      set second_dir [lindex $direction_list 1]

      # Case 1: same direction continues
      if {$current_dir eq $main_dir || ($second_dir ne "" && $current_dir eq $second_dir)} {
        # Do nothing, valid
      } else {
        # Case 2: direction change
        incr dir_change_count

        # Rule 1: multi_dir disabled → no change allowed
        if {$multi_dir == 0} {
          set bad_rect [lindex $valid_rects $curr_idx]
          error "Direction error: multi-direction is disabled, rectangle [expr {$curr_idx+1}] ($bad_rect) changes direction (only single direction allowed)"
        }

        # Rule 2: max 2 directions only
        if {$dir_change_count > 1} {
          set bad_rect [lindex $valid_rects $curr_idx]
          error "Direction error: max 2 directions allowed, rectangle [expr {$curr_idx+1}] ($bad_rect) causes a third direction"
        }

        # Rule 3: add new valid second direction
        lappend direction_list $current_dir
      }
    }

    # Final rule: NO REVERSE ALLOWED (critical)
    switch $current_dir {
      HORIZONTAL_LEFT_TO_RIGHT {
        if {$curr_dx < 0} {
          set bad_rect [lindex $valid_rects $curr_idx]
          error "Direction error: rectangle [expr {$curr_idx+1}] ($bad_rect) reverses to left (forbidden)"
        }
      }
      HORIZONTAL_RIGHT_TO_LEFT {
        if {$curr_dx > 0} {
          set bad_rect [lindex $valid_rects $curr_idx]
          error "Direction error: rectangle [expr {$curr_idx+1}] ($bad_rect) reverses to right (forbidden)"
        }
      }
      VERTICAL_BOTTOM_TO_TOP {
        if {$curr_dy < 0} {
          set bad_rect [lindex $valid_rects $curr_idx]
          error "Direction error: rectangle [expr {$curr_idx+1}] ($bad_rect) reverses down (forbidden)"
        }
      }
      VERTICAL_TOP_TO_BOTTOM {
        if {$curr_dy > 0} {
          set bad_rect [lindex $valid_rects $curr_idx]
          error "Direction error: rectangle [expr {$curr_idx+1}] ($bad_rect) reverses up (forbidden)"
        }
      }
    }
  }

  # --------------------------
  # Step 5: Check Adjacent Center Manhattan Distance
  # --------------------------
  set distance_errors [list]
  for {set i 1} {$i < $total_rects} {incr i} {
    set prev_idx [expr {$i - 1}]
    set curr_idx $i

    lassign [lindex $centers $prev_idx] prev_cx prev_cy
    lassign [lindex $centers $curr_idx] curr_cx curr_cy

    # Calculate Manhattan distance
    set manhattan_dist [expr {abs($curr_cx - $prev_cx) + abs($curr_cy - $prev_cy)}]

    if {$manhattan_dist > $max_distance} {
      set pair "rectangle [expr {$prev_idx + 1}] <-> rectangle [expr {$curr_idx + 1}] (distance: $manhattan_dist, max allowed: $max_distance)"
      lappend distance_errors $pair
    }
  }

  # Report all distance errors if any
  if {[llength $distance_errors] > 0} {
    error "Distance error: [llength $distance_errors] adjacent pairs exceed max distance:\n  - [join $distance_errors "\n  - "]"
  }

  # --------------------------
  # All Checks Passed
  # --------------------------
  return 1
}
