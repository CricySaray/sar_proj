#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/05 10:30:00 Friday
# label     : display_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This proc formats tabular data from NESTED LIST ONLY into columns (auto-detected from max items in sublists).
#             It supports per-column width restrictions, adds optional grid lines, handles line breaks, 
#             supports per-column or global alignment, and displays a centered title above.
# inputArgs : inputData           : tabular data, MUST be a nested list (each sublist represents a row of data)  
#             width_spec          : width specification (non-negative integer or list of non-negative integers). 
#                                   - Integer: uniform width limit for all columns (0 = no restriction)
#                                   - List: per-column width limits (must match column count, 0 = no restriction)
#             title               : table title to be displayed centered above the table (string)
#             align_spec          : alignment specification (valid values: left/center/right, or list of these values).
#                                   - Single value: apply to all columns
#                                   - List: per-column alignment (must match column count)
#                                   - Default: left
#             show_border         : border display switch (0 = no border, 1 = show border)
#                                   - Default: 1
# return    : formatted table string with title
# ref       : based on original table_col_format_wrap proc
# --------------------------
proc table_format_with_title {inputData {width_spec 0} {align_spec "left"} {title ""} {show_border 1}} {
  # Validate input parameters
  # 1. Check if inputData is a non-empty list (required for nested list structure)
  if {![llength $inputData]} {
    error "proc table_format_with_title: inputData must be a non-empty nested list (each sublist is a row)"
  }
  # 2. Check if all elements in inputData are lists (ensure nested list structure)
  foreach row $inputData {
    if {![llength $row] && $row ne ""} {
      error "proc table_format_with_title: all elements in inputData must be sublists (each sublist represents a row)"
    }
  }
  # 3. Check width_spec type and validity
  if {![string is integer -strict $width_spec] && ![llength $width_spec]} {
    error "proc table_format_with_title: width_spec must be a non-negative integer or list of non-negative integers"
  }
  if {[string is integer -strict $width_spec] && $width_spec < 0} {
    error "proc table_format_with_title: width_spec integer must be non-negative"
  }
  if {[llength $width_spec]} {
    foreach w $width_spec {
      if {![string is integer -strict $w] || $w < 0} {
        error "proc table_format_with_title: all width_spec list items must be non-negative integers"
      }
    }
  }
  # 4. Check title is a string (allow empty)
  if {![string is list $title] && [llength $title] > 1} {
    error "proc table_format_with_title: title must be a single string"
  }
  # 5. Check alignment specification validity
  set valid_alignments {"left" "center" "right"}
  if {[lsearch -exact $valid_alignments $align_spec] == -1 && [llength $align_spec] == 0} {
    error "proc table_format_with_title: align_spec must be a valid alignment ([join $valid_alignments {, }]) or a list of valid alignments"
  }
  # 6. Check show_border validity
  if {![string is integer -strict $show_border] || $show_border < 0 || $show_border > 1} {
    error "proc table_format_with_title: show_border must be 0 (no border) or 1 (show border)"
  }
  
  # Process inputData into standard row-column structure (ONLY handle nested list)
  set rows [list]
  foreach row $inputData {
    set processed_row [list]
    foreach col $row {
      # Preserve internal spaces in column content (same as original logic for nested list)
      lappend processed_row [join $col]
    }
    lappend rows $processed_row
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
    return "" ;# No valid data to format (all sublists are empty)
  }
  
  # Validate and process width_spec (with additional checks)
  set col_widths [list]
  if {[string is integer -strict $width_spec]} {
    # Handle uniform width specification
    # Create list with same width for all columns
    for {set i 0} {$i < $col_count} {incr i} {
      lappend col_widths $width_spec
    }
  } else {
    # Handle per-column width specification
    if {[llength $width_spec] != $col_count} {
      error "proc table_format_with_title: width_spec list length ([llength $width_spec]) must match column count ($col_count)"
    }
    foreach w $width_spec {
      lappend col_widths $w
    }
  }

  # Process alignment specification
  set align_cols [list]
  
  # Check if align_spec is a single valid alignment
  if {[lsearch -exact $valid_alignments $align_spec] != -1} {
    # Apply same alignment to all columns
    for {set i 0} {$i < $col_count} {incr i} {
      lappend align_cols $align_spec
    }
  } elseif {[llength $align_spec] > 0} {
    # Check if align_spec is a valid list of alignments
    if {[llength $align_spec] != $col_count} {
      error "proc table_format_with_title: align_spec list length ([llength $align_spec]) must match column count ($col_count)"
    }
    foreach align $align_spec {
      if {[lsearch -exact $valid_alignments $align] == -1} {
        error "proc table_format_with_title: invalid alignment '$align' in align_spec. Must be one of [join $valid_alignments {, }]"
      }
      lappend align_cols $align
    }
  }
  
  # Set table formatting characters based on border switch
  if {$show_border} {
    set col_sep "|"       ;# Column separator
    set line_char "-"     ;# Character for separator lines
    set corner_char "+"   ;# Corner character for separator lines
  } else {
    set col_sep " "       ;# Use space instead of | for column separation
    set line_char ""      ;# No line characters
    set corner_char ""    ;# No corner characters
  }
  
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
  
  # Create base separator line if borders are enabled
  set base_sep ""
  if {$show_border} {
    set sep_parts [list $corner_char]
    foreach w $actual_widths {
      append sep_parts [string repeat $line_char [expr {$w + 2}]] $corner_char
    }
    set base_sep $sep_parts
  }
  
  # Build table content
  set table_content [list]
  # Add top separator if borders are enabled
  if {$show_border} {
    lappend table_content $base_sep
  }
  
  for {set r 0} {$r < [llength $wrapped_rows]} {incr r} {
    set row_cols [lindex $wrapped_rows $r]
    set row_height [lindex $row_heights $r]
    # Process each line in the wrapped row
    for {set line_idx 0} {$line_idx < $row_height} {incr line_idx} {
      set parts [list]
      # Add column separator at start if borders are enabled
      if {$show_border} {
        lappend parts $col_sep
      }
      # Add each column's content for this line (with alignment)
      for {set i 0} {$i < $col_count} {incr i} {
        set col_lines [lindex $row_cols $i]
        set line_content [expr {$line_idx < [llength $col_lines] ? [lindex $col_lines $line_idx] : ""}]
        set w [lindex $actual_widths $i]
        set align [lindex $align_cols $i]
        
        # Format column content based on alignment
        if {$align eq "left"} {
          # Left alignment: use "-" flag in format (left-justified)
          set formatted_col [format " %-*s " $w $line_content]
        } elseif {$align eq "center"} {
          # Center alignment: calculate left/right padding manually
          set content_len [string length $line_content]
          if {$content_len >= $w} {
            # Content exceeds width (wrap_text should prevent this, fallback to left)
            set formatted_col " $line_content "
          } else {
            set pad_left [expr {int(($w - $content_len) / 2)}]
            set pad_right [expr {$w - $content_len - $pad_left}]
            set formatted_col " [string repeat " " $pad_left]$line_content[string repeat " " $pad_right] "
          }
        } elseif {$align eq "right"} {
          # Right alignment: no "-" flag (right-justified)
          set formatted_col [format " %*s " $w $line_content]
        }
        
        lappend parts $formatted_col
        # Add column separator between columns if borders are enabled
        if {$show_border || $i < [expr {$col_count - 1}]} {
          lappend parts $col_sep
        }
      }
      # Remove trailing separator if needed
      if {!$show_border && [llength $parts] > 0} {
        set parts [lrange $parts 0 end-1]
      }
      lappend table_content [join $parts ""]
    }
    # Add row separator if borders are enabled
    if {$show_border} {
      lappend table_content $base_sep
    }
  }
  
  # Combine table content into single string
  set table_body $table_content
  
  # Process title (center it above the table)
  set formatted_output [list]
  if {$title ne ""} {
    # Calculate table width to center title
    set table_width [expr {[llength $table_body] > 0 ? [string length [lindex $table_body 0]] : 0}]
    set title_len [string length $title]
    if {$title_len >= $table_width || $table_width == 0} {
      # Title is longer than table or table is empty, add as-is
      lappend formatted_output $title
    } else {
      # Center title by adding leading spaces
      set pad [expr {int(($table_width - $title_len) / 2)}]
      lappend formatted_output [string repeat " " $pad]$title
    }
    lappend formatted_output "" ;# Add blank line between title and table
  }
  
  # Add table body to output
  lappend formatted_output {*}$table_body
  
  # Return final formatted string
  return $formatted_output
}

### TEST
if {1} {
  # 1. Prepare nested list data (valid input: only nested list)
  set product_data {
    {"ID" "Product Name" "Stock" "Category" "Description (long text test)"}
    {"PRD-001" "Wireless Mouse" 450 "Peripherals" "Ergonomic design with Bluetooth 5.1 and 2.4G dual-mode; 800-1600 DPI adjustable; up to 60 days battery life"}
    {"PRD-002" "Mechanical Keyboard" 230 "Peripherals" "Blue switch with anti-ghosting; RGB backlight; compatible with Windows/macOS"}
    {"PRD-003" "27\" Monitor" 89 "Displays" "4K UHD (3840×2160); 100% sRGB; HDR10 support; height-adjustable stand"}
  }
  # 2. Call procedure: width specs [10, 18, 6, 12, 35]; title "Office Equipment Inventory"
  set formatted_table [table_format_with_title $product_data {10 18 6 12 35} center "Office Equipment Inventory" 0]
  set formatted_table [table_format_with_title $product_data {10 18 6 12 35} center "" 1]
  # 3. Output result
  puts "=== Test Case 1: Valid Nested List Input ==="
  puts [join $formatted_table \n]
  
  # Test Case 2: Invalid input (non-nested list, e.g., raw string) - should throw error
  puts "\n=== Test Case 2: Error Handling for Non-Nested List Input ==="
  set invalid_data "2024-09-01 Alice Engineering API integration completed"
  puts [join [table_format_with_title $invalid_data 15 center ""] \n]
  
  # Test Case 3: Invalid input (mixed list with non-sublist elements) - should throw error
  puts "\n=== Test Case 3: Error Handling for Mixed List Input ==="
  set mixed_data {{"Row1 Col1" "Row1 Col2"} "This is not a sublist" {"Row3 Col1" "Row3 Col2"}}
  puts [join [table_format_with_title $mixed_data 0 {right left left left left} "" 0] \n]
}
