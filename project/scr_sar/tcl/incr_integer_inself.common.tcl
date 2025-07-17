#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/17 17:07:29 Thursday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : related to incr i
#             if you input "a", it will return a number increased one based on previous value,
#             if it is invoked first time, it will return 1 (default), you can specify the beginning value
# update    : 2025/07/18 00:39:49 Friday
#           add $holdon: if it is 1, it return now value(will not increase 1 based on original value) for different situation
# ref       : link url
# --------------------------
alias ci "counter"
catch {unset counters}
proc counter {input {holdon 0} {start 1}} {
    global counters
    if {![info exists counters($input)]} {
        set counters($input) [expr $start - 1]
    }
    if {!$holdon} {
      incr counters($input)
    }
    return "$counters($input)"
}
