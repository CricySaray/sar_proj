#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/02 23:16:52 Saturday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : get cell drive capacity of celltype (pt edition)
# update    : (U001) add another type of proc: get_driveCapacityAndVTtype_of_celltype_spcifyingStdCellLib
#             you can control $regExp more precisely
# return    : integer
# ref       : link url
# --------------------------
proc get_driveCapacity_of_celltype {{celltype ""} {regExp ".*X(\\d+).*(A\[HRL\]\\d+)$"}} {
  if {$celltype == "" || $celltype == "0x0" || ![sizeof_collection [get_lib_cells -q "*/$celltype"]]} { 
    return "0x0:1"; # check your input 
  } else {
    regexp $regExp $celltype wholename driveLevel VTtype 
    if {![info exists wholename]} { 
      error "proc get_driveCapacity_of_celltype: celltype($celltype) can't be matched by regExp($regExp)"
    }
    if {$driveLevel == "05"} {set driveLevel 0.5}
    return $driveLevel
  }
}
proc get_driveCapacity_of_celltype_returnCapacityAndVTtype {{celltype ""} {regExp ".*X(\\d+).*(A\[HRL\]\\d+)$"}} {
  if {$celltype == "" || $celltype == "0x0" || ![sizeof_collection [get_lib_cells -q "*/$celltype"]]} { 
    return "0x0:1"; # check your input 
  } else {
    regexp $regExp $celltype wholename driveLevel VTtype 
    if {![info exists wholename]} { 
      error "proc get_driveCapacity_of_celltype_returnCapacityAndVTtype: celltype($celltype) can't be matched by regExp($regExp)"
    }
    if {$driveLevel == "05"} {set driveLevel 0.5}
    if {$VTtype == ""} {set VTtype "SVT"}
    return [list $driveLevel $VTtype]
  }
}
proc get_driveCapacityAndVTtype_of_celltype_spcifyingStdCellLib {{celltype ""} {process {M31GPSC900NL040P*_40N}}} {
  if {$celltype == "" || $celltype == "0x0" || ![sizeof_collection [get_lib_cells -q "*/$celltype"]]} { 
    error "proc get_driveCapacityAndVTtype_of_celltype_spcifyingStdCellLib: check your input: celltype($celltype) not found!!!"; # check your input 
  } else {
    if {$process == {M31GPSC900NL040P*_40N}} {
      set regExp {.*X(\d+).*(A[HRL]9)$}
    } 
    set ifError [catch {regexp $regExp $celltype wholename driveLevel VTtype} errInfo]
    if {$ifError || ![info exists wholename] || ![info exists driveLevel] || ![info exists VTtype]} {
      error "proc get_driveCapacityAndVTtype_of_celltype_spcifyingStdCellLib: check your regExp($regExp) can't match this celltype($celltype)" 
    }
    if {$process == {M31GPSC900NL040P*_40N} && $driveLevel == "05"} {set driveLevel 0.5}
    return [list $driveLevel $VTtype]
  }
}
