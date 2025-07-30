#!/bin/tclsh
# author    : sar song
# date      : 2025/07/10 22:09:47 Thursday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|misc_proc)
# descrip   : check problem that is not on manufacturing grid from lef file (test env: manufacturing grid is 0.005)
# ref       : link url
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
