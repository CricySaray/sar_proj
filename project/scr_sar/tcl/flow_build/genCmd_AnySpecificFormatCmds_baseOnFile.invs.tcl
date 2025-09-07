#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/01 18:07:22 Monday
# label     : flow_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
# descrip   : processes a file by grouping content lines using either "blankLine" (via regex-matched separator lines) or "firstColumn" (by first column values) 
#             methods, transforms valid content lines with provided options and a format string while preserving comment lines and empty lines, and outputs 
#             the result to a specified or auto-generated file.
# usage     : 
# 					Purpose: Processes a file by grouping content lines, transforms them using a format string,
# 					         and saves results to an output file while preserving comments and empty lines.
# 					Parameters (in order):
# 					  input_file     - (required) Path to input file (must exist and be readable)
# 					  groupMethod    - (optional) Grouping method: "blankLine" (default) or "firstColumn"
# 					  options        - (required) List of values to replace <value> in format (at least as many as groups)
# 					  format         - (required) Transformation string with <value> (from options) and <target> (from content)
# 					  output_file    - (optional) Path for output; defaults to "processedGoruped_<input_file>"
# 					  regex          - (optional) Regex for "blankLine" separators (full-line match); default: ^\s*$ (empty lines)
# 					  debug          - (optional) 1 to enable debug messages, 0 (default) for silent mode
# 					Group Method Details:
# 					  "firstColumn":
# 					    - Content lines need exactly 2 columns (after trimming spaces/tabs)
# 					    - Groups by values in the first column
# 					  "blankLine":
# 					    - Content lines need exactly 1 column (after trimming spaces/tabs)
# 					    - Groups by lines matching 'regex' (separators, preserved in output)
# 					Notes:
# 					  - Comment lines (start with #, optional leading spaces) and empty lines are preserved
# 					  - Format string must contain both <value> and <target>
# 					  - Extra items in 'options' are ignored; too few cause an error
# return    : outputfile
# ref       : link url
# --------------------------
proc genCmd_AnySpecificFormatCmds_baseOnFile {input_file {groupMethod "blankLine"} {options {33 34 35 36 37 38 46 47 3 7 8 9 10 15 17 18 20}} {format "highlight -index <value> <target>"} {output_file ""} {regex ""} {debug 0}} {
  # NOTICE: $options: these numbers are index of highlight
  # Internal procedure for debug messages
  proc debug_msg {msg debug_flag} {
    if {$debug_flag} {
      puts "DEBUG: $msg"
    }
  }

  # Validate group method is valid
  if {$groupMethod ni {blankLine firstColumn}} {
    error "Invalid group method: '$groupMethod'. Must be 'blankLine' or 'firstColumn'"
  }
  debug_msg "Using grouping method: $groupMethod" $debug

  # Set default regex for blankLine method if not provided
  if {$groupMethod eq "blankLine" && $regex eq ""} {
    set regex {^\s*$} ;# Default: match empty lines (including whitespace-only lines)
    debug_msg "No regex provided for blankLine grouping, using default: '$regex'" $debug
  }

  # Validate input file exists and is readable
  if {![file exists $input_file]} {
    error "Input file '$input_file' does not exist"
  }
  if {![file readable $input_file]} {
    error "Input file '$input_file' is not readable"
  }
  debug_msg "Successfully validated input file: $input_file" $debug

  # Handle output file naming with proper path handling
  if {$output_file eq ""} {
    set file_dir [file dirname $input_file]
    set file_name [file tail $input_file]
    set new_file_name "processedGoruped_$file_name"
    set output_file [file join $file_dir $new_file_name]
    debug_msg "No output file specified. Generated: $output_file" $debug
  } else {
    set output_dir [file dirname $output_file]
    if {$output_dir ne "."} {
      if {![file exists $output_dir]} {
        error "Output directory '$output_dir' does not exist"
      }
      if {![file isdirectory $output_dir]} {
        error "'$output_dir' is not a valid directory"
      }
    }
    if {[file exists $output_file] && ![file writable $output_file]} {
      error "Output file '$output_file' is not writable"
    }
    debug_msg "Successfully validated output file: $output_file" $debug
  }

  # Validate format string contains required placeholders
  if {[string first "<value>" $format] == -1} {
    error "Format string must contain '<value>' placeholder"
  }
  if {[string first "<target>" $format] == -1} {
    error "Format string must contain '<target>' placeholder"
  }
  debug_msg "Format string validated: '$format'" $debug

  # Validate options is a proper list
  if {![llength $options] eq [llength $options]} {
    error "Options parameter must be a valid list"
  }
  debug_msg "Options list validated. Contains [llength $options] elements" $debug

  # First pass: identify all groups based on selected method
  set groups [list]
  set line_count 0

  if {[catch {open $input_file r} in_channel]} {
    error "Failed to open input file '$input_file': $in_channel"
  }

  if {$groupMethod eq "firstColumn"} {
    # Grouping by first column values
    set group_ids [dict create]
    
    while {[gets $in_channel line] != -1} {
      incr line_count
      debug_msg "Line $line_count analysis (firstColumn): '$line'" $debug

      if {[string trim $line] eq ""} {
        debug_msg "Line $line_count is empty - skipping" $debug
        continue
      }
      
      set trimmed_line [string trimleft $line]
      if {[string index $trimmed_line 0] eq "#"} {
        debug_msg "Line $line_count is comment - skipping" $debug
        continue
      }
      
      # Trim whitespace from both ends before checking columns
      set cleaned_line [string trim $line "\t "]
      set columns [split $cleaned_line]
      set column_count [llength $columns]
      if {$column_count != 2} {
        close $in_channel
        error "firstColumn grouping: Line $line_count has $column_count columns (requires exactly 2)"
      }
      
      set group_id [lindex $columns 0]
      if {![dict exists $group_ids $group_id]} {
        dict set group_ids $group_id 1
        debug_msg "Line $line_count added new group: '$group_id'" $debug
      }
    }
    
    set groups [lsort [dict keys $group_ids]]
  } else {
    # Grouping by blankLine with refined comment handling
    set current_group [list]
    set group_index 0
    set original_groups [list]  ;# Temporary storage for groups
    
    while {[gets $in_channel line] != -1} {
      incr line_count
      debug_msg "Line $line_count analysis (blankLine): '$line'" $debug

      # Check if line matches the group separator regex (highest priority)
      # Use ^...$ to simulate full line match without -fullmatch option
      set is_separator [regexp -nocase -- "^${regex}$" $line]
      
      # Check if line is a comment (but may still be a separator)
      set trimmed_line [string trimleft $line]
      set is_comment [expr {[string index $trimmed_line 0] eq "#" ? 1 : 0}]
      
      # Handle separators (including comment lines that match regex)
      if {$is_separator} {
        debug_msg "Line $line_count is a group separator (is_comment=$is_comment)" $debug
        
        # Only create new group if current group has content
        if {[llength $current_group] > 0} {
          lappend original_groups $current_group
          debug_msg "Created group $group_index with [llength $current_group] lines" $debug
          incr group_index
          set current_group [list]
        }
        continue
      }
      
      # Skip non-separator comment lines in group content analysis
      if {$is_comment} {
        debug_msg "Line $line_count is a non-separator comment - skipping from group content" $debug
        continue
      }
      
      # Skip empty lines in group content (only separators matter)
      if {[string trim $line] eq ""} {
        debug_msg "Line $line_count is empty - skipping from group content" $debug
        continue
      }
      
      # Validate line has exactly 1 column for blankLine grouping
      # Trim whitespace from both ends before checking columns
      set cleaned_line [string trim $line "\t "]
      set columns [split $cleaned_line]
      set column_count [llength $columns]
      if {$column_count != 1} {
        close $in_channel
        error "blankLine grouping: Line $line_count has $column_count columns (requires exactly 1)"
      }
      
      # Add line to current group
      lappend current_group $line
      debug_msg "Line $line_count added to current group" $debug
    }
    
    # Add final group if it has content
    if {[llength $current_group] > 0} {
      lappend original_groups $current_group
      debug_msg "Created final group $group_index with [llength $current_group] lines" $debug
    }
    
    # Generate 0-based index list using simple loop (replaces range command)
    set groups [list]
    for {set i 0} {$i < [llength $original_groups]} {incr i} {
      lappend groups $i
    }
  }
  
  if {[catch {close $in_channel} close_err]} {
    error "Error closing input file: $close_err"
  }
  
  set group_count [llength $groups]
  debug_msg "First pass complete. Identified $group_count groups" $debug
  
  # Validate option count is sufficient
  set option_count [llength $options]
  if {$option_count < $group_count} {
    error "Insufficient options: $option_count options provided for $group_count groups (needs at least $group_count)"
  }
  set used_options [lrange $options 0 [expr {$group_count - 1}]]
  debug_msg "Using first $group_count options: [join $used_options ", "]" $debug
  
  # Create group to option mapping
  set group_option_map [dict create]
  for {set i 0} {$i < $group_count} {incr i} {
    set current_group [lindex $groups $i]
    set current_option [lindex $used_options $i]
    dict set group_option_map $current_group $current_option
    debug_msg "Mapped group '$current_group' to option '$current_option'" $debug
  }
  
  # Second pass: process file and generate output
  if {[catch {open $output_file w} out_channel]} {
    error "Failed to open output file '$output_file' for writing: $out_channel"
  }
  
  if {[catch {open $input_file r} in_channel]} {
    close $out_channel
    error "Failed to reopen input file '$input_file': $in_channel"
  }
  
  set line_count 0
  set processed_lines 0
  set skipped_lines 0
  set current_group_index -1

  # Initialize for blankLine method
  if {$groupMethod eq "blankLine"} {
    set current_group_index 0
    set total_groups [llength $groups]
    debug_msg "Initialized blankLine processing with $total_groups groups" $debug
  }
  
  while {[gets $in_channel line] != -1} {
    incr line_count
    debug_msg "Processing line $line_count for output" $debug

    # Common checks for all lines
    set trimmed_line [string trimleft $line]
    set is_comment [expr {[string index $trimmed_line 0] eq "#" ? 1 : 0}]
    set is_separator [expr {$groupMethod eq "blankLine" ? [regexp -nocase -- "^${regex}$" $line] : 0}]

    # Handle comment lines (always output as-is)
    if {$is_comment} {
      puts $out_channel $line
      incr skipped_lines
      debug_msg "Line $line_count is comment - written as-is" $debug
      
      # For blankLine method: check if comment is a separator and update group index
      if {$groupMethod eq "blankLine" && $is_separator && $current_group_index < $total_groups - 1} {
        incr current_group_index
        debug_msg "Comment line $line_count is separator - moved to group $current_group_index" $debug
      }
      continue
    }

    # Handle separators (non-comment, output as-is)
    if {$groupMethod eq "blankLine" && $is_separator} {
      puts $out_channel $line
      incr skipped_lines
      debug_msg "Line $line_count is non-comment separator - written as-is" $debug
      
      # Move to next group if possible
      if {$current_group_index < $total_groups - 1} {
        incr current_group_index
        debug_msg "Moved to group $current_group_index after separator" $debug
      }
      continue
    }

    # Handle empty lines (always output as-is)
    if {[string trim $line] eq ""} {
      puts $out_channel $line
      incr skipped_lines
      debug_msg "Line $line_count is empty - written as-is" $debug
      continue
    }

    # Process content lines based on grouping method
    if {$groupMethod eq "firstColumn"} {
      set cleaned_line [string trim $line "\t "]
      set columns [split $cleaned_line]
      set group_id [lindex $columns 0]
      set target_value [lindex $columns 1]
    } else {
      # blankLine method content processing
      set group_id $current_group_index
      set target_value [string trim $line "\t "]
    }
    
    # Get option for this group
    if {![dict exists $group_option_map $group_id]} {
      close $in_channel
      close $out_channel
      error "Internal error: Group '$group_id' not found in mapping (line $line_count)"
    }
    set option_value [dict get $group_option_map $group_id]
    
    # Perform substitution
    set new_line [string map [list "<value>" $option_value "<target>" $target_value] $format]
    debug_msg "Line $line_count transformed: '$line' -> '$new_line'" $debug
    
    # Write transformed line
    puts $out_channel $new_line
    incr processed_lines
  }
  
  # Clean up file handles
  if {[catch {close $in_channel} in_close_err]} {
    error "Error closing input file: $in_close_err"
  }
  if {[catch {close $out_channel} out_close_err]} {
    error "Error closing output file: $out_close_err"
  }
  
  debug_msg "Processing complete. Statistics: Total=$line_count, Processed=$processed_lines, Skipped=$skipped_lines" $debug
  
  return "Processing completed successfully. Output saved to: $output_file"
}

