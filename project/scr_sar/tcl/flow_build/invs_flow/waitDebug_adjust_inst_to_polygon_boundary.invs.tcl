##############################################################################
# Main Proc: adjust_inst_to_polygon
# Params with default values:
#   1. poly_rect_list  : 2D list, each element is {x y x1 y1} (rect for polygon)
#   2. inst_name_list  : 1D list, instance names
#   3. dist_threshold  : Real number, distance threshold, DEFAULT = 8
#   4. target_offset   : Real number, final offset to polygon boundary, DEFAULT = 5
#   5. summary_file    : String, summary report file path/name, DEFAULT = adjust_inst_to_polygon.list
#   6. debug_switch    : Integer 0/1, 0=disable debug print, 1=enable debug print, DEFAULT = 1
# Return:
#   2D list {{inst_name {new_x new_y}} ...} (only moved instances)
# Error handling: Strict parameter format/type/value check
##############################################################################
proc adjust_inst_to_polygon {poly_rect_list inst_name_list {dist_threshold 8} {target_offset 5} {summary_file "adjust_inst_to_polygon.list"} {debug_switch 1}} {
  # --------------------------
  # Step 1: Parameter Validation
  # --------------------------
  # Check actual input parameter count
  set input_param_cnt [expr {[llength [info level 0]] - 1}]
  if {$input_param_cnt < 2 || $input_param_cnt > 6} {
    error "Parameter Error: Valid input parameters count is 2~6, got $input_param_cnt"
  }

  # Validate debug switch (must be 0 or 1)
  if {![string is integer -strict $debug_switch] || $debug_switch ni {0 1}} {
    error "Value Error: Debug switch must be integer 0 or 1, got $debug_switch"
  }

  foreach rect $poly_rect_list {
    if {[llength $rect] != 4} {
      error "Format Error: Polygon rect $rect must be {x y x1 y1} (4 elements)"
    }
    foreach val $rect {
      if {![string is double -strict $val]} {
        error "Value Error: Rect coordinate $val is not a number"
      }
    }
    lassign $rect rx ry rx1 ry1
    if {$rx >= $rx1 || $ry >= $ry1} {
      error "Range Error: Rect $rect invalid, require x < x1 and y < y1"
    }
  }

  foreach inst $inst_name_list {
    if {[string trim $inst] eq ""} {
      error "Format Error: Instance name cannot be empty string"
    }
  }

  if {![string is double -strict $dist_threshold] || $dist_threshold < 0.0} {
    error "Value Error: Threshold must be non-negative real number, got $dist_threshold"
  }

  if {![string is double -strict $target_offset] || $target_offset < 0.0} {
    error "Value Error: Target offset must be non-negative real number, got $target_offset"
  }

  if {[string trim $summary_file] eq ""} {
    error "Format Error: Summary file name cannot be empty"
  }

  # Debug print: Start execution
  if {$debug_switch == 1} {
    puts "===== DEBUG: Start running adjust_inst_to_polygon ====="
    puts "Polygon rect list: $poly_rect_list"
    puts "Instance list: $inst_name_list"
    puts "Distance threshold: $dist_threshold"
    puts "Target offset to boundary: $target_offset"
    puts "Summary file: $summary_file"
    puts "Debug switch: $debug_switch"
    puts "======================================================="
  }

  # --------------------------
  # Step 2: Define Internal Sub Procs (_ prefix)
  # --------------------------
  # Check if point (px,py) is inside the combined polygon (Original code, no changes)
  proc _is_point_in_polygon {poly_rect_list px py} {
    foreach rect $poly_rect_list {
      lassign $rect rx ry rx1 ry1
      if {$px >= $rx && $px <= $rx1 && $py >= $ry && $py <= $ry1} {
        return 1
      }
    }
    return 0
  }

  # Extract all unique outer/inner boundary segments & corner points
  # Filter overlapped edges between adjacent rectangles, keep effective boundaries
  proc _extract_poly_boundaries {poly_rect_list} {
    set all_edges [list]
    set all_corners [list]

    # Step1: Collect all 4 edges and 4 corners for each rectangle
    foreach rect $poly_rect_list {
      lassign $rect x0 y0 x1 y1
      # Four corners of single rect
      lappend all_corners [list $x0 $y0]
      lappend all_corners [list $x1 $y0]
      lappend all_corners [list $x0 $y1]
      lappend all_corners [list $x1 $y1]

      # Four edges: format {type x y x2 y2} (h=horizontal, v=vertical)
      # Bottom edge (horizontal)
      lappend all_edges [list h $x0 $y0 $x1 $y0]
      # Top edge (horizontal)
      lappend all_edges [list h $x0 $y1 $x1 $y1]
      # Left edge (vertical)
      lappend all_edges [list v $x0 $y0 $x0 $y1]
      # Right edge (vertical)
      lappend all_edges [list v $x1 $y0 $x1 $y1]
    }

    # Step2: Remove fully overlapped edges (merged edges are not valid boundary)
    set valid_edges [list]
    set edge_count [llength $all_edges]
    set skip_idx [list]

    for {set i 0} {$i < $edge_count} {incr i} {
      if {[lsearch $skip_idx $i] != -1} {
        continue
      }
      set e1 [lindex $all_edges $i]
      set e1_type [lindex $e1 0]
      set e1_x0 [lindex $e1 1]
      set e1_y0 [lindex $e1 2]
      set e1_x1 [lindex $e1 3]
      set e1_y1 [lindex $e1 4]
      set is_overlap 0

      # Compare with other edges
      for {set j [expr {$i + 1}]} {$j < $edge_count} {incr j} {
        if {[lsearch $skip_idx $j] != -1} {
          continue
        }
        set e2 [lindex $all_edges $j]
        set e2_type [lindex $e2 0]
        set e2_x0 [lindex $e2 1]
        set e2_y0 [lindex $e2 2]
        set e2_x1 [lindex $e2 3]
        set e2_y1 [lindex $e2 4]

        if {$e1_type ne $e2_type} {
          continue
        }

        # Check horizontal edge overlap
        if {$e1_type eq "h"} {
          if {$e1_y0 == $e2_y0 && $e1_x0 == $e2_x0 && $e1_x1 == $e2_x1} {
            set is_overlap 1
            lappend skip_idx $j
            break
          }
        }
        # Check vertical edge overlap
        if {$e1_type eq "v"} {
          if {$e1_x0 == $e2_x0 && $e1_y0 == $e2_y0 && $e1_y1 == $e2_y1} {
            set is_overlap 1
            lappend skip_idx $j
            break
          }
        }
      }

      if {!$is_overlap} {
        lappend valid_edges $e1
      }
    }

    # Deduplicate corner points
    set unique_corners [list]
    foreach c $all_corners {
      if {[lsearch -exact $unique_corners $c] == -1} {
        lappend unique_corners $c
      }
    }

    return [list $valid_edges $unique_corners]
  }

  # Calculate Euclidean distance between two points (x0,y0) <-> (x1,y1)
  proc _point_to_point_dist {x0 y0 x1 y1} {
    set dx [expr {$x1 - $x0}]
    set dy [expr {$y1 - $y0}]
    return [expr {sqrt($dx*$dx + $dy*$dy)}]
  }

  # Calculate minimal Euclidean distance from a point to a line segment
  proc _point_to_segment_dist {px py seg} {
    lassign $seg s_type sx0 sy0 sx1 sy1
    set x0 $sx0
    set y0 $sy0
    set x1 $sx1
    set y1 $sy1

    set A [expr {$py - $y0}]
    set B [expr {$x0 - $x1}]
    set C [expr {$x1*$y0 - $x0*$y1}]
    set len_seg [_point_to_point_dist $x0 $y0 $x1 $y1]

    # Segment length is zero (degenerate point)
    if {$len_seg < 1e-9} {
      return [_point_to_point_dist $px $py $x0 $y0]
    }

    # Projection parameter t
    set t [expr { (($px - $x0)*($x1 - $x0) + ($py - $y0)*($y1 - $y0)) / ($len_seg * $len_seg) }]

    # Clamp t to [0,1] (projection outside segment)
    if {$t < 0.0} {
      return [_point_to_point_dist $px $py $x0 $y0]
    } elseif {$t > 1.0} {
      return [_point_to_point_dist $px $py $x1 $y1]
    }

    # Projection on segment: perpendicular distance
    set dist [expr {abs($A*$px + $B*$py + $C) / sqrt($A*$A + $B*$B)}]
    return $dist
  }

  # Get minimal Euclidean distance from inst center to polygon boundary
  proc _calc_min_euclidean_dist {poly_rect_list inst_box} {
    lassign $inst_box ix iy ix1 iy1
    # Use inst box center as reference point
    set ref_x [expr {($ix + $ix1) / 2.0}]
    set ref_y [expr {($iy + $iy1) / 2.0}]
    set min_dist 1e20

    # Get valid edges and unique corners (remove overlapped merged edges)
    lassign [_extract_poly_boundaries $poly_rect_list] valid_edges poly_corners

    # 1. Calculate distance to all valid boundary line segments
    foreach seg $valid_edges {
      set d [_point_to_segment_dist $ref_x $ref_y $seg]
      if {$d < $min_dist} {
        set min_dist $d
      }
    }

    # 2. Calculate distance to all polygon corners (concave angle / inner corner)
    foreach corner $poly_corners {
      lassign $corner cx cy
      set d [_point_to_point_dist $ref_x $ref_y $cx $cy]
      if {$d < $min_dist} {
        set min_dist $d
      }
    }

    return $min_dist
  }

  # Get nearest boundary feature and its projection point
  proc _get_nearest_boundary_info {poly_rect_list inst_box} {
    lassign $inst_box ix iy ix1 iy1
    set ref_x [expr {($ix + $ix1) / 2.0}]
    set ref_y [expr {($iy + $iy1) / 2.0}]

    lassign [_extract_poly_boundaries $poly_rect_list] valid_edges poly_corners

    set nearest_dist 1e20
    set nearest_type ""
    set nearest_obj ""

    # Traverse all edge segments
    foreach seg $valid_edges {
      set d [_point_to_segment_dist $ref_x $ref_y $seg]
      if {$d < $nearest_dist} {
        set nearest_dist $d
        set nearest_type "seg"
        set nearest_obj $seg
      }
    }
    # Traverse all corners
    foreach corner $poly_corners {
      lassign $corner cx cy
      set d [_point_to_point_dist $ref_x $ref_y $cx $cy]
      if {$d < $nearest_dist} {
        set nearest_dist $d
        set nearest_type "corner"
        set nearest_obj $corner
      }
    }

    return [list $ref_x $ref_y $nearest_dist $nearest_type $nearest_obj]
  }

  # Adjust inst center to target offset from boundary, then calculate new lower-left coordinate
  proc _adjust_inst_pos {poly_rect_list inst_box target_offset} {
    lassign $inst_box ix iy ix1 iy1
    set inst_w [expr {$ix1 - $ix}]
    set inst_h [expr {$iy1 - $iy}]

    # Get center and nearest boundary info
    lassign [_get_nearest_boundary_info $poly_rect_list $inst_box] c_x c_y dist b_type b_obj

    set new_cx $c_x
    set new_cy $c_y

    # Move center to target offset distance from nearest boundary
    if {$b_type eq "seg"} {
      lassign $b_obj s_type sx0 sy0 sx1 sy1
      if {$s_type eq "h"} {
        # Horizontal boundary
        if {$c_y < $sy0} {
          set new_cy [expr {$sy0 - $target_offset}]
        } else {
          set new_cy [expr {$sy0 + $target_offset}]
        }
      } else {
        # Vertical boundary
        if {$c_x < $sx0} {
          set new_cx [expr {$sx0 - $target_offset}]
        } else {
          set new_cx [expr {$sx0 + $target_offset}]
        }
      }
    } elseif {$b_type eq "corner"} {
      lassign $b_obj cx cy
      set dx [expr {$c_x - $cx}]
      set dy [expr {$c_y - $cy}]
      set total_d [expr {sqrt($dx*$dx + $dy*$dy)}]
      if {$total_d > 1e-9} {
        set ratio [expr {$target_offset / $total_d}]
        set new_cx [expr {$cx + $dx * $ratio}]
        set new_cy [expr {$cy + $dy * $ratio}]
      } else {
        set new_cx [expr {$cx + $target_offset}]
        set new_cy [expr {$cy + $target_offset}]
      }
    }

    # Calculate new lower-left coordinate from new center
    set new_lx [expr {$new_cx - $inst_w / 2.0}]
    set new_ly [expr {$new_cy - $inst_h / 2.0}]

    return [list $new_lx $new_ly]
  }

  # --------------------------
  # Step 3: Initialize Statistics Variables (Original code, no changes)
  # --------------------------
  set total_inst    [llength $inst_name_list]
  set out_poly_cnt  0
  set in_poly_cnt   0
  set within_thres_cnt 0
  set exceed_thres_cnt 0
  set moved_inst_list  [list]

  set out_poly_inst    [list]
  set within_thres_inst [list]
  set moved_detail     [list]

  if {$debug_switch == 1} {
    puts "===== DEBUG: Initialize statistics ====="
    puts "Total instance count: $total_inst"
    puts "========================================"
  }

  # --------------------------
  # Step 4: Process Each Instance
  # --------------------------
  foreach inst $inst_name_list {
    if {$debug_switch == 1} {
      puts "\n----- DEBUG: Process instance -> $inst -----"
    }

    if {[catch {
      set inst_box_raw [dbget [dbget top.insts.name $inst -p].box -e]
      set inst_box [lindex $inst_box_raw 0]
    } err]} {
      error "DB Access Error: Cannot get box for inst $inst, reason: $err"
    }

    if {$debug_switch == 1} {
      puts "Instance box: $inst_box"
    }

    if {[llength $inst_box] != 4} {
      error "Box Format Error: Inst $inst box $inst_box is not {x y x1 y1}"
    }
    foreach b_val $inst_box {
      if {![string is double -strict $b_val]} {
        error "Box Value Error: Inst $inst box has non-numeric value $b_val"
      }
    }
    lassign $inst_box ix iy ix1 iy1

    set in_poly [_is_point_in_polygon $poly_rect_list $ix $iy]
    if {!$in_poly} {
      incr out_poly_cnt
      lappend out_poly_inst $inst
      if {$debug_switch == 1} {
        puts "Result: Instance OUT of polygon, skip follow-up process"
      }
      continue
    }

    incr in_poly_cnt
    if {$debug_switch == 1} {
      puts "Result: Instance IN polygon"
    }

    # Use Euclidean distance (slant distance)
    set min_dist [_calc_min_euclidean_dist $poly_rect_list $inst_box]
    if {$debug_switch == 1} {
      puts "Min Euclidean distance to boundary: $min_dist"
      puts "Distance threshold: $dist_threshold"
    }

    if {$min_dist <= $dist_threshold} {
      incr within_thres_cnt
      lappend within_thres_inst [list $inst $min_dist]
      if {$debug_switch == 1} {
        puts "Result: Distance within threshold, no move"
      }
      continue
    }

    incr exceed_thres_cnt
    set old_ll [list $ix $iy]
    set new_ll [_adjust_inst_pos $poly_rect_list $inst_box $target_offset]
    lassign $new_ll nlx nly

    # Calculate Euclidean moving distance for record
    set move_eu_dist [_point_to_point_dist $ix $iy $nlx $nly]
    set move_man_dist [expr {abs($nlx - $ix) + abs($nly - $iy)}]

    lappend moved_detail [list $inst $old_ll $new_ll $min_dist $move_eu_dist $move_man_dist]
    lappend moved_inst_list [list $inst $new_ll]

    if {$debug_switch == 1} {
      puts "Result: Distance exceed threshold, need to move"
      puts "Original lower-left: $old_ll"
      puts "New lower-left: $new_ll"
      puts "Euclidean move distance: $move_eu_dist"
      puts "Manhattan move distance: $move_man_dist"
    }
  }

  # --------------------------
  # Step 5: Generate Summary File (Updated content)
  # --------------------------
  if {$debug_switch == 1} {
    puts "\n===== DEBUG: Start writing summary file -> $summary_file ====="
  }

  if {[catch {set f [open $summary_file w]} err]} {
    error "File Error: Cannot open summary file $summary_file, reason: $err"
  }

  puts $f "==================================== Summary Statistics Table ===================================="
  puts $f "Total Instances          : $total_inst"
  puts $f "Out of Polygon Area      : $out_poly_cnt"
  puts $f "Inside Polygon Area      : $in_poly_cnt"
  puts $f "  Within Distance Threshold : $within_thres_cnt"
  puts $f "  Exceed Distance Threshold : $exceed_thres_cnt (Moved)"
  puts $f "Distance Type            : Euclidean (slant) distance"
  puts $f "Distance Threshold       : $dist_threshold"
  puts $f "Target Boundary Offset   : $target_offset"
  puts $f "=================================================================================================="
  puts $f ""

  puts $f "1. Instances OUT of Polygon (Total: $out_poly_cnt):"
  if {$out_poly_cnt == 0} {
    puts $f "  None"
  } else {
    foreach inst $out_poly_inst {
      puts $f "  - $inst"
    }
  }
  puts $f ""

  puts $f "2. Instances IN Polygon, Distance Within Threshold (Total: $within_thres_cnt):"
  if {$within_thres_cnt == 0} {
    puts $f "  None"
  } else {
    foreach item $within_thres_inst {
      lassign $item inst d
      puts $f "  - $inst : Min boundary distance = $d"
    }
  }
  puts $f ""

  puts $f "3. Instances IN Polygon, Distance Exceed Threshold (Moved, Total: $exceed_thres_cnt):"
  if {$exceed_thres_cnt == 0} {
    puts $f "  None"
  } else {
    foreach item $moved_detail {
      lassign $item inst old_ll new_ll orig_dist move_eu_dist move_man_dist
      puts $f "  - Instance Name: $inst"
      puts $f "    Original Lower-Left : $old_ll"
      puts $f "    New Lower-Left      : $new_ll"
      puts $f "    Original Min Euclidean Dist : $orig_dist"
      puts $f "    Move Euclidean Distance     : $move_eu_dist"
      puts $f "    Move Manhattan Distance     : $move_man_dist"
      puts $f ""
    }
  }

  close $f

  if {$debug_switch == 1} {
    puts "===== DEBUG: Summary file write completed ====="
    puts "\n===== DEBUG: Proc execution finished ====="
    puts "Final moved instance list: $moved_inst_list"
    puts "==========================================="
  }

  # --------------------------
  # Step 6: Return final result list (Original format, no changes)
  # --------------------------
  return $moved_inst_list
}
