#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/05/20 18:02:01 Wednesday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : calculate Manhattan distance
# return    : number
# ref       : link url
# --------------------------
proc calculate_manhattan_distance {first_pt second_pt} {
  if {[llength $first_pt] != 2 || [llength $second_pt] != 2} {
    error "proc calculate_manhattan_distance: input format error !!!"
  }
  lassign $first_pt first_x first_y
  lassign $second_pt second_x second_y
  # Calculate Manhattan distance
  set manhattan_dist [expr {abs($first_x - $second_x) + abs($first_y - $second_y)}]
  return $manhattan_dist
}
