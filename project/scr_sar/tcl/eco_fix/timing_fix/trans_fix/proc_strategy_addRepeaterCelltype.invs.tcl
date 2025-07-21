#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/15 13:30:32 Tuesday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : strategy of fixing transition: add repeater cell to fix long net or weak drive capacity
# ref       : link url
# --------------------------
source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # proc: whichProcess_fromStdCellPattern
source ./proc_find_nearestNum_atIntegerList.invs.tcl; # find_nearestNum_atIntegerList list num big?
source ./proc_changeDriveCapacity_of_celltype.invs.tcl; # changeDriveCapacity_of_celltype
proc strategy_addRepeaterCelltype {{driverCelltype ""} {loaderCelltype ""} {method "refDriver|refLoader|auto"} {forceSpecifyDriveCapacibility 4} {driveRange {4 16}} {ifGetBigDriveNumInAvaialbeDriveCapacityList 1} {refType "BUFD4BWP6T16P96CPD"} {regExp "D(\\d+).*CPD(U?L?H?VT)?"} } {
  if {$driverCelltype == "" || $loaderCelltype == "" || [dbget top.insts.cell.name $driverCelltype -e] == "" || [dbget top.insts.cell.name $loaderCelltype -e] == ""} {
    error "proc strategy_addRepeaterCelltype: check your input !!!"; # check your input 
  } else {
    set runError0 [catch {regexp $regExp $refType wholeNameR levelNumR VTtypeR} errorInfoR]
    set runError1 [catch {regexp $regExp $driverCelltype wholeNameD levelNumD VTtypeD} errorInfoD]
    set runError2 [catch {regexp $regExp $loaderCelltype wholeNameL levelNumL VTtypeL} errorInfoL]
    if {$runError1 || $runError2 || ![info exists wholeNameR] || ![info exists wholeNameD] || ![info exists wholeNameL]} {
      error "proc strategy_addRepeaterCelltype: can't regexp"; # check regexp expression 
    } else {
      # check driveRange correction
      if {[llength $driveRange] == 2 && [expr {"[dbget head.libCells.name [changeDriveCapacity_of_celltype $refType $levelNumR [lindex $driveRange 0]] -e]" == "" || "[dbget head.libCells.name [changeDriveCapacity_of_celltype $refType $levelNumR [lindex $driveRange 1]] -e]" == ""}]} {
        error "proc strategy_addRepeaterCelltype: check your var driveRange , have no celltype in std cell library for min or max driveCapacity from driveRange"; # check your $driveRange , have no celltype in std cell library for min or max driveCapacity from driveRange 
      } elseif {[llength $driveRange] == 2} {
        set driveRangeRight [lsort -integer -increasing $driveRange] 
      }
      # if specify the value of drvie capacibility
      # force mode will ignore $driveRange
      if {$forceSpecifyDriveCapacibility} {
        set toCelltype [changeDriveCapacity_of_celltype $refType $levelNumR $forceSpecifyDriveCapacibility]
        if {[dbget head.libCells.name $toCelltype -e] == ""} {
          error "proc strategy_addRepeaterCelltype: force specified drive capacity is not valid: $forceSpecifyDriveCapacibility"; # forceSpecifyDriveCapacibility: toCelltype is not acceptable celltype in std cell libray
        } else {
          return $toCelltype
        }
      }
      # refDriver and refLoader have low priority
      set processType [whichProcess_fromStdCellPattern $refType]
      if {$processType == "TSMC"} {
        regsub D$levelNumR $refType D* searchCelltypeExp
      } elseif {$processType == "HH"} {
        regsub X$levelNumR $refType X* searchCelltypeExp
      }
      set availableCelltypeList [dbget head.libCells.name $searchCelltypeExp]
      set availableDriveCapacityIntegerList [lmap celltype $availableCelltypeList {
        regexp $regExp $celltype wholename driveLevel VTtype
        if {$driveLevel == "05"} {continue} else { set driveLevel [expr int($driveLevel)]}
      }]
      switch $method {
        "refDriver" {
          if {$levelNumD == "05"} {set levelNumD 0.5}; # fix situation that it has 0.5 drive capacity at HH40 process/ M31 std cell library
          set toDriveNum [find_nearestNum_atIntegerList $availableDriveCapacityIntegerList $levelNumD $ifGetBigDriveNumInAvaialbeDriveCapacityList 1]
          if {$toDriveNum <  [lindex $driveRangeRight 0]} {
            set toCelltype [changeDriveCapacity_of_celltype $refType $levelNumR [lindex $driveRangeRight 0]]
            return $toCelltype 
          } elseif {$toDriveNum > [lindex $driveRangeRight 1]} {
            set toCelltype [changeDriveCapacity_of_celltype $refType $levelNumR [lindex $driveRangeRight 1]]
            return $toCelltype 
          } else {
            set toCelltype [changeDriveCapacity_of_celltype $refType $levelNumR $toDriveNum]
            return $toCelltype 
          }
        } 
        "refLoader" {
          if {$levelNumL == "05"} {set levelNumD 0.5}; # fix situation that it has 0.5 drive capacity at HH40 process/ M31 std cell library
          set toDriveNum [find_nearestNum_atIntegerList $availableDriveCapacityIntegerList $levelNumL $ifGetBigDriveNumInAvaialbeDriveCapacityList 1]
          if {$toDriveNum <  [lindex $driveRangeRight 0]} {
            set toCelltype [changeDriveCapacity_of_celltype $refType $levelNumR [lindex $driveRangeRight 0]]
            return $toCelltype 
          } elseif {$toDriveNum > [lindex $driveRangeRight 1]} {
            set toCelltype [changeDriveCapacity_of_celltype $refType $levelNumR [lindex $driveRangeRight 1]]
            return $toCelltype 
          } else {
            set toCelltype [changeDriveCapacity_of_celltype $refType $levelNumR $toDriveNum]
            return $toCelltype 
          }
        }
        "auto" {
          # improve after
        }
      }
    }
  }
}
