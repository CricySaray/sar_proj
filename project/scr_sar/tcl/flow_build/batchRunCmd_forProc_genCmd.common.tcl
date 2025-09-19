#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/08 14:46:25 Monday
# label     : atomic_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : It is specifically designed for Tcl scripts of the `genCmd_*` type. It can directly execute the return values of these `proc` (procedures) 
#             in sequence while displaying the commands being executed. Additionally, it can also only print the commands that are to be executed without 
#             actually running them, which is known as the **dry run** mode.
# return    : /
# ref       : link url
# --------------------------
source ./common/run_and_print_cmd.common.tcl; # pe
proc batchRunCmd_forProc_genCmd {{cmds {}} {ifRun 1}} {
  if {![llength $cmds]} {
    error "proc batchRunCmd_forProc_genCmd: check your input: cmds($cmds) is empty!!!"
  } else {
    foreach cmd $cmds {
      pe $cmd $ifRun
    }
  }
}
