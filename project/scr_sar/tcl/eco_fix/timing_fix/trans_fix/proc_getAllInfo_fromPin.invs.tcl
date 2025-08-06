#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/03 21:05:46 Sunday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|misc_proc)
# descrip   : get $all information from only pin name in innovus
# update    : 2025/08/06 23:25:16 Wednesday
#             (U001) improve method to judge if the one2more situation is loopped 
# mini descrip: driverPin/sinksPin/driverCellClass/sinksCellClass/netName/netLen/driverInstname/sinksInstname/
#               driverCellType/sinksCellType/driverCapacity/sinksCapacity/driverVTtype/sinksVTtype/driverPinPT/
#               sinksPinPT/numSinks/shortenedSinksCellClassRaw/simplizedSinksCellClass/shortenedSinksCellClassSimplized/
#               uniqueSinksCellClass/mostFrequentInSinksCellClass/numOfMostFrequentInSinksCellClass/centerPtOfSinksPinPT/
#               distanceOfDriver2CenterOfSinksPinPt/ifLoop/ifOne2One/ifSimpleOne2More/driverSinksSymbol/ifHaveBeenFastestVTinRange/
#               ifHaveBeenLargestCapacityInRange
# return    : dict variable
# ref       : link url
# --------------------------
source ./proc_get_cell_class.invs.tcl; # get_cell_class
source ./proc_get_fanoutNum_and_inputTermsName_of_pin.invs.tcl; # get_driverPin | get_sinkPins
source ./proc_get_net_lenth.invs.tcl; # get_net_length
source ./proc_getDriveCapacity_ofCelltype.pt.tcl; # get_driveCapacity_of_celltype
source ./proc_get_VTtype_of_celltype.invs.tcl; # get_VTtype_of_celltype
source ./proc_getPt_ofObj.invs.tcl; # gpt
source ./proc_findMostFrequentElementOfList.invs.tcl; # findMostFrequentElement
source ./proc_calculateResistantCenter.invs.tcl; # calculateResistantCenter_fromPoints
source ./proc_calculateDistance_betweenTwoPoint.invs.tcl; # calculateDistance
source ./proc_checkRoutingLoop.invs.tcl; # checkRoutingLoop
source ./proc_judgeIfLoop_forOne2More.invs.tcl; # judgeIfLoop_forOne2More

proc get_allInfo_fromPin {{pinname ""} {forbidenVT {AH9}} {driveCapacityRange {1 12}}} {
  if {$pinname == "" || $pinname == "0x0" || [dbget top.insts.instTerms.name $pinname -e] == ""} {
    error "proc [regsub ":" [lindex [info level 0] 0] ""]: check your input: pinname($pinname) is incorrect!!!"
  } else {
    set allInfo [dict create ]
    dict set allInfo driverPin [get_driverPin $pinname]
    dict set allInfo sinksPin [get_sinkPins $pinname]
    dict set allInfo driverCellClass [get_cell_class [dict get $allInfo driverPin]]
    dict set allInfo sinksCellClass [lmap sinkpin [dict get $allInfo sinksPin] { get_cell_class $sinkpin }]
    dict set allInfo netName [get_object_name [get_nets -of $pinname]]
    dict set allInfo netLen [get_net_length [dict get $allInfo netName]]
    dict set allInfo driverInstname [dbget [dbget top.insts.instTerms.name [dict get $allInfo driverPin] -p2].name]
    dict set allInfo sinksInstname [lmap sinkpin [dict get $allInfo sinksPin] { dbget [dbget top.insts.instTerms.name $sinkpin -p2].name }]
    dict set allInfo driverCellType [dbget [dbget top.insts.instTerms.name [dict get $allInfo driverPin] -p2].cell.name]
    dict set allInfo sinksCellType [lmap sinkpin [dict get $allInfo sinksPin] { dbget [dbget top.insts.instTerms.name $sinkpin -p2].cell.name }]
    dict set allInfo driverCapacity [get_driveCapacity_of_celltype [dict get $allInfo driverCellType]]
    dict set allInfo sinksCapacity [lmap sinkcelltype [dict get $allInfo sinksCellType] { get_driveCapacity_of_celltype $sinkcelltype }]
    dict set allInfo driverVTtype [get_VTtype_of_celltype [dict get $allInfo driverCellType]]
    dict set allInfo sinksVTtype [lmap sinkcelltype [dict get $allInfo sinksCellType] { get_VTtype_of_celltype $sinkcelltype }]
    dict set allInfo driverPinPT [gpt [dict get $allInfo driverPin]]
    dict set allInfo sinksPinPT [lmap sinkpin [dict get $allInfo sinksPin] { gpt $sinkpin }]

    dict set allInfo numSinks [llength [dict get $allInfo sinksPin]]
    dict set allInfo shortenedSinksCellClassRaw [shortenCellClass [dict get $allInfo sinksCellClass]] 
    dict set allInfo simplizedSinksCellClass [simplizeCellClass [dict get $allInfo sinksCellClass]]
    dict set allInfo shortenedSinksCellClassSimplized [shortenCellClass [dict get $allInfo simplizedSinksCellClass]]
    dict set allInfo uniqueSinksCellClass [lsort -unique [dict get $allInfo sinksCellClass] ]
    dict set allInfo mostFrequentInSinksCellClass [findMostFrequentElement [dict get $allInfo simplizedSinksCellClass]]
    dict set allInfo numOfMostFrequentInSinksCellClass [llength [dict get $allInfo mostFrequentInSinksCellClass]]

    dict set allInfo centerPtOfSinksPinPT [format "%.3f %.3f" {*}[calculateResistantCenter_fromPoints [dict get $allInfo sinksPinPT]]]
    dict set allInfo distanceOfDriver2CenterOfSinksPinPt [format "%.3f" [calculateDistance [dict get $allInfo driverPinPT] [dict get $allInfo centerPtOfSinksPinPT]]]
    if {[dict get $allInfo numSinks] == 1} {
      set resultOfCheckRoutingLoop [checkRoutingLoop [dict get $allInfo distanceOfDriver2CenterOfSinksPinPt] [dict get $allInfo netLen] "normal"]
    } elseif {[dict get $allInfo numSinks] > 1} {
      set resultOfCheckRoutingLoop [lindex [judgeIfLoop_forOne2More [dict get $allInfo driverPinPT] [dict get $allInfo sinksPinPT] [dict get $allInfo netLen] 16] 0] ; # U001
    }
    dict set allInfo ifLoop [switch $resultOfCheckRoutingLoop {
      0 {set result "noLoop"}
      1 {set result "mild"}
      2 {set result "moderate"}
      3 {set result "severe"}
    }]
    
    dict set allInfo ifOne2One [expr ([dict get $allInfo numSinks] == 1) ? 1 : 0]
    dict set allInfo ifSimpleOne2More [expr ([dict get $allInfo numOfMostFrequentInSinksCellClass] == 1) ? 1 : 0]
    dict set allInfo driverSinksSymbol [zipCellClass [dict get $allInfo driverCellClass] [dict get $allInfo mostFrequentInSinksCellClass]]

    dict set allInfo ifHaveBeenFastestVTinRange [judge_ifHaveBeenFastVTinRange [dict get $allInfo driverCellType] $forbidenVT]
    dict set allInfo ifHaveBeenLargestCapacityInRange [judge_ifHaveBeenLargestCapacityInRange [dict get $allInfo driverCellType] $driveCapacityRange]
    return $allInfo
  }
}
proc simplizeCellClass {{sinksCellClass {}}} {
  set simplized [lmap sinkcellclass $sinksCellClass {
    if {$sinkcellclass in {logic delay CLKlogic}} {
      set t "logic"
    } elseif {$sinkcellclass in {buffer inverter CLKbuffer CLKinverter}} {
      set t "buffer"
    } elseif {$sinkcellclass in {sequential}} {
      set t "sequential"
    }
    set t
  }]
  return $simplized
}
proc shortenCellClass {{sinksCellClass {}}} { ; # return a string like "b/i/l/f/s/N"
  set shortened [lmap sinkcellclass $sinksCellClass {
    switch $sinkcellclass {
      "buffer"      {set t "b"}
      "inverter"    {set t "v"}
      "logic"       {set t "l"}
      "CLKbuffer"   {set t "f"}
      "CLKinverter" {set t "n"}
      "CLKlogic"    {set t "o"}
      "delay"       {set t "d"}
      "sequential"  {set t "s"}
      "memory"      {set t "m"}
      "IP"          {set t "P"}
      "IOpad"       {set t "p"}
      default       {set t "N"}
    }
    set t
  }]

  return [join [lsort -unique $shortened] "/"]
}
proc zipCellClass {driverCellClass mostFrequentInSinksCellClass} {
  set shortenedDriverCellClass [shortenCellClass [simplizeCellClass $driverCellClass]]
  set shortenedSinksCellClass [shortenCellClass $mostFrequentInSinksCellClass]
  return [append shortenedDriverCellClass $shortenedSinksCellClass]
}

source ../../../packages/andnot_ofList.package.tcl; # andnot
source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
source ./proc_get_VTtype_of_celltype.invs.tcl; # get_VTtype_of_celltype
proc judge_ifHaveBeenFastVTinRange {{celltype ""} {forbidenVT {AH9}}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e] == "" || [whichProcess_fromStdCellPattern $celltype] == "other"} {
    error "proc judge_ifHaveBeenFastVTinRange: check your input: celltype($celltype) not valid !!!" 
  } else {
    set process [whichProcess_fromStdCellPattern $celltype] 
    if {$process == "TSMC"} {
      set VTrange {HVT SVT LVT ULVT}
    } elseif {$process == "HH"} {
      set VTrange {AL9 AR9 AH9}
    }
    if {$forbidenVT != "" && [every x $forbidenVT { expr { $x ni $VTrange }} ]} { error "proc judge_ifHaveBeenFastVTinRange: forbidenVT($forbidenVT) is not in VTrange($VTrange)!!!" }
    set nowVT [get_VTtype_of_celltype $celltype]
    set availableVTrange [andnot $VTrange $forbidenVT]
    if {[lsearch -exact $availableVTrange $nowVT] != 0} { return 0 } else { return 1 }
  }
}
source proc_getDriveCapacity_ofCelltype.invs.tcl; # get_driveCapacity_of_celltype
source ../../../packages/filter_numberList.package.tcl; # filter_numberList
proc judge_ifHaveBeenLargestCapacityInRange {{celltype ""} {driveCapacityRange {1 12}}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e] == "" || [whichProcess_fromStdCellPattern $celltype] == "other"} {
    error "proc judge_ifHaveBeenLargestCapacityInRange: check your input: celltype($celltype) not valid !!!" 
  } else {
    set process [whichProcess_fromStdCellPattern $celltype] 
    if {$process == "TSMC"} {
      set regExp "D(\\d+).*CPD(U?L?H?VT)?"
      set nowCapacity [get_driveCapacity_of_celltype $celltype $regExp]
      regsub D${nowCapacity}BWP $celltype D*BWP searchCelltypeExp
    } elseif {$process == "HH"} {
      set regExp ".*X(\\d+).*(A\[HRL\]\\d+)$"
      set nowCapacity [get_driveCapacity_of_celltype $celltype $regExp]
      regsub [subst {(.*)X$nowCapacity}] $celltype [subst {\\1X*}] searchCelltypeExp
    }
    set availableCelltypeList [dbget head.libCells.name $searchCelltypeExp]
    set availableDriveCapacityList [lmap Acelltype $availableCelltypeList {
      regexp $regExp $Acelltype wholename AdriveLevel AVTtype
      if {$AdriveLevel == "05"} {set AdriveLevel 0.5} else { set AdriveLevel } 
    }]
    set filteredAvailableDriveCapacityList [filter_numberList $availableDriveCapacityList $driveCapacityRange]
    if {[lindex $filteredAvailableDriveCapacityList end] == $nowCapacity} {
      return 1 
    } else {
      return 0 
    }
  }
}
