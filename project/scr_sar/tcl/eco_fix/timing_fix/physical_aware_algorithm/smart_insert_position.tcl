# now problem is movement algorithm, it can't move more than one objects to get box to insert obj 

source ./get_objRect.tcl; # get_objRect
source ./proc_judge_ifHaveSpaceToInsertBuffer_findNearestPosition.invsGUI.tcl # judge_ifHaveSpaceToInsertBuffer_findNearestPosition
proc smart_insert_position {center_point expand_range object_size {secondary_expand {0 0}} {min_move {0.14 1.26}} {debug 0}} {
  # Extract center coordinates
  set center_x [lindex $center_point 0]
  set center_y [lindex $center_point 1]
  
  # Extract expand ranges
  set expand_lr [lindex $expand_range 0]
  set expand_tb [lindex $expand_range 1]
  
  # Extract secondary expand values
  set sec_expand_z [lindex $secondary_expand 0]
  set sec_expand_q [lindex $secondary_expand 1]
  
  # Calculate original search box (x y x1 y1)
  set orig_x [expr {$center_x - $expand_lr}]
  set orig_y [expr {$center_y - $expand_tb}]
  set orig_x1 [expr {$center_x + $expand_lr}]
  set orig_y1 [expr {$center_y + $expand_tb}]
  
  # Apply secondary expansion
  set search_x [expr {$orig_x - $sec_expand_z}]
  set search_y [expr {$orig_y - $sec_expand_q}]
  set search_x1 [expr {$orig_x1 + $sec_expand_z}]
  set search_y1 [expr {$orig_y1 + $sec_expand_q}]
  
  # Ensure search box coordinates are valid (x < x1, y < y1)
  if {$search_x >= $search_x1} {
    if {$debug} {puts "Invalid search box width, adjusting..."}
    set search_x1 [expr {$search_x + 0.001}]
  }
  if {$search_y >= $search_y1} {
    if {$debug} {puts "Invalid search box height, adjusting..."}
    set search_y1 [expr {$search_y + 0.001}]
  }
  
  set searchingBox [list $search_x $search_y $search_x1 $search_y1]
  
  if {$debug} {
    puts "Searching box coordinates: $searchingBox"
    puts "Object size to insert: $object_size"
  }
  
  # Get all objects in the search area
  if {$debug} {puts "Retrieving objects in search area..."}
  set objList [get_objRect $searchingBox]
  if {$debug} {
    puts "Found [llength $objList] objects in search area"
    foreach obj $objList {
      puts "  Object [lindex $obj 0]: [lindex $obj 1]"
    }
  }
  
  # Extract object rectangles for dbShape command
  set objRectList [lmap obj $objList {lindex $obj 1}]
  
  # Calculate available space
  if {$debug} {puts "Calculating initial available space..."}
  set availableBox [dbShape $searchingBox ANDNOT $objRectList -output hrect]
  
  # Extract object dimensions
  set obj_width [lindex $object_size 0]
  set obj_height [lindex $object_size 1]
  
  # Validate object size
  if {$obj_width <= 0 || $obj_height <= 0} {
    if {$debug} {puts "Invalid object size: $object_size"}
    error "check your input: obj width and height"
  }
  
  # Check if we can insert without moving objects
  if {$debug} {puts "Checking for available space without moving objects..."}
  set best_pos [judge_ifHaveSpaceToInsertBuffer_findNearestPosition $center_point $object_size $availableBox $debug]
  set initial_position [lindex $best_pos 0]
  set initial_distance [lindex $best_pos 1]
  
  if {$initial_position ne "0" && $initial_position ne ""} {
    if {$debug} {
      puts "Found suitable position without moving objects: $initial_position (distance: $initial_distance)"
    }
    return [list $initial_position]
  }
  
  # If we reach here, we need to try moving objects
  if {$debug} {
    puts "No suitable position found initially. Attempting to move objects..."
  }
  
  # Extract minimum move distances
  set min_move_lr [lindex $min_move 0]
  set min_move_tb [lindex $min_move 1]
  
  # Validate minimum move distances
  if {$min_move_lr <= 0} {
    if {$debug} {puts "Invalid left-right minimum move distance, using default 0.14"}
    set min_move_lr 0.14
  }
  if {$min_move_tb <= 0} {
    if {$debug} {puts "Invalid top-bottom minimum move distance, using default 1.26"}
    set min_move_tb 1.26
  }
  
  # Sort objects by distance from center (closest first)
  if {$debug} {puts "Sorting objects by distance from center point..."}
  set sortedObjs [lsort -command [list obj_distance_compare $center_point] $objList]
  
  # Try moving objects one by one, starting with closest
  set moved_objects [list]
  set new_obj_rects $objRectList
  set max_attempts [llength $sortedObjs]
  set attempts 0
  
  while {$attempts < $max_attempts} {
    set obj [lindex $sortedObjs $attempts]
    set obj_name [lindex $obj 0]
    set obj_rect [lindex $obj 1]
    
    # Check if object was already moved
    set already_moved 0
    foreach moved $moved_objects {
      if {[lindex $moved 0] eq $obj_name} {
        set already_moved 1
        break
      }
    }
    if {$already_moved} {
      incr attempts
      continue
    }
    
    # Current object coordinates
    set obj_x [lindex $obj_rect 0]
    set obj_y [lindex $obj_rect 1]
    set obj_x1 [lindex $obj_rect 2]
    set obj_y1 [lindex $obj_rect 3]
    set obj_w [expr {$obj_x1 - $obj_x}]
    set obj_h [expr {$obj_y1 - $obj_y}]
    
    if {$debug} {
      puts "\nAttempting to move object: $obj_name (attempt $attempts of $max_attempts)"
      puts "Current position: $obj_rect"
    }
    
    # Determine possible movement directions
    set possible_moves [list]
    
    # Check if object is partially outside original search area
    set is_partial_left [expr {$obj_x < $orig_x && $obj_x1 >= $orig_x}]
    set is_partial_right [expr {$obj_x1 > $orig_x1 && $obj_x <= $orig_x1}]
    set is_partial_bottom [expr {$obj_y < $orig_y && $obj_y1 >= $orig_y}]
    set is_partial_top [expr {$obj_y1 > $orig_y1 && $obj_y <= $orig_y1}]
    
    if {$debug} {
      puts "Object boundary check: left=$is_partial_left, right=$is_partial_right, bottom=$is_partial_bottom, top=$is_partial_top"
    }
    
    # Left movement (only if not partial left)
    if {!$is_partial_left} {
      set new_x [expr {$obj_x - $min_move_lr}]
      set new_rect [list $new_x $obj_y [expr {$new_x + $obj_w}] $obj_y1]
      # Ensure we don't move outside secondary expanded area
      if {[lindex $new_rect 0] >= $search_x} {
        lappend possible_moves [list $new_rect "left" $min_move_lr]
      } else {
        if {$debug} {puts "Cannot move left - would exit search area"}
      }
    } else {
      if {$debug} {puts "Cannot move left - object partially outside original area"}
    }
    
    # Right movement (only if not partial right)
    if {!$is_partial_right} {
      set new_x [expr {$obj_x + $min_move_lr}]
      set new_rect [list $new_x $obj_y [expr {$new_x + $obj_w}] $obj_y1]
      # Ensure we don't move outside secondary expanded area
      if {[lindex $new_rect 2] <= $search_x1} {
        lappend possible_moves [list $new_rect "right" $min_move_lr]
      } else {
        if {$debug} {puts "Cannot move right - would exit search area"}
      }
    } else {
      if {$debug} {puts "Cannot move right - object partially outside original area"}
    }
    
    # Down movement (only if not partial bottom)
    if {!$is_partial_bottom} {
      set new_y [expr {$obj_y - $min_move_tb}]
      set new_rect [list $obj_x $new_y $obj_x1 [expr {$new_y + $obj_h}]]
      # Ensure we don't move outside secondary expanded area
      if {[lindex $new_rect 1] >= $search_y} {
        lappend possible_moves [list $new_rect "down" $min_move_tb]
      } else {
        if {$debug} {puts "Cannot move down - would exit search area"}
      }
    } else {
      if {$debug} {puts "Cannot move down - object partially outside original area"}
    }
    
    # Up movement (only if not partial top)
    if {!$is_partial_top} {
      set new_y [expr {$obj_y + $min_move_tb}]
      set new_rect [list $obj_x $new_y $obj_x1 [expr {$new_y + $obj_h}]]
      # Ensure we don't move outside secondary expanded area
      if {[lindex $new_rect 3] <= $search_y1} {
        lappend possible_moves [list $new_rect "up" $min_move_tb]
      } else {
        if {$debug} {puts "Cannot move up - would exit search area"}
      }
    } else {
      if {$debug} {puts "Cannot move up - object partially outside original area"}
    }
    
    if {$debug && [llength $possible_moves] == 0} {
      puts "No possible moves for $obj_name"
      incr attempts
      continue
    }
    
    # Try each possible move in order of increasing distance
    set best_move [list]
    set best_move_dist [expr {inf}]
    set best_space_dist [expr {inf}]
    set best_insert_pos [list]
    
    foreach move $possible_moves {
      set new_rect [lindex $move 0]
      set dir [lindex $move 1]
      set dist [lindex $move 2]
      
      if {$debug} {
        puts "Testing move $dir by $dist units to $new_rect"
      }
      
      # Check if new position would overlap with other objects
      set overlap 0
      set temp_rects $new_obj_rects
      
      # Replace old rect with new rect in temp list
      set idx [lsearch -exact $temp_rects $obj_rect]
      if {$idx != -1} {
        lset temp_rects $idx $new_rect
      } else {
        # If not found, find by approximate match (floating point tolerance)
        for {set i 0} {$i < [llength $temp_rects]} {incr i} {
          set r [lindex $temp_rects $i]
          if {[rect_approx_equal $r $obj_rect 0.001]} {
            set idx $i
            lset temp_rects $idx $new_rect
            break
          }
        }
      }
      
      # Check for overlaps with other objects
      for {set i 0} {$i < [llength $temp_rects]} {incr i} {
        set r1 [lindex $temp_rects $i]
        for {set j [expr {$i + 1}]} {$j < [llength $temp_rects]} {incr j} {
          set r2 [lindex $temp_rects $j]
          if {[rect_overlap $r1 $r2]} {
            set overlap 1
            break
          }
        }
        if {$overlap} break
      }
      
      if {$overlap} {
        if {$debug} {puts "Move $dir causes overlap, skipping"}
        continue
      }
      
      # Calculate available space with this move
      set space_available [dbShape $searchingBox ANDNOT $temp_rects -output hrect]
      set pos_check [judge_ifHaveSpaceToInsertBuffer_findNearestPosition $center_point $object_size $space_available 0]
      set check_pos [lindex $pos_check 0]
      set check_dist [lindex $pos_check 1]
      
      if {$check_pos ne "0" && $check_pos ne ""} {
        # This move creates enough space
        if {$debug} {
          puts "Move $dir creates enough space at $check_pos (distance: $check_dist)"
        }
        
        # Prioritize by object move distance, then by insertion distance
        if {$dist < $best_move_dist || ($dist == $best_move_dist && $check_dist < $best_space_dist)} {
          set best_move $move
          set best_move_dist $dist
          set best_space_dist $check_dist
          set best_insert_pos $check_pos
        }
      } else {
        if {$debug} {puts "Move $dir does not create enough space"}
      }
    }
    
    # Apply best move if found
    if {[llength $best_move] > 0} {
      set new_rect [lindex $best_move 0]
      set dir [lindex $best_move 1]
      set dist [lindex $best_move 2]
      
      # Update object rect list
      set idx [lsearch -exact $new_obj_rects $obj_rect]
      if {$idx == -1} {
        # Try approximate match
        for {set i 0} {$i < [llength $new_obj_rects]} {incr i} {
          set r [lindex $new_obj_rects $i]
          if {[rect_approx_equal $r $obj_rect 0.001]} {
            set idx $i
            break
          }
        }
      }
      
      if {$idx != -1} {
        lset new_obj_rects $idx $new_rect
      } else {
        if {$debug} {puts "Warning: Could not find object rectangle to update"}
      }
      
      # Record the move
      set new_x [lindex $new_rect 0]
      set new_y [lindex $new_rect 1]
      lappend moved_objects [list $obj_name [list $new_x $new_y]]
      
      if {$debug} {
        puts "Moved $obj_name $dir by $dist units to [list $new_x $new_y]"
        puts "Now have [llength $moved_objects] moved objects"
      }
      
      # Return immediately since we found a solution
      return [linsert $moved_objects 0 $best_insert_pos]
    }
    
    incr attempts
  }
  
  # If we reach here, couldn't create enough space even after trying all objects
  if {$debug} {
    puts "\nCould not create enough space to insert object after trying all possible moves"
  }
  return 0
}

# Helper function to compare objects by distance from center
proc obj_distance_compare {center obj1 obj2} {
  set center_x [lindex $center 0]
  set center_y [lindex $center 1]
  
  set rect1 [lindex $obj1 1]
  set rect2 [lindex $obj2 1]
  
  # Calculate center of each rectangle
  set obj1_center_x [expr {([lindex $rect1 0] + [lindex $rect1 2]) / 2.0}]
  set obj1_center_y [expr {([lindex $rect1 1] + [lindex $rect1 3]) / 2.0}]
  set obj2_center_x [expr {([lindex $rect2 0] + [lindex $rect2 2]) / 2.0}]
  set obj2_center_y [expr {([lindex $rect2 1] + [lindex $rect2 3]) / 2.0}]
  
  # Calculate distances
  set dx1 [expr {$obj1_center_x - $center_x}]
  set dy1 [expr {$obj1_center_y - $center_y}]
  set dist1 [expr {sqrt($dx1*$dx1 + $dy1*$dy1)}]
  
  set dx2 [expr {$obj2_center_x - $center_x}]
  set dy2 [expr {$obj2_center_y - $center_y}]
  set dist2 [expr {sqrt($dx2*$dx2 + $dy2*$dy2)}]
  
  # Compare distances
  if {$dist1 < $dist2} {
    return -1
  } elseif {$dist1 > $dist2} {
    return 1
  } else {
    return 0
  }
}

# Helper function to check if two rectangles overlap
proc rect_overlap {rect1 rect2} {
  set x1 [lindex $rect1 0]
  set y1 [lindex $rect1 1]
  set x1_1 [lindex $rect1 2]
  set y1_1 [lindex $rect1 3]
  
  set x2 [lindex $rect2 0]
  set y2 [lindex $rect2 1]
  set x2_1 [lindex $rect2 2]
  set y2_1 [lindex $rect2 3]
  
  # Check if rectangles overlap
  if {$x1 >= $x2_1 || $x2 >= $x1_1} {
    return 0
  }
  if {$y1 >= $y2_1 || $y2 >= $y1_1} {
    return 0
  }
  
  return 1
}

# Helper function to check if two rectangles are approximately equal
proc rect_approx_equal {rect1 rect2 tolerance} {
  if {[llength $rect1] != 4 || [llength $rect2] != 4} {
    return 0
  }
  
  for {set i 0} {$i < 4} {incr i} {
    set val1 [lindex $rect1 $i]
    set val2 [lindex $rect2 $i]
    if {abs($val1 - $val2) > $tolerance} {
      return 0
    }
  }
  
  return 1
}

