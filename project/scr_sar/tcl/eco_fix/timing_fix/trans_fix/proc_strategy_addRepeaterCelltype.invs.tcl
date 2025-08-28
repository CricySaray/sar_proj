#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/15 13:30:32 Tuesday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : strategy of fixing transition: add repeater cell to fix long net or weak drive capacity
# update    : 2025/08/13 22:28:23 Wednesday
#             (U001) Adapt the information acquisition method of the lookup table: ../lut_build/operateLUT.tcl and ../lut_build/build_sar_LUT_usingDICT.tcl
#             you can get vt type from lutDict that is built before you run this proc, it can reduce errors and the time of debugging.
#             (U002) To be compatible with the original fix_trans.invs.tcl and other scripts that call this proc, this update needs to 
#             adopt an incremental update method by renaming the proc. The original proc name will remain, and a new proc name will be 
#             added to achieve the same function. However, the internal information calling method has changed, which is more efficient 
#             and faster compared to the previous method of obtaining information for the proc.
# TODO      : U003: add option: addRepeaterMapList
# ref       : link url
# --------------------------
source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # proc: whichProcess_fromStdCellPattern
source ./proc_find_nearestNum_atIntegerList.invs.tcl; # find_nearestNum_atIntegerList list num big?
source ./proc_changeDriveCapacity_of_celltype.invs.tcl; # changeDriveCapacity_of_celltype
proc strategy_addRepeaterCelltype_withLUT {{driverCelltype ""} {sinkCelltype ""} {method "refDriver|refSink|auto"} {forceSpecifyDriveCapacibility 4} {driveRange {2 16}} {ifCheckDriveRangeCorrection 0} {ifGetBigDriveNumInAvaialbeDriveCapacityList 1} {refType "BUFD4BWP6T16P96CPD"}} {
  if {$driverCelltype == "" || $sinkCelltype == "" || ![operateLUT -type exists -attr [list celltype $driverCelltype]] || ![operateLUT -type exists -attr [list celltype $sinkCelltype]]} {
    error "proc strategy_addRepeaterCelltype: check your input : driverCelltype($driverCelltype) or sinkCelltype($sinkCelltype) not found!!!"; # check your input 
  } else {
    set levelNumR [operateLUT -type read -attr [list celltype $refType capacity]]
    set levelNumD [operateLUT -type read -attr [list celltype $driverCelltype capacity]]
    set levelNumS [operateLUT -type read -attr [list celltype $sinkCelltype capacity]]
    set VTtypeR [operateLUT -type read -attr [list celltype $refType vt]]
    set VTtypeD [operateLUT -type read -attr [list celltype $driverCelltype vt]]
    set VTtypeS [operateLUT -type read -attr [list celltype $sinkCelltype vt]]
    set availableDriveCapacityIntegerList [operateLUT -type read -attr [list celltype $refType caplist]]
    # check driveRange correction
    if {$ifCheckDriveRangeCorrection && [expr {![llength $driveRange] == 2 || ![every x $driveRange { expr {$x in $availableDriveCapacityIntegerList} }]}]} {
      error "proc strategy_addRepeaterCelltype: check your var driveRange , have no celltype in std cell library for min or max driveCapacity from driveRange"; # check your $driveRange , have no celltype in std cell library for min or max driveCapacity from driveRange 
    } elseif {[llength $driveRange] == 2} {
      set driveRangeRight [lsort -integer -increasing $driveRange] 
      lassign $driveRangeRight minDrive maxDrive
      set validMinDrive [find_nearestNum_atIntegerList $availableDriveCapacityIntegerList $minDrive 0 1]
      set validMaxDrive [find_nearestNum_atIntegerList $availableDriveCapacityIntegerList $maxDrive 1 1]
      set driveRangeRight [list $validMinDrive $validMaxDrive]
    }
    # if specify the value of drvie capacibility
    # force mode will ignore $driveRange
    if {$forceSpecifyDriveCapacibility} {
      set toCelltype [changeDriveCapacity_of_celltype $refType $levelNumR $forceSpecifyDriveCapacibility]
      if {![operateLUT -type exists -attr [list celltype $toCelltype]]} {
        error "proc strategy_addRepeaterCelltype: force specified drive capacity is not valid: $forceSpecifyDriveCapacibility"; # forceSpecifyDriveCapacibility: toCelltype is not acceptable celltype in std cell libray
      } else {
        return $toCelltype
      }
    }
    # refDriver and refSink have low priority
    set processType [operateLUT -type read -attr {process}]
    set availableDriveCapacityIntegerList [operateLUT -type read -attr [list celltype $refType caplist]]
    switch $method {
      "refDriver" {
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
      "refSink" {
        set toDriveNum [find_nearestNum_atIntegerList $availableDriveCapacityIntegerList $levelNumS $ifGetBigDriveNumInAvaialbeDriveCapacityList 1]
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

# U002: This proc has been abandoned and will no longer be updated
proc strategy_addRepeaterCelltype {{driverCelltype ""} {sinkCelltype ""} {method "refDriver|refLoader|auto"} {forceSpecifyDriveCapacibility 4} {driveRange {4 16}} {ifGetBigDriveNumInAvaialbeDriveCapacityList 1} {refType "BUFD4BWP6T16P96CPD"} {regExp "D(\\d+).*CPD(U?L?H?VT)?"} } {
  if {$driverCelltype == "" || $sinkCelltype == "" || [dbget top.insts.cell.name $driverCelltype -e] == "" || [dbget top.insts.cell.name $sinkCelltype -e] == ""} {
    error "proc strategy_addRepeaterCelltype: check your input !!!"; # check your input 
  } else {
    set runError0 [catch {regexp $regExp $refType wholeNameR levelNumR VTtypeR} errorInfoR]
    set runError1 [catch {regexp $regExp $driverCelltype wholeNameD levelNumD VTtypeD} errorInfoD]
    set runError2 [catch {regexp $regExp $sinkCelltype wholeNameL levelNumS VTtypeS} errorInfoL]
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
          if {$levelNumS == "05"} {set levelNumD 0.5}; # fix situation that it has 0.5 drive capacity at HH40 process/ M31 std cell library
          set toDriveNum [find_nearestNum_atIntegerList $availableDriveCapacityIntegerList $levelNumS $ifGetBigDriveNumInAvaialbeDriveCapacityList 1]
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
