#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/19 14:43:34 Friday
# label     : flow_proc gui_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : Find the gaps between two power domains and add routeBlockage in these gaps to prevent redundant pg nets from being generated in the gaps during powerplan.
#             This procedure detects narrow channels between boxes, including horizontal, vertical, and corner regions formed by extending channels from shared 
#             vertices, while merging perfectly aligned rectangles without altering their overall shape.
# input     : $boxes : { {{x y x1 y1} {x y x1 y1} ...} {{x y x1 y1} {x y x1 y1} ...} ... }
#             $threshold: Narrow channel width threshold: when searching for gaps (narrow channels) between two polygons, if the gap width is less than 
#                         or equal to this threshold, it is considered a qualified gap, and the rectangular area of this part will be returned as part 
#                         of the return value.
#             $off: Typically, the value of this offset is negative, meaning that the entire gap needs to be shrunk.
# return    : list {{x y x1 y1} {x y x1 y1}}
# ref       : link url
# --------------------------
proc find_narrow_channels {{boxes {}} {threshold 10} {off -0.5} {debug 0}} {
  # Internal helper function: Validate polygon format
  proc _validate_polygon {polygon} {
    foreach rect $polygon {
      if {[llength $rect] != 4} {return 0}
      foreach coord $rect {
        if {![string is double -strict $coord]} {return 0}
      }
      lassign $rect x y x1 y1
      if {$x > $x1 || $y > $y1} {return 0}
    }
    return 1
  }

  # Internal helper function: Extract all edges of a polygon (including internal edges)
  proc _extract_all_edges {polygon} {
    set edges [list]
    foreach rect $polygon {
      lassign $rect x y x1 y1
      lappend edges [list bottom $y $x $x1]
      lappend edges [list top $y1 $x $x1]
      lappend edges [list left $x $y $y1]
      lappend edges [list right $x1 $y $y1]
    }
    return $edges
  }

  # Internal helper function: Filter out internal edges
  proc _filter_exterior_edges {all_edges} {
    set edge_counts [dict create]
    set exterior_edges [list]

    foreach edge $all_edges {
      lassign $edge type pos start end
      if {$start > $end} {
        lassign [list $end $start] start end
      }
      set key [list $type $pos $start $end]
      dict incr edge_counts $key
    }

    foreach edge $all_edges {
      lassign $edge type pos start end
      if {$start > $end} {
        lassign [list $end $start] start end
      }
      set key [list $type $pos $start $end]
      if {[dict get $edge_counts $key] == 1} {
        lappend exterior_edges $edge
      }
    }

    return $exterior_edges
  }

  # Internal helper function: Classify edges into horizontal and vertical
  proc _classify_edges {edges} {
    set horizontal [list] ;# {y x_start x_end}
    set vertical [list]   ;# {x y_start y_end}
    
    foreach edge $edges {
      lassign $edge type pos start end
      if {$start > $end} {
        lassign [list $end $start] start end
      }
      
      if {$type eq "top" || $type eq "bottom"} {
        lappend horizontal [list $pos $start $end]
      } else {
        lappend vertical [list $pos $start $end]
      }
    }
    return [list $horizontal $vertical]
  }

  # Internal helper function: Calculate distance between two horizontal edges
  proc _horizontal_edge_distance {edge1 edge2} {
    lassign $edge1 y1 x1_start x1_end
    lassign $edge2 y2 x2_start x2_end
    
    set distance [expr {abs($y1 - $y2)}]
    
    set overlap_start [expr {max($x1_start, $x2_start)}]
    set overlap_end [expr {min($x1_end, $x2_end)}]
    
    if {$overlap_start >= $overlap_end} {
      return [list $distance {}]
    }
    
    set y_min [expr {min($y1, $y2)}]
    set y_max [expr {max($y1, $y2)}]
    set channel [list $overlap_start $y_min $overlap_end $y_max]
    
    return [list $distance $channel]
  }

  # Internal helper function: Calculate distance between two vertical edges
  proc _vertical_edge_distance {edge1 edge2} {
    lassign $edge1 x1 y1_start y1_end
    lassign $edge2 x2 y2_start y2_end
    
    set distance [expr {abs($x1 - $x2)}]
    
    set overlap_start [expr {max($y1_start, $y2_start)}]
    set overlap_end [expr {min($y1_end, $y2_end)}]
    
    if {$overlap_start >= $overlap_end} {
      return [list $distance {}]
    }
    
    set x_min [expr {min($x1, $x2)}]
    set x_max [expr {max($x1, $x2)}]
    set channel [list $x_min $overlap_start $x_max $overlap_end]
    
    return [list $distance $channel]
  }

  # Internal helper function: Check if two rectangles are perfectly aligned and mergeable
  proc _can_merge_rectangles {rect1 rect2} {
    lassign $rect1 x1 y1 x1e y1e
    lassign $rect2 x2 y2 x2e y2e

    # Same row (y coordinates match)
    if {[expr {abs($y1 - $y2) < 1e-9 && abs($y1e - $y2e) < 1e-9}]} {
      return [expr {($x1e >= $x2 - 1e-9) && ($x2e >= $x1 - 1e-9)}]
    }

    # Same column (x coordinates match)
    if {[expr {abs($x1 - $x2) < 1e-9 && abs($x1e - $x2e) < 1e-9}]} {
      return [expr {($y1e >= $y2 - 1e-9) && ($y2e >= $y1 - 1e-9)}]
    }

    return 0
  }

  # Internal helper function: Check if two rectangles form a corner (share a vertex only)
  # Returns {1 shared_vertex} if corner, {0 {}} otherwise
  proc _form_corner {rect1 rect2} {
    lassign $rect1 x1 y1 x1e y1e
    lassign $rect2 x2 y2 x2e y2e
    
    # Get all vertices of both rectangles
    set verts1 [list [list $x1 $y1] [list $x1e $y1] [list $x1 $y1e] [list $x1e $y1e]]
    set verts2 [list [list $x2 $y2] [list $x2e $y2] [list $x2 $y2e] [list $x2e $y2e]]
    
    # Check if they share exactly one vertex (but no edges)
    set shared 0
    set shared_vertex {}
    foreach v1 $verts1 {
      foreach v2 $verts2 {
        if {[expr {abs([lindex $v1 0]-[lindex $v2 0]) < 1e-9 && 
                  abs([lindex $v1 1]-[lindex $v2 1]) < 1e-9}]} {
          incr shared
          set shared_vertex $v1
        }
      }
    }
    
    if {$shared != 1} {
      return [list 0 {}]
    }
    
    # Check if they are perpendicular (one horizontal, one vertical)
    set rect1_width [expr {$x1e - $x1}]
    set rect1_height [expr {$y1e - $y1}]
    set rect2_width [expr {$x2e - $x2}]
    set rect2_height [expr {$y2e - $y2}]
    
    set rect1_horizontal [expr {$rect1_width > $rect1_height * 2}]
    set rect2_vertical [expr {$rect2_height > $rect2_width * 2}]
    set rect1_vertical [expr {$rect1_height > $rect1_width * 2}]
    set rect2_horizontal [expr {$rect2_width > $rect2_height * 2}]
    
    set perpendicular [expr {($rect1_horizontal && $rect2_vertical) || 
                             ($rect1_vertical && $rect2_horizontal)}]
    
    return [list $perpendicular $shared_vertex]
  }

  # Internal helper function: Calculate corner extension with direction based on overlapping vertex
  proc _calculate_corner_extension {rect1 rect2 shared_vertex threshold debug} {
    if {$debug} {
      puts "  Calculating corner extension between:"
      puts "  Rect1: $rect1"
      puts "  Rect2: $rect2"
      puts "  Shared vertex: $shared_vertex"
      puts "  Threshold: $threshold"
    }
    
    lassign $rect1 x1 y1 x1e y1e
    lassign $rect2 x2 y2 x2e y2e
    lassign $shared_vertex sv_x sv_y
    
    # Determine which is horizontal and which is vertical
    set rect1_width [expr {$x1e - $x1}]
    set rect1_height [expr {$y1e - $y1}]
    
    if {$rect1_width > $rect1_height * 2} {
      set horizontal $rect1
      set vertical $rect2
      if {$debug} {
        puts "  Identified rect1 as horizontal, rect2 as vertical"
      }
    } else {
      set horizontal $rect2
      set vertical $rect1
      if {$debug} {
        puts "  Identified rect2 as horizontal, rect1 as vertical"
      }
    }
    
    lassign $horizontal hx hy hxe hye ;# hx: left x, hxe: right x, hy: bottom y, hye: top y
    lassign $vertical vx vy vxe vye   ;# vx: left x, vxe: right x, vy: bottom y, vye: top y
    
    # Determine horizontal extension direction based on shared vertex
    set h_left_vertex [expr {abs($sv_x - $hx) < 1e-9}]
    set h_right_vertex [expr {abs($sv_x - $hxe) < 1e-9}]
    
    if {$h_left_vertex} {
      set extended_h [list [expr {$hx - $threshold}] $hy $hxe $hye] ;# Extend left
      if {$debug} {puts "  Horizontal rectangle extended left by threshold: $extended_h"}
    } elseif {$h_right_vertex} {
      set extended_h [list $hx $hy [expr {$hxe + $threshold}] $hye] ;# Extend right
      if {$debug} {puts "  Horizontal rectangle extended right by threshold: $extended_h"}
    } else {
      if {$debug} {puts "  No valid horizontal vertex match for extension"}
      return {}
    }
    
    # Determine vertical extension direction based on shared vertex
    set v_bottom_vertex [expr {abs($sv_y - $vy) < 1e-9}]
    set v_top_vertex [expr {abs($sv_y - $vye) < 1e-9}]
    
    if {$v_bottom_vertex} {
      set extended_v [list $vx [expr {$vy - $threshold}] $vxe $vye] ;# Extend down
      if {$debug} {puts "  Vertical rectangle extended down by threshold: $extended_v"}
    } elseif {$v_top_vertex} {
      set extended_v [list $vx $vy $vxe [expr {$vye + $threshold}]] ;# Extend up
      if {$debug} {puts "  Vertical rectangle extended up by threshold: $extended_v"}
    } else {
      if {$debug} {puts "  No valid vertical vertex match for extension"}
      return {}
    }
    
    # Get overlapping area using dbShape command
    if {[catch {set overlapRect {*}[dbShape -output hrect $extended_h AND $extended_v]} result]} {
      if {$debug} {
        puts "  dbShape command failed (error: $result), using fallback calculation"
      }
      # Fallback calculation if dbShape is unavailable
      lassign $extended_h hx2 hy2 hxe2 hye2
      lassign $extended_v vx2 vy2 vxe2 vye2
      
      set x_start [expr {max($hx2, $vx2)}]
      set x_end [expr {min($hxe2, $vxe2)}]
      set y_start [expr {max($hy2, $vy2)}]
      set y_end [expr {min($hye2, $vye2)}]
      
      if {$x_start < $x_end && $y_start < $y_end} {
        set overlapRect [list $x_start $y_start $x_end $y_end]
        if {$debug} {puts "  Fallback overlap found: $overlapRect"}
      } else {
        set overlapRect {}
        if {$debug} {puts "  No fallback overlap found"}
      }
    } else {
      if {$debug} {puts "  dbShape overlap result: $overlapRect"}
    }
    
    if {$debug && $overlapRect ne ""} {
      puts "  Valid corner extension found: $overlapRect"
    } elseif {$debug} {
      puts "  No valid corner extension found"
    }
    
    return $overlapRect
  }

  # Internal helper function: Merge aligned rectangles and handle corner extensions
  proc _merge_aligned_rectangles {regions threshold debug} {
    if {[llength $regions] <= 1} {return $regions}
    
    # First pass: Merge perfectly aligned rectangles
    set merged [list]
    set unmerged $regions

    while {[llength $unmerged] > 0} {
      set current [lindex $unmerged 0]
      set unmerged [lrange $unmerged 1 end]
      set merged_current $current

      for {set i 0} {$i < [llength $merged]} {incr i} {
        set m [lindex $merged $i]
        if {[_can_merge_rectangles $merged_current $m]} {
          lassign $merged_current x1 y1 x1e y1e
          lassign $m x2 y2 x2e y2e
          
          set new_x1 [expr {min($x1, $x2)}]
          set new_y1 [expr {min($y1, $y2)}]
          set new_xe [expr {max($x1e, $x2e)}]
          set new_ye [expr {max($y1e, $y2e)}]
          
          set merged_current [list $new_x1 $new_y1 $new_xe $new_ye]
          
          set merged [lreplace $merged $i $i]
          set i -1
        }
      }

      lappend merged $merged_current
    }
    
    # Second pass: Check for corner connections and add extensions
    set corner_extensions [list]
    
    for {set i 0} {$i < [llength $merged]} {incr i} {
      for {set j [expr {$i + 1}]} {$j < [llength $merged]} {incr j} {
        set r1 [lindex $merged $i]
        set r2 [lindex $merged $j]
        
        lassign [_form_corner $r1 $r2] is_corner shared_vertex
        if {$is_corner && $shared_vertex ne ""} {
          if {$debug} {
            puts "\n  Found corner-forming rectangles at indices $i and $j with shared vertex $shared_vertex"
          }
          set extension [_calculate_corner_extension $r1 $r2 $shared_vertex $threshold $debug]
          if {$extension ne "" && [llength $extension] == 4} {
            lappend corner_extensions $extension
            if {$debug} {
              puts "  Added corner extension: $extension"
            }
          }
        }
      }
    }
    
    # Add corner extensions to merged regions if valid
    foreach ext $corner_extensions {
      lappend merged $ext
    }
    
    # Final merge pass to combine any new aligned regions from extensions
    set final_merged [list]
    foreach reg $merged {
      set current $reg
      for {set i 0} {$i < [llength $final_merged]} {incr i} {
        set m [lindex $final_merged $i]
        if {[_can_merge_rectangles $current $m]} {
          lassign $current x1 y1 x1e y1e
          lassign $m x2 y2 x2e y2e
          
          set new_x1 [expr {min($x1, $x2)}]
          set new_y1 [expr {min($y1, $y2)}]
          set new_xe [expr {max($x1e, $x2e)}]
          set new_ye [expr {max($y1e, $y2e)}]
          
          set current [list $new_x1 $new_y1 $new_xe $new_ye]
          set final_merged [lreplace $final_merged $i $i]
          set i -1
        }
      }
      lappend final_merged $current
    }
    
    return $final_merged
  }

  # Internal helper function: Remove duplicate regions
  proc _remove_duplicate_regions {regions} {
    set unique [list]
    foreach reg $regions {
      set found 0
      foreach u $unique {
        if {[expr {abs([lindex $reg 0]-[lindex $u 0]) < 1e-9 &&
                  abs([lindex $reg 1]-[lindex $u 1]) < 1e-9 &&
                  abs([lindex $reg 2]-[lindex $u 2]) < 1e-9 &&
                  abs([lindex $reg 3]-[lindex $u 3]) < 1e-9}]} {
          set found 1
          break
        }
      }
      if {!$found} {
        lappend unique $reg
      }
    }
    return $unique
  }

  # Main procedure starts here
  if {[llength $boxes] < 2} {
    error "At least two polygon regions are required"
  }
  
  if {![string is double -strict $threshold] || $threshold <= 0} {
    error "Threshold must be a positive number"
  }

  set all_polygon_edges [list]
  
  for {set i 0} {$i < [llength $boxes]} {incr i} {
    set poly [lindex $boxes $i]
    if {![_validate_polygon $poly]} {
      error "Invalid format for polygon $i"
    }
    
    set all_edges [_extract_all_edges $poly]
    set exterior_edges [_filter_exterior_edges $all_edges]
    lassign [_classify_edges $exterior_edges] horizontal vertical
    
    if {$debug} {
      puts "Polygon $i boundary edges - horizontal: [llength $horizontal], vertical: [llength $vertical]"
    }
    
    lappend all_polygon_edges [list $horizontal $vertical]
  }

  set candidate_channels [list]
  
  for {set i 0} {$i < [llength $boxes]} {incr i} {
    for {set j [expr {$i + 1}]} {$j < [llength $boxes]} {incr j} {
      if {$debug} {
        puts "\nChecking for narrow channels between polygon $i and polygon $j..."
      }
      
      lassign [lindex $all_polygon_edges $i] h1 v1
      lassign [lindex $all_polygon_edges $j] h2 v2
      
      foreach he1 $h1 {
        foreach he2 $h2 {
          lassign [_horizontal_edge_distance $he1 $he2] dist channel
          if {$dist <= $threshold && $channel ne ""} {
            if {$debug} {
              puts "  Found horizontal narrow channel (distance: $dist): $channel"
            }
            lappend candidate_channels $channel
          }
        }
      }
      
      foreach ve1 $v1 {
        foreach ve2 $v2 {
          lassign [_vertical_edge_distance $ve1 $ve2] dist channel
          if {$dist <= $threshold && $channel ne ""} {
            if {$debug} {
              puts "  Found vertical narrow channel (distance: $dist): $channel"
            }
            lappend candidate_channels $channel
          }
        }
      }
    }
  }

  set merged_channels [_merge_aligned_rectangles $candidate_channels $threshold $debug]
  set final_channels [_remove_duplicate_regions $merged_channels]
  
  if {$debug} {
    puts "\nFound [llength $final_channels] narrow channel regions in total"
  }
  set offed_final_channels [dbShape -output hrect $final_channels SIZE $off]
  
  return $offed_final_channels
}

