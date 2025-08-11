#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/08 00:32:53 Friday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : judge if the provided rects have space to insert buffer
# return    : ll_rect [list ll_x ll_y] or 0: have no space
# ref       : link url
# --------------------------
proc judge_ifHaveSpaceToInsertBuffer {object_dimensions free_spaces {debug 0}} {
  # Extract object width and height from dimensions
  set obj_width [lindex $object_dimensions 0]
  set obj_height [lindex $object_dimensions 1]
  
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
      # Return bottom-left coordinates of the first suitable space
      return [list $space_x $space_y]
    }
  }
  # No suitable space found
  return 0
}
  
