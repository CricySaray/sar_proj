#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/15 10:09:06 Tuesday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : puts message to file and window
# ref       : link url
# --------------------------
proc pw {{fileId ""} {message ""}} {
  puts $message
  puts $fileId $message
}
