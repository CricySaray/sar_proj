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
proc execute_selected_lines_of_script {script_file line_spec {temp_file ""} {debug 0} {show_remaining 1} {show_executed 0}} {
  # Read script file content
  if {![file exists $script_file]} {
    error "Error: Script file '$script_file' does not exist."
  }
  if {![file readable $script_file]} {
    error "Error: Script file '$script_file' is not readable."
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
    error "Error: No valid lines specified."
  }
  
  # Validate line numbers
  set invalid_lines [list]
  foreach line $target_lines {
    if {![string is integer -strict $line] || $line < 1 || $line > $total_lines} {
      lappend invalid_lines $line
    }
  }
  
  if {[llength $invalid_lines] > 0} {
    error "Error: Invalid line numbers (out of range 1-$total_lines): [join $invalid_lines ", "]"
  }
  
  # Ensure unique lines in sorted order
  set unique_lines [lsort -integer -unique $target_lines]
  if {$debug} {
    puts "Debug: Lines to execute (sorted): [join $unique_lines ", "]"
  }
  
  # Determine temporary file name and whether to clean it up
  set use_custom_tempfile [expr {$temp_file ne ""}]
  set delete_tempfile [expr {!$use_custom_tempfile}]
  
  if {$use_custom_tempfile} {
    set temp_name $temp_file
    if {$debug} {
      puts "Debug: Using custom temporary file: $temp_name"
    }
  } else {
    # Create default temporary file
    set temp_file_handle [file tempfile temp_name]
    close $temp_file_handle
    if {$debug} {
      puts "Debug: Created default temporary file: $temp_name"
    }
  }
  
  # Prepare content for temporary file with ONLY original lines
  set temp_content ""
  foreach line_num $unique_lines {
    append temp_content [lindex $script_lines [expr {$line_num - 1}]] "\n"
  }
  
  # Write to temporary file
  set f [open $temp_name w]
  puts $f $temp_content
  close $f
  
  # Create command map: maps command index to original line numbers
  set command_map [create_command_map $unique_lines $script_lines]
  set total_commands [llength $command_map]
  
  if {$debug} {
    puts "Debug: Total commands to execute: $total_commands"
    foreach cmd_idx [lsort -integer [dict keys $command_map]] {
      puts "Debug: Command $cmd_idx maps to lines: [dict get $command_map $cmd_idx]"
    }
  }
  
  # Execute commands and track progress
  set error_occurred 0
  set error_info [dict create line_num 0 message "" content "" original_lines ""]
  set executed_commands [list]
  
  try {
    set cmd_file [open $temp_name r]
    set cmd_idx 0
    
    while {![eof $cmd_file]} {
      set cmd [read_command $cmd_file]
      if {$cmd eq ""} break
      
      # Record command index before execution attempt
      set current_cmd_idx $cmd_idx
      
      # Attempt to execute the command
      if {[catch {
        uplevel #0 $cmd
      } err]} {
        # Error occurred during execution
        set error_occurred 1
        dict set error_info message $err
        dict set error_info content $cmd
        
        # Map to original line numbers
        if {[dict exists $command_map $current_cmd_idx]} {
          set original_line_nums [dict get $command_map $current_cmd_idx]
          dict set error_info original_lines $original_line_nums
          dict set error_info line_num [lindex $original_line_nums 0]
        }
        break
      }
      
      # If no error, record successful execution
      lappend executed_commands $current_cmd_idx
      incr cmd_idx
    }
    close $cmd_file
    
  } on error {msg} {
    # This catches errors in the execution framework itself, not in the script commands
    set error_occurred 1
    dict set error_info message "Framework error: $msg"
  } finally {
    # Clean up temporary file only if it's not a custom one
    if {$delete_tempfile && [file exists $temp_name]} {
      file delete -force $temp_name
      if {$debug} {
        puts "Debug: Default temporary file deleted: $temp_name"
      }
    } elseif {$use_custom_tempfile && $debug} {
      puts "Debug: Custom temporary file preserved: $temp_name"
    }
  }
  
  # Handle success case - only show success messages when no errors occurred
  if {!$error_occurred} {
    # Collect all executed line numbers
    set executed_lines [list]
    foreach cmd_idx $executed_commands {
      lappend executed_lines {*}[dict get $command_map $cmd_idx]
    }
    set executed_lines [lsort -integer -unique $executed_lines]
    
    puts "\nSuccessfully executed all specified commands."
    puts "Executed line numbers: [format_line_ranges $executed_lines]"
    
    if {$show_executed} {
      puts "\nContent of executed lines:"
      foreach line_num $executed_lines {
        puts "Line $line_num: [lindex $script_lines [expr {$line_num - 1}]]"
      }
    }
    
    if {$use_custom_tempfile} {
      puts "\nCustom temporary file preserved: $temp_name"
    }
    
    return $executed_lines
  }
  
  # Handle error case - only show error messages when errors occurred
  set line_num [dict get $error_info line_num]
  set msg [dict get $error_info message]
  set content [dict get $error_info content]
  set original_lines [dict get $error_info original_lines]
  
  puts "\nError occurred in command starting at line $line_num:"
  if {[llength $original_lines] > 1} {
    puts "This command spans lines: [join $original_lines ", "]"
  }
  puts "Command content: $content"
  puts "Error message: $msg"
  
  # Calculate remaining lines
  set executed_line_set [list]
  if {[llength $executed_commands] > 0} {
    foreach cmd_idx $executed_commands {
      lappend executed_line_set {*}[dict get $command_map $cmd_idx]
    }
    set executed_line_set [lsort -integer -unique $executed_line_set]
  }
  
  set remaining_lines [list]
  foreach line $unique_lines {
    if {$line ni $executed_line_set} {
      lappend remaining_lines $line
    }
  }
  
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
  
  if {$use_custom_tempfile} {
    puts "\nCustom temporary file preserved for inspection: $temp_name"
  }
  
  error "Execution aborted at or near line $line_num"
}

proc parse_line_spec {line_spec debug} {
  set target_lines [list]
  
  # Clean the input by removing all whitespace first
  set cleaned_input [string map {" " ""} $line_spec]
  
  # Handle empty specification
  if {$cleaned_input eq ""} {
    error "Error: Empty line specification"
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
        error "Error: Invalid range format '$elem' in line specification"
      }
      
      lassign $range_parts start end
      
      # Validate range values
      if {![string is integer -strict $start] || ![string is integer -strict $end]} {
        error "Error: Invalid range values '$elem' in line specification"
      }
      
      if {$start > $end} {
        error "Error: Invalid range - start ($start) is greater than end ($end) in '$elem'"
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
        error "Error: Invalid line number '$elem' in line specification"
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

proc create_command_map {line_numbers script_lines} {
  # Creates a map from command index to original line numbers
  set command_map [dict create]
  set cmd_idx 0
  set current_cmd_lines [list]
  set in_quote 0
  set quote_char ""
  set brace_level 0
  set bracket_level 0
  set paren_level 0
  
  foreach line_num $line_numbers {
    set line_content [lindex $script_lines [expr {$line_num - 1}]]
    set line_len [string length $line_content]
    set pos 0
    
    while {$pos < $line_len} {
      set char [string index $line_content $pos]
      
      # Handle quotes
      if {!$in_quote && ($char eq "\"" || $char eq "'")} {
        set in_quote 1
        set quote_char $char
        incr pos
        continue
      } elseif {$in_quote && $char eq $quote_char} {
        set in_quote 0
        incr pos
        continue
      }
      
      # Skip characters inside quotes
      if {$in_quote} {
        incr pos
        continue
      }
      
      # Handle braces, brackets and parentheses
      switch $char {
        "{" { incr brace_level }
        "}" { if {$brace_level > 0} { incr brace_level -1 } }
        "[" { incr bracket_level }
        "]" { if {$bracket_level > 0} { incr bracket_level -1 } }
        "(" { incr paren_level }
        ")" { if {$paren_level > 0} { incr paren_level -1 } }
      }
      
      incr pos
    }
    
    # Add current line to command lines
    lappend current_cmd_lines $line_num
    
    # Check if we've reached the end of a command
    if {$brace_level == 0 && $bracket_level == 0 && $paren_level == 0 && !$in_quote} {
      dict set command_map $cmd_idx $current_cmd_lines
      incr cmd_idx
      set current_cmd_lines [list]
    }
  }
  
  # Add any remaining lines as a command
  if {[llength $current_cmd_lines] > 0} {
    dict set command_map $cmd_idx $current_cmd_lines
  }
  
  return $command_map
}

proc read_command {file_handle} {
  # Reads a complete TCL command from a file handle
  set cmd ""
  set in_quote 0
  set quote_char ""
  set brace_level 0
  set bracket_level 0
  set paren_level 0
  
  while {![eof $file_handle]} {
    if {[gets $file_handle line] < 0} break
    
    append cmd $line "\n"
    set line_len [string length $line]
    set pos 0
    
    while {$pos < $line_len} {
      set char [string index $line $pos]
      
      # Handle quotes
      if {!$in_quote && ($char eq "\"" || $char eq "'")} {
        set in_quote 1
        set quote_char $char
        incr pos
        continue
      } elseif {$in_quote && $char eq $quote_char} {
        set in_quote 0
        incr pos
        continue
      }
      
      # Skip characters inside quotes
      if {$in_quote} {
        incr pos
        continue
      }
      
      # Handle braces, brackets and parentheses
      switch $char {
        "{" { incr brace_level }
        "}" { if {$brace_level > 0} { incr brace_level -1 } }
        "[" { incr bracket_level }
        "]" { if {$bracket_level > 0} { incr bracket_level -1 } }
        "(" { incr paren_level }
        ")" { if {$paren_level > 0} { incr paren_level -1 } }
      }
      
      incr pos
    }
    
    # Check if we've reached the end of a command
    if {$brace_level == 0 && $bracket_level == 0 && $paren_level == 0 && !$in_quote} {
      break
    }
  }
  
  return [string trimright $cmd "\n"]
}

