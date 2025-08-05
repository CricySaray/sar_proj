#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/05 11:36:55 Tuesday
# label     : package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : count num for everyone of categories
# input require: {{cateName1 {item1 item2 ...}} {cateName2 {item1 item2 ...}} ...}
# return    : {{cateName1 num1} {cateName2 num2}}
# ref       : link url
# --------------------------
proc count_categories {two_d_list} {
  # Check if input is an empty list
  if {[llength $two_d_list] == 0} {
    return [list]
  }
  # Validate index
  set first_sublist [lindex $two_d_list 0]
  set sublist_length [llength $first_sublist]
  # Check that all sublists have the same length
  foreach sublist $two_d_list {
    if {[llength $sublist] != $sublist_length} {
      error "proc count_categories: All sublists must have the same length"
    }
  }
  set cate_num [lmap two $two_d_list {
    list [lindex $two 0] [llength [lindex $two 1]] 
  }]
  return $cate_num
}
