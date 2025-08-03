#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/03 21:49:58 Sunday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|misc_proc)
# descrip   : get VT type from celltype
# return    : string of VTtype
# ref       : link url
# --------------------------
source ../../../proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
source ../../../packages/logic_AND_OR.package.tcl; # er
proc get_VTtype_of_celltype {{celltype ""} {regExp ".*X(\\d+).*(A\[HRL\]\\d+)$"}} {
  if {$celltype == "" || $celltype == "0c0" || [dbget head.libCells.name $celltype -e] == ""} {
    error "proc [regsub ":" [lindex [info level 0] 0] ""]: check your input: celltype($celltype) is incorrect!!!"
  } else {
    if {[catch {regexp $regExp $celltype wholename driveCapacity VTtype}]} {
      error "proc [regsub ":" [lindex [info level 0] 0] ""]: check your input: regExp($regExp) can't be matched!!!"
    } else {
      set process [whichProcess_fromStdCellPattern $celltype]
      if {$process == "TSMC"} { er $VTtype {set VTtype} {set VTtype "SVT"} }
      return $VTtype
    }
  }
}
