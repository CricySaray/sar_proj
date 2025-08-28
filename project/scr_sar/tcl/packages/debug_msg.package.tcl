#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/28 15:18:01 Thursday
# label     : package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : Debug message helper
# return    : 
# ref       : link url
# --------------------------
proc debug_msg {msg debug_flag} {
  if {$debug_flag} {
    puts "DEBUG: $msg"
  }
}
