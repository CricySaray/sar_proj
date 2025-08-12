#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/08 09:33:12 Friday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : This proc checks if an object with specified dimensions can fit into any of the given free spaces and 
#             returns the bottom-left coordinate of the object's optimal position (within a valid space) that minimizes 
#             the distance between the object's center and the specified target point, or 0 if no suitable space exists.
# update    : 2025/08/11 10:37:05 Monday
#             (U001) add function: $ifForceInsert, if it is 1, it will force insert repeater in non-sufficient space finding biggest space, which you can specify extra space list.
# return    : [list $spaceType [list x y] minDistance] or 0 (have no available space)
#             $spaceType: noSpace|sufficient|forceInsert
# ref       : link url
# --------------------------
proc judge_ifHaveSpaceToInsertBuffer_findNearestPosition {target_point object_dimensions free_spaces {ifForceInsert 0} {forceInsert_freeSpace {}} {debug 0}} {
  # Extract target point coordinates
  set target_x [lindex $target_point 0]
  set target_y [lindex $target_point 1]
  
  # Extract object width and height from dimensions
  set obj_width [lindex $object_dimensions 0]
  set obj_height [lindex $object_dimensions 1]
  
  set best_distance [expr {inf}]
  set best_position 0
  
  set ifHaveSufficientSpace 0
  # Check each free space in the list
  foreach space $free_spaces {
    # Extract coordinates of the free space
    set space_x [lindex $space 0]   ;# Bottom-left x coordinate
    set space_y [lindex $space 1]   ;# Bottom-left y coordinate
    
    # Calculate actual width and height of the free space
    set space_width [db_rect -sizex $space]
    set space_height [db_rect -sizey $space]
    
    # Check if object dimensions fit within the space
    if {$debug} { puts "test: width : $space_width | height : $space_height" }
    if {$obj_width <= $space_width && $obj_height <= $space_height} {
      # Calculate optimal position within this space
      
      # The ideal bottom-left position to make object center align with target point
      set ideal_obj_x [expr {$target_x - $obj_width / 2.0}]
      set ideal_obj_y [expr {$target_y - $obj_height / 2.0}]
      
      # Constrain the object position within the available space
      # Minimum x position is space's x coordinate
      set min_x $space_x
      # Maximum x position is space's right edge minus object width
      set max_x [expr {$space_x + $space_width - $obj_width}]
      # Clamp x position to valid range
      set best_obj_x [expr {max($min_x, min($max_x, $ideal_obj_x))}] ; # IMPORTANT
      
      # Minimum y position is space's y coordinate
      set min_y $space_y
      # Maximum y position is space's top edge minus object height
      set max_y [expr {$space_y + $space_height - $obj_height}]
      # Clamp y position to valid range
      set best_obj_y [expr {max($min_y, min($max_y, $ideal_obj_y))}] ; # IMPORTANT
      
      # Calculate center of the placed object
      set obj_center_x [expr {$best_obj_x + $obj_width / 2.0}]
      set obj_center_y [expr {$best_obj_y + $obj_height / 2.0}]
      
      # Calculate distance from object center to target point
      set dx [expr {$obj_center_x - $target_x}]
      set dy [expr {$obj_center_y - $target_y}]
      set distance [expr {sqrt($dx*$dx + $dy*$dy)}]
      
      if {$debug} { puts "test 1: now test point: [list $best_obj_x $best_obj_y] | with distance: $distance"; puts "" }
      # Update best position if this is closer
      if {$distance < $best_distance} {
        set best_distance $distance
        set best_position [list $best_obj_x $best_obj_y]
        if {$debug} {
          puts "Found better position: $best_position with distance: $distance"
        }
        set ifHaveSufficientSpace 1
      }
    }
  }
  
  # U001 If no position found and force insert is enabled, check force insert spaces 
  if {$best_position == 0 && $ifForceInsert == 1} {
    if {$debug} { puts "No suitable space found, checking force insert spaces..." }
    
    set max_area 0
    set candidate_spaces [list]
    
    # First pass: find all spaces that can fit the object and determine maximum area
    foreach space $forceInsert_freeSpace {
      set space_x [lindex $space 0]
      set space_y [lindex $space 1]
      set space_width [db_rect -sizex $space]
      set space_height [db_rect -sizey $space]
      set area [expr {$space_width * $space_height}]
      
      # Update maximum area if current space is larger
      if {$area > $max_area} {
        set max_area $area
        set candidate_spaces [list $space]
      } elseif {$area == $max_area} {
        lappend candidate_spaces $space
      }
      
      if {$debug} {
        puts "Force insert space [list $space_x $space_y] with area $area (max so far: $max_area)"
      }
    }
    
    # Second pass: among spaces with maximum area, find the one closest to target point
    if {[llength $candidate_spaces] > 0} {
      set best_force_distance [expr {inf}]
      set best_force_position 0
      
      foreach space $candidate_spaces {
        set space_x [lindex $space 0]
        set space_y [lindex $space 1]
        
        # For force insert, simply return the bottom-left corner of the space
        set force_position [list $space_x $space_y]
        
        # Calculate distance from space center to target point
        set space_width [db_rect -sizex $space]
        set space_height [db_rect -sizey $space]
        set space_center_x [expr {$space_x + $space_width / 2.0}]
        set space_center_y [expr {$space_y + $space_height / 2.0}]
        
        set dx [expr {$space_center_x - $target_x}]
        set dy [expr {$space_center_y - $target_y}]
        set distance [expr {sqrt($dx*$dx + $dy*$dy)}]
        
        if {$debug} {
          puts "Candidate force position $force_position with distance $distance"
        }
        
        # Update best force position if closer
        if {$distance < $best_force_distance} {
          set best_force_distance $distance
          set best_force_position $force_position
        }
      }
      
      # Update return values with best force insert position
      set best_position $best_force_position
      set best_distance $best_force_distance
      
      if {$debug} {
        puts "Selected force insert position: $best_position with distance: $best_distance"
      }
    } else {
      if {$debug} {
        puts "No suitable spaces in forceInsert_freeSpace for insertion"
      }
    }
  }
  
  # Return the best position found or 0 if none
  if {$ifHaveSufficientSpace} {
    set spaceType "sufficient"
  } elseif {!$ifHaveSufficientSpace && $best_position != 0} {
    set spaceType "forceInsert" 
  } else {
    set spaceType "noSpace" 
  }
  return [list $spaceType $best_position [format "%.3f" $best_distance]]
}

