#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/08 14:57:36 Monday
# label     : atomic_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : print cmd to window, and then run/eval this cmd in shell
# return    : /
# ref       : link url
# --------------------------
alias pe "run_and_print_cmd"
proc run_and_print_cmd {{cmd ""} {ifRun 1}} {
  if {$cmd == ""} {
    error "proc run_and_print_cmd: check your input: cmd($cmd) is empty!!!" 
  } else {
    if {!$ifRun} { puts "Dry run: < $cmd >" }
    if {$ifRun} { puts "Now running: < $cmd >" ; eval $cmd } 
  }
}

