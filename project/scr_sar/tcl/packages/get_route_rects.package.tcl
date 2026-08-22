#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/05/21 17:06:07 Thursday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This proc takes an ordered list of rectangular regions, a start point, and an end point, then finds the nearest rectangle 
#             for both points and returns the sequential sublist of rectangles between them while preserving the original order.
#             It includes comprehensive input validation to check for empty lists, invalid coordinates, and malformed data, throwing clear 
#             error messages if invalid inputs are detected.
# return    : box list
# ref       : link url
# --------------------------
# Proc: get_route_rects
# Function: Find the sequential sublist of rectangles from start point's nearest rect to end point's nearest rect
# Parameters:
#   rect_list  - 2D list, ordered rectangles {x y x1 y1} (lower-left & upper-right)
#   start_pt   - 2D list, start coordinate {x y}
#   end_pt     - 2D list, end coordinate {x y}
# Return: Ordered sublist of rectangles from start rect to end rect
proc get_route_rects {rect_list start_pt end_pt} {
  # Error defense 1: Check rectangle list is a valid 2D list
  if {![llength $rect_list]} {
    error "Input rectangle list is empty"
  }
  foreach rect $rect_list {
    if {[llength $rect] != 4} {
      error "Invalid rectangle format: $rect, must be {x y x1 y1}"
    }
    foreach coord $rect {
      if {![string is double -strict $coord]} {
        error "Rectangle coordinate $coord is not a valid number"
      }
    }
    lassign $rect x y x1 y1
    if {$x >= $x1 || $y >= $y1} {
      error "Invalid rectangle bounds: $rect (x<x1 and y<y1 required)"
    }
  }

  # Error defense 2: Check start/end point format and valid numbers
  foreach pt [list $start_pt $end_pt] {
    if {[llength $pt] != 2} {
      error "Invalid point format: $pt, must be {x y}"
    }
    foreach coord $pt {
      if {![string is double -strict $coord]} {
        error "Point coordinate $coord is not a valid number"
      }
    }
  }

  # Helper proc: Calculate point to rectangle minimum distance
  proc point_to_rect_dist {pt rect} {
    lassign $pt px py
    lassign $rect rx ry rx1 ry1

    # Clamp point to rectangle bounds
    set cx [expr {max($rx, min($px, $rx1))}]
    set cy [expr {max($ry, min($py, $ry1))}]

    # Euclidean distance between original point and clamped point
    set dx [expr {$px - $cx}]
    set dy [expr {$py - $cy}]
    return [expr {sqrt($dx*$dx + $dy*$dy)}]
  }

  # Find nearest rectangle for a point
  proc find_nearest_rect {pt rect_list} {
    set min_dist Inf
    set nearest_rect ""
    foreach rect $rect_list {
      set dist [point_to_rect_dist $pt $rect]
      if {$dist < $min_dist} {
        set min_dist $dist
        set nearest_rect $rect
      }
    }
    return $nearest_rect
  }

  # Get start and end target rectangles
  set start_rect [find_nearest_rect $start_pt $rect_list]
  set end_rect [find_nearest_rect $end_pt $rect_list]

  # Get indices of start and end rectangles in original list
  set start_idx [lsearch -exact $rect_list $start_rect]
  set end_idx [lsearch -exact $rect_list $end_rect]

  # Error defense 3: Check rectangles found in list (theoretical safety check)
  if {$start_idx == -1 || $end_idx == -1} {
    error "Start/end rectangle not found in original rectangle list"
  }

  # Extract sublist in original order
  if {$start_idx <= $end_idx} {
    set result [lrange $rect_list $start_idx $end_idx]
  } else {
    set result [lreverse [lrange $rect_list $end_idx $start_idx]]
  }

  # Cleanup helper procs
  rename point_to_rect_dist ""
  rename find_nearest_rect ""

  return $result
}
