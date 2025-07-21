#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:25 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|task_proc)
# descrip   : strategy of fixing transition: change drive capacibility of cell. ONLY one celltype
# update    : 2025/07/17 10:40:17 Thursday
#             add $ifClamp: if changedDriveCapacity is out of $driveRange, it can clamp it and return it 
# ref       : link url
# --------------------------
source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
source ./proc_find_nearestNum_atIntegerList.invs.tcl; # find_nearestNum_atIntegerList
proc strategy_changeDriveCapacity {{celltype ""} {forceSpecifyDriveCapacity 4} {changeStairs 1} {driveRange {1 16}} {regExp "D(\\d+)BWP.*CPD(U?L?H?VT)?"} {ifClamp 1} {debug 0}} {
  # $changeStairs : if it is 1, like : D2 -> D4, D4 -> D8
  #                 if it is 2, like : D1 - D4, D4 -> D16, D2 -> D8
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e ] == ""} {
    error "proc strategy_changeDriveCapacity: check your input!!!" 
  } else {
    #get now Drive Capacibility
    set runError [catch {regexp $regExp $celltype wholename driveLevel VTtype} errorInfo]
    if {$runError || $wholename == ""} {
      error "proc strategy_changeDriveCapacity: can't regexp!!!" 
    } else {
      #puts "driveLevel : $driveLevel"
      if {$driveLevel == "05"} { ; # M31 std cell library have X05(0.5) driveCapacity
        set driveLevelNum 0.5
      } else {
        set driveLevelNum [expr int($driveLevel)]
      }
      set processType [whichProcess_fromStdCellPattern $celltype]
      set toDrive 0
      if {$forceSpecifyDriveCapacity } {
        set toDrive $forceSpecifyDriveCapacity
        if {$processType == "TSMC"} {
          regsub "D${driveLevel}BWP" $celltype "D${toDrive}BWP" toCelltype
          if {[dbget head.libCells.name $toCelltype -e] == ""} {
            return "0x0:4"; # forceSpecifyDriveCapacity: have no this celltype 
          } else {
            return $toCelltype
          }
        } elseif {$processType == "HH"} {
          regsub [subst {(.*)X${driveLevel}}] $celltype [subst {\\1X${toDrive}}] toCelltype
          if {[dbget head.libCells.name $toCelltype -e] == ""} {
            return $celltype ; # songNOTE: temp!!!
            return "0x0:4"; # forceSpecifyDriveCapacity: have no this celltype 
          } else {
            return $toCelltype
          }
        }
      }
      set ifHaveRangeFlag 1
      if {![llength $driveRange]} {
        set ifHaveRangeFlag 0
      } else {
        set driveRangeRight [lsort -integer -increasing $driveRange]
      }
      # simple version, provided fixed drive capacibility for 
      set toDrive_temp [expr $driveLevelNum * ($changeStairs * 2)]
if {$debug} { puts "strategy_changeDriveCapacity : celltype : $celltype  driveLevelNum : $driveLevelNum stairs : $changeStairs toDrive_tmp : $toDrive_temp" }
      if {$processType == "TSMC"} {
        regsub D${driveLevel}BWP $celltype D*BWP searchCelltypeExp
      } elseif {$processType == "HH"} {
        regsub [subst {(.*)X$driveLevel}] $celltype [subst {\\1X*}] searchCelltypeExp
      }
      set availableCelltypeList [dbget head.libCells.name $searchCelltypeExp]
      set availableDriveCapacityList [lmap Acelltype $availableCelltypeList {
        regexp $regExp $Acelltype wholename AdriveLevel AVTtype
        if {$AdriveLevel == "05"} {set AdriveLevel 0.5} else { set AdriveLevel}
      }]
  #puts $availableDriveCapacityList
      if {$toDrive_temp <= 8} {
        set toDrive [find_nearestNum_atIntegerList $availableDriveCapacityList $toDrive_temp 1 1]
      } else {
        set toDrive [find_nearestNum_atIntegerList $availableDriveCapacityList $toDrive_temp 0 1]
      }
if {$debug} { puts "strategy_changeDriveCapacity2 : toDrive : $toDrive" }

      # legealize edge of $driveRange
      if {$ifHaveRangeFlag} {
        set maxAvailableDriveOnRange [find_nearestNum_atIntegerList $availableDriveCapacityList [lindex $driveRangeRight 1] 0 1]
        set minAvailableDriveOnRnage [find_nearestNum_atIntegerList $availableDriveCapacityList [lindex $driveRangeRight 0] 1 1]
      } else {
        return "0x0:5"; # please input valid driveRange ; TODO: you can imporve this case
      }
if {$debug} { puts "- > $minAvailableDriveOnRnage $maxAvailableDriveOnRange" }
      if {$ifClamp && $toDrive > $maxAvailableDriveOnRange} {
        set toDrive $maxAvailableDriveOnRange
      } elseif {$ifClamp && $toDrive < $minAvailableDriveOnRnage} {
        set toDrive $minAvailableDriveOnRnage
      } elseif {[expr !$ifClamp && $toDrive > $maxAvailableDriveOnRange] || [expr !$ifClamp && $toDrive < $minAvailableDriveOnRnage]} {
        return "0x0:3"; # toDrive is out of acceptable driveCapacity list ($driveRange)
      }
      if {[regexp BWP $celltype]} { ; # TSMC standard cell keyword
        regsub "D${driveLevel}BWP" $celltype "D${toDrive}BWP" toCelltype
        return $toCelltype
      } elseif {[regexp {.*X\d+.*A[RHL]\d+} $celltype]} { ; # M31 standard cell keyword/ HH40
        if {$toDrive == 0.5} {set toDrive "05"}
        regsub [subst {(.*)X${driveLevel}}] $celltype [subst {\\1X${toDrive}}] toCelltype
        return $toCelltype
      }
    }
  }
}
