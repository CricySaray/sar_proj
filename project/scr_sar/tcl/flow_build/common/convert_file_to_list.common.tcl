#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/30 14:49:42 Saturday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : converts a file's content to a TCL list by optionally removing comments, trimming whitespace, skipping empty lines, 
#             with error handling and verbose output options.
# return    : list converted from a input file
# ref       : link url
# --------------------------
proc convert_file_to_list {filename {trim_whitespace 1} {skip_empty 1} {verbose 0} {remove_comments 1}} {
  # Initialize the result list
  set result [list]
  
  # Check if the file exists
  if {![file exists $filename]} {
    error "Error: File '$filename' does not exist."
  }
  
  # Check if it's a regular file
  if {![file isfile $filename]} {
    error "Error: '$filename' is not a regular file."
  }
  
  # Check if the file is readable
  if {![file readable $filename]} {
    error "Error: File '$filename' is not readable."
  }
  
  try {
    # Open the file for reading
    set f [open $filename r]
    
    # Read lines one by one
    set line_number 0
    while {[gets $f line] != -1} {
      incr line_number
      set original_line $line
      
      # Remove comments if enabled
      if {$remove_comments} {
        # Check for line comments (start with #)
        set comment_index [string first "#" $line]
        if {$comment_index != -1} {
          set line [string range $line 0 [expr {$comment_index - 1}]]
          if {$verbose} {
            puts "Removed comment from line $line_number"
          }
        }
      }
      
      # Trim whitespace if enabled
      if {$trim_whitespace} {
        set line [string trim $line]
      }
      
      # Check if we should skip empty lines
      set is_empty [expr {[string length [string trim $line]] == 0}]
      
      if {$skip_empty && $is_empty} {
        if {$verbose} {
          puts "Skipping empty line $line_number"
        }
        continue
      }
      
      # Add to result list
      lappend result $line
      
      if {$verbose} {
        puts "Processed line $line_number: [expr {$is_empty ? "(empty)" : $line}]"
      }
    }
    
    # Close the file
    close $f
    
    if {$verbose} {
      puts "Successfully processed file. Total lines added: [llength $result]"
    }
    
    return $result
  } on error {msg} {
    # Handle any errors during file processing
    error "Error processing file '$filename': $msg"
  }
}

