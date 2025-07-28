#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/27 19:22:57 Sunday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : struct::list::every
# return    : 
# ref       : link url
# --------------------------
proc every {{List {}} {judgeValue true}} {
  set flag 1
  foreach temp $List {
    if {$temp == $judgeValue} {continue}
    set flag 0; break
  }
  return $flag
}
