#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/02/19 21:41:23 Thursday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Remove duplicates from the provided list without any sorting, while preserving the original relative order.
# return    : unique list without reordering
# ref       : link url
# --------------------------
proc get_unique_list_without_reorder {{input_list ""}} {
  if {$input_list eq ""} {
    return [list] 
  } else {
    set sortedList [list]
    foreach temp_item $input_list {
      if {$temp_item in $sortedList} {
        continue 
      } else {
        lappend sortedList $temp_item 
      }
    }
    return $sortedList
  }
}
