#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/03 21:05:46 Sunday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|misc_proc)
# descrip   : get $all information from only pin name in innovus
# mini descrip: driverPin/sinksPin/driverCellClass/sinksCellClass/netName/netLen/driverInstname/sinksInstname/
#               driverCellType/sinksCellType/driverCapacity/sinksCapacity/driverVTtype/sinksVTtype/driverPinPT/
#               sinksPinPT/numSinks/shortenedSinksCellClassRaw/simplizedSinksCellClass/shortenedSinksCellClassSimplized/
#               uniqueSinksCellClass/mostFrequentInSinksCellClass/numOfMostFrequentInSinksCellClass/centerPtOfSinksPinPT/distanceOfDriver2CenterOfSinksPinPt/ifLoop
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

proc get_allInfo_fromPin {{pinname ""}} {
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
    dict set allInfo uniqueSinksCellClass [lsort -unique [dict get $allInfo sinksCellType] ]
    dict set allInfo mostFrequentInSinksCellClass [findMostFrequentElement [dict get $allInfo sinksCellType]]
    dict set allInfo numOfMostFrequentInSinksCellClass [llength [dict get $allInfo mostFrequentInSinksCellClass]]

    dict set allInfo centerPtOfSinksPinPT [calculateResistantCenter_fromPoints [dict get $allInfo sinksPinPT]]
    dict set allInfo distanceOfDriver2CenterOfSinksPinPt [format "%.3f" [calculateDistance [dict get $allInfo driverPinPT] [dict get $allInfo centerPtOfSinksPinPT]]]
    set resultOfCheckRoutingLoop [checkRoutingLoop [dict get $allInfo distanceOfDriver2CenterOfSinksPinPt] [dict get $allInfo netLen] "normal"]
    dict set allInfo ifLoop [switch $resultOfCheckRoutingLoop {
      0 {set result "noLoop"}
      1 {set result "mild"}
      2 {set result "moderate"}
      3 {set result "severe"}
    }]
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
      "buffer" {set t "b"}
      "inverter" {set t "i"}
      "logic" {set t "l"}
      "CLKbuffer" {set t "f"}
      "CLKinverter" {set t "n"}
      "CLKlogic" {set t "o"}
      "delay" {set t "d"}
      "sequential" {set t "s"}
      default {set t "N"}
    }
    set t
  }]
  return [join [lsort -unique $shortened] "/"]
}
