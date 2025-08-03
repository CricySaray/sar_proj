#!/bin/tclsh
# --------------------------
# author    : from tcl manual example
# date      : 2025/08/03 18:00:35 Sunday
# label     : package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : opposite to incr - decrease by one(default)
# return    : 
# ref       : link url
# --------------------------
proc decr {varName {decrement 1}} {
    upvar 1 $varName var
    incr var [expr {-$decrement}]
}
