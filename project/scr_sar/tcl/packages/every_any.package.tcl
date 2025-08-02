#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/02 14:03:13 Saturday
# label     : package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : return 1 when items of list meets specified requirement processing script which of var name can be specified by user
# return    : every:
#             1: every items can return 1 running script
#             0: one at least can't return 1 running script
#             any:
#             1: one at least can return 1 running script
#             0: every items can't return 1 running script
# example   : set song [list 1.1 2 3 4]
#             set result [every x $song {string is integer $x}]
#             > $result == 0
#             set result [every x $song {string is double $x}]
#             > $result == 1
#             set result [any x $song {string is integer $x}]
#             > $result == 1
#             set result [any x $song {string is double $x}]
#             > $result == 1
# --------------------------
proc every {varName list script} {
  foreach item $list {
    # specify var in script
    uplevel 1 [list set $varName $item]
    # run script
    if {![uplevel 1 $script]} {
      return 0
    }
  }
  return 1
}
proc any {varName list script} {
  foreach item $list {
    # specify var in script
    uplevel 1 [list set $varName $item]
    # run script
    if {[uplevel 1 $script]} {
      return 1
    }
  }
  return 0
}
