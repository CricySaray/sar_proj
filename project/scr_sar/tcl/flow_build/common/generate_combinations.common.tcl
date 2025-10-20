#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/28 11:36:05 Sunday
# label     : atomic_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : This proc generates all possible combinations of elements from an arbitrary number of input lists (each must be a valid non-empty list) while preserving their 
#             relative order, with debug mode enabled by appending "-debug" as the last argument to show processing details.
# return    : combined list
# ref       : link url
# --------------------------
proc generate_combinations {args} {
  # Check for debug flag (must be last argument if present)
  set debug 0
  if {[llength $args] > 0 && [lindex $args end] eq "-debug"} {
    set debug 1
    set args [lrange $args 0 end-1]
    if {$debug} {
      puts "Debug mode enabled"
    }
  }
  set j 0
  foreach temp_arg [lrange $args 0 end-1] {
    incr j
    if {$temp_arg eq "-connector"} {
      if {[llength [lindex $args $j]] != 1} {
        error "proc generate_combinations: check your input: connector([lindex $args $j]) is invalid!!!" 
      } else {
        set connector [lindex $args $j]
        set args [lreplace $args [expr $j - 1] $j]
      }
    }
  }
  if {![info exists connector]} {
    set connector "_" 
  }

  # Error checking: no input lists provided
  if {[llength $args] == 0} {
    error "proc generate_combinations: Error: No input lists provided"
  }

  # Validate all arguments are valid lists and check for empty lists
  for {set i 0} {$i < [llength $args]} {incr i} {
    set current_arg [lindex $args $i]
    # Check if argument is a valid list
    if {[catch {llength $current_arg} len]} {
      error "proc generate_combinations: Error: Argument $i is not a valid list: $current_arg"
    }
    # Warn about empty lists in debug mode
    if {$len == 0} {
      if {$debug} {
        puts "Warning: List $i is empty - this will result in empty output"
      } else {
        error "proc generate_combinations: Error: List $i is empty - cannot generate combinations"
      }
    }
  }

  if {$debug} {
    puts "Processing [llength $args] lists:"
    for {set i 0} {$i < [llength $args]} {incr i} {
      puts "  List $i: [lindex $args $i] (length: [llength [lindex $args $i]])"
    }
  }

  # Initialize result with first list elements as single-item lists
  set result [list]
  set first_list [lindex $args 0]
  foreach item $first_list {
    lappend result [list $item]
  }

  if {$debug} {
    puts "After initial processing: [llength $result] combinations"
    puts "  $result"
  }

  # Process remaining lists
  for {set i 1} {$i < [llength $args]} {incr i} {
    set current_list [lindex $args $i]
    set temp [list]

    if {$debug} {
      puts "\nProcessing list $i: $current_list"
    }

    # Combine each existing result with each item in current list
    foreach res $result {
      foreach item $current_list {
        set new_combination [concat $res [list $item]]
        lappend temp $new_combination
        if {$debug} {
          puts "  Combined $res with $item -> $new_combination"
        }
      }
    }

    # Update result with new combinations
    set result $temp

    if {$debug} {
      puts "After list $i: [llength $result] combinations"
    }
  }
  set finalResult [lmap temp_list $result { join $temp_list $connector }]

  if {$debug} {
    puts "\nFinal result: [llength $finalResult] total combinations"
  }

  return $finalResult
}


# for example
if {0} {
  set one {1 2 3}
  set tow {one two three}
  set th {song an rui}
  puts "not on debug mode:"
  puts [join [generate_combinations $one -connector "+" $tow $th] \n]
  puts "on debug mode:"
  puts [join [generate_combinations $one $tow -connector "-_+_-" $th -debug] \n]
}
if {1} {
  set mode {func scan}
  set type {setup hold}
  set volt {0p99v 1p21v 1p1v}
  set corner {cbest cworst rcbest rcworst typical}
  set temp {m40c 25c 125c}
  puts [join [generate_combinations $mode $type $volt $corner $temp -connector "_"] \n]
}

