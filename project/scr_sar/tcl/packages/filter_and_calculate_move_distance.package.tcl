#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/06/12 18:06:57 Friday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
# Define main procedure with debug switch (default 0: disable debug)
# Define main procedure with debug switch (default 0: disable debug)
proc filter_and_calculate_move_distance {rect_list point_list {debug 0}} {
  set out_result [list]

  # ============== Start Input Validation & Error Defense ==============
  # Check if rect_list is a valid list
  if {![llength $rect_list]} {
    error "ERROR: rect_list is empty, no valid placement rectangles"
  }

  # Validate each rectangle item: format {x y x1 y1}, total 4 numeric elements
  set rect_idx 0
  foreach rect $rect_list {
    incr rect_idx
    if {[llength $rect] != 4} {
      error "ERROR: Rectangle index $rect_idx format error. Require {x y x1 y1} with 4 elements"
    }
    # Check all elements are numeric
    foreach val $rect {
      if {![string is double -strict $val]} {
        error "ERROR: Rectangle index $rect_idx contains non-numeric value: $val"
      }
    }
    # Check coordinate logic: lower-left <= upper-right
    lassign $rect rx_min ry_min rx_max ry_max
    if {$rx_min > $rx_max || $ry_min > $ry_max} {
      error "ERROR: Rectangle index $rect_idx coordinate error: left-bottom > right-top"
    }
  }

  # Check if point_list is a valid list
  if {![llength $point_list]} {
    puts "WARNING: point_list is empty, no points to process"
    return $out_result
  }

  # Validate each point item: format {instname {x y}}
  set point_idx 0
  foreach point_item $point_list {
    incr point_idx
    if {[llength $point_item] != 2} {
      error "ERROR: Point index $point_idx format error. Require {instname {x y}} with 2 elements"
    }
    lassign $point_item inst p_coord
    # Check coordinate part is a 2-element list
    if {[llength $p_coord] != 2} {
      error "ERROR: Point index $point_idx \[$inst\] coordinate format error. Require {x y}"
    }
    # Check coordinate values are numeric
    foreach coord $p_coord {
      if {![string is double -strict $coord]} {
        error "ERROR: Point index $point_idx \[$inst\] has non-numeric coordinate: $coord"
      }
    }
  }
  # ============== End Input Validation & Error Defense ==============

  # Traverse each point: instname + point coordinate {x y}
  foreach point_item $point_list {
    lassign $point_item inst p_coord
    lassign $p_coord px py
    set is_in_area 0
    set min_dist ""
    set nearest_offset {0 0}

    # Check if current point is inside any placement rectangle
    foreach rect $rect_list {
      lassign $rect rx_min ry_min rx_max ry_max
      # Judge point inside rectangle (including boundary)
      if {$px >= $rx_min && $px <= $rx_max && $py >= $ry_min && $py <= $ry_max} {
        set is_in_area 1
        break
      }
    }

    # Skip point if inside valid placement area
    if {$is_in_area} {
      if {$debug} {
        puts "DEBUG: Point $inst ($px,$py) is inside placement area, skip"
      }
      continue
    }

    if {$debug} {
      puts "DEBUG: Process out-of-area point $inst ($px,$py)"
    }

    # Calculate minimal distance and offset to nearest rectangle
    foreach rect $rect_list {
      lassign $rect rx_min ry_min rx_max ry_max
      set dx 0
      set dy 0

      # Calculate X direction offset
      if {$px < $rx_min} {
        set dx [expr {$rx_min - $px}]
      } elseif {$px > $rx_max} {
        set dx [expr {$rx_max - $px}]
      }

      # Calculate Y direction offset
      if {$py < $ry_min} {
        set dy [expr {$ry_min - $py}]
      } elseif {$py > $ry_max} {
        set dy [expr {$ry_max - $py}]
      }

      # Compute Euclidean distance to rectangle
      set dist [expr {sqrt($dx*$dx + $dy*$dy)}]

      # Update nearest rectangle info
      if {$min_dist eq "" || $dist < $min_dist} {
        set min_dist $dist
        set nearest_offset [list $dx $dy]
      }
    }

    # Parse offset to direction and distance rules
    lassign $nearest_offset off_x off_y
    set move_list [list]

    # Process X axis (left / right)
    if {$off_x > 0} {
      lappend move_list [list right $off_x]
    } elseif {$off_x < 0} {
      lappend move_list [list left [expr {abs($off_x)}]]
    }

    # Process Y axis (up / down)
    if {$off_y > 0} {
      lappend move_list [list up $off_y]
    } elseif {$off_y < 0} {
      lappend move_list [list down [expr {abs($off_y)}]]
    }

    # Assemble final record for current point
    lappend out_result [list $inst $move_list]

    if {$debug} {
      puts "DEBUG: $inst move rule: $move_list"
    }
  }

  return $out_result
}
