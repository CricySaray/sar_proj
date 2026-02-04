#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/02/04 13:58:32 Wednesday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This proc transposes a 2D Tcl list by converting its rows to columns and includes comprehensive error checking to validate 
#             input structure and uniform row lengths.
#             It offers flexible control via debug mode for detailed process logging and non-strict mode with customizable fill characters 
#             to handle irregular row lengths automatically.
# return    : 2d list
# ref       : link url
# --------------------------
# Proc to transpose a 2D list with error checking and flexible options
proc transpose_2d_list {matrix {strict 1} {fill_char ""} {debug 0}} {
  # Debug: Print input information if enabled
  if {$debug} {
    puts "DEBUG: [info level 0]"
    puts "DEBUG: Input matrix raw value: $matrix"
  }

  # Error check 1: Input must be a valid Tcl list
  if {[catch {llength $matrix} row_count]} {
    error "Input is not a valid Tcl list. Details: $row_count"
  }
  if {$debug} {
    puts "DEBUG: Input matrix row count: $row_count"
  }

  # Handle empty matrix case
  if {$row_count == 0} {
    if {$debug} {
      puts "DEBUG: Input matrix is empty, return empty list"
    }
    return [list]
  }

  # Error check 2 & 3: Each row must be a valid list, collect row lengths
  set valid_rows [list]
  set col_count -1
  set row_idx 0
  foreach row $matrix {
    # Check if current row is a valid Tcl list
    if {[catch {llength $row} curr_row_len]} {
      error "Row $row_idx is not a valid Tcl list. Row content: '$row', Details: $curr_row_len"
    }
    lappend valid_rows $row

    # Set column count from first valid row
    if {$col_count == -1} {
      set col_count $curr_row_len
      if {$debug} {
        puts "DEBUG: Column count (from first row): $col_count"
      }
    }

    incr row_idx
  }

  # Error check 4: All rows must have same length (strict mode) or pad rows (non-strict mode)
  set processed_rows [list]
  set row_idx 0
  foreach row $valid_rows {
    set curr_row_len [llength $row]
    if {$curr_row_len != $col_count} {
      if {$strict} {
        # Strict mode: Throw error for mismatched row length
        error "Row $row_idx length mismatch: expected $col_count elements, got $curr_row_len. Row content: '$row'"
      } else {
        # Non-strict mode: Pad short rows with fill_char, truncate long rows
        set padded_row [lrange $row 0 [expr {$col_count - 1}]]
        while {[llength $padded_row] < $col_count} {
          lappend padded_row $fill_char
        }
        if {$debug} {
          puts "DEBUG: Row $row_idx padded: '$row' -> '$padded_row'"
        }
        lappend processed_rows $padded_row
      }
    } else {
      # Row length matches, add directly
      lappend processed_rows $row
    }
    incr row_idx
  }

  # Core logic: Transpose the 2D list
  set transposed [list]
  for {set c 0} {$c < $col_count} {incr c} {
    set new_row [list]
    foreach row $processed_rows {
      lappend new_row [lindex $row $c]
    }
    lappend transposed $new_row
    if {$debug} {
      puts "DEBUG: Transposed column $c -> new row: $new_row"
    }
  }

  # Debug: Print final transposed result
  if {$debug} {
    puts "DEBUG: Final transposed matrix: $transposed"
    puts "DEBUG: Transpose completed successfully"
  }

  # Return the transposed 2D list
  return $transposed
}
if {0} {
  set song {
    {name age age2}
    {song 18 18}
    {an 20 }
    {rui 1 100 200}
  }
  puts [join [transpose_2d_list $song 0 "##"] \n]
}
