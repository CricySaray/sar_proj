#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/02 23:08:37 Saturday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : which process from std cell pattern(pt edition)
# return    : process name
# ref       : link url
# --------------------------
proc whichProcess_fromStdCellPattern {{celltype ""}} {
  if {$celltype == "" || $celltype == "0x0" || ![sizeof_collection [get_lib_cells "*/$celltype" -quiet]]} {
    return "0x0:1"; # can't find celltype in this design and library 
  } else {
    if {[regexp BWP $celltype]} {
      set processType "TSMC" 
    } elseif {[regexp {A[HRL]\d+$} $celltype]} {
      set processType "HH" 
    } else {
      return "0x0:1"; # can't indentify where the celltype is come from
    }
    return $processType
  }
}
