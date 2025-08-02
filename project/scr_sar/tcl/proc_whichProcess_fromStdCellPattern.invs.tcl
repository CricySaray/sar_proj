#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Tue Jul  8 11:22:06 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
# descrip   : judge which process specified celltype is 
# ref       : link url
# --------------------------
proc whichProcess_fromStdCellPattern {{celltype ""}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e] == ""} {
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
