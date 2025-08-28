#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/26 17:01:49 Tuesday
# label     : package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : A procedure to count occurrences of items at a specific position in nested lists and return results as a nested list with a header.
# return    : nested list {{type num} {fa 2} {ft 3} ...}
# ref       : link url
# --------------------------
# Count occurrences of items at specific position in nested lists
# Parameters:
#   nested_list - The input nested list to process
#   position    - The index position to check in each sublist (default: 0)
#   header      - The header sublist for the result (default: {type num})
#   debug       - Enable debug messages (0: disable, 1: enable, default: 0)
proc count_items_advance {nested_list {position 0} {header {type num}} {debug 0}} {
  # Debug message helper
  proc debug_msg {msg debug_flag} {
    if {$debug_flag} {
      puts "DEBUG: $msg"
    }
  }

  # Validate input is a list
  if {![llength $nested_list]} {
    error "Invalid input: Not a valid list"
  }
  debug_msg "Processing list with [llength $nested_list] elements" $debug

  # Initialize counter dictionary
  array set counters {}

  # Iterate through each sublist
  set index 0
  foreach sublist $nested_list {
    incr index
    # Check if current element is a valid sublist
    if {![llength $sublist]} {
      debug_msg "Skipping invalid sublist at index $index: Not a valid list" $debug
      continue
    }

    # Check if position exists in sublist
    if {$position >= [llength $sublist]} {
      debug_msg "Skipping sublist at index $index: Position $position out of range" $debug
      continue
    }

    # Get the item at specified position
    set item [lindex $sublist $position]
    debug_msg "Found item '$item' at position $position in sublist $index" $debug

    # Update counter
    if {[info exists counters($item)]} {
      incr counters($item)
    } else {
      set counters($item) 1
    }
  }

  # Check if any items were counted
  if {[array size counters] == 0} {
    debug_msg "No valid items found for counting" $debug
    return [list $header]
  }

  # Prepare result list
  set result [list $header]
  
  # Add counted items to result
  foreach item [lsort [array names counters]] {
    lappend result [list $item $counters($item)]
  }

  debug_msg "Counting completed. Found [array size counters] unique items" $debug
  lappend result "total [llength $nested_list]"
  return $result
}

if {0} {
  # Example usage
  if {[info exists argv0] && ($argv0 eq [info script])} {
    # Sample nested list
    set sample_list {
      {ft song an rui}
      {ft song s an}
      {fa son sjd jjs}
      {fa jskf ajsdfl jasd}
      {ft third example}
      {unknown type}
    }

    # Demonstrate basic usage
    puts "Basic example - count first elements:"
    set result [count_nested_items $sample_list]
    puts $result

    # Demonstrate with debug enabled
    puts "\nWith debug information:"
    set result [count_nested_items $sample_list 0 {type count} 1]
    
    # Demonstrate counting different position
    puts "\nCount elements at position 1:"
    set result [count_nested_items $sample_list 1 {second_item count}]
    puts $result
  }
}
