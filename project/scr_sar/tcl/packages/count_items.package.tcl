#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/03 12:06:26 Sunday
# label     : package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : A Tcl procedure that counts occurrences of elements at a specified index in a 2D list, 
#             returning results as a 2D list of {item count} pairs.
# return    : {{item1 num1} {item2 num2} {...}}
# ref       : link url
# --------------------------
proc count_items {two_d_list index} {
  # Check if input is an empty list
  if {[llength $two_d_list] == 0} {
    return [list]
  }
  # Validate index
  set first_sublist [lindex $two_d_list 0]
  set sublist_length [llength $first_sublist]
  if {$index < 0 || $index >= $sublist_length} {
    error "Invalid index: $index. Valid range is 0 to [expr {$sublist_length - 1}]"
  }
  # Check that all sublists have the same length
  foreach sublist $two_d_list {
    if {[llength $sublist] != $sublist_length} {
      error "All sublists must have the same length"
    }
  }
  # Use an array to count occurrences of each element
  array set counts {}
  # Iterate through each sublist in the 2D list
  foreach sublist $two_d_list {
    # Get the element at the specified index
    set item [lindex $sublist $index]
    # Update count: increment if exists, initialize to 1 if not
    if {[info exists counts($item)]} {
      incr counts($item)
    } else {
      set counts($item) 1
    }
  }
  # Convert the results to the required 2D list format
  set result [list]
  foreach item [array names counts] {
    lappend result [list $item $counts($item)]
  }
  return $result
}

# Example usage:
if {0} {
  set data {
    {apple red 10}
    {banana yellow 5}
    {apple green 8}
    {orange orange 12}
    {banana yellow 7}
  }
  # Count elements at index 0 (fruit names)
  puts [count_items $data 0]
  # Output might be: {{apple 2} {banana 2} {orange 1}}
  # Count elements at index 1 (colors)
  puts [count_items $data 1]
  # Output might be: {{red 1} {yellow 2} {green 1} {orange 1}}
}
