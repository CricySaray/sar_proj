#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/12 10:35:29 Friday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : count items for D1 list
# input     : {song song song an rui rui}
# return    : {{item1 3} {item2 10} ...}
# ref       : link url
# --------------------------
proc count_items_forD1List {input_list} {
  # Check number of arguments
  if {[llength [info level 0]] != 2} {
    error "Invalid number of arguments. Usage: count_duplicates list"
  }
  
  # Validate input is a proper list
  if {[catch {llength $input_list} list_length]} {
    error "Invalid input: Not a valid list - $list_length"
  }
  
  # Handle empty list case
  if {$list_length == 0} {
    return [list]
  }
  
  # Initialize array to hold counts
  array set item_counts {}
  
  # Count occurrences of each item
  foreach item $input_list {
    if {[info exists item_counts($item)]} {
      incr item_counts($item)
    } else {
      set item_counts($item) 1
    }
  }
  
  # Convert array to required output format
  set result [list]
  foreach item [array names item_counts] {
    lappend result [list $item $item_counts($item)]
  }
  
  return $result
}

if {0} {
  set test_list [list song song song an rui an an rui]
  puts [join [lsort -index 1 -decreasing [count_items_forD1List $test_list]] \n]
}
