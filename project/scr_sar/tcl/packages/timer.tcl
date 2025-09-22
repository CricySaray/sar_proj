#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/22 17:25:36 Monday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : The start_timer and end_timer procs record the start time and calculate the elapsed execution time, returning a formatted string 
#             (hours, minutes, seconds) adjusted to the duration.
# return    : string like: "3.0 seconds" from end_timer
#             list   like: [list $hours $minutes $seconds]
# ref       : link url
# --------------------------
# Start timing and store the start time in a global variable
proc start_timer {} {
  global timer_start_time
  # Record current time in milliseconds for higher precision
  set timer_start_time [clock milliseconds]
}

# End timing and return formatted time string
proc end_timer {{type "string"}} {
  # type: list|string
  global timer_start_time
  
  # Calculate elapsed time in milliseconds (integer)
  set end_time [clock milliseconds]
  set elapsed_ms [expr {$end_time - $timer_start_time}]
  
  # Calculate total seconds (integer) and remaining milliseconds
  set total_seconds [expr {$elapsed_ms / 1000}]
  set ms_remaining [expr {$elapsed_ms % 1000}]
  set seconds_decimal [expr {$ms_remaining / 1000.0}]
  
  # Calculate hours, minutes and remaining seconds using integers
  set hours [expr {$total_seconds / 3600}]
  set remaining_seconds [expr {$total_seconds % 3600}]
  set minutes [expr {$remaining_seconds / 60}]
  set seconds [expr {$remaining_seconds % 60 + $seconds_decimal}]
  
  if {$type == "string"} {
    # Format output string based on time duration
    if {$hours > 0} {
      return [format "%d hours %d minutes %.1f seconds" $hours $minutes $seconds]
    } elseif {$minutes > 0} {
      return [format "%d minutes %.1f seconds" $minutes $seconds]
    } else {
      return [format "%.1f seconds" $seconds]
    }
  } elseif {$type == "list"} {
    # return list format: {hours minutes seconds}
    return [list $hours $minutes $seconds]
  }
}

# for example
if {0} {
  start_timer
  after 3000 ; # ms
  puts [end_timer "string"]
}
