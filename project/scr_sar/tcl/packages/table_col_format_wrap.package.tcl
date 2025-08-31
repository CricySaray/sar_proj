#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/18 15:32:48 Monday
# label     : table_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This proc formats tabular data from lists, files, or strings into colNumFinal columns, with the first colNumFinal-1 columns wrapped to 
#             max_first_width and the nth column (combining original nth and subsequent columns) wrapped to max_rest_width. It 
#             adds grid lines and handles line breaks to keep content readable without overlapping.
# inputArgs : inputData           : tabular data inputData, can be a nested list, file path, or raw string  
#             colNumFinal         : target number of columns (non-negative integer), 0 means auto-calculate max columns  
#             max_rest_width      : max width for the nth column (non-negative integer), 0 means no restriction  
#             max_first_width     : max width for the first colNumFinal-1 columns (non-negative integer), 0 means no restriction
# return    : list that has been tabled
# ref       : link url
# --------------------------
proc table_col_format_wrap {inputData {colNumFinal 3} {max_first_width 20} {max_rest_width 120}} {
  # Validate inputData parameters
  if {![string is integer -strict $colNumFinal] || $colNumFinal < 0} {
    error "proc table_col_format_wrap: colNumFinal must be a non-negative integer"
  }
  if {![string is integer -strict $max_rest_width] || $max_rest_width < 0} {
    error "proc table_col_format_wrap: max_rest_width must be a non-negative integer"
  }
  if {![string is integer -strict $max_first_width] || $max_first_width < 0} {
    error "proc table_col_format_wrap: max_first_width must be a non-negative integer"
  }

  # Constants for table formatting
  set col_sep "|"       ;# Column separator
  set line_char "-"     ;# Character for separator lines
  set corner_char "+"   ;# Corner character for separator lines

  # Helper function to split text into lines with max width
  proc wrap_text {text max_width} {
    if {$max_width <= 0} {return [list $text]} ;# No wrapping if width <=0
    set lines [list]
    set len [string length $text]
    set start 0
    while {$start < $len} {
      set end [expr {min($start + $max_width, $len)}]
      # Try to split at word boundary if possible
      if {$end < $len && [string index $text $end] ne " " && [string index $text [expr {$end - 1}]] ne " "} {
        set space_pos [string last " " $text [expr {$end - 1}]]
        if {$space_pos > $start} {
          set end $space_pos
        }
      }
      lappend lines [string range $text $start [expr {$end - 1}]]
      set start [expr {$end == $start ? $end + 1 : $end}] ;# Prevent infinite loop
    }
    return $lines
  }

  # Process inputData into standard row-column structure
  set rows [list]
  if {[llength $inputData] > 0} {
    set first_elem [lindex $inputData 0]
    # Check if inputData is nested list (each row is a sublist)
    if {[llength $first_elem] > 0 && [lindex $first_elem 0] ne ""} {
      foreach row $inputData {
        set processed_row [list]
        foreach col $row {
          lappend processed_row [join $col] ;# Preserve internal spaces
        }
        lappend rows $processed_row
      }
    } else {
      # Handle file path or raw string inputData
      set content ""
      if {[file exists $inputData]} {
        set f [open $inputData r]
        set content [read $f]
        close $f
      } else {
        set content $inputData
      }

      # Split into lines and process each line into columns
      foreach line [split $content \n] {
        set trimmed [string trim $line]
        if {$trimmed eq ""} {
          lappend rows [list] ;# Preserve empty lines
        } else {
          set cols [regexp -all -inline {\S+(?:\s+\S+)*} $line]
          lappend rows $cols
        }
      }
    }
  }

  # Handle colNumFinal=0: adjust to maximum number of columns across all rows
  if {$colNumFinal == 0} {
    set max_cols 0
    foreach row $rows {
      set max_cols [expr {max($max_cols, [llength $row])}]
    }
    set colNumFinal $max_cols
  }

  # Preprocess all columns with wrapping
  set wrapped_rows [list]
  set row_heights [list]

  foreach row $rows {
    set col_count [llength $row]
    set wrapped_cols [list]
    set max_lines 1 ;# Minimum height is 1 line

    # Process first (colNumFinal-1) columns with max_first_width
    for {set i 0} {$i < $colNumFinal - 1} {incr i} {
      set col_content [expr {$i < $col_count ? [lindex $row $i] : ""}]
      set wrapped [wrap_text $col_content $max_first_width]
      lappend wrapped_cols $wrapped
      set max_lines [expr {max($max_lines, [llength $wrapped])}]
    }

    # Process nth column (contains original nth column and all subsequent columns)
    # Apply max_rest_width for wrapping
    set nth_content ""
    if {$col_count >= $colNumFinal} {
      # Combine original nth column (index colNumFinal-1) and all columns after
      set nth_content [join [lrange $row [expr {$colNumFinal - 1}] end] " "]
    }
    set wrapped_nth [wrap_text $nth_content $max_rest_width]
    lappend wrapped_cols $wrapped_nth
    set max_lines [expr {max($max_lines, [llength $wrapped_nth])}]

    # Store wrapped data and row height
    lappend wrapped_rows $wrapped_cols
    lappend row_heights $max_lines
  }

  # Calculate column widths based on wrapped content
  set group1_widths [list]  ;# first colNumFinal-1 columns
  set group2_width 0        ;# nth column

  # Calculate group1 widths (first colNumFinal-1 columns)
  for {set i 0} {$i < $colNumFinal - 1} {incr i} {
    set max_w 0
    for {set r 0} {$r < [llength $wrapped_rows]} {incr r} {
      set row_cols [lindex $wrapped_rows $r]
      if {$i < [llength $row_cols]} {
        set col_lines [lindex $row_cols $i]
        foreach line $col_lines {
          set current_len [string length $line]
          set max_w [expr {max($max_w, $current_len)}]
        }
      }
    }
    lappend group1_widths $max_w
  }

  # Calculate group2 width (nth column) with max_rest_width consideration
  for {set r 0} {$r < [llength $wrapped_rows]} {incr r} {
    set row_cols [lindex $wrapped_rows $r]
    set nth_lines [lindex $row_cols [expr {$colNumFinal - 1}]]
    foreach line $nth_lines {
      set current_len [string length $line]
      set group2_width [expr {max($group2_width, $current_len)}]
    }
  }
  # Ensure group2 width does not exceed max_rest_width when restriction is active
  if {$max_rest_width > 0 && $group2_width > $max_rest_width} {
    set group2_width $max_rest_width
  }

  # Create base separator line
  set sep_parts [list $corner_char]
  # Add group1 separators
  foreach w $group1_widths {
    append sep_parts [string repeat $line_char [expr {$w + 2}]] $corner_char
  }
  # Add group2 separator
  append sep_parts [string repeat $line_char [expr {$group2_width + 2}]] $corner_char
  set base_sep $sep_parts

  # Build final output with proper line wrapping
  set result [list]
  lappend result $base_sep ;# Top separator

  for {set r 0} {$r < [llength $wrapped_rows]} {incr r} {
    set row_cols [lindex $wrapped_rows $r]
    set row_height [lindex $row_heights $r]
    set group1 [lrange $row_cols 0 [expr {$colNumFinal - 2}]] ;# first colNumFinal-1 columns
    set group2 [lindex $row_cols [expr {$colNumFinal - 1}]]   ;# nth column

    # Process each line in the wrapped row
    for {set line_idx 0} {$line_idx < $row_height} {incr line_idx} {
      set parts [list $col_sep]

      # Add group1 columns
      for {set i 0} {$i < [llength $group1]} {incr i} {
        set col_lines [lindex $group1 $i]
        set line_content [expr {$line_idx < [llength $col_lines] ? [lindex $col_lines $line_idx] : ""}]
        set w [lindex $group1_widths $i]
        lappend parts [format " %-*s " $w $line_content] $col_sep
      }

      # Add group2 column (nth column)
      set line_content [expr {$line_idx < [llength $group2] ? [lindex $group2 $line_idx] : ""}]
      lappend parts [format " %-*s " $group2_width $line_content] $col_sep

      lappend result [join $parts ""]
    }

    lappend result $base_sep ;# Separator after row (including multi-line rows)
  }

  # Join all parts and return
  return [string trim [join $result \n] "\n"]
}

