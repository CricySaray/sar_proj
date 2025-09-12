#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/12 10:57:31 Friday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : This proc splits each string in a given list using a specified delimiter (validating all contain it), aligns the left and right parts based on provided 
#             alignment rules (single or dual), and returns a list with aligned left segments, delimiters, and aligned right segments, including error checking 
#             and debug options.
# return    : list
# ref       : link url
# --------------------------
proc split_and_align_forString {{str_list {}} {delimiter ":"} {alignment left} {debug 0}} {
  # Check number of arguments
  if {[llength [info level 0]] < 4 || [llength [info level 0]] > 5} {
    error "proc split_and_align_forString: Invalid number of arguments. Usage: split_and_align str_list delimiter alignment ?debug?"
  }
  
  # Validate string list
  if {![string is list $str_list]} {
    error "proc split_and_align_forString: First argument must be a valid list"
  }
  
  # Check for empty list
  if {[llength $str_list] == 0} {
    error "proc split_and_align_forString: First argument cannot be an empty list"
  }
  
  # Validate delimiter
  if {![string is list $delimiter] || $delimiter eq ""} {
    error "proc split_and_align_forString: Second argument must be a non-empty string"
  }
  
  # Escape special regex characters in delimiter
  set escaped_delimiter [regsub -all {([\[\]\\\^\$\.\|\?\*\+\(\)])} $delimiter {\\\1}]
  
  # Validate alignment parameter
  set valid_alignments {left center right}
  if {[string is list $alignment]} {
    if {$alignment ni $valid_alignments} {
      error "proc split_and_align_forString: Invalid alignment string: $alignment. Must be one of: [join $valid_alignments {, }]"
    }
    # Apply same alignment to both columns
    set left_align $alignment
    set right_align $alignment
  } elseif {[string is list $alignment] && [llength $alignment] == 2} {
    lassign $alignment left_align right_align
    if {$left_align ni $valid_alignments || $right_align ni $valid_alignments} {
      error "proc split_and_align_forString: Invalid alignment in list. Elements must be one of: [join $valid_alignments {, }]"
    }
  } else {
    error "proc split_and_align_forString: Third argument must be a valid alignment string or a list of two alignment strings"
  }
  
  # Validate debug parameter
  if {![string is boolean $debug]} {
    error "proc split_and_align_forString: Fourth argument (debug) must be 0 or 1"
  }
  
  # Debug information
  if {$debug} {
    puts "Debug mode enabled"
    puts "Input list: $str_list"
    puts "Delimiter: \"$delimiter\""
    puts "Escaped delimiter: \"$escaped_delimiter\""
    puts "Left alignment: $left_align"
    puts "Right alignment: $right_align"
  }
  
  # Check if all strings contain the delimiter
  foreach str $str_list {
    if {![regexp -- $escaped_delimiter $str]} {
      error "proc split_and_align_forString: String \"$str\" does not contain delimiter \"$delimiter\""
    }
  }
  
  # Find maximum widths for alignment
  set max_left_width 0
  set max_right_width 0
  set split_strings [list]
  
  foreach str $str_list {
    # Split string once using the delimiter
    if {[regexp -- "^(.*?)${escaped_delimiter}(.*)$" $str -> left right]} {
      set left [regsub {^\s*(.*)\s*$} $left {\1}]
      set right [regsub {^\s*(.*)\s*$} $right {\1}]
      lappend split_strings [list $left $right]
      
      # Update maximum widths
      set left_width [string length $left]
      set right_width [string length $right]
      
      if {$left_width > $max_left_width} {
        set max_left_width $left_width
      }
      if {$right_width > $max_right_width} {
        set max_right_width $right_width
      }
    } else {
      error "proc split_and_align_forString: Failed to split string \"$str\" with delimiter \"$delimiter\""
    }
  }
  
  if {$debug} {
    puts "Max left column width: $max_left_width"
    puts "Max right column width: $max_right_width"
  }
  
  # Process alignment and build result
  set result [list]
  foreach pair $split_strings {
    lassign $pair left right
    
    # Align left part
    switch $left_align {
      left {
        set aligned_left [format "%-*s" $max_left_width $left]
      }
      center {
        set pad [expr {$max_left_width - [string length $left]}]
        set left_pad [expr {$pad / 2}]
        set right_pad [expr {$pad - $left_pad}]
        set aligned_left [string repeat " " $left_pad]$left[string repeat " " $right_pad]
      }
      right {
        set aligned_left [format "%*s" $max_left_width $left]
      }
    }
    
    # Align right part
    switch $right_align {
      left {
        set aligned_right [format "%-*s" $max_right_width $right]
      }
      center {
        set pad [expr {$max_right_width - [string length $right]}]
        set left_pad [expr {$pad / 2}]
        set right_pad [expr {$pad - $left_pad}]
        set aligned_right [string repeat " " $left_pad]$right[string repeat " " $right_pad]
      }
      right {
        set aligned_right [format "%*s" $max_right_width $right]
      }
    }
    
    lappend result [string cat $aligned_left " " $delimiter " " $aligned_right]
    
    if {$debug} {
      puts "Processed entry: [string cat $aligned_left " " $delimiter " " $aligned_right]"
    }
  }
  
  return $result
}

if {0} {
  set test_list [list "song:this is song an rui " "anajsdflkajsdlkf :this is an" "r: sjdalfjsld"]
  puts [join [split_and_align_forString $test_list ":" "left" 0] \n]
}
