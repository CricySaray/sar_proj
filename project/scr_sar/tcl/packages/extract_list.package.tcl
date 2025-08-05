#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/05 11:32:48 Tuesday
# label     : 
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : Extract specific indices from each sublist in a nested list
#             Parameters:
#               nested_list  - The input nested list to process
#               indices      - List of indices to extract from each sublist (default: {0})
#               ifListCheck  - error defence
#               ?-skip-empty? - Skip empty sublists instead of processing them (default: 0)
#               ?-default?    - Default value for invalid indices (default: "")
# return    : extracted list
# ref       : link url
# --------------------------
proc lextract {nested_list {indices {0}} {ifListCheck 1} {skip_empty 1} {default ""}} {
  # Validate input is a proper list
  if {![llength $nested_list]} {
    error "proc lextract: First argument must be a valid list"
  }
  
  # Validate indices are non-negative integers
  foreach idx $indices {
    if {![string is integer -strict $idx] || $idx < 0} {
      error "proc lextract: Invalid index '$idx' - must be non-negative integer"
    }
  }
  
  set result [list]
  
  # Process each sublist
  foreach sublist $nested_list {
    # Skip empty sublists if requested
    if {!$ifListCheck && $skip_empty && [llength $sublist] == 0} {
      continue
    } elseif {$ifListCheck && [llength $sublist] == 0} {
      error "proc lextract: input list($nested_list) has empty sublist!!!" 
    }
    
    set extracted [list]
    foreach idx $indices {
      # Check if index exists in current sublist
      if {$idx < [llength $sublist]} {
        lappend extracted [lindex $sublist $idx]
      } elseif {!$ifListCheck} {
        lappend extracted $default
      } elseif {$ifListCheck} {
        error "proc lextract: your indices have error, out of max index of sublist of input list!!!" 
      }
    }
    
    # For single index, return scalar value instead of list
    if {[llength $indices] == 1} {
      lappend result [lindex $extracted 0]
    } else {
      lappend result $extracted
    }
  }
  
  return $result
}

if {0} {
  # Example usage
  set data {
    {10 apple red}
    {20 banana yellow}
    {} 
    {30 orange orange}
    {40 grape purple small}
  }

  puts "Extract index 0:"
  puts [lextract $data]
  # Output: 10 20 "" 30 40

  puts "\nExtract indices 0 and 1:"
  puts [lextract $data {0 1}]
  # Output: {10 apple} {20 banana} {} {30 orange} {40 grape}

  puts "\nExtract index 2 with custom default:"
  puts [lextract $data {2} 0 0 "N/A"]
  #puts [lextract $data {2} 1 0 "N/A"]
  # Output: red yellow N/A orange purple

  puts "\nExtract index 1, skipping empty sublists:"
  puts [lextract $data {1} 0 1]
  puts [lextract $data {1} 1 1]
  # Output: apple banana orange grape
}
