#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/29 15:13:12 Friday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This proc parses various line specifications (including mixed lines and ranges) and executes the corresponding lines in a 
#             specified TCL script. It includes robust error handling and provides feedback on executed and unexecuted lines with 
#             configurable output options.
# return    : 
# ref       : link url
# --------------------------
alias se "execute_selected_lines_of_script"
proc execute_selected_lines_of_script {script_file line_spec {debug 0} {show_remaining 1} {show_executed 0}} {
  # Read script file content
  if {![file exists $script_file]} {
    error "proc execute_selected_lines_of_script: Error: Script file '$script_file' does not exist."
  }
  if {![file readable $script_file]} {
    error "proc execute_selected_lines_of_script: Error: Script file '$script_file' is not readable."
  }
  
  set f [open $script_file r]
  set script_content [read $f]
  close $f
  set script_lines [split $script_content \n]
  set total_lines [llength $script_lines]
  
  if {$debug} {
    puts "Debug: Total lines in script file: $total_lines"
  }
  
  # Parse line specification
  if {$debug} {
    puts "Debug: Parsing line specification: $line_spec"
  }
  set target_lines [parse_line_spec $line_spec $debug]
  if {[llength $target_lines] == 0} {
    error "proc execute_selected_lines_of_script: Error: No valid lines specified."
  }
  
  # Validate line numbers
  set invalid_lines [list]
  foreach line $target_lines {
    if {![string is integer -strict $line] || $line < 1 || $line > $total_lines} {
      lappend invalid_lines $line
    }
  }
  
  if {[llength $invalid_lines] > 0} {
    error "proc execute_selected_lines_of_script: Error: Invalid line numbers (out of range 1-$total_lines): [join $invalid_lines ", "]"
  }
  
  # Ensure unique lines in sorted order
  set unique_lines [lsort -integer -unique $target_lines]
  if {$debug} {
    puts "Debug: Lines to execute (sorted): [join $unique_lines ", "]"
  }
  
  # Prepare commands to execute with line numbers
  set execution_plan [list]
  foreach line_num $unique_lines {
    set line_content [string trim [lindex $script_lines [expr {$line_num - 1}]]]
    lappend execution_plan [list $line_num $line_content]
  }
  
  # Execute all commands in a single try block
  set executed_lines [list]
  set error_occurred 0
  set error_info [dict create line_num 0 message "" content ""]
  
  try {
    foreach plan $execution_plan {
      lassign $plan line_num line_content
      
      if {$debug} {
        puts "\nDebug: Executing line $line_num: $line_content"
      }
      
      uplevel #0 $line_content
      lappend executed_lines $line_num
    }
    
    # If all commands succeeded
    puts "\nSuccessfully executed all specified lines."
    puts "Executed line numbers: [format_line_ranges $executed_lines]"
    
    if {$show_executed} {
      puts "\nContent of executed lines:"
      foreach plan $execution_plan {
        lassign $plan line_num line_content
        puts "Line $line_num: $line_content"
      }
    }
  } on error {msg} {
    set error_occurred 1
    dict set error_info message $msg
    
    # Find which line caused the error
    set executed_count [llength $executed_lines]
    if {$executed_count < [llength $execution_plan]} {
      set failed_plan [lindex $execution_plan $executed_count]
      lassign $failed_plan line_num line_content
      dict set error_info line_num $line_num
      dict set error_info content $line_content
    }
  }
  
  # Handle error case
  if {$error_occurred} {
    set line_num [dict get $error_info line_num]
    set msg [dict get $error_info message]
    set content [dict get $error_info content]
    
    puts "\nError occurred at line $line_num:"
    puts "Line content: $content"
    puts "Error message: $msg"
    
    set remaining_lines [lrange $unique_lines $executed_count end]
    set num_remaining [llength $remaining_lines]
    
    if {$num_remaining > 0} {
      puts "\nThere are $num_remaining lines that were not executed:"
      puts "Line numbers: [format_line_ranges $remaining_lines]"
      
      if {$show_remaining} {
        puts "\nContent of unexecuted lines:"
        foreach line $remaining_lines {
          puts "Line $line: [lindex $script_lines [expr {$line - 1}]]"
        }
      }
    } else {
      puts "\nNo remaining lines to execute after the error."
    }
    
    error "proc execute_selected_lines_of_script: Execution aborted at line $line_num"
  }
  
  return $executed_lines
}

proc parse_line_spec {line_spec debug} {
  set target_lines [list]
  
  # Clean the input by removing all whitespace first
  set cleaned_input [string map {" " ""} $line_spec]
  
  # Handle empty specification
  if {$cleaned_input eq ""} {
    error "proc parse_line_spec: Error: Empty line specification"
  }
  
  # Handle single integer case
  if {[string is integer -strict $cleaned_input]} {
    if {$debug} {
      puts "Debug: Parsed as single line: $cleaned_input"
    }
    return [list $cleaned_input]
  }
  
  # Split into elements using comma as delimiter
  set elements [split $cleaned_input ","]
  
  # Process each element
  foreach elem $elements {
    if {$elem eq ""} {
      continue ;# Skip empty elements from consecutive commas
    }
    
    # Check if element is a range (contains hyphen)
    if {[string first "-" $elem] != -1} {
      set range_parts [split $elem "-"]
      
      # Validate range format
      if {[llength $range_parts] != 2} {
        error "proc parse_line_spec: Error: Invalid range format '$elem' in line specification"
      }
      
      lassign $range_parts start end
      
      # Validate range values
      if {![string is integer -strict $start] || ![string is integer -strict $end]} {
        error "proc parse_line_spec: Error: Invalid range values '$elem' in line specification"
      }
      
      if {$start > $end} {
        error "proc parse_line_spec: Error: Invalid range - start ($start) is greater than end ($end) in '$elem'"
      }
      
      # Add all lines in the range
      for {set i $start} {$i <= $end} {incr i} {
        lappend target_lines $i
      }
      
      if {$debug} {
        puts "Debug: Parsed range: $start-$end"
      }
    } else {
      # Single line number
      if {![string is integer -strict $elem]} {
        error "proc parse_line_spec: Error: Invalid line number '$elem' in line specification"
      }
      
      lappend target_lines $elem
      
      if {$debug} {
        puts "Debug: Parsed line: $elem"
      }
    }
  }
  
  return $target_lines
}

proc format_line_ranges {lines} {
  if {[llength $lines] == 0} {
    return ""
  }
  
  # Sort and remove duplicates
  set sorted [lsort -integer -unique $lines]
  set ranges [list]
  set current_start [lindex $sorted 0]
  set current_end $current_start
  
  # Iterate through lines to find consecutive ranges
  foreach line [lrange $sorted 1 end] {
    if {$line == $current_end + 1} {
      set current_end $line
    } else {
      if {$current_start == $current_end} {
        lappend ranges $current_start
      } else {
        lappend ranges "$current_start-$current_end"
      }
      set current_start $line
      set current_end $line
    }
  }
  
  # Add the last range
  if {$current_start == $current_end} {
    lappend ranges $current_start
  } else {
    lappend ranges "$current_start-$current_end"
  }
  
  return [join $ranges ", "]
}
