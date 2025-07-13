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
source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
proc strategy_changeDriveCapacity {{celltype ""} {changeStairs 1} {driveRange {1 16}} {regExp "D(\\d+)BWP.*CPD(U?L?H?VT)?"}} {
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
#puts "driveLevel : $driveLevel"
if {$driveLevel == "05"} {
  set driveLevelNum 0.5
} else {
  set driveLevelNum [expr int($driveLevel)]
}
      set toDrive 0
      set driveRangeRight [lsort -integer -increasing $driveRange]
      # simple version, provided fixed drive capacibility for 
      set toDrive_temp [expr int([expr $driveLevelNum * ($changeStairs * 2)])]
      set processType [whichProcess_fromStdCellPattern $celltype]
      if {$processType == "TSMC"} {
        regsub D$driveLevel $celltype D* searchCelltypeExp
      } elseif {$processType == "HH"} {
        regsub X$driveLevel $celltype X* searchCelltypeExp
      }
      set availableCelltypeList [dbget head.libCells.name $searchCelltypeExp]
      set availableDriveCapacityList [lmap celltype $availableCelltypeList {
        regexp $regExp $celltype wholename driveLevel VTtype
        if {$driveLevel == "05"} {continue} else { set driveLevel [expr int($driveLevel)]}
      }]
  #puts $availableDriveCapacityList
      if {$toDrive_temp <= 8} {
        set toDrive [find_nearest $availableDriveCapacityList $toDrive_temp 1]
      } else {
        set toDrive [find_nearest $availableDriveCapacityList $toDrive_temp 0]
      }
      if {$toDrive > [lindex $driveRangeRight end] || $toDrive < [lindex $driveRangeRight 0] } {
        return "0x0:3"; # toDrive is out of acceptable driveCapacity list ($driveRange)
      }
      if {[regexp BWP $celltype]} { ; # TSMC standard cell keyword
        regsub "D${driveLevel}BWP" $celltype "D${toDrive}BWP" toCelltype
        return $toCelltype
      } elseif {[regexp {.*X\d+.*A[RHL]\d+} $celltype]} { ; # M31 standard cell keyword
        regsub "X${driveLevel}" $celltype "X${toDrive}" toCelltype
        return $toCelltype
      }
    }
  }
}

#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Tue Jul  8 11:05:01 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> gui_proc   : for gui display, or effort can be viewed in invs GUI
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
# descrip   : find the nearest number from list, you can control which one of bigger or smaller
# ref       : link url
# --------------------------
proc find_nearest {{realList {}} number {returnBigOneFlag 1}} {
  set s [lsort -unique -increasing -real $realList]
  set idx [lsearch -exact $s $number]
  if {$idx != -1} {
    return $number ; # number is not equal every real digit of list
  }
  if {$number < [lindex $s 0] || $number > [lindex $s end]} {
    return "0x0:1"; # your number is not in the range of list
  }
  foreach i $s {
    set next_i [lindex $s [expr [lsearch $s $i] + 1]]
    if {$i < $number && $number < $next_i} {
      set lowerIdx [lsearch $s $i]
      break
    } 
  }
  set upperIdx [expr {$lowerIdx + 1}]
  return [lindex $s [expr {$returnBigOneFlag ? $upperIdx : $lowerIdx}]]
}
