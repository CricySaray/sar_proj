#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/02/17 17:16:17 Tuesday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This TCL procedure extracts structured text blocks from a specified input file using four configurable extraction methods 
#             (start, separator, end, start_end) that support regular expression pattern matching for block boundaries.
#             It validates all input parameters rigorously to prevent runtime errors and returns a nested list of matched text blocks, 
#             preserving the original line order and relative positioning from the input file.
# return    : nested list, every child list is a block info list
#
#       Core proc to extract text blocks from file using 4 extraction methods
#       Arguments:
#         1. input_file: Path to input file (MANDATORY, first parameter)
#         2. method: Extraction method (start/separator/end/start_end)
#         3. start_pattern: Regex for block start line (for start/start_end methods)
#         4. separator_pattern: Regex for block separator line (for separator method)
#         5. end_pattern: Regex for block end line (for end/start_end methods)
#       Return: Nested list - each sublist is a matched block (lines preserved in order)
# ref       : link url
# --------------------------
proc get_block_info_fromTimingRptFile {input_file {method "start_end"} {start_pattern {Startpoint:}} {separator_pattern ""} {end_pattern {slack \(VIO}}} {
  # ==============================
  # Step 1: Validate input file
  # ==============================
  if {![file exists $input_file]} {
    error "proc get_block_info_fromTimingRptFile: Input file error: '$input_file' does not exist"
  }
  if {![file readable $input_file]} {
    error "proc get_block_info_fromTimingRptFile: Input file error: '$input_file' is not readable"
  }
  if {![file isfile $input_file]} {
    error "proc get_block_info_fromTimingRptFile: Input file error: '$input_file' is not a regular file"
  }

  # ==============================
  # Step 2: Validate extraction method
  # ==============================
  set valid_methods {start separator end start_end}
  if {$method ni $valid_methods} {
    error "proc get_block_info_fromTimingRptFile: Invalid method: '$method'. Valid methods: [join $valid_methods {, }]"
  }

  # ==============================
  # Step 3: Validate required patterns for each method
  # ==============================
  switch $method {
    start {
      if {$start_pattern eq ""} {
        error "proc get_block_info_fromTimingRptFile: Method 'start' requires non-empty start_pattern"
      }
    }
    separator {
      if {$separator_pattern eq ""} {
        error "proc get_block_info_fromTimingRptFile: Method 'separator' requires non-empty separator_pattern"
      }
    }
    end {
      if {$end_pattern eq ""} {
        error "proc get_block_info_fromTimingRptFile: Method 'end' requires non-empty end_pattern"
      }
    }
    start_end {
      if {$start_pattern eq "" || $end_pattern eq ""} {
        error "proc get_block_info_fromTimingRptFile: Method 'start_end' requires non-empty start_pattern AND end_pattern"
      }
    }
  }

  # ==============================
  # Step 4: Initialize core variables
  # ==============================
  set in_block 0                  ;# Flag: 1 = inside a block, 0 = outside
  set current_block [list]        ;# Current block lines (list)
  set all_blocks [list]           ;# Final nested list of all blocks
  set fh [open $input_file r]     ;# Open input file handle

  # ==============================
  # Step 5: Line-by-line processing (core extraction logic)
  # ==============================
  while {[gets $fh line] != -1} {
    # Remove trailing newline (preserve other whitespace)
    set line [string trimright $line "\n\r"]

    switch $method {
      # Method 1: Start - new block on start pattern, continue until next start
      start {
        if {[regexp $start_pattern $line]} {
          # If already in block: finalize current block first
          if {$in_block} {
            lappend all_blocks $current_block
            set current_block [list]
          }
          set in_block 1
          lappend current_block $line
        } elseif {$in_block} {
          lappend current_block $line
        }
      }

      # Method 2: Separator - blocks split by separator lines
      separator {
        if {[regexp $separator_pattern $line]} {
          # Finalize current block if exists
          if {$in_block && [llength $current_block] > 0} {
            lappend all_blocks $current_block
            set current_block [list]
            set in_block 0
          }
        } else {
          set in_block 1
          lappend current_block $line
        }
      }

      # Method 3: End - block ends on end pattern, start collecting immediately
      end {
        if {$in_block} {
          lappend current_block $line
          # Check if current line matches end pattern
          if {[regexp $end_pattern $line]} {
            lappend all_blocks $current_block
            set current_block [list]
            set in_block 0
          }
        } else {
          lappend current_block $line
          set in_block 1
        }
      }

      # Method 4: Start_End - block starts on start AND ends on end
      start_end {
        if {!$in_block && [regexp $start_pattern $line]} {
          set in_block 1
          lappend current_block $line
        } elseif {$in_block} {
          lappend current_block $line
          # Check if current line matches end pattern
          if {[regexp $end_pattern $line]} {
            lappend all_blocks $current_block
            set current_block [list]
            set in_block 0
          }
        }
      }
    }
  }

  # ==============================
  # Step 6: Process remaining block (after EOF)
  # ==============================
  if {$in_block && [llength $current_block] > 0} {
    lappend all_blocks $current_block
  }

  # ==============================
  # Step 7: Cleanup and return
  # ==============================
  close $fh
  return $all_blocks
}
