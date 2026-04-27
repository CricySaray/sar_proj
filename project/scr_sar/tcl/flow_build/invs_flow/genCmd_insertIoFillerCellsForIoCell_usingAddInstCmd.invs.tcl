#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/03/17 17:19:23 Tuesday
# label     : gui_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This proc automatically inserts multiple types of filler cells into a specified rectangular region with wide-first priority, 
#               strict error checking, and customizable insertion order, direction, and small-gap handling rules.
#             It generates non-overlapping filler instance commands and returns a formatted list of `addInst` commands for EDA tool execution.
# return    : cmds list
# ref       : link url
# --------------------------

# Proc to insert filler cells in a specified region with comprehensive rules
proc insert_filler_cells {
  {search_rect {}}
  {filler_names {}}
  {insert_order clockwise}
  {insert_direction horizontal}
  {fill_gap_mode force_min}
  {inst_prefix FILLER}
} {
  # Parameter Description:
  # search_rect      : Target region {x y x1 y1} (llx lly urx ury), default empty
  # filler_names     : List of filler cell names, default empty
  # insert_order     : Fill order: clockwise/counter_clockwise, default clockwise
  # insert_direction : Fill orientation: horizontal/vertical, default horizontal
  # fill_gap_mode    : Gap handling: force_min/skip_min, default force_min
  # inst_prefix      : Prefix for filler instance names, default FILLER

  # ==============================================
  # Step 1: Basic Input Validation (Error Defense)
  # ==============================================
  # Check empty search region
  if {[llength $search_rect] != 4} {
    error "insert_filler_cells: Invalid search_rect format. Must be {x y x1 y1}"
  }
  lassign $search_rect llx lly urx ury
  if {$llx >= $urx || $lly >= $ury} {
    error "insert_filler_cells: Invalid search_rect (zero/negative area)"
  }

  # Check empty filler names
  if {[llength $filler_names] == 0} {
    error "insert_filler_cells: filler_names cannot be empty"
  }

  # Check valid insert order
  if {$insert_order ni {clockwise counter_clockwise}} {
    error "insert_filler_cells: insert_order must be clockwise or counter_clockwise"
  }

  # Check valid insert direction
  if {$insert_direction ni {horizontal vertical}} {
    error "insert_filler_cells: insert_direction must be horizontal or vertical"
  }

  # Check valid gap fill mode
  if {$fill_gap_mode ni {force_min skip_min}} {
    error "insert_filler_cells: fill_gap_mode must be force_min or skip_min"
  }

  # Check empty instance prefix
  if {$inst_prefix eq ""} {
    error "insert_filler_cells: inst_prefix cannot be empty"
  }

  # ==============================================
  # Step 2: Get Filler Width/Height & Validate
  # ==============================================
  set filler_info [list]  ;# Format: {name width height}
  set filler_heights [list]
  foreach fname $filler_names {
    # Get filler cell size using specified command
    set lib_cell [dbget head.libCells.name $fname -p]
    if {$lib_cell eq ""} {
      error "insert_filler_cells: Filler cell $fname not found in library"
    }
    set f_size [lindex [dbget $lib_cell.size] 0]
    lassign $f_size f_width f_height

    # Store filler info
    lappend filler_info [list $fname $f_width $f_height]
    lappend filler_heights $f_height
  }

  # Validate ALL fillers have the SAME height (critical requirement)
  set ref_height [lindex $filler_heights 0]
  foreach h $filler_heights {
    if {$h != $ref_height} {
      error "insert_filler_cells: All filler heights must be identical. Found mismatched heights: $filler_heights"
    }
  }

  # ==============================================
  # Step 3: Sort Fillers by WIDTH (DESC: Wide First)
  # ==============================================
  set sorted_fillers [lsort -real -decreasing -index 1 $filler_info]
  set min_filler_width [lindex [lindex $sorted_fillers end] 1]
  set filler_height $ref_height

  # ==============================================
  # Step 4: Get Empty Regions (Remove Instances)
  # ==============================================
  # Get all instances enclosed in search region
  set inst_rects [dbget [dbQuery -areas $search_rect -enclosed_only -objType inst].box -e]

  # Get empty fillable regions (region minus instances)
  set empty_regions [dbShape -output hrect $search_rect ANDNOT $inst_rects]
  if {[llength $empty_regions] == 0} {
    puts "insert_filler_cells: No empty space found in target region"
    return [list]
  }

  # ==============================================
  # Step 5: Validate Fillable Region Height
  # ==============================================
  foreach region $empty_regions {
    lassign $region r_llx r_lly r_urx r_ury
    set region_height [expr {$r_ury - $r_lly}]

    # Check if filler height > available region height (cannot insert)
    if {$filler_height > $region_height} {
      error "insert_filler_cells: Filler height ($filler_height) exceeds available region height ($region_height). Insertion failed."
    }
  }

  # ==============================================
  # Step 6: Initialize Variables for Insertion
  # ==============================================
  set inst_count 0
  set command_list [list]

  # ==============================================
  # Step 7: Fill Empty Regions (Wide First, No Overlap)
  # ==============================================
  foreach region $empty_regions {
    lassign $region r_llx r_lly r_urx r_ury

    # Calculate fill axis based on insert direction
    if {$insert_direction eq "horizontal"} {
      set fill_start $r_llx
      set fill_end $r_urx
      set fill_axis_len [expr {$r_urx - $r_llx}]
      set fixed_y $r_lly
    } else {
      set fill_start $r_lly
      set fill_end $r_ury
      set fill_axis_len [expr {$r_ury - $r_lly}]
      set fixed_x $r_llx
    }

    set current_pos $fill_start
    set remaining_space $fill_axis_len

    # Core filling loop: wide fillers first
    while {$remaining_space > 0} {
      set filler_placed 0

      # Try each filler in sorted order (wide -> narrow)
      foreach filler $sorted_fillers {
        lassign $filler fname fwidth fheight

        # Check if current filler fits in remaining space
        if {$fwidth <= $remaining_space} {
          # Generate instance name
          incr inst_count
          set inst_name "${inst_prefix}_${fname}_${inst_count}"

          # Create placement coordinate (lower-left corner)
          if {$insert_direction eq "horizontal"} {
            set loc [list $current_pos $fixed_y]
          } else {
            set loc [list $fixed_x $current_pos]
          }

          # Create addInst command
          set cmd "addInst -physical -loc \{$loc\} -place_status fixed -cell $fname -inst $inst_name"
          lappend command_list $cmd

          # Update position and remaining space
          set current_pos [expr {$current_pos + $fwidth}]
          set remaining_space [expr {$remaining_space - $fwidth}]
          set filler_placed 1
          break
        }
      }

      # If no filler can fit (gap < min width)
      if {!$filler_placed} {
        if {$fill_gap_mode eq "force_min"} {
          # Force insert smallest filler (allow overlap as required)
          set min_filler [lindex $sorted_fillers end]
          lassign $min_filler min_fname min_fwidth min_fheight

          incr inst_count
          set inst_name "${inst_prefix}_${min_fname}_${inst_count}"

          if {$insert_direction eq "horizontal"} {
            set loc [list $current_pos $fixed_y]
          } else {
            set loc [list $fixed_x $current_pos]
          }

          set cmd "addInst -physical -loc \{$loc\} -place_status fixed -cell $min_fname -inst $inst_name"
          lappend command_list $cmd
        }

        # Exit loop (no more space to fill)
        set remaining_space 0
      }
    }
  }

  # ==============================================
  # Step 8: Return Final Command List
  # ==============================================
  puts "insert_filler_cells: Successfully generated $inst_count filler instances"
  return $command_list
}
