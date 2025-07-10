#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/10 22:09:47 Thursday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|misc_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> gui_proc   : for gui display, or effort can be viewed in invs GUI
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
#   -> dump_proc  : dump data with specific format from db(invs/pt/starrc/pv...)
#   -> misc_proc  : some other uses of procs
# descrip   : check problem that is not on manufacturing grid from lef file (test env: manufacturing grid is 0.005)
# ref       : link url
# --------------------------
proc check_multiple_005 {leffile} {
  set fi [open $leffile r]
  set num 0
  while {[gets $fi line] > -1} {
    set num [expr $num + 1]
    foreach i $line {
      if {[string is double $i] || [string is integer $i]} {
        if {[expr [expr $i / 0.005] != int([expr $i / 0.005])]} {
          puts "(Line: $num) (value : $i) $line"
        }
      } 
    }
  }
  close $fi
}
