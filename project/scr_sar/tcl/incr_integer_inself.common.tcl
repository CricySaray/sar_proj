#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/17 17:07:29 Thursday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : related to incr i
#             if you input "a", it will return a number increased one based on previous value,
#             if it is invoked first time, it will return 1 (default), you can specify the beginning value
# ref       : link url
# --------------------------
alias ci "counter"
unset counters
proc counter {input {start 1}} {
    global counters
    if {![info exists counters($input)]} {
        set counters($input) [expr $start - 1]
    }
    incr counters($input)
    return "$counters($input)"
}
