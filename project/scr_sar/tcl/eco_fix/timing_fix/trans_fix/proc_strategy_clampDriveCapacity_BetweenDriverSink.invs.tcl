#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/21 20:52:47 Monday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : 
# ref       : link url
# --------------------------
source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
source ./proc_find_nearestNum_atIntegerList.invs.tcl; # find_nearestNum_atIntegerList
source ./proc_changeDriveCapacity_of_celltype.invs.tcl; # changeDriveCapacity_of_celltype
proc strategy_clampDriveCapacity_BetweenDriverSink {{driverCelltype ""} {sinkCelltype ""} {toCheckCelltype ""} {regExp "D(\\d+)BWP.*CPD(U?L?H?VT)?"} {refDriverOrSink "refSink"} {maxExcessRatio 0.5}} {
  if {$driverCelltype == "" || [dbget head.libCells.name $driverCelltype -e] == "" || $sinkCelltype == "" || [dbget head.libCells.name $sinkCelltype -e] == "" || $toCheckCelltype == "" || [dbget head.libCells.name $toCheckCelltype -e] == ""} {
    error "proc strategy_clampDriveCapacity_BetweenDriverSink: check your input!!!"
  } else {
    set runError1 [catch {regexp $regExp $driverCelltype wholename1 driveLevel1 VTtype} errorInfo]
    set runError2 [catch {regexp $regExp $sinkCelltype wholename2 driveLevel2 VTtype} errorInfo]
    set runError3 [catch {regexp $regExp $toCheckCelltype wholename3 driveLevel3 VTtype} errorInfo]
    if {$runError1 || $runError2 || $runError3 || ![info exists wholename1] || ![info exists wholename2] || ![info exists wholename3]} {
      error "proc strategy_clampDriveCapacity_BetweenDriverSink: can't regexp!!!"
    } else {
      if {$driveLevel1 == "05"} { set driveLevel1 0.5 } else { set driveLevel1 [expr int($driveLevel)] }
      if {$driveLevel2 == "05"} { set driveLevel2 0.5 } else { set driveLevel2 [expr int($driveLevel)] }
      if {$driveLevel3 == "05"} { set driveLevel3 0.5 } else { set driveLevel3 [expr int($driveLevel)] }
      
      if {$refDriverOrSink == "refDriver"} {
        set rawResultDrive [lindex [lsort -increasing -real [concat [expr $driveLevel1 * (1 + $maxExcessRatio)] $driveLevel3]] 0] ; # get min Drive, and is result raw drive capacity
      } elseif {$refDriverOrSink == "refSink"} {
        set rawResultDrive [lindex [lsort -increasing -real [concat [expr $driveLevel2 * (1 + $maxExcessRatio)] $driveLevel3]] 0] ; # get min Drive, and is result raw drive capacity
      } elseif {$refDriverOrSink == "autoBig"} {
        lassign [lsort -increasing -real [concat $driveLevel1 $driveLevel2]] minDrive maxDrive
        set rawResultDrive [lindex [lsort -increasing -real [concat [expr $maxDrive * (1 + $maxExcessRatio)] $driveLevel3]] 0] ; # get min Drive, and is result raw drive capacity
      } elseif {$refDriverOrSink == "autoSmall"} {
        lassign [lsort -increasing -real [concat $driveLevel1 $driveLevel2]] minDrive maxDrive
        set rawResultDrive [lindex [lsort -increasing -real [concat [expr $minDrive * (1 + $maxExcessRatio)] $driveLevel3]] 0] ; # get min Drive, and is result raw drive capacity
      } else {
        error "check your input!!! var refDriverOrSink can specify: refSink|refDriver|autoBig|autoSmall"
      }
      set processType [whichProcess_fromStdCellPattern $toCheckCelltype]
      if {$processType == "TSMC"} {
        regsub D${driveLevel}BWP $celltype D*BWP searchCelltypeExp
      } elseif {$processType == "HH"} {
        regsub [subst {(.*)X$driveLevel}] $celltype [subst {\\1X*}] searchCelltypeExp
      }
      set availableCelltypeList [dbget head.libCells.name $searchCelltypeExp]
      set availableDriveCapacityList [lsort -unique [lmap Acelltype $availableCelltypeList {
        regexp $regExp $Acelltype wholename AdriveLevel AVTtype
        if {$AdriveLevel == "05"} {set AdriveLevel 0.5} else { set AdriveLevel}
      }]]
      # make drive capacity to valid
      set resultDrive [find_nearestNum_atIntegerList $availableDriveCapacityList $rawResultDrive 0 1] ; # always get min value(valid)
      return [changeDriveCapacity_of_celltype $toCheckCelltype $driveLevel3 $resultDrive]
    }
  }
}
