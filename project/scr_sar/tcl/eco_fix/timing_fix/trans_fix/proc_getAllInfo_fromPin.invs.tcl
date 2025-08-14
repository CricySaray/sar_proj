#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/03 21:05:46 Sunday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|misc_proc)
# descrip   : get $all information from only pin name in innovus
# update    : 2025/08/06 23:25:16 Wednesday
#             (U001) improve method to judge if the one2more situation is loopped 
# update    : 2025/08/07 09:16:54 Thursday
#             (U002) add some unique dict items
# update    : 2025/08/13 09:07:43 Wednesday
#             (U003) NOTICE: add access for LUT using proc operateLUT, you need load lutDict dict variable before run this proc
#             build LUT using build_sar_LUT_usingDICT at  ../lut_build/build_sar_LUT_usingDICT.tcl
# mini descrip: driverPin/sinksPin/netName/netLen/wiresPts/driverInstname/sinksInstname/driverCellType/sinksCellType/
#               driverCellClass/sinksCellClass/driverCapacity/sinksCapacity/driverVTtype/sinksVTtype/driverPinPT/
#               sinksPinPT/numSinks/shortenedSinksCellClass/simplizedSinksCellClass/shortenedSimplizedSinksCellClass/
#               uniqueSinksCellClass/uniqueShortenedSinksCellClass/uniqueSimplizedSinksCellClass/uniqueShortenedSimplizedSinksCellClass
#               mostFrequentInSinksCellClass/numOfMostFrequentInSinksCellClass/centerPtOfSinksPinPT/
#               distanceOfDriver2CenterOfSinksPinPt/ifLoop/ifOne2One/ifSimpleOne2More/driverSinksSymbol/ifHaveBeenFastestVTinRange/
#               ifHaveBeenLargestCapacityInRange/ifNetConnected/ruleLen/sink_pt_D2List/sinkPinFarthestToDriverPin/sinksCellClassForShow/farthestSinkCellType/
#               [one2more: numFartherGroupSinks/fartherGroupSinksPin]/infoToShow
# return    : dict variable
# ref       : link url
# --------------------------
source ../../../packages/logic_AND_OR.package.tcl; # eo
source ../../../packages/judge_ifAllSegmentsConnected.package.tcl; # judge_ifAllSegmentsConnected
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
source ./proc_findFarthestSinkPinAndPt_toDriverPin.invs.tcl; # find_farthest_sinkpoint_to_driver_pin
source ../../../packages/group_points_by_distribution_and_preferFartherCenterPt.package.tcl; # group_points_by_distribution_and_preferFartherCenterPt
source ./proc_changeDriveCapacity_of_celltype.invs.tcl; # changeDriveCapacity_of_celltype
source ../lut_build/operateLUT.tcl; # operateLUT

alias sus "subst -nocommands -nobackslashes"
proc get_allInfo_fromPin {{pinname ""} {forbidenVT {AH9}} {driveCapacityRange {1 12}}} {
  if {$pinname == "" || $pinname == "0x0" || [dbget top.insts.instTerms.name $pinname -e] == ""} {
    error "proc [regsub ":" [lindex [info level 0] 0] ""]: check your input: pinname($pinname) is incorrect!!!"
  } else {
    set allInfo [dict create ]
    dict set allInfo driverPin [get_driverPin $pinname]
    dict set allInfo sinksPin [get_sinkPins $pinname]
    dict set allInfo netName [get_object_name [get_nets -of $pinname]]
    dict set allInfo netLen [get_net_length [dict get $allInfo netName]]
    dict set allInfo wiresPts [dbget [dbget top.nets.name [dict get $allInfo netName] -p].wires.pts]
    dict set allInfo driverInstname [dbget [dbget top.insts.instTerms.name [dict get $allInfo driverPin] -p2].name]
    dict set allInfo sinksInstname [lmap sinkpin [dict get $allInfo sinksPin] { dbget [dbget top.insts.instTerms.name $sinkpin -p2].name }]
    dict set allInfo driverCellType [dbget [dbget top.insts.instTerms.name [dict get $allInfo driverPin] -p2].cell.name]
    dict set allInfo sinksCellType [lmap sinkpin [dict get $allInfo sinksPin] { dbget [dbget top.insts.instTerms.name $sinkpin -p2].cell.name }]
    dict set allInfo driverCellClass [operateLUT -type read -attr [list celltype [dict get $allInfo driverCellType] class]]
    dict set allInfo sinksCellClass [lmap sinkcelltype [dict get $allInfo sinksCellType] { operateLUT -type read -attr [list celltype $sinkcelltype class] }]

    dict set allInfo driverCapacity [operateLUT -type read -attr [list celltype [dict get $allInfo driverCellType] capacity]]
    dict set allInfo sinksCapacity [lmap sinkcelltype [dict get $allInfo sinksCellType] { operateLUT -type read -attr [list celltype $sinkcelltype capacity] }]
    dict set allInfo driverVTtype [operateLUT -type read -attr [list celltype [dict get $allInfo driverCellType] vt]]
    dict set allInfo sinksVTtype [lmap sinkcelltype [dict get $allInfo sinksCellType] { operateLUT -type read -attr [list celltype $sinkcelltype vt] }]
    dict set allInfo driverPinPT [gpt [dict get $allInfo driverPin]]
    dict set allInfo sinksPinPT [lmap sinkpin [dict get $allInfo sinksPin] { gpt $sinkpin }]

    dict set allInfo numSinks [llength [dict get $allInfo sinksPin]]
    dict set allInfo shortenedSinksCellClass [shortenCellClass [dict get $allInfo sinksCellClass]] ; # b/b/s/v/l/f/f
    dict set allInfo simplizedSinksCellClass [simplizeCellClass [dict get $allInfo sinksCellClass]] ; # { buffer buffer sequential buffer logic buffer buffer  }
    dict set allInfo shortenedSimplizedSinksCellClass [shortenCellClass [dict get $allInfo simplizedSinksCellClass]] ; # b/b/s/b/l/b/b
    # U002
    dict set allInfo uniqueSinksCellClass [lsort -unique [dict get $allInfo sinksCellClass] ] ; # { buffer sequential inverter logic CLKbuffer }
    dict set allInfo uniqueShortenedSinksCellClass [join [lsort -unique [split [dict get $allInfo shortenedSinksCellClass] "/"]] "/"] ; # b/s/v/l/f
    dict set allInfo uniqueSimplizedSinksCellClass [lsort -unique [dict get $allInfo simplizedSinksCellClass]] ; # { buffer sequential logic }
    dict set allInfo uniqueShortenedSimplizedSinksCellClass [join [lsort -unique [split [dict get $allInfo shortenedSimplizedSinksCellClass] "/"]] "/"]; # b/s/l
    
    dict set allInfo mostFrequentInSinksCellClass [findMostFrequentElement [dict get $allInfo simplizedSinksCellClass]]; # { buffer }
    dict set allInfo numOfMostFrequentInSinksCellClass [llength [dict get $allInfo mostFrequentInSinksCellClass]] ; # 1

    dict set allInfo centerPtOfSinksPinPT [format "%.3f %.3f" {*}[calculateResistantCenter_fromPoints [dict get $allInfo sinksPinPT]]]
    dict set allInfo distanceOfDriver2CenterOfSinksPinPt [format "%.3f" [calculateDistance [dict get $allInfo driverPinPT] [dict get $allInfo centerPtOfSinksPinPT]]]
    if {[dict get $allInfo numSinks] == 1} {
      set resultOfCheckRoutingLoop [checkRoutingLoop [dict get $allInfo distanceOfDriver2CenterOfSinksPinPt] [dict get $allInfo netLen] "normal"]
    } elseif {[dict get $allInfo numSinks] > 1} {
      set resultOfIfLoop_forOne2More [judgeIfLoop_forOne2More [dict get $allInfo driverPinPT] [dict get $allInfo sinksPinPT] [dict get $allInfo netLen] 16] ; # U001
      set resultOfCheckRoutingLoop [lindex $resultOfIfLoop_forOne2More 0] 
    }
    dict set allInfo ifLoop [switch $resultOfCheckRoutingLoop {
      0 {set result "noLoop"}
      1 {set result "mild"}
      2 {set result "moderate"}
      3 {set result "severe"}
    }]
    
    dict set allInfo ifOne2One [expr ([dict get $allInfo numSinks] == 1) ? 1 : 0]
    dict set allInfo ifSimpleOne2More [expr ([dict get $allInfo numOfMostFrequentInSinksCellClass] == 1) ? 1 : 0]
    dict set allInfo driverSinksSymbol [zipCellClass [dict get $allInfo driverCellClass] [dict get $allInfo mostFrequentInSinksCellClass] [dict get $allInfo numSinks]]

    dict set allInfo ifHaveBeenFastestVTinRange [judge_ifHaveBeenFastVTinRange [dict get $allInfo driverCellType] $forbidenVT]
    dict set allInfo ifHaveBeenLargestCapacityInRange [judge_ifHaveBeenLargestCapacityInRange [dict get $allInfo driverCellType] $driveCapacityRange ]

    dict set allInfo ifNetConnected [judge_ifAllSegmentsConnected [dict get $allInfo wiresPts]] ; # 1: connected 0: not connected

    dict set allInfo ruleLen [if { [expr [dict get $allInfo numSinks] == 1]} { dict get $allInfo distanceOfDriver2CenterOfSinksPinPt } else { lindex $resultOfIfLoop_forOne2More end }]
    dict set allInfo sink_pt_D2List [lmap sinkpinname [dict get $allInfo sinksPin] { set sinkpt [gpt $sinkpinname] ; set sink_pt [list $sinkpinname $sinkpt] }]
    dict set allInfo sinkPinFarthestToDriverPin [lindex [find_farthest_sinkpoint_to_driver_pin [dict get $allInfo driverPinPT] [dict get $allInfo sink_pt_D2List]] 0] 
    dict set allInfo sinksCellClassForShow [eo [expr [dict get $allInfo numSinks] == 1] [dict get $allInfo sinksCellClass] [dict get $allInfo uniqueShortenedSinksCellClass]]
    dict set allInfo farthestSinkCellType [dbget [dbget top.insts.instTerms.name [dict get $allInfo sinkPinFarthestToDriverPin] -p2].cell.name]

    if {![dict get $allInfo ifOne2One]} {
      set sinksPinNameAndPt [lmap sinkpin [dict get $allInfo sinksPin] { set sinkpt [gpt $sinkpin] ; set temp_pinname_pt [list $sinkpin $sinkpt] }]
      set distributionInfo [group_points_by_distribution_and_preferFartherCenterPt [list [dict get $allInfo driverPin] [dict get $allInfo driverPinPT]] $sinksPinNameAndPt]
      lassign $distributionInfo fartherGroup closerGroup 
      lassign $fartherGroup groupPinnameLocations fartherCenterPoint
      dict set allInfo numFartherGroupSinks [llength $groupPinnameLocations]
      dict set allInfo fartherGroupSinksPin [lmap temp_pinname_location $groupPinnameLocations { lindex $temp_pinname_location 0 }]
    }    
    
    dict set allInfo mostFrequentInSinksCellType [if {$numOfMostFrequentInSinksCellClass > 1} { set temp_return cantSelect } else {
      set temp_sameClass_celltype_capacity [lmap temp_celltype [dict get $allInfo sinksCellType] {
        set temp_cellclass [operateLUT -type read -atrr [list celltype $temp_celltype class]] 
        if {[shortenCellClass $temp_cellclass] eq $mostFrequentInSinksCellClass} {
          set temp_return [operateLUT -type read -attr [list celltype $temp_celltype capacity]]
        } else {
          continue 
        }
      }]
      set temp_sameClass_celltype_capacity_sorted [lsort -unique -real $temp_sameClass_celltype_capacity]
      set temp_mostCapacity [lindex [findMostFrequentElement $temp_sameClass_celltype_capacity 30.0 1] 0]
      set temp_result [change]
    }]
    
    dict for {key val} $allInfo  { set $key $val }
    dict set allInfo infoToShow [list $netLen $ruleLen $ifLoop $driverCellClass $driverCellType $driverPin "-$numSinks-" $sinksCellClassForShow $farthestSinkCellType $sinkPinFarthestToDriverPin]
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
    } else {
      set t "cantMap_$sinkcellclass"
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

  return [join $shortened "/"]
}
proc zipCellClass {driverCellClass mostFrequentInSinksCellClass numSinks} {
  set shortenedDriverCellClass [shortenCellClass [simplizeCellClass $driverCellClass]]
  set shortenedSinksCellClass [shortenCellClass $mostFrequentInSinksCellClass]
  if {$numSinks == 1} {
    return [append shortenedDriverCellClass $shortenedSinksCellClass]
  } elseif {$numSinks > 1 && [llength $mostFrequentInSinksCellClass] == 1} {
    set simpleOne2MoreSymbol "m"
    return [append simpleOne2MoreSymbol $shortenedDriverCellClass $shortenedSinksCellClass]
  } elseif {$numSinks > 1 && [llength $mostFrequentInSinksCellClass] > 1} {
    set complexOne2MoreSymbol "mm" 
    return [append complexOne2MoreSymbol $shortenedDriverCellClass $shortenedSinksCellClass]
  }
}

source ../../../packages/andnot_ofList.package.tcl; # andnot
source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
source ./proc_get_VTtype_of_celltype.invs.tcl; # get_VTtype_of_celltype
source ../lut_build/operateLUT.tcl; # operateLUT
proc judge_ifHaveBeenFastVTinRange {{celltype ""} {forbidenVT {AH9}}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e] == "" || [whichProcess_fromStdCellPattern $celltype] == "other"} {
    error "proc judge_ifHaveBeenFastVTinRange: check your input: celltype($celltype) not valid !!!" 
  } else {
    set process [operateLUT -type read -attr {process}] 
    if {$process == "TSMC"} {
      set VTrange {HVT SVT LVT ULVT}
    } elseif {$process == {M31GPSC900NL040P*_40N}} {
      set VTrange {AL9 AR9 AH9}
    }
    if {$forbidenVT != "" && [every x $forbidenVT { expr { $x ni $VTrange }} ]} { error "proc judge_ifHaveBeenFastVTinRange: forbidenVT($forbidenVT) is not in VTrange($VTrange)!!!" }
    set nowVT [operateLUT -type read -attr [list celltype $celltype vt]]
    if {$nowVT eq "NaN"} {return 1}
    set availableVTrange [andnot $VTrange $forbidenVT]
    if {[lsearch -exact $availableVTrange $nowVT] != 0} { return 0 } else { return 1 }
  }
}
source proc_getDriveCapacity_ofCelltype.invs.tcl; # get_driveCapacity_of_celltype
source ../../../packages/filter_numberList.package.tcl; # filter_numberList
source ../lut_build/operateLUT.tcl; # operateLUT
proc judge_ifHaveBeenLargestCapacityInRange {{celltype ""} {driveCapacityRange {1 12}}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e] == "" || [whichProcess_fromStdCellPattern $celltype] == "other"} {
    error "proc judge_ifHaveBeenLargestCapacityInRange: check your input: celltype($celltype) not valid !!!" 
  } else {
    set process [operateLUT -type read -attr {process}] 
    if {$process == "TSMC"} {
      set regExp "D(\\d+).*CPD(U?L?H?VT)?"
      set nowCapacity [operateLUT -type read -attr [list celltype $celltype capacity]]
      if {$nowCapacity eq "NaN"} {return 1}
    } elseif {$process == {M31GPSC900NL040P*_40N}} {
      set regExp ".*X(\\d+).*(A\[HRL\]\\d+)$"
      set nowCapacity [operateLUT -type read -attr [list celltype $celltype capacity]]
      if {$nowCapacity eq "NaN"} {return 1}
    }
    set availableDriveCapacityList [operateLUT -type read -attr [list celltype $celltype caplist]]
    set filteredAvailableDriveCapacityList [filter_numberList $availableDriveCapacityList $driveCapacityRange]
    if {[lindex $filteredAvailableDriveCapacityList end] == $nowCapacity} {
      return 1 
    } else {
      return 0 
    }
  }
}
source ../../../proc_whichProcess_fromStdCellPattern.pt.tcl; # whichProcess_fromStdCellPattern
# absolute proc
proc judge_ifCanMapWithRegExp {{pinNameOrCelltype ""}} {
  set testPin [dbget top.insts.instTerms.name $pinNameOrCelltype -e -p]
  set testCellType [dbget head.libCells.name $pinNameOrCelltype -e -p]
  if {$pinNameOrCelltype == "" || $pinNameOrCelltype == "0x0" || [expr {$testPin == "" && $testCellType == ""}]} {
    error "proc [regsub ":" [lindex [info level 0] 0] ""]: check your input : pinNameOrCelltype($pinNameOrCelltype) not be found!!!"
  } else {
    if {$testPin != ""} {
      set celltype [dbget [dbget top.insts.instTerms.name $pinNameOrCelltype -p2].cell.name]
    } elseif {$testCellType != ""} {
      set celltype [dbget $testCellType.name]
    }
    set process [whichProcess_fromStdCellPattern $celltype]
    if {$process == "TSMC"} {
      set regExp "D(\\d+).*CPD(U?L?H?VT)?"
    } elseif {$process == "HH"} {
      set regExp ".*X(\\d+).*(A\[HRL\]\\d+)$"
    } else {
      set regExp "notSet"
    }
    regexp $regExp $celltype wholename driveCapacity VTtype
    if {![info exists wholename] || ![info exists driverCapacity] || ![info exists VTtype]} {
      return 0
    } else {
      return 1
    }
  }
}
