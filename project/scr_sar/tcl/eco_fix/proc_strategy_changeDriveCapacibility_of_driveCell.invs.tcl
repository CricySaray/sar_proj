#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:25 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|task_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, focusing on data display and aesthetics
#   -> task_proc  : composed of multiple atomic_proc s, focus on logical integrity, process control, error recovery, and the output of files and reports when solving problems.
# descrip   : strategy of fixing transition: change drive capacibility of cell. ONLY one celltype
# ref       : link url
# --------------------------
proc strategy_changeDriveCapacibility {{celltype ""} {regExp "D(\\d+).*CPD(U?L?H?VT)?"} {driveRange {1 16}} {changeStairs 1}} {
  # $changeStairs : if it is 1, like : D2 -> D4, D4 -> D8
  #                 if it is 2, like : D1 - D4, D4 -> D16, D2 -> D8
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e ] == ""} {
    return "0x0:1" 
  } else {
    #get now Drive Capacibility
    set runError [catch {regexp $regExp $celltype wholename driveLevel VTtype} errorInfo]
    if {$runError || $wholename == ""} {
      return "0x0:2" 
    } else {
      set toDrive 0
      set driveRangeRight [lsort -integer -increasing $driveRange]
      if {$driveLevel < [lindex $driveRangeRight 0] || $driveLevel > [lindex $driveRangeRight 1]} {
        return "0x0:3"; # out of driveRange, not to change Drive Capcibility 
      } else { ; # simple version, provided fixed drive capacibility for 
        set toDrive [expr $driveLevel * ($changeStairs * 2)]
        regsub "D$driveLevel" $celltype "D$toDrive" toCelltype
        return $toCelltype
      }
    }
  }
}
