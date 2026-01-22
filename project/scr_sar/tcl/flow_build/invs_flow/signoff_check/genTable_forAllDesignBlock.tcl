#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/01/22 23:45:31 Thursday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Recursively searches for files matching the specified pattern in the given directory and its subdirectories, reads their contents, 
#             and constructs a consolidated 2D list table. Each file must contain exactly two non-empty lines (header and values) with the same 
#             number of columns. The proc merges headers from all files, fills missing values with "/", and supports custom header ordering and table transposition.
# params    :
#   folder_path   - Root directory to start searching from (required)
#   file_pattern  - File name pattern to match (required)
#   col_order     - Optional, tab-separated list of headers in desired order
#   folder_level  - Optional, path level to extract folder name from (default: "end-1")
#   transpose     - Optional, flag to transpose the table (default: 0, no transpose)
# return    : 2D list representing the consolidated table
#   - Non-transposed: First sublist is headers including "Folder", subsequent sublists are data rows with folder name as first element
#   - Transposed: First sublist is "Folder" followed by folder names, subsequent sublists are header followed by corresponding values
# ref       : link url
# --------------------------
# Recursive function to find files matching pattern in directory and subdirectories
source ../../../packages/table_format_with_title.package.tcl; # table_format_with_title
proc genTable_fromEverySubDirSumCsvFile {
    folder_path
    file_pattern
    {col_order {}}
    {folder_level "end-1"}
    {transpose 0}
} {
  # Validate input parameters
  if {![file exists $folder_path] || ![file isdirectory $folder_path]} {
    error "Invalid folder path: $folder_path"
  }
  
  # Step 1: Get all matching files recursively
  set all_files [find_files_recursive $folder_path $file_pattern]
  if {[llength $all_files] == 0} {
    error "No files found matching pattern: $file_pattern in $folder_path"
  }
  
  # Step 2: Process each file
  set file_data_list [list]
  set all_headers [list]
  
  foreach file_path $all_files {
    # Get folder name from path based on specified level
    set path_parts [split $file_path "/"]
    set folder_name [lindex $path_parts $folder_level]
    
    # Read file content and filter out empty lines
    set file_content [read [open $file_path r]]
    set lines [split $file_content "\n"]
    set non_empty_lines [list]
    
    foreach line $lines {
      set trimmed_line [string trim $line]
      if {$trimmed_line ne ""} {
        lappend non_empty_lines $trimmed_line
      }
    }
    
    # Check exactly two non-empty lines
    if {[llength $non_empty_lines] != 2} {
      error "File $file_path must contain exactly two non-empty lines after filtering out blank lines, but found [llength $non_empty_lines] lines"
    }
    
    # Split into columns
    set headers [split [lindex $non_empty_lines 0] "\t"]
    set values [split [lindex $non_empty_lines 1] "\t"]
    
    # Check same number of columns in header and values
    if {[llength $headers] != [llength $values]} {
      error "File $file_path has mismatched column count: header has [llength $headers] columns, values has [llength $values] columns"
    }
    
    # Create header-value map and update all_headers
    set header_value_map [dict create]
    foreach header $headers value $values {
      dict set header_value_map $header $value
      if {$header ni $all_headers} {
        lappend all_headers $header
      }
    }
    
    # Store file data
    lappend file_data_list [list $folder_name $header_value_map]
  }
  
  # Step 3: Determine final header order
  if {$col_order eq {}} {
    # Default to ASCII sort
    set final_headers [lsort $all_headers]
  } else {
    # Use specified order, then add remaining headers sorted
    set specified_headers [split $col_order "\t"]
    set remaining_headers [lsort [lsearch -all -inline -not $all_headers $specified_headers]]
    set final_headers [concat $specified_headers $remaining_headers]
    
    # Remove duplicates while preserving order
    set temp_headers [list]
    foreach header $final_headers {
      if {$header ni $temp_headers} {
        lappend temp_headers $header
      }
    }
    set final_headers $temp_headers
  }
  
  # Step 4: Build the main table
  # First row: folder name + all headers
  set main_table [list [concat [list "Folder"] {*}$final_headers]]
  
  # Add each file's data as a row
  foreach file_data $file_data_list {
    set folder_name [lindex $file_data 0]
    set header_value_map [lindex $file_data 1]
    
    set row [list $folder_name]
    foreach header $final_headers {
      if {[dict exists $header_value_map $header]} {
        lappend row {*}[dict get $header_value_map $header]
      } else {
        lappend row {/}
      }
    }
    
    lappend main_table $row
  }
  
  # Step 5: Transpose if requested
  if {$transpose} {
    set transposed [list]
    
    # Determine dimensions
    set num_rows [llength $main_table]
    set num_cols [llength [lindex $main_table 0]]
    
    # First row: "Folder" + folder names
    set first_row [list [lindex $main_table 0 0]]
    for {set i 1} {$i < $num_rows} {incr i} {
      lappend first_row [lindex $main_table $i 0]
    }
    lappend transposed $first_row
    
    # Add remaining rows: header + values
    for {set i 1} {$i < $num_cols} {incr i} {
      set header_row [list [lindex $main_table 0 $i]]
      for {set j 1} {$j < $num_rows} {incr j} {
        lappend header_row [lindex $main_table $j $i]
      }
      lappend transposed $header_row
    }
    
    set main_table $transposed
  }
  
  return $main_table
}
proc find_files_recursive {dir pattern} {
  set result [list]
  
  # Find files in current directory
  foreach file [glob -nocomplain -type f [file join $dir $pattern]] {
    lappend result $file
  }
  
  # Recurse into subdirectories
  foreach subdir [glob -nocomplain -type d [file join $dir *]] {
    if {[file tail $subdir] ni {. ..}} {
      set subdir_files [find_files_recursive $subdir $pattern]
      set result [concat $result $subdir_files]
    }
  }
  
  return $result
}

if {0} {
  set searchDir "./"
  set searchFilename "sum_subblock.csv"
  set allsumlist [genTable_fromEverySubDirSumCsvFile $searchDir $searchFilename]
  puts [join [table_format_with_title $allsumlist 0 center "" 0] \n]
}
