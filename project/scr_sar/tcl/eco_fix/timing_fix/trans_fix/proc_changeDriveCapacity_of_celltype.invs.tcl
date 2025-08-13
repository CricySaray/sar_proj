#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/21 23:24:37 Monday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : change cell drive capacity of cell type according to different std process
# ref       : link url
# --------------------------
source ../lut_build/operateLUT.tcl; # operateLUT
alias sus "subst -nocommands -nobackslashes"
proc changeDriveCapacity_of_celltype {{refType "BUFD4BWP6T16P96CPD"} {originalDriveCapacibility 0} {toDriverCapacibility 0}} {
  set processType [operateLUT -type read -attr {process}]
  set stdCellFlag [operateLUT -type read -attr {stdcellflag}]
  set capacityFlag [operateLUT -type read -attr {capacityflag}]
  regsub [sus {^(.*$capacityFlag)$originalDriveCapacibility($stdCellFlag.*)$}] $refType [sus {\1$toDriverCapacibility\2}] toCelltype
  if {[operateLUT -type exists -attr [list celltype $toCelltype]]} {
    error "proc changeDriveCapacity_of_celltype: error toCelltype($toCelltype), double check it!!!"
  } else {
    return $toCelltype
  }
}
