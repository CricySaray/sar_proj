#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/29 15:13:12 Friday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This proc parses various line specifications (including mixed lines and ranges) and executes the corresponding lines in a 
#             specified TCL script. It includes robust error handling and provides feedback on executed and unexecuted lines with 
#             configurable output options.
# update    : 2025/08/29 20:00:49 Friday
#             Added execution handling for single but multi-line commands, while also enhancing the functionality of program execution 
#             error judgment and error information capture.
# update    : 2025/08/30 16:26:18 Saturday
#             (U001) change method print the info of processing, as it can print out the execution information displayed during the operation in real time.
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
  # Create map from temp file line numbers to original line numbers
  set temp_content ""
  set temp_line_map [dict create]
  set temp_line_num 1
  
  foreach original_line_num $unique_lines {
    set line_content [lindex $script_lines [expr {$original_line_num - 1}]]
    append temp_content "$line_content\n"
    dict set temp_line_map $temp_line_num $original_line_num
    incr temp_line_num
  }
  
  # Write to temporary file
  set f [open $temp_name w]
  puts $f $temp_content
  close $f
  
  if {$debug} {
    puts "Debug: Temporary file line mapping:"
    dict for {temp_line orig_line} $temp_line_map {
      puts "Debug: Temp line $temp_line -> Original line $orig_line"
    }
  }
  
  # Execute using source -v with error redirection to errorInfo and track errors
  set error_occurred 0
  set error_info [dict create \
    temp_line_num 0 \
    original_line_num 0 \
    full_error "" \
    error_details "" \
    line_content "" \
  ]
  set executed_lines [list]
  
  try {
    # Use source -v with error redirection to errorInfo as specified
    set result [catch {uplevel #0 [list redirect errorInfo "source $temp_name" -variable -tee]} err] ; # U001
    
    # Get full error information from global errorInfo
    #uplevel #0 [list set local_errorInfo $errorInfo]
    upvar #0 errorInfo local_errorInfo

    if {$result != 0} {
      set error_occurred 1
      dict set error_info full_error $local_errorInfo
      
      # Parse errorInfo to find (file "filename" line X) pattern
      set temp_name_quoted [string map {"\\" "\\\\" "\"" "\\\""} $temp_name]
      set pattern "\\(file \"$temp_name_quoted\" line (\\d+)\\)"
      
      if {[regexp -line -indices $pattern $local_errorInfo match_pos line_pos]} {
        # Extract line number from the match
        set line_num_str [string range $local_errorInfo [lindex $line_pos 0] [lindex $line_pos 1]]
        if {[string is integer -strict $line_num_str]} {
          dict set error_info temp_line_num $line_num_str
          
          # Map to original line number
          if {[dict exists $temp_line_map $line_num_str]} {
            set original_line [dict get $temp_line_map $line_num_str]
            dict set error_info original_line_num $original_line
            dict set error_info line_content [lindex $script_lines [expr {$original_line - 1}]]
          }
          
          # Extract error details (all lines above the matching line)
          set match_start [lindex $match_pos 0]
          set error_details [string range $local_errorInfo 0 [expr {$match_start - 1}]]
          dict set error_info error_details [string trim $error_details]
        }
      } else {
        # Couldn't find exact pattern, use the original error message
        dict set error_info error_details $err
      }
    } else {
      # No error - all lines were executed
      set printInfoWhenSuccess $local_errorInfo
      set executed_lines $unique_lines
    }
  } on error {msg} {
    set error_occurred 1
    dict set error_info error_details "Framework error: $msg"
  } finally {
    # Clean up temporary file only if no error and not custom
    if {$delete_tempfile && !$error_occurred && [file exists $temp_name]} {
      file delete -force $temp_name
      if {$debug} {
        puts "Debug: Default temporary file deleted: $temp_name"
      }
    } elseif {$use_custom_tempfile && $debug} {
      puts "Debug: Custom temporary file preserved: $temp_name"
    }
  }
  
  # Handle success case
  if {!$error_occurred} {
    puts ""
    puts $printInfoWhenSuccess
    puts "---------------------------------------------"
    puts "Successfully executed all specified commands."
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
  
  # Handle error case
  set temp_line [dict get $error_info temp_line_num]
  set original_line [dict get $error_info original_line_num]
  set error_details [dict get $error_info error_details]
  set line_content [dict get $error_info line_content]
  
  puts "\nError occurred:"
  puts "------------------------------"
  puts "$error_details"
  puts "------------------------------"
  
  if {$original_line != 0} {
    puts "\nError location in original file:"
    puts "Line $original_line: $line_content"
  } elseif {$temp_line != 0} {
    puts "\nError location in temporary file:"
    puts "Line $temp_line in file: $temp_name"
  }
  
  # Calculate remaining lines
  if {$temp_line > 0 && [dict exists $temp_line_map $temp_line]} {
    set failed_original_line [dict get $temp_line_map $temp_line]
    set failed_index [lsearch -integer $unique_lines $failed_original_line]
    
    if {$failed_index != -1} {
      set remaining_lines [lrange $unique_lines [expr {$failed_index + 0}] end]
    } else {
      set remaining_lines [list]
    }
  } else {
    # If we can't determine the exact failed line, assume none were executed
    set remaining_lines $unique_lines
  }
  
  # Calculate executed lines
  set executed_lines [list]
  if {[llength $remaining_lines] > 0 && [llength $unique_lines] > 0} {
    set last_remaining [lindex $remaining_lines 0]
    set executed_index [expr {[lsearch -integer $unique_lines $last_remaining] - 1}]
    if {$executed_index >= 0} {
      set executed_lines [lrange $unique_lines 0 $executed_index]
    }
  } elseif {[llength $unique_lines] > 0 && [llength $remaining_lines] == 0} {
    set executed_lines $unique_lines
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
  
  if {$use_custom_tempfile || $error_occurred} {
    puts "\nTemporary file preserved for inspection: $temp_name"
  }
  
  error "Execution aborted at original line $original_line"
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
    
