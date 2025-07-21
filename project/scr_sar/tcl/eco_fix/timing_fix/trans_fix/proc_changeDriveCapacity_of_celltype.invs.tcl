#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/21 23:24:37 Monday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : change cell drive capacity of cell type according to different std process
# ref       : link url
# --------------------------
source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
proc changeDriveCapacity_of_celltype {{refType "BUFD4BWP6T16P96CPD"} {originalDriveCapacibility 0} {toDriverCapacibility 0}} {
  set processType [whichProcess_fromStdCellPattern $refType]
  if {$processType == "TSMC"} { ; # TSMC
    regsub "D${originalDriveCapacibility}BWP" $refType "D${toDriverCapacibility}BWP" toCelltype
    return $toCelltype
  } elseif {$processType == "HH"} { ; # HH40 huahonghongli
    if {$toDriverCapacibility == 0.5} {set toDriverCapacibility "05"}
    regsub [subst {(.*)X${originalDriveCapacibility}}] $refType [subst {\\1X${toDriverCapacibility}}] toCelltype
    return $toCelltype
  } else {
    error "proc changeDriveCapacity_of_celltype: process of std cell is not belong to TSMC or HH!!!"
  }
}
