#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:25 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|task_proc)
# descrip   : strategy of fixing transition: change drive capacibility of cell. ONLY one celltype
# ref       : link url
# --------------------------
source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
source ./proc_find_nearestNum_atIntegerList.invs.tcl; # find_nearestNum_atIntegerList
proc strategy_changeDriveCapacity {{celltype ""} {forceSpecifyDriveCapacibility 4} {changeStairs 1} {driveRange {1 16}} {regExp "D(\\d+)BWP.*CPD(U?L?H?VT)?"}} {
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
      set processType [whichProcess_fromStdCellPattern $celltype]
      set toDrive 0
      if {$forceSpecifyDriveCapacibility } {
        set toDrive $forceSpecifyDriveCapacibility
        if {$processType == "TSMC"} {
          regsub "D${driveLevel}BWP" $celltype "D${toDrive}BWP" toCelltype
          if {[dbget head.libCells.name $toCelltype -e] == ""} {
            return "0x0:4:"; # forceSpecifyDriveCapacibility: have no this celltype 
          } else {
            return $toCelltype
          }
        } elseif {$processType == "HH"} {
          regsub "X${driveLevel}" $celltype "X${toDrive}" toCelltype
          if {[dbget head.libCells.name $toCelltype -e] == ""} {
            return "0x0:4:"; # forceSpecifyDriveCapacibility: have no this celltype 
          } else {
            return $toCelltype
          }
        }
      }
      set driveRangeRight [lsort -integer -increasing $driveRange]
      # simple version, provided fixed drive capacibility for 
      set toDrive_temp [expr int([expr $driveLevelNum * ($changeStairs * 2)])]
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
        set toDrive [find_nearestNum_atIntegerList $availableDriveCapacityList $toDrive_temp 1]
      } else {
        set toDrive [find_nearestNum_atIntegerList $availableDriveCapacityList $toDrive_temp 0]
      }
      if {$toDrive > [lindex $driveRangeRight end] || $toDrive < [lindex $driveRangeRight 0] } {
        return "0x0:3"; # toDrive is out of acceptable driveCapacity list ($driveRange)
      }
      if {[regexp BWP $celltype]} { ; # TSMC standard cell keyword
        regsub "D${driveLevel}BWP" $celltype "D${toDrive}BWP" toCelltype
        return $toCelltype
      } elseif {[regexp {.*X\d+.*A[RHL]\d+} $celltype]} { ; # M31 standard cell keyword/ HH40
        regsub "X${driveLevel}" $celltype "X${toDrive}" toCelltype
        return $toCelltype
      }
    }
  }
}
