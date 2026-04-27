#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/02/10 11:09:17 Tuesday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This Tcl procedure calculates horizontal, vertical, or both numerical sums for a 2D list table, excluding string values 
#             in the first row and first column from calculations. It appends a custom-labeled total column/row to the table, features 
#             robust error validation for invalid inputs, and returns the modified 2D list without altering the original data.
#     Procedure to calculate horizontal/vertical/both sums for a 2D list table_2D_list
#     Parameters:
#       table_2D_list - Original 2D list (table_2D_list data)
#       direction - Sum direction: "horizontal", "vertical", "both"
#       total_label - Custom label for total column/row (default: "total")
# return    : 2D list
# ref       : link url
# --------------------------
proc calculate_table_sum {{table_2D_list ""} {direction "vertical"} {total_label "total"}} {
  # -------------------------- Error Validation --------------------------
  # 1. Check if table_2D_list is empty
  if {![llength $table_2D_list]} {
    error "proc calculate_table_sum: Error: Input table_2D_list is empty (must have at least 1 row and 1 column)"
  }

  # 2. Check if all rows have the same length (regular table_2D_list)
  set row_lengths [list]
  foreach row $table_2D_list {
    lappend row_lengths [llength $row]
  }
  set unique_lengths [lsort -unique $row_lengths]
  if {[llength $unique_lengths] > 1} {
    error "proc calculate_table_sum: Error: Irregular table_2D_list - rows have different lengths: $unique_lengths"
  }
  set col_count [lindex $unique_lengths 0]
  if {$col_count < 1} {
    error "proc calculate_table_sum: Error: All rows are empty (must have at least 1 column)"
  }

  # 3. Check if direction is valid
  set valid_directions {horizontal vertical both}
  if {$direction ni $valid_directions} {
    error "proc calculate_table_sum: Error: Invalid direction '$direction'. Valid options: [join $valid_directions {, }]"
  }

  # 4. Check if total label is non-empty
  if {[string trim $total_label] eq ""} {
    error "proc calculate_table_sum: Error: Total label cannot be empty string"
  }

  # 5. Validate numeric cells (only non-first row/column need to be numeric)
  set row_idx 0
  foreach row $table_2D_list {
    set col_idx 0
    foreach cell $row {
      if {$row_idx > 0 && $col_idx > 0} {
        if {![string is double -strict $cell]} {
          error "proc calculate_table_sum: Error: Cell at row $row_idx, column $col_idx is not a valid number: '$cell'"
        }
      }
      incr col_idx
    }
    incr row_idx
  }

  # -------------------------- Core Logic --------------------------
  # Create a copy to avoid modifying original table_2D_list
  set result_table $table_2D_list

  # Handle horizontal sum (add total column)
  if {$direction in {horizontal both}} {
    set new_table [list]
    set row_idx 0
    foreach row $result_table {
      if {$row_idx == 0} {
        # Add total label to header row
        lappend new_table [lappend row $total_label]
      } else {
        # Calculate sum of numeric cells (column 1 to end)
        set numeric_cells [lrange $row 1 end]
        set sum_val 0.0
        foreach num $numeric_cells {
          set sum_val [expr {$sum_val + $num}]
        }
        # Append sum to current row
        lappend new_table [lappend row $sum_val]
      }
      incr row_idx
    }
    set result_table $new_table
  }

  # Handle vertical sum (add total row)
  if {$direction in {vertical both}} {
    set current_col_count [llength [lindex $result_table 0]]
    # Initialize total row with custom label
    set total_row [list $total_label]
    
    # Calculate sum for each column (start from column 1)
    for {set col_idx 1} {$col_idx < $current_col_count} {incr col_idx} {
      set sum_val 0.0
      set row_idx 0
      foreach row $result_table {
        if {$row_idx > 0} { # Skip header row
          set cell [lindex $row $col_idx]
          set sum_val [expr {$sum_val + $cell}]
        }
        incr row_idx
      }
      lappend total_row $sum_val
    }
    # Append total row to table_2D_list
    lappend result_table $total_row
  }

  # Return modified table_2D_list
  return $result_table
}

if {0} {
  # -------------------------- Test Example --------------------------
  # Test table_2D_list (2D list)
  set test_table {
    {"Name" "Math" "English" "Science"}
    {"Alice" 90 85 95}
    {"Bob" 80 75 85}
    {"Charlie" 70 90 80}
  }

  # Test 1: Horizontal sum (add total column)
  puts "=== Horizontal Sum Result ==="
  set horizontal_result [calculate_table_sum $test_table "horizontal" "Total"]
  foreach row $horizontal_result {
    puts $row
  }

  # Test 2: Vertical sum (add total row)
  puts "\n=== Vertical Sum Result ==="
  set vertical_result [calculate_table_sum $test_table "vertical" "SUM"]
  foreach row $vertical_result {
    puts $row
  }

  # Test 3: Both horizontal and vertical sum
  puts "\n=== Both Sum Result ==="
  set both_result [calculate_table_sum $test_table "both" "Total"]
  foreach row $both_result {
    puts $row
  }
    
}
