#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/27 18:22:01 Sunday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : get cell drive capacity of celltype
# return    : 
# ref       : link url
# --------------------------
proc get_driveCapacity_of_celltype {{celltype ""} {regExp ".*X(\\d+).*(A\[HRL\]\\d+)$"}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e ] == ""} { ; # FIXED: U003: before: dbget top.insts.cell.name $celltype -e
    return "0x0:1"; # check your input 
  } else {
    set wholename 0
    set driveLevel 0
    set VTtype 0
    regexp $regExp $celltype wholename driveLevel VTtype 
    if {$driveLevel == "05"} {set driveLevel 0.5}
    return $driveLevel
  }
}
