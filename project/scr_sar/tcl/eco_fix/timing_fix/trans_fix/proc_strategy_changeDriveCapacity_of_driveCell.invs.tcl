#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:25 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|task_proc)
# descrip   : strategy of fixing transition: change drive capacibility of cell. ONLY one celltype
# update    : 2025/07/17 10:40:17 Thursday
#             add $ifClamp: if changedDriveCapacity is out of $driveRange, it can clamp it and return it 
# update    : 2025/08/13 19:24:48 Wednesday
#             (U001) Adapt the information acquisition method of the lookup table: ../lut_build/operateLUT.tcl and ../lut_build/build_sar_LUT_usingDICT.tcl
#             you can get capacity type from lutDict that is built before you run this proc, it can reduce errors and the time of debugging.
#             (U002) To be compatible with the original fix_trans.invs.tcl and other scripts that call this proc, this update needs to 
#             adopt an incremental update method by renaming the proc. The original proc name will remain, and a new proc name will be 
#             added to achieve the same function. However, the internal information calling method has changed, which is more efficient 
#             and faster compared to the previous method of obtaining information for the proc.
# update    : 2025/08/13 19:53:24 Wednesday
#             (U003) add mapList to from original capacity to specified capacity by user at the beginning which is can be saved in variable. it is more flexible.
#             if have mapList, it will ignore the restriction of driveRange!!
# ref       : link url
# --------------------------
source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
source ./proc_find_nearestNum_atIntegerList.invs.tcl; # find_nearestNum_atIntegerList
source ../lut_build/operateLUT.tcl; # operateLUT
alias sus "subst -nocommands -nobackslashes"
proc strategy_changeDriveCapacity_withLUT {{celltype ""} {forceSpecifyDriveCapacity 4} {mapList {{0.5 2} {1 4} {2 4} {4 8} {8 12}}} {ifStrictCheckForMapList 0} {ifAutoSelectBiggerWhenNotMatch 1} {changeStairs 1} {driveRange {1 12}} {ifClamp 1} {debug 0}} {
  # $changeStairs : if it is 1, like : D2 -> D4, D4 -> D8
  #                 if it is 2, like : D1 - D4, D4 -> D16, D2 -> D8
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e ] == ""} {
    error "proc strategy_changeDriveCapacity: check your input!!!" 
  } else {
    #get now Drive Capacibility
    set driveLevel [operateLUT -type read -attr [list celltype $celltype capacity]]
    #puts "driveLevel : $driveLevel"
    set processType [operateLUT -type read -attr {process}]
    set toDrive 0
    set availableDriveCapacityList [operateLUT -type read -attr [list celltype $celltype caplist]]
    set capacityFlag [operateLUT -type read -attr {capacityflag}]
    set stdCellFlag [operateLUT -type read -attr {stdcellflag}]
    if {$forceSpecifyDriveCapacity } {
      if {$forceSpecifyDriveCapacity ni $availableDriveCapacityList} {
        error "proc strategy_changeDriveCapacity_withLUT: error operation, the \$forceSpecifyDriveCapacity($forceSpecifyDriveCapacity) is not valid which is not found in available capacity list($availableDriveCapacityList)!!!" 
      }
      set toDrive $forceSpecifyDriveCapacity
      if {$processType == "M31GPSC900NL040P*_40N" && $driveLevel 0.5} {set driveLevel 05}
      regsub [sus {^(.*$capacityFlag)${driveLevel}($stdCellFlag.*)$}] $celltype [sus {\1$toDrive\2}] toCelltype
      if {[operateLUT -type exists -attr [list celltype $toCelltype]]} {
        error "proc strategy_changeDriveCapacity_withLUT: fixed celltype($toCelltype) is not found in std cell lib!!! check it (forceSpecifyDriveCapacity mode)" 
      } else {
        return $toCelltype 
      }
    } elseif {[llength $mapList]} {
      # check validation
      set fromCapacityList [lmap fromtemp $mapList { lindex $fromtemp 0 }]
      set toCapacityList [lmap totemp $mapList { lindex $totemp 1 }]
      set ifValidMapList [every x [concat $fromCapacityList $toCapacityList] { expr {$x in $availableDriveCapacityList} }]
      set ifHaveDuplicateItems [any x $fromCapacityList { expr {[llength [lsearch -all -index 0 $mapList $x]] > 1} }]
      if {!$ifValidMapList && $ifStrictCheckForMapList} {
        error "proc strategy_changeDriveCapacity_withLUT: check your input: mapList($mapList) has invalid item!!! double check it!!!"
      } elseif {$ifHaveDuplicateItems} {
        error "proc strategy_changeDriveCapacity_withLUT: check your input: mapList($mapList) has duplicate items!!! double check it!!!"
      } else {
        set toCapacityMatched [lindex [lsearch -index 0 -inline $mapList $driveLevel] 1]
        set ifInToCapacityList [lsearch -inline $toCapacityList $toCapacityMatched]
        if {$ifInToCapacityList == "" && $ifAutoSelectBiggerWhenNotMatch} {
          set toCapacityMatched [find_nearestNum_atIntegerList $availableDriveCapacityList $toCapacityMatched 1 1]
        } elseif {$ifInToCapacityList == "" && !$ifAutoSelectBiggerWhenNotMatch} {
          set toCapacityMatched [find_nearestNum_atIntegerList $availableDriveCapacityList $toCapacityMatched 0 1]
        }
        regsub [sus {^(.*$capacityFlag)${driveLevel}($stdCellFlag.*)$}] $celltype [sus {\1$toCapacityMatched\2}] toCelltype
        if {![operateLUT -type exists -attr [list celltype $toCelltype]]} {
          error "proc strategy_changeDriveCapacity_withLUT: fixed celltype($toCelltype) is not found in std cell lib!!! check it (mapList mode)" 
        } else {
          return $toCelltype 
        }
      }
    }
    if {![llength $driveRange]} {
      error "proc strategy_changeDriveCapacity_withLUT: check your input: \$driveRange is empty!!!"
    } else {
      set driveRangeRight [lsort -integer -increasing $driveRange]
    }
    # simple version, provided fixed drive capacibility for 
    set toDrive_temp [expr $driveLevel * ($changeStairs * 2)]
if {$debug} { puts "strategy_changeDriveCapacity : celltype : $celltype  driveLevel : $driveLevel stairs : $changeStairs toDrive_tmp : $toDrive_temp" }
    if {$toDrive_temp <= 8} {
      set toDrive [find_nearestNum_atIntegerList $availableDriveCapacityList $toDrive_temp 1 1]
    } else {
      set toDrive [find_nearestNum_atIntegerList $availableDriveCapacityList $toDrive_temp 0 1]
    }
if {$debug} { puts "strategy_changeDriveCapacity2 : toDrive : $toDrive" }

    # legealize edge of $driveRange
    set maxAvailableDriveOnRange [find_nearestNum_atIntegerList $availableDriveCapacityList [lindex $driveRangeRight 1] 0 1]
    set minAvailableDriveOnRnage [find_nearestNum_atIntegerList $availableDriveCapacityList [lindex $driveRangeRight 0] 1 1]
if {$debug} { puts "- > $minAvailableDriveOnRnage $maxAvailableDriveOnRange" }
    if {$ifClamp && $toDrive > $maxAvailableDriveOnRange} {
      set toDrive $maxAvailableDriveOnRange
    } elseif {$ifClamp && $toDrive < $minAvailableDriveOnRnage} {
      set toDrive $minAvailableDriveOnRnage
    } elseif {[expr !$ifClamp && $toDrive > $maxAvailableDriveOnRange] || [expr !$ifClamp && $toDrive < $minAvailableDriveOnRnage]} {
      error "proc strategy_changeDriveCapacity_withLUT: error internal of proc, fixed celltype is out of acceptable driveCapacity list($driveRangeRight)"; # toDrive is out of acceptable driveCapacity list ($driveRange)
    }
    if {$processType == "M31GPSC900NL040P*_40N" && $driveLevel 0.5} {set driveLevel 05}
    regsub [sus {^(.*$capacityFlag)${driveLevel}($stdCellFlag.*)$}] $celltype [sus {\1$toDrive\2}] toCelltype
    if {[operateLUT -type exists -attr [list celltype $toCelltype]]} {
      error "proc strategy_changeDriveCapacity_withLUT: fixed celltype($toCelltype) is not found in std cell lib!!! check it (non forceSpecifyDriveCapacity mode)" 
    } else {
      return $toCelltype 
    }
  }
}


# U002: This proc has been abandoned and will no longer be updated
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
