#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/13 15:25:05 Sunday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : fix trans
# update    : 2025/07/18 19:51:29 Friday
#           (U001) check if changed cell meet rule that is larger than specified drive capacity(such as X1) at end of fixing looping
#                  if $largerThanDriveCapacityOfChangedCelltype is X1, so drive capacity of needing to ecoChangeCell must be larger than X1
# update    : 2025/07/20 01:43:43 Sunday
#           (U003) fixed logic error: in proc get_driveCapacity_of_celltype, input check part: dbget top.insts.cell.name can only get exist cell of name. 
#           it will return 0x0:1 when you input changed celltype that is not exist in now design. and it will get to checking loop, so result toCelltype 
#           drive capacity be smaller
# update    : 2025/07/21 20:25:25 Monday
#           (U004) fixed summary of situations and methods for one2more violation
# ref       : link url
#
# TODO: judge powerdomain area and which powerdomain the inst is belong to, get accurate location of toAddRepeater, 
#       to fix IMPOPT-616
#       1) get powerdomains name, 2) get powerdomain area, 3) get powerdomain which the inst is belong to, 4) get location of inst, 5) calculate the loc of toAddRepeater
# TODO: 1 v more: calculate lenth between every sinks of driveCell, and classify them to one or more group in order to fix fanout or set ecoAddRepeater -term {... ...}
# TODO: songNOTE: judge mem and ip celltype!!!
# --------------------------
# ------
# need :
#   viol driver pins (primary!) and viol value
#     viol loader pins (optional)
#   net length
#   driver pin and driver cell type and net len
#   load cell type and net len
# cosider method:
# V change VT (set priority editable for design that mustn't use LVT)
# V(but very simple) change drive (set range of useable drive)
# V change loader drive or VT
#
#   add buffer in middle when driver is buf or inv (according to driver drive index and net len)
#   add buffer next driver that is logic cell (consider if logic cell can drive this buf)
#     - use -relativeDistToSink when loader is only one
#     - (advance) use algorithm logic to add buffer
#
#   special situation:
#     more viol situation all is at one chain, like several buffers or inverters
#
# dont fix when situation not occur
# return report of summary:
#   fixed :
#     viol value | viol pin | fix method
#   can't fix :
#     viol value | viol pin | reason to unfix
#
# songNOTE: DEFENSIVE FIX:
#   if inst is mem/IP, it can't be changed DriveCapacibility and can't move location
#   TODO: get previous fixing summary, and check if it is fixed in new iteration fix!
#   TODO: deal with summary, select violated drivePin, driveInst, sinkPin and sinkInst in invsGUI for convenience
# return time
#
# fix long net:
#   get drive net len in PT:看看一个buf驱动和他同级的buffer时，不违例的net len最长长度，这个需要大量测试，每个项目都不一样。（脚本处理） tcl在pt里面获取海量原始数据，然后perl来处理和统计。为了给fix long net和fix trans脚本提供判断依据。
#     buf/inv cell | drive net len
# --------
# 01 get info of viol cell: pin cellname celltype driveNum netlength
source ../../../incr_integer_inself.common.tcl; # ci(proc counter), don't use array: counters
source ../../../logic_or_and.common.tcl; # operators: lo la ol al re eo - return 0|1
source ./proc_getPt_ofObj.invs.tcl; # gpt - return pt(location) of object
source ./proc_get_net_lenth.invs.tcl; # get_net_length - num
source ./proc_if_driver_or_load.invs.tcl; # if_driver_or_load - 1: driver  0: load
source ./proc_get_fanoutNum_and_inputTermsName_of_pin.invs.tcl; # get_fanoutNum_and_inputTermsName_of_pin - return list [num termsNameList] || get_driverPin - return drivePin
source ./proc_get_cellDriveLevel_and_VTtype_of_inst.invs.tcl; # get_cellDriveLevel_and_VTtype_of_inst - return [instname cellName driveLevel VTtype]
source ./proc_get_cell_class.invs.tcl; # get_cell_class - return logic|buffer|inverter|CLKcell|sequential|gating|other
source ./proc_strategy_changeVT.invs.tcl; # strategy_changeVT - return VT-changed cellname
source ./proc_strategy_addRepeaterCelltype.invs.tcl; # strategy_addRepeaterCelltype - return toAddCelltype
source ./proc_strategy_changeDriveCapacity_of_driveCell.invs.tcl; # strategy_changeDriveCapacity - return toChangeCelltype
source ./proc_print_ecoCommands.invs.tcl; # print_ecoCommand - return command string (only one command)
source ./proc_print_formatedTable.common.tcl; # print_formatedTable D2 list - return 0, puts formated table
source ./proc_pw_puts_message_to_file_and_window.common.tcl; # pw - advanced puts
source ./proc_strategy_clampDriveCapacity_BetweenDriverSink.invs.tcl; # strategy_clampDriveCapacity_BetweenDriverSink - return celltype

source ./proc_calculateResistantCenter_advanced.invs.tcl; # calculateResistantCenter_fromPoints - input pointsList, return center pt
source ./proc_calculateRelativePoint.invs.tcl; # calculateRelativePoint - return relative point
source ./proc_calculateDistance_betweenTwoPoint.invs.tcl; # calculateDistance - return value of distance
source ./proc_findMostFrequentElementOfList.invs.tcl; # findMostFrequentElement - return string
source ./proc_reverseListRange.invs.tcl; # reverseListRange - return reversed list
source ./proc_formatDecimal.invs.tcl; # formatDecimal/fm - return string converted from number
source ./proc_checkRoutingLoop.invs.tcl; # checkRoutingLoop - return number

# The principle of minimum information
proc fix_trans {args} {
  # default value for all var
  set file_viol_pin                            ""
  set violValue_pin_columnIndex                {4 1}
  set canChangeVT                              1
  set canChangeDriveCapacity                   1
  set canChangeVTandDriveCapacity              1
  set canAddRepeater                           1
  set unitOfNetLength                          10
  set refBufferCelltype                        "BUFX4AR9"
  set refInverterCelltype                      "INVX4AR9"
  set refCLKBufferCelltype                     "CLKBUFX4AL9"
  set refCLKInverterCelltype                   "CLKINVX4AL9"
  set cellRegExp                               "X(\\d+).*(A\[HRL\]\\d+)$"
  set rangeOfVtSpeed                           {AL9 AR9 AH9}
  set clkNeedVtWeightList                      {{AL9 3} {AR9 0} {AH9 0}}; # weight:0 is stand for forbidden using
  set normalNeedVtWeightList                   {{AL9 1} {AR9 3} {AH9 0}}; # normal std cell can use AL9 and AR9, but weight of AR9 is larger
  set specialNeedVtWeightList                  {{AL9 0} {AR9 3} {AH9 0}}; # for checking AH9(HVT), if violated drive inst is HVT, change it. it oftenly is used to change to almost vt like RVT/SVT.
  set rangeOfDriveCapacityForChange            {1 12}
  set rangeOfDriveCapacityForAdd               {3 12}
  set largerThanDriveCapacityOfChangedCelltype 1
  set ecoNewInstNamePrefix                     "sar_fix_trans_clk_071615"
  set suffixFilename                           "" ; # for example : eco4
  set debug                                    0
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set sumFile                                 [eo $suffixFilename "sor_summary_of_result_$suffixFilename.list" "sor_summary_of_result.list" ]
  set cantExtractFile                         [eo $suffixFilename "sor_cantExtract_$suffixFilename.list" "sor_cantExtract.list"]
  set cmdFile                                 [eo $suffixFilename "sor_ecocmds_$suffixFilename.tcl" "sor_ecocmds.tcl"]
  set one2moreDetailViolInfo                  [eo $suffixFilename "sor_one2moreDetailViolInfo_$suffixFilename.tcl" "sor_one2moreDetailViolInfo.tcl"]
  # songNOTE: only deal with loadPin viol situation, ignore drivePin viol situation
  # $violValue_pin_columnIndex  : for example : {3 1}
  #   violPin   xxx   violValue   xxx   xxx
  #   you can specify column of violValue and violPin
  if {$file_viol_pin == "" || [glob -nocomplain $file_viol_pin] == ""} {
    error "check your input file"; # check your file 
  } else {
    set fi [open $file_viol_pin r]
    set violValue_driverPin_onylOneLoaderPin_D3List [list ]; # one to one
    set violValue_drivePin_loadPin_numSinks_sinks_D5List [list ]; # one to more
    set oneToMoreList_diffSinksCellclass [list ]
    # ------------------------------------
    # sort two class for all viol situations
    set j 0
    while {[gets $fi line] > -1} {
      incr j
      set viol_value [lindex $line [expr [lindex $violValue_pin_columnIndex 0] - 1]]
      set viol_pin   [lindex $line [expr [lindex $violValue_pin_columnIndex 1] - 1]]
      if {![string is double $viol_value] || [dbget top.insts.instTerms.name $viol_pin -e] == ""} {
        error "column([lindex $violValue_pin_columnIndex 0]) is not number, or violPin($viol_pin) can't find"; # column([lindex $violValue_pin_columnIndex 0]) is not number
      }
      if {![if_driver_or_load $viol_pin]} { ; # only extract viol loadPin
        set load_pin $viol_pin 
        set drive_pin [get_driverPin $load_pin]
        set num_termName_D2List [get_fanoutNum_and_inputTermsName_of_pin $drive_pin]
        if {[lindex $num_termName_D2List 0] == 1} { ; # load cell is only one. you can use option: -relativeDistToSink to ecoAddRepeater
          lappend violValue_driverPin_onylOneLoaderPin_D3List [list $viol_value $drive_pin [lindex $num_termName_D2List 1]]
        } elseif {[lindex $num_termName_D2List 0] > 1} { ; # load cell are several, need consider other method
          lappend violValue_drivePin_loadPin_numSinks_sinks_D5List [list $viol_value $drive_pin $load_pin [lindex $num_termName_D2List 0] [lindex $num_termName_D2List 1]]
          lappend oneToMoreList_diffSinksCellclass [list $viol_value $drive_pin $load_pin]
          # songNOTE: TODO show one drivePin , but all sink Pins
          #           annotate a X flag in violated sink Pin
        }
      } else {

        set drive_pin $viol_pin 
        set num_termName_D2List [get_fanoutNum_and_inputTermsName_of_pin $drive_pin]
        if {[lindex $num_termName_D2List 0] == 1} { ; # load cell is only one. you can use option: -relativeDistToSink to ecoAddRepeater
          lappend violValue_driverPin_onylOneLoaderPin_D3List [list $viol_value $drive_pin [lindex $num_termName_D2List 1]]
        } elseif {[lindex $num_termName_D2List 0] > 1} { ; # load cell are several, need consider other method
          set load_pin [lindex [lindex $num_termName_D2List 1] 0]
          lappend violValue_drivePin_loadPin_numSinks_sinks_D5List [list $viol_value $drive_pin $load_pin [lindex $num_termName_D2List 0] [lindex $num_termName_D2List 1]]
          lappend oneToMoreList_diffSinksCellclass [list $viol_value $drive_pin $load_pin]
          # songNOTE: TODO show one drivePin , but all sink Pins
          #           annotate a X flag in violated sink Pin
        }

        lappend cantExtractList "(Line $j) drivePin - not extract! : $line"
      }
    }
    close $fi
    # -----------------------
    # sort and check D3List correction : $violValue_driverPin_onylOneLoaderPin_D3List and $violValue_drivePin_loadPin_numSinks_sinks_D5List
    # 1 v 1
    set violValue_driverPin_onylOneLoaderPin_D3List [lsort -index 0 -real -decreasing $violValue_driverPin_onylOneLoaderPin_D3List]
    set violValue_driverPin_onylOneLoaderPin_D3List [lsort -index 0 -real -decreasing [lsort -unique -index 1 $violValue_driverPin_onylOneLoaderPin_D3List]]
    set violValue_drivePin_loadPin_numSinks_sinks_D5List [lsort -index 0 -real -decreasing $violValue_drivePin_loadPin_numSinks_sinks_D5List]
    set violValue_drivePin_loadPin_numSinks_sinks_D5List [lsort -index 0 -real -increasing [lsort -unique -index 2 $violValue_drivePin_loadPin_numSinks_sinks_D5List]]
    if {$debug} { puts [join $violValue_driverPin_onylOneLoaderPin_D3List \n] }
    # 1 v more
    set oneToMoreList_diffSinksCellclass [lsort -index 0 -real -decreasing $oneToMoreList_diffSinksCellclass]
    set oneToMoreList_diffSinksCellclass [lsort -index 1 -increasing [lsort -unique -index 2 $oneToMoreList_diffSinksCellclass]]
    set oneToMoreList_diffSinksCellclass [linsert $oneToMoreList_diffSinksCellclass 0 [list violValue drivePin loadPin]]
    # ----------------------
    # info collections
    ## cant change info
    set cantChangePrompts {
      "# error/warning symbols"
      "# changeVT:"
      "## V - the celltype to changeVT is forbidden to use, like {AL9 0} which of weight:0 is forbidden to use"
      "## F - don't have faster VT to change, like celltype is LVT or ULVT, which is no faster VT than LVT or ULVT"
      "# changeDriveCapacity"
      "## O - out of acceptable drive capacity list. if you specify the range of useful drive capacity like $rangeOfDriveCapacityForChange, toChangeCelltype capacity can't be out of it."
      "# addRepeaterCelltype"
      "## N - toAddCelltype is not acceptable celltype from std cell library"
      "# special situation:(need fix by your hand)"
      "## S - violation value is very huge but net length is short"
      "# special inst"
      "## M_D - drive inst is mem"
      "## M_S - sink inst is mem"
    }
    set cantChangeList_1v1 [list [list situation method violVal netLen distance ifLoop driveClass driveCelltype driveViolPin loadClass sinkCelltype loadViolPin]]
    ## changed info
    set fixedPrompts {
      "# symbols of normal methods : all of symbols can combine with each other, which is mix of a lot methods."
      "## T - changedVT, below is toChangeCelltype"
      "## D - changedDriveCapacity, below is toChangeCelltype"
      "## A_09 A_0.9 - near the driver - addedRepeaterCell, below is toAddCelltype"
      "## A_05 A_0.5 - in the middle of driver and sink - addedRepeaterCell, below is toAddCelltype"
      "## A_01 A_0.1 - near the sink   - addedRepeaterCell, below is toAddCelltype"
      "# special fixed"
      "## FS - fix special situation: change driveCelltype (changeVT and changeDriveCapacity)"
      "## _C - checked driveCapacity of celltype at every end of fixing loop "
      ""
      "# symbol of cell class:"
      "## 'l' - logic class: logic/CLKlogic/delay"
      "## 'b' - buffer class: buffer/inverter/CLKbuffer/CLKinverter"
      "## 's' - sequential class: sequential"
      "## 'e' - mem class: mem"
      "## 'i' - IP class: IP, an ip buffer will be middle between IP and logic at normal situation"
      "## 'p' - IOpad class: IOpad"
      "## 't' - dt - dont touch cell class: dontouch"
      "## 'u' - du - dont use cell class: dontuse"
    }
    set fixedList_1v1 [list [list situation method celltypeToFix violVal netLen distance ifLoop driveClass driveCelltype driveViolPin loadClass sinkCelltype loadViolPin]]
    # skipped situation info
    set skippedSituationsPrompt {
      "# NF - have no faster vt" 
      "# NL - have no lager drive capacity"
      "# NFL - have no both faster vt and lager drive capacity"
    }
    set skippedList_1v1 [list [list situation method violVal netLen distance ifLoop driveClass driveCelltype driveViolPin loadClass sinkCelltype loadViolPin]]
    set notConsideredPrompt {
      "# NC - not considered situation"
    }
    set notConsideredList_1v1 [list [list situation violVal netLen distance ifLoop driveClass driveCelltype driveViolPin loadClass sinkCelltype loadViolPin]]
    # ------
    # init LIST
    set cmdList $fixedPrompts
    lappend cmdList "setEcoMode -reset"
    lappend cmdList "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"
    lappend cmdList " "

    # ---------------------------------
    # begin deal with different situation
    ## only load one cell
    
    # songNOTE: TODO: 
    # 1 check violated chain, or timing arc
    # 2 specially deal with specific situation, such as big violValue but short net length
##### BEGIN OF LOOP
    foreach viol_driverPin_loadPin $violValue_driverPin_onylOneLoaderPin_D3List {; # violValue: ns
      if {$debug} { puts "drive: [get_cell_class [lindex $viol_driverPin_loadPin 1]] load: [get_cell_class [lindex $viol_driverPin_loadPin 2]]" }
      foreach var {violnum driveCellClass loadCellClass netName netLength driveInstname driveInstname_celltype_driveLevel_VTtype driveCelltype driveCapacity sinkInstname sinkInstname_celltype_driveLevel_VTtype sinkCelltype sinkCapacity allInfoList} { set $var "" }
      set violnum [lindex $viol_driverPin_loadPin 0]
      set driveCellClass [get_cell_class [lindex $viol_driverPin_loadPin 1]]
      set loadCellClass  [get_cell_class [lindex $viol_driverPin_loadPin 2]]
      set netName [get_object_name [get_nets -of_objects [lindex $viol_driverPin_loadPin 1]]]
      set netLength [get_net_length $netName] ; # net length: um
      set driveInstname [dbget [dbget top.insts.instTerms.name [lindex $viol_driverPin_loadPin 1] -p2].name]
      set driveInstname_celltype_driveLevel_VTtype [get_cellDriveLevel_and_VTtype_of_inst $driveInstname $cellRegExp]
      set driveCelltype [lindex $driveInstname_celltype_driveLevel_VTtype 1]
      set driveCapacity [lindex $driveInstname_celltype_driveLevel_VTtype 2]
      set sinkInstname [dbget [dbget top.insts.instTerms.name [lindex $viol_driverPin_loadPin 2] -p2].name]
      set sinkInstname_celltype_driveLevel_VTtype [get_cellDriveLevel_and_VTtype_of_inst $sinkInstname $cellRegExp]
      set sinkCelltype [lindex $sinkInstname_celltype_driveLevel_VTtype 1]
      set sinkCapacity [lindex $sinkInstname_celltype_driveLevel_VTtype 2]
      set drivePt [gpt [lindex $viol_driverPin_loadPin 1]]
      set sinkPt [gpt [lindex $viol_driverPin_loadPin 2]]
      set distanceToSink [format "%.3f" [calculateDistance $drivePt $sinkPt]]
      set resultOfCheckRoutingLoop [checkRoutingLoop $distanceToSink $netLength "normal"]
      set ifLoop [switch $resultOfCheckRoutingLoop {
        0 {set result "noLoop"}
        1 {set result "mild"} 
        2 {set result "moderate"} 
        3 {set result "severe"} 
      }]
      set allInfoList [concat $violnum $netLength $distanceToSink $ifLoop \
                              $driveCellClass $driveCelltype [lindex $viol_driverPin_loadPin 1] \
                              $loadCellClass $sinkCelltype [lindex $viol_driverPin_loadPin 2] ]
      # initialize some iterative vars
      set cmd1 ""
      set toChangeCelltype ""
      set toAddCelltype ""
#puts "$driveCellClass : $loadCellClass"

    #
    # ----------------------
    # info collections
    ## cant change info
    set cantChangePrompts_one2more {
      "# error/warning symbols"
      "# changeVT:"
      "## V - the celltype to changeVT is forbidden to use, like {AL9 0} which of weight:0 is forbidden to use"
      "## F - don't have faster VT to change, like celltype is LVT or ULVT, which is no faster VT than LVT or ULVT"
      "# changeDriveCapacity"
      "## O - out of acceptable drive capacity list. if you specify the range of useful drive capacity like $rangeOfDriveCapacityForChange, toChangeCelltype capacity can't be out of it."
      "# addRepeaterCelltype"
      "## N - toAddCelltype is not acceptable celltype from std cell library"
      "# special situation:(need fix by your hand)"
      "## S - violation value is very huge but net length is short"
      "# special inst"
      "## M_D - drive inst is mem"
      "## M_S - sink inst is mem"
    }
    set allInfoPrompt [list violVal dist2cent driveClass driveCelltype driveViolPin numSinks loadClass sinkCelltype loadViolPin]
    set cantChangeList_one2more [list [concat situation sym $allInfoPrompt]]
    ## changed info
    set fixedPrompts_one2more {
      "# symbols of normal methods : all of symbols can combine with each other, which is mix of a lot methods."
      "## T - changedVT, below is toChangeCelltype"
      "## D - changedDriveCapacity, below is toChangeCelltype"
      "## A_09 A_0.9 - near the driver - addedRepeaterCell, below is toAddCelltype"
      "## A_05 A_0.5 - in the middle of driver and sink - addedRepeaterCell, below is toAddCelltype"
      "## A_01 A_0.1 - near the sink   - addedRepeaterCell, below is toAddCelltype"
      "# special fixed"
      "## FS - fix special situation: change driveCelltype (changeVT and changeDriveCapacity)"
      "## _C - checked driveCapacity of celltype at every end of fixing loop "
      ""
      "# symbol of cell class:"
      "## 'l' - logic class: logic/CLKlogic/delay"
      "## 'b' - buffer class: buffer/inverter/CLKbuffer/CLKinverter"
      "## 's' - sequential class: sequential"
      "## 'e' - mem class: mem"
      "## 'i' - IP class: IP, an ip buffer will be middle between IP and logic at normal situation"
      "## 'p' - IOpad class: IOpad"
      "## 't' - dt - dont touch cell class: dontouch"
      "## 'u' - du - dont use cell class: dontuse"
      "## 'm' - one 2 more situations, if there are two adjacent m flags at the very beginning, it indicates that in the one-to-many situation, the types of sinks cells have multiple types"
    }
    set fixedList_one2more [list [concat situation method celltypeToFix $allInfoPrompt]]
    # skipped situation info
    set skippedSituationsPrompt_one2more {
      "# NF - have no faster vt" 
      "# NL - have no lager drive capacity"
      "# NFL - have no both faster vt and lager drive capacity"
    }
    set skippedList_one2more [list [concat situation method $allInfoPrompt]]
    set notConsideredPrompt_one2more {
      "# NC - not considered situation"
    }
    set notConsideredList_one2more [list [concat situation violValue $allInfoPrompt]]
    set one2moreList_diffTypesOfSinks [list [concat situation types $allInfoPrompt]]
    set one2moreDetailList_withAllViolSinkPinsInfo [list [linsert $allInfoPrompt 2 distanceToSink]]

    # ---------------------------------------------------
    ## one 2 more , you need consider num of sinks when addrepeater!!!

    foreach violValue_drivePin_loadPin_numSinks_sinks $violValue_drivePin_loadPin_numSinks_sinks_D5List {
      if {$debug} { puts "drive: [get_cell_class [lindex $violValue_drivePin_loadPin_numSinks_sinks 1]] load: [get_cell_class [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]]" }

      foreach var {violnum driveCellClass loadCellClass netName netLength driveInstname driveInstname_celltype_driveLevel_VTtype driveCelltype driveCapacity sinkInstname sinkInstname_celltype_driveLevel_VTtype sinkCelltype sinkCapacity allInfoList numSinks sinksList sinksType sinksPt centerPtOfSinks drivePt distanceOfdrive2CenterPtOfSinks allInfoList} {
        set $var "" 
      }
      set violnum [lindex $violValue_drivePin_loadPin_numSinks_sinks 0]
      set driveCellClass [get_cell_class [lindex $violValue_drivePin_loadPin_numSinks_sinks 1]]
      set loadCellClass  [get_cell_class [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]]
      set netName [get_object_name [get_nets -of_objects [lindex $violValue_drivePin_loadPin_numSinks_sinks 1]]]
      set netLength [get_net_length $netName] ; # net length: um
      set driveInstname [dbget [dbget top.insts.instTerms.name [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -p2].name]
      set driveInstname_celltype_driveLevel_VTtype [get_cellDriveLevel_and_VTtype_of_inst $driveInstname $cellRegExp]
      set driveCelltype [lindex $driveInstname_celltype_driveLevel_VTtype 1]
      set driveCapacity [lindex $driveInstname_celltype_driveLevel_VTtype 2]
      set sinkInstname [dbget [dbget top.insts.instTerms.name [lindex $violValue_drivePin_loadPin_numSinks_sinks 2] -p2].name]
      set sinkInstname_celltype_driveLevel_VTtype [get_cellDriveLevel_and_VTtype_of_inst $sinkInstname $cellRegExp]
      set sinkCelltype [lindex $sinkInstname_celltype_driveLevel_VTtype 1]
      set sinkCapacity [lindex $sinkInstname_celltype_driveLevel_VTtype 2]
      set numSinks [lindex $violValue_drivePin_loadPin_numSinks_sinks 3]
      set sinksList [lindex $violValue_drivePin_loadPin_numSinks_sinks 4]
      set rawSinksType [lmap sink $sinksList { set sinkType [get_cell_class $sink] }]
      set sinksType [lsort -unique $rawSinksType]
      set sinksPt [lmap sink $sinksList {set pt [gpt $sink]}]
      set centerPtOfSinks [calculateResistantCenter_fromPoints  $sinksPt]
      #puts "drivePin : [lindex $violValue_drivePin_loadPin_numSinks_sinks 1]"
      set drivePt [gpt [lindex $violValue_drivePin_loadPin_numSinks_sinks 1]]
      #puts "centerPtOfSinks: $centerPtOfSinks, drivePt: $drivePt"
      set distanceOfdrive2CenterPtOfSinks [format "%.3f" [calculateDistance $centerPtOfSinks $drivePt]]
      set sinkPt [gpt [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]]
      set distanceToSink [format "%.3f" [calculateDistance $sinkPt $drivePt]]

      #puts "driveInstname : $driveInstname , pt of drive: $drivePt, pt of center of sinks: $centerPtOfSinks,  distance to center of sinks: $distanceOfdrive2CenterPtOfSinks"

      set allInfoList [concat $violnum $distanceOfdrive2CenterPtOfSinks \
                              $driveCellClass $driveCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] "-$numSinks-" \
                              $loadCellClass $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 2] ]

      if {[lsearch -exact -index 5 $one2moreDetailList_withAllViolSinkPinsInfo [lindex $violValue_drivePin_loadPin_numSinks_sinks 1]] > -1 } {
        lappend one2moreDetailList_withAllViolSinkPinsInfo [concat $violnum $distanceOfdrive2CenterPtOfSinks $distanceToSink "/" "/" "/" "/" $loadCellClass $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]]
        continue; # AT001
      } ; # if this drive pin has been deal with, next loop
      lappend one2moreDetailList_withAllViolSinkPinsInfo [concat $violnum $distanceOfdrive2CenterPtOfSinks $distanceToSink $driveCellClass $driveCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] $numSinks $loadCellClass $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]]

      # initialize some iterative vars
      set cmd2 ""
      set toChangeCelltype2 ""
      set toAddCelltype2 ""

      # Merge similar cell class
      set rawMergeSinksType [lmap sinkType $rawSinksType {
        if {$sinkType in {logic delay CLKlogic}} { 
          set t "logic" 
        } elseif {$sinkType in {buffer inverter CLKbuffer CLKinverter}} {
          set t "buffer"
        } elseif {$sinkType in {sequential}} {
          set t "sequential"
        }
        set t
      }]
      set mergedSinksType [findMostFrequentElement $rawMergeSinksType 50 1]
      #puts "origin: $rawSinksType"
      #puts "rawMerge: $rawMergeSinksType"
      #puts "merged: $mergedSinksType"
      
      ## sinks all are only one type of cellclass
      
    }
    lappend cmdList " "
    lappend cmdList "setEcoMode -reset"

    # --------------------
    # summary of result: TODO:(FIXED in U004) need make similar part for one2more situations
    set fixedSituationSortNumber [lmap item $fixedList_1v1 {
      set symbol [lindex $item 0]
    }]
    set situs [lsort -unique $fixedSituationSortNumber]
    foreach s $situs { set num_$s 0 }
    foreach item $fixedSituationSortNumber {
      foreach s $situs {
        if {$item == $s} {
          incr num_$s; # calculate number of every method
        }
      }
    }
    set fixedMethodSortNumber [lmap item $fixedList_1v1 {
      set symbol [lindex $item 1]
    }]
    set methods [lsort -unique $fixedMethodSortNumber]
    foreach m $methods { set num_$m 0 }
    foreach item $fixedMethodSortNumber {
      foreach method $methods {
        if {$item == $method} {
          incr num_$method; # calculate number of every method
        }
      }
    }
    # summary of result: one 2 more U004
    set fixedSituationSortNumber_one2more [lmap item $fixedList_one2more {
      set symbol [lindex $item 0]
    }]
    set m_situs [lsort -unique $fixedSituationSortNumber_one2more]
    foreach s $m_situs { set num_$s 0 }
    foreach item $fixedSituationSortNumber_one2more {
      foreach s $m_situs {
        if {$item == $s} {
          incr m_num_$s; # calculate number of every method
        }
      }
    }
    set fixedMethodSortNumber_one2more [lmap item $fixedList_one2more {
      set symbol [lindex $item 1]
    }]
    set m_methods [lsort -unique $fixedMethodSortNumber_one2more]
    foreach m $m_methods { set num_$m 0 }
    foreach item $fixedMethodSortNumber_one2more {
      foreach method $m_methods {
        if {$item == $method} {
          incr m_num_$method; # calculate number of every method
        }
      }
    }
    # print to window
    ## file that can't extract cuz it is drivePin
    set ce [open $cantExtractFile w]
    set co [open $cmdFile w]
    set sf [open $sumFile w]
    set di [open $one2moreDetailViolInfo w]
    if {1} {
      ## 1 v 1
      ### can't extract
      puts $ce "CANT EXTRACT:"
      puts $ce ""
      if {[info exists cantExtractList]} { puts $ce [join $cantExtractList \n] }
      ### file of cmds 
      set beginIndexOfOne2MoreCmds [expr [lsearch -exact $cmdList $beginOfOne2MoreCmds] + 2]
      set endIndexOfOne2MoreCmds [expr [lindex [lsearch -exact -all $cmdList "setEcoMode -reset"] end] - 2]
      set reverseOne2MoreCmdFromCmdList [reverseListRange $cmdList $beginIndexOfOne2MoreCmds $endIndexOfOne2MoreCmds 0 0 1 "#"]
      pw $co [join $cmdList \n]

      ### file of summary
      pw $sf "Summary of fixed:"
      pw $sf ""
      pw $sf "FIXED CELL LIST"
      pw $sf [join $fixedPrompts \n]
      pw $sf ""
      pw $sf [print_formatedTable $fixedList_1v1]
      pw $sf "total fixed : [expr [llength $fixedList_1v1] - 1]"
      pw $sf ""
      pw $sf "situ  num"
      foreach s $situs { set num [eval set -nonewline \${num_${s}}]; lappend situ_number [list $s $num] }
      pw $sf [print_formatedTable $situ_number]
      pw $sf ""
      pw $sf "method num"
      foreach m $methods { set num [eval set -nonewline \${num_${m}}]; lappend method_number [list $m $num] }
      pw $sf [print_formatedTable $method_number]
      pw $sf ""
      pw $sf "CANT CHANGE LIST"
      pw $sf [join $cantChangePrompts \n]
      pw $sf ""
      pw $sf [print_formatedTable $cantChangeList_1v1]
      pw $sf ""
      pw $sf "SKIPPED LIST"
      pw $sf [join $skippedSituationsPrompt \n]
      pw $sf ""
      pw $sf [print_formatedTable $skippedList_1v1]
      pw $sf ""
      pw $sf "NOT CONSIDERED LIST"
      pw $sf ""
      pw $sf [join $notConsideredPrompt \n]
      pw $sf ""
      pw $sf [print_formatedTable $notConsideredList_1v1]
      pw $sf "total non-considered [expr [llength $notConsideredList_1v1] - 1]"

      ## one 2 more
      ### primarily focus on driver capacity and cell type, if have too many loaders, can fix fanout! (need notice some sticks)
      pw $sf ""
      pw $sf "FIXED CELL LIST: ONE 2 MORE"
      pw $sf [join $fixedPrompts_one2more \n]
      pw $sf ""
      if {[llength $fixedList_one2more] >= 2} {
        set reversedFixedList_one2more [reverseListRange $fixedList_one2more 1 end 0]
      } else {
        set reversedFixedList_one2more $fixedList_one2more
      }
      pw $sf [print_formatedTable $reversedFixedList_one2more]
      pw $sf "total fixed : [expr [llength $fixedList_one2more] - 1]"
      pw $sf ""
      pw $sf "situ  num"
      foreach s $m_situs { set num [eval set -nonewline \${m_num_${s}}]; lappend m_situ_number [list $s $num] }
      pw $sf [print_formatedTable $m_situ_number]
      pw $sf ""
      pw $sf "method num"
      foreach m $m_methods { set num [eval set -nonewline \${m_num_${m}}]; lappend m_method_number [list $m $num] }
      pw $sf [print_formatedTable $m_method_number]
      pw $sf ""
      pw $sf "CANT CHANGE LIST: ONE 2 MORE"
      pw $sf [join $cantChangePrompts_one2more \n]
      pw $sf ""
      pw $sf [print_formatedTable $cantChangeList_one2more]
      pw $sf ""
      pw $sf "SKIPPED LIST: ONE 2 MORE"
      pw $sf [join $skippedSituationsPrompt_one2more \n]
      pw $sf ""
      pw $sf [print_formatedTable $skippedList_one2more]
      pw $sf ""
      pw $sf "NOT CONSIDERED LIST: ONE 2 MORE"
      pw $sf ""
      pw $sf [join $notConsideredPrompt_one2more \n]
      pw $sf ""
      pw $sf [print_formatedTable $notConsideredList_one2more]
      pw $sf "total non-considered [expr [llength [lsort -unique -index 5 $notConsideredList_one2more]] - 1]"
      pw $sf ""
      pw $sf "DIFF TYPES OF SINKS: ONE 2 MORE"
      pw $sf ""
      pw $sf [print_formatedTable $one2moreList_diffTypesOfSinks]
      pw $sf "total viol drivePin (sorted) with diff types of sinks: [expr [llength [lsort -unique -index 6 $one2moreList_diffTypesOfSinks]] - 1]"
      
      puts $di "ONE to MORE SITUATIONS (different sinks cell class!!! need to improve, i can't fix now)"
      puts $di ""
      puts $di [print_formatedTable $one2moreDetailList_withAllViolSinkPinsInfo]
      puts $di "total of all viol sinks : [expr [llength $one2moreDetailList_withAllViolSinkPinsInfo] - 1]"
      puts $di "total of all viol drivePin (sorted) : [expr [llength [lsort -unique -index 5 $one2moreDetailList_withAllViolSinkPinsInfo]] - 1]"
      puts $di ""

      # summary of two situations
      pw $sf ""
      pw $sf "TWO SITUATIONS OF ALL VIOLATIONS:"
      pw $sf "1 v 1    number: [llength $violValue_driverPin_onylOneLoaderPin_D3List]"
      pw $sf "1 v more number: [llength [lsort -unique -index 1 $violValue_drivePin_loadPin_numSinks_sinks_D5List]]"
      pw $sf ""
    }
    close $ce
    close $co
    close $sf
    close $di
  }
}
define_proc_arguments fix_trans \
  -info "fix transition"\
  -define_args {
    {-file_viol_pin "specify violation filename" AString string required}
    {-violValue_pin_columnIndex "specify the column of violValue and pinname" AList list optional}
    {-canChangeVT "if it use strategy of changing VT" "" boolean optional}
    {-canChangeDriveCapacity "if it use strategy of changing drive capacity" "" boolean optional}
    {-canChangeVTandDriveCapacity "if it use strategy of changing VT and drive capacity" "" boolean optional}
    {-canAddRepeater "if it use strategy of adding repeater" "" boolean optional}
    {-unitOfNetLength "sepcify unit of min net length" AFloat float optional}
    {-refBufferCelltype "specify ref buffer cell type name" AString string optional}
    {-refInverterCelltype "specify ref inverter cell type name" AString string optional}
    {-refCLKBufferCelltype "specify ref clk buffer cell type name" AString string optional}
    {-refCLKInverterCelltype "specify ref clk inverter cell type name" AString string optional}
    {-cellRegExp "specify universal regExp for this process celltype, need pick out driveCapacity and VTtype" AString string optional}
    {-rangeOfVtSpeed "specify range of vt speed, it will be different from every process" AList list optional}
    {-clkNeedVtWeightList "specify vt weight list clock-needed" AList list optional}
    {-normalNeedVtWeightList "specify normal(std cell need) vt weight list" AList list optional}
    {-specialNeedVtWeightList "specify special check for VT in violated drive inst" AList list optional}
    {-rangeOfDriveCapacityForChange "specify range of drive capacity for ecoChangeCell" AList list optional}
    {-rangeOfDriveCapacityForAdd "specify range of drive capacity for ecoAddRepeater" AList list optional}
    {-largerThanDriveCapacityOfChangedCelltype "specify drive capacity to meet rule in FIXED U001" AList list optional}
    {-ecoNewInstNamePrefix "specify a new name for inst when adding new repeater" AList list required}
    {-suffixFilename "specify suffix of result filename" AString string optional}
    {-debug "debug mode" "" boolean optional}
  }
# needn't to set options as below:
#    {-sumFile "specify summary filename" AString string optional}
#    {-cantExtractFile "specify cantExtract file name" AString string optional}
#    {-cmdFile "specify cmd file name" AString string optional}
#    {-one2moreDetailViolInfo "specify one2more detailed viol info, there are all violated sinks pin and other info" AString string optional}

proc get_driveCapacity_of_celltype {{celltype ""} {regExp "X(\\d+).*(A\[HRL\]\\d+)$"}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e ] == ""} { ; # FIXED: U003: before: dbget top.insts.cell.name $celltype -e
    return "0x0:1"; # check your input 
  } else {
    set wholename 0
    set driveLevel 0
    set VTtype 0
    regexp $regExp $celltype wholename driveLevel VTtype 
    if {$driveLevel == "05"} {set driveLevel 0.5}
    return $driveLevel
  }
}
