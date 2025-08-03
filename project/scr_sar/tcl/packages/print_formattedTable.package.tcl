#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/13 17:23:21 Sunday
# label     : display_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : format input List(only for D2 List), print table using linux command column
# ref       : link url
# --------------------------
proc print_formattedTable {{dataList {}}} {
  set text ""
  foreach row $dataList {
      append text [join $row "\t"]
      append text "\n"
  }
  # 通过管道传递给column命令
  set pipe [open "| column -t" w+]
  puts -nonewline $pipe $text
  close $pipe w
  set formattedLines [list ]
  while {[gets $pipe line] > -1} {
    lappend formattedLines $line
  }
  close $pipe
  return [join $formattedLines \n]
}
