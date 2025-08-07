#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/07 10:39:32 Thursday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : get farthest sink pin name and pt to driver pin
# return    : {pinname {x y} distance}
# ref       : link url
# --------------------------
proc find_farthest_sinkpoint_to_driver_pin {start_point pinname_points_D2List} {
  # Extract x and y coordinates from start point
  set start_x [lindex $start_point 0]
  set start_y [lindex $start_point 1]
  
  # Initialize variables to track the farthest point
  set farthest_point ""
  set max_distance_squared -1
  
  # Iterate through each point in the pinname_points_D2List list
  foreach pinname_point $pinname_points_D2List {
    # Extract point name and its coordinates
    set point_name [lindex $pinname_point 0]
    set point_coords [lindex $pinname_point 1]
    set point_x [lindex $point_coords 0]
    set point_y [lindex $point_coords 1]
    
    # Calculate squared distance (avoid square root for efficiency)
    set dx [expr {$point_x - $start_x}]
    set dy [expr {$point_y - $start_y}]
    set distance_squared [expr {$dx*$dx + $dy*$dy}]
    
    # Update farthest point if current point is farther
    if {$distance_squared > $max_distance_squared} {
      set max_distance_squared $distance_squared
      set farthest_point $pinname_point
    }
  }
  set max_distance [format "%.3f" [expr sqrt($max_distance_squared)]]
  return [list {*}$farthest_point $max_distance]
}

