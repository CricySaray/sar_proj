#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/05 10:30:00 Friday
# label     : display_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This proc formats tabular data from lists, files, or strings into columns (auto-detected from max items in sublists).
#             It supports per-column width restrictions, adds grid lines, handles line breaks, and displays a centered title above.
# inputArgs : inputData           : tabular data, can be a nested list, file path, or raw string  
#             width_spec          : width specification (non-negative integer or list of non-negative integers). 
#                                   - Integer: uniform width limit for all columns (0 = no restriction)
#                                   - List: per-column width limits (must match column count, 0 = no restriction)
#             title               : table title to be displayed centered above the table
# return    : formatted table string with title
# ref       : based on original table_col_format_wrap proc
# --------------------------
proc table_format_with_title {inputData {width_spec 0} title} {
  # Validate input parameters
  # Check width_spec type and validity
  if {![string is integer -strict $width_spec] && ![llength $width_spec]} {
    error "proc table_format_with_title: width_spec must be a non-negative integer or list of non-negative integers"
  }
  
  # Process inputData into standard row-column structure (same as original logic)
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

  # Determine column count based on maximum items in sublists
  set col_count 0
  foreach row $rows {
    set current_cols [llength $row]
    if {$current_cols > $col_count} {
      set col_count $current_cols
    }
  }
  if {$col_count == 0} {
    return "" ;# No data to format
  }

  # Validate and process width_spec
  set col_widths [list]
  if {[string is integer -strict $width_spec]} {
    # Handle uniform width specification
    if {$width_spec < 0} {
      error "proc table_format_with_title: width_spec integer must be non-negative"
    }
    # Create list with same width for all columns
    for {set i 0} {$i < $col_count} {incr i} {
      lappend col_widths $width_spec
    }
  } else {
    # Handle per-column width specification
    if {[llength $width_spec] != $col_count} {
      error "proc table_format_with_title: width_spec list length ($llength($width_spec)) must match column count ($col_count)"
    }
    foreach w $width_spec {
      if {![string is integer -strict $w] || $w < 0} {
        error "proc table_format_with_title: all width_spec list items must be non-negative integers"
      }
      lappend col_widths $w
    }
  }

  # Constants for table formatting
  set col_sep "|"       ;# Column separator
  set line_char "-"     ;# Character for separator lines
  set corner_char "+"   ;# Corner character for separator lines

  # Helper function to split text into lines with max width
  # (preserved from original with minor variable name changes)
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

  # Preprocess all columns with wrapping
  set wrapped_rows [list]
  set row_heights [list]

  foreach row $rows {
    set row_cols [llength $row]
    set wrapped_cols [list]
    set max_lines 1 ;# Minimum height is 1 line

    # Process each column with its specific width restriction
    for {set i 0} {$i < $col_count} {incr i} {
      set col_content [expr {$i < $row_cols ? [lindex $row $i] : ""}]
      set wrapped [wrap_text $col_content [lindex $col_widths $i]]
      lappend wrapped_cols $wrapped
      set max_lines [expr {max($max_lines, [llength $wrapped])}]
    }

    # Store wrapped data and row height
    lappend wrapped_rows $wrapped_cols
    lappend row_heights $max_lines
  }

  # Calculate actual column widths based on wrapped content and width restrictions
  set actual_widths [list]
  for {set i 0} {$i < $col_count} {incr i} {
    set max_w 0
    set width_limit [lindex $col_widths $i]
    # Find maximum width in this column across all rows
    for {set r 0} {$r < [llength $wrapped_rows]} {incr r} {
      set row_cols [lindex $wrapped_rows $r]
      set col_lines [lindex $row_cols $i]
      foreach line $col_lines {
        set current_len [string length $line]
        set max_w [expr {max($max_w, $current_len)}]
      }
    }
    # Apply width restriction if specified
    if {$width_limit > 0 && $max_w > $width_limit} {
      set max_w $width_limit
    }
    lappend actual_widths $max_w
  }

  # Create base separator line
  set sep_parts [list $corner_char]
  foreach w $actual_widths {
    append sep_parts [string repeat $line_char [expr {$w + 2}]] $corner_char
  }
  set base_sep $sep_parts

  # Build table content
  set table_content [list]
  lappend table_content $base_sep ;# Top separator

  for {set r 0} {$r < [llength $wrapped_rows]} {incr r} {
    set row_cols [lindex $wrapped_rows $r]
    set row_height [lindex $row_heights $r]

    # Process each line in the wrapped row
    for {set line_idx 0} {$line_idx < $row_height} {incr line_idx} {
      set parts [list $col_sep]

      # Add each column's content for this line
      for {set i 0} {$i < $col_count} {incr i} {
        set col_lines [lindex $row_cols $i]
        set line_content [expr {$line_idx < [llength $col_lines] ? [lindex $col_lines $line_idx] : ""}]
        set w [lindex $actual_widths $i]
        lappend parts [format " %-*s " $w $line_content] $col_sep
      }

      lappend table_content [join $parts ""]
    }

    lappend table_content $base_sep ;# Separator after row
  }

  # Combine table content into single string
  set table_body [join $table_content \n]

  # Process title (center it above the table)
  set formatted_output [list]
  if {$title ne ""} {
    # Calculate table width to center title
    set table_width [string length $base_sep]
    set title_len [string length $title]
    if {$title_len >= $table_width} {
      # Title is longer than table, add as-is
      lappend formatted_output $title
    } else {
      # Center title by adding leading spaces
      set pad [expr {int(($table_width - $title_len) / 2)}]
      lappend formatted_output [string repeat " " $pad]$title
    }
    lappend formatted_output "" ;# Add blank line between title and table
  }

  # Add table body to output
  lappend formatted_output $table_body

  # Return final formatted string
  return [string trim [join $formatted_output \n] "\n"]
}


### TEST
if {0} {
  # 1. Prepare nested list data (sublists with varying item counts: 4, 3, 5 → auto-detect 5 columns)
  set product_data {
    {"ID" "Product Name" "Stock" "Category" "Description (long text test)"}
    {"PRD-001" "Wireless Mouse" 450 "Peripherals" "Ergonomic design with Bluetooth 5.1 and 2.4G dual-mode; 800-1600 DPI adjustable; up to 60 days battery life"}
    {"PRD-002" "Mechanical Keyboard" 230 "Peripherals" "Blue switch with anti-ghosting; RGB backlight; compatible with Windows/macOS"}
    {"PRD-003" "27\" Monitor" 89 "Displays" "4K UHD (3840×2160); 100% sRGB; HDR10 support; height-adjustable stand"}
  }

  # 2. Call procedure: width specs [10, 18, 6, 12, 35]; title "Office Equipment Inventory"
  set formatted_table [table_format_with_title $product_data {10 18 6 12 35} "Office Equipment Inventory"]

  # 3. Output result
  puts "=== Test Case 1: Nested List with Per-Column Widths ==="
  puts $formatted_table



	# 1. Prepare raw string data (with empty lines; varying column counts)
	set meeting_notes {
		"2024-09-01 Alice Engineering API integration completed User testing scheduled"
		"2024-09-02 Bob Product Requirements review Finalized core features"
		"2024-09-03 Charlie QA Regression testing Passed 85% of cases"
		"2024-09-04 Dave DevOps Server migration completed Monitoring system deployed"
	}

	# 2. Call procedure: uniform width 15 for all columns; title "Weekly Project Meeting Notes (September 2024)"
	set formatted_table [table_format_with_title $meeting_notes 15 "Weekly Project Meeting Notes (September 2024)"]

	# 3. Output result
	puts "\n=== Test Case 2: Raw String with Uniform Width ==="
	puts $formatted_table


  if {0} {
    # Part A: Valid case - width list matches auto-detected columns
    if {[file exists "gadget_specs.txt"]} {
      puts "\n=== Test Case 3A: Valid File Input ==="
      set valid_table [table_format_with_title "gadget_specs.txt" {8 18 10 0} "Gadget Specifications (File Input)"]
      puts $valid_table
    }

    # Part B: Invalid case - width list length mismatch (should throw error)
    puts "\n=== Test Case 3B: Error Handling for Mismatched Width List ==="
    if {[catch {
      table_format_with_title "test.txt" {8 18 10} "Invalid Width List Test"
    } error_msg]} {
      puts "Expected error caught: $error_msg"
    }
   
  }
}
