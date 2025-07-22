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
    return "0x0:1"; # check your file 
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
        return "0x0:2"; # column([lindex $violValue_pin_columnIndex 0]) is not number
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
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 1: mem
      if {$driveCellClass == "mem"} {
        lappend cantChangeList_1v1 [concat "in_0" "M_D" $allInfoList]
        set cmd1 "cantChange"
      } elseif {$loadCellClass == "mem"} {
        lappend cantChangeList_1v1 [concat "in_0" "M_S" $allInfoList]
        set cmd1 "cantChange"
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 2: logic to logic
      } elseif {$driveCellClass in {delay logic CLKlogic} && $loadCellClass in {delay logic CLKlogic}} { ; # songNOTE: now dont split between different cell classes
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        # some useful flag
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "ll:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "ll:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "ll:in_1:3" "NL" $allInfoList] 
        }
        #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
              } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
            if {$debug} { puts "------" }
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            if {$debug} { puts "ll:in_1:1 FS changeVT : $toChangeCelltype" }
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype] 
            if {$debug} { puts "ll:in_1:1 FS changeDrive : $toChangeCelltype" }
            lappend fixedList_1v1 [concat "ll:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "ll:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                   $violnum >= -0.01 && $netLength > [expr $unitOfNetLength  * 15 ] || \
                   $violnum >= -0.02 && $netLength > [expr $unitOfNetLength  * 30 ] \
                   ]} { ; # songNOTE: situation 01 only changeVT,
          # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "ll:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.04 && $netLength <= [expr $unitOfNetLength * 1.5]} { ; # songNOTE: situation 02 only changeDriveCapacity
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
#puts "in 2: $driveCelltype $toChangeCelltype"
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity == 0.5} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity in {1 2}} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "ll:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  $violnum >= -0.05 && $netLength <= [expr $unitOfNetLength * 2.2] ||  $violnum >= -0.11 && $netLength <= [expr $unitOfNetLength * 1.4]]} { ; # songNOTE: situation 03 change VT and DriveCapacity
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "ll:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "ll:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.08  && $violnum >= -0.1 && $netLength < [expr $unitOfNetLength * 4] && $netLength > [expr $unitOfNetLength * 2]} { ; # songNOTE: situation 04 add Repeater near logic cell
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          #puts  "in 4: $driveCelltype --  $toChangeCelltype song"
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
            lappend fixedList_1v1 [concat "ll:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "ll:in_6:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        } elseif {$canAddRepeater && $violnum < -0.12 && $netLength > [expr $unitOfNetLength * 9]} { ; # songNOTE: situation 05 not in above situation
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_7:1" "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "ll:in_7:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              if {$debug} {puts "test : ll:in_7:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
                lappend fixedList_1v1 [concat "ll:in_7:3" "TA_09" $toAddCelltype $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_1v1 [concat "ll:in_7:4" "A_09" $toAddCelltype $allInfoList]
                set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              }
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.1 && $netLength < [expr $unitOfNetLength * 1]} {; # fix viol big and short length
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_6:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
#puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ; # specify 8 drive capacity is special set for this case viol > 100ps and net length < 10um
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "ll:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "ll:in_6:4" "A_09" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            }
          }
        } else { ; # songNOTE: situation 05 not in above situation
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
            if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
            set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
            lappend fixedList_1v1 [concat "ll:in_8:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
            if {$debug} {puts "test : ll:in_8:2"}
            set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
          } else {
            lappend fixedList_1v1 [concat "ll:in_8:4" "A_09" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
          }
        }
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 3: logic to buffer/inverter
      ### TODO: logic to buffer : consider insert two buffers: insert on middle of net, and on drive side of net!!! (to fix long net and huge violation situation)
      } elseif {$driveCellClass in {delay logic CLKlogic} && $loadCellClass in {buffer inverter CLKbuffer CLKinverter}} { ; # songNOTE: now dont split between different cell classes
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "lb:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "lb:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "lb:in_1:3" "NL" $allInfoList] 
        }
        #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
            } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 6 || [expr  $driveCapacity - $sinkCapacity] < 2]} {
            set leftStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 4 3]
            set rightStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 3 2]
            set leftStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 5 $leftStair]
            set rightStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 4 $rightStair]
            #### songNOTE: TODO: expanded to all case with above method
            if {$debug} { puts "----------------" }
            if {$debug} { puts "driveCapacity: $driveCapacity  | sinkCapacity: $sinkCapacity" }
            if {$debug} { puts "left: $leftStair  right: $rightStair" }
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 2] $leftStair $rightStair] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype] 
            lappend fixedList_1v1 [concat "lb:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "lb:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && $violnum >= -0.005} { ; # songNOTE: situation 01 only changeVT
          # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "lb:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.015 && $netLength <= [expr $unitOfNetLength * 1.1]} { ; # songNOTE: situation 02 only changeDriveCapacity
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          #puts "in 2: $driveCelltype $toChangeCelltype"
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity == 0.5} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity in {1 2}} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "lb:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && $violnum >= -0.04 && $netLength <= [expr $unitOfNetLength * 1.8]} { ; # songNOTE: situation 03 change VT and DriveCapacity
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "lb:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "lb:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum >= -0.12 && $netLength < [expr $unitOfNetLength * 5] && $netLength > [expr $unitOfNetLength * 1]} { ; # songNOTE: situation 04 add Repeater near logic cell
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_6:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            #puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "lb:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "lb:in_6:4" "A_09" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.18 && $netLength > [expr $unitOfNetLength * 4]} { ; # songNOTE: add two repeater
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_7:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            #puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "lb:in_7:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
            } else {
              lappend fixedList_1v1 [concat "lb:in_7:4" "AA_0509" $toAddCelltype $allInfoList]
              set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.22 && $netLength > [expr $unitOfNetLength * 4]} { ; # songNOTE: situation 05 not in above situation
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_8:1" "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 8 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "lb:in_8:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              if {$debug} {puts "test : lb:in_8:2"}
              set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
              if {$debug} {puts $cmd1}
            } else {
              lappend fixedList_1v1 [concat "lb:in_8:4" "AA_0509" $toAddCelltype $allInfoList]
              set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
            }
          }
        } elseif {$canAddRepeater && [expr $violnum > -0.2 && $netLength < [expr $unitOfNetLength * 4] && $netLength > [expr $unitOfNetLength * 1.5] || \
                                    $violnum > -0.4 && $netLength < [expr $unitOfNetLength * 6] && $netLength > [expr $unitOfNetLength * 2]]} {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_9:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "lb:in_9:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "lb:in_9:4" "A_09" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            }
          }
        } else {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_0:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "lb:in_0:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "lb:in_0:4" "A_09" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            }
          }
        }
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 4: buffer/inverter to logic
      } elseif {$driveCellClass in {buffer inverter CLKbuffer CLKinverter} && $loadCellClass in {delay logic CLKlogic}} { ; # songNOTE: now dont split between different cell classes
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "bl:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "bl:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "bl:in_1:3" "NL" $allInfoList] 
        }
        #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
            } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr  $driveCapacity - $sinkCapacity] < 0]} {
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 3] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype] 
            lappend fixedList_1v1 [concat "bl:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "bl:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.02 || \
                   $violnum >= -0.01 && $netLength > [expr $unitOfNetLength  * 15 ] || \
                   $violnum >= -0.02 && $netLength > [expr $unitOfNetLength  * 30 ] \
                   ]} { ; # songNOTE: situation 01 only changeVT,
          # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bl:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bl:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "bl:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.04 && $netLength <= [expr $unitOfNetLength * 2.1]} { ; # songNOTE: situation 02 only changeDriveCapacity
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          #puts "in 2: $driveCelltype $toChangeCelltype"
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity in {0.5 1 2}} { ; # buffer/inverter to logic, don't need change a lot
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bl:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "bl:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && $violnum >= -0.06 && $netLength <= [expr $unitOfNetLength * 2.5]} { ; # songNOTE: situation 03 change VT and DriveCapacity
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bl:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bl:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "bl:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "bl:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.06  && $violnum >= -0.1 && $netLength < [expr $unitOfNetLength * 4] && $netLength > [expr $unitOfNetLength * 2]} { ; # songNOTE: situation 04 add Repeater near logic cell
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "bl:in_6:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            #puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "bl:in_6:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "bl:in_6:4" "A_05" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            }
          }
        } else { ; # songNOTE: situation 05 not in above situation
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "bl:in_7:1" "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "bl:in_7:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "bl:in_7:4" "A_05" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            }
          }
        }
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 5: buffer/inverter to buffer/inverter
      } elseif {$driveCellClass in {CLKbuffer CLKinverter buffer inverter} && $loadCellClass in {CLKbuffer CLKinverter buffer inverter}} { ; # songNOTE: now dont split between different cell classes
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "bb:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "bb:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "bb:in_1:3" "NL" $allInfoList] 
        }
        #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
            } { ; # songNOTE: special situation
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity < 4 || [expr  $driveCapacity - $sinkCapacity] < 0]} {
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 4] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype] 
            lappend fixedList_1v1 [concat "bb:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "bb:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.015 || \
           $violnum >= -0.02 && $netLength >= [expr $unitOfNetLength * 20]  || \
           $violnum >= -0.03 && $netLength >= [expr $unitOfNetLength * 30] \
          ] } { ; # songNOTE: situation 01 only changeVT,
          # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "bb:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.04 && $netLength <= [expr $unitOfNetLength * 1.5]} { ; # songNOTE: situation 02 only changeDriveCapacity
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          #puts "in 2: $driveCelltype $toChangeCelltype"
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity in {0.5 1 2}} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "bb:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && $violnum >= -0.07 && $netLength <= [expr $unitOfNetLength * 2.2]} { ; # songNOTE: situation 03 change VT and DriveCapacity
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "bb:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "bb:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.08  && $violnum >= -0.1 && $netLength < [expr $unitOfNetLength * 4] && $netLength > [expr $unitOfNetLength * 2]} { ; # songNOTE: situation 04 add Repeater near logic cell
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_6:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            #puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "bb:in_6:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "bb:in_6:4" "A_05" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            }
          }
        } else { ; # songNOTE: situation 05 not in above situation
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_7:1" "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "bb:in_7:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "bb:in_7:4" "A_05" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            }
          }
        }
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 6: logic to sequential  (related to logic to buffer, add repeater as much as possible)
      } elseif {$driveCellClass in {delay logic CLKlogic} && $loadCellClass in {sequential}} {
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "ls:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "ls:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "ls:in_1:3" "NL" $allInfoList] 
        }
        #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
            } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 6 || [expr  $driveCapacity - $sinkCapacity] < 2]} {
            set leftStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 4 3]
            set rightStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 3 2]
            set leftStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 5 $leftStair]
            set rightStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 4 $rightStair]
            #### songNOTE: TODO: expanded to all case with above method
            if {$debug} { puts "----------------" }
            if {$debug} { puts "driveCapacity: $driveCapacity  | sinkCapacity: $sinkCapacity" }
            if {$debug} { puts "left: $leftStair  right: $rightStair" }
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 2] $leftStair $rightStair] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype] 
            lappend fixedList_1v1 [concat "ls:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "ls:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && $violnum >= -0.005} { ; # songNOTE: situation 01 only changeVT
          # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ls:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ls:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "ls:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.01 && $netLength <= [expr $unitOfNetLength * 1.1]} { ; # songNOTE: situation 02 only changeDriveCapacity
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          #puts "in 2: $driveCelltype $toChangeCelltype"
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity == 0.5} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity in {1 2}} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ls:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "ls:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && $violnum >= -0.03 && $netLength <= [expr $unitOfNetLength * 1.7]} { ; # songNOTE: situation 03 change VT and DriveCapacity
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ls:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ls:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "ls:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "ls:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum >= -0.12 && $netLength < [expr $unitOfNetLength * 5] && $netLength > [expr $unitOfNetLength * 1]} { ; # songNOTE: situation 04 add Repeater near logic cell
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "ls:in_6:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            #puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "ls:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "ls:in_6:4" "A_09" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.18 && $netLength > [expr $unitOfNetLength * 5]} { ; # songNOTE: add two repeater
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "ls:in_7:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            #puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "ls:in_7:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
            } else {
              lappend fixedList_1v1 [concat "ls:in_7:4" "AA_0509" $toAddCelltype $allInfoList]
              set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.22 && $netLength > [expr $unitOfNetLength * 5]} { ; # songNOTE: situation 05 not in above situation
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "ls:in_8:1" "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 8 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "ls:in_8:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              if {$debug} {puts "test : ls:in_8:2"}
              set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
              if {$debug} {puts $cmd1}
            } else {
              lappend fixedList_1v1 [concat "ls:in_8:4" "AA_0509" $toAddCelltype $allInfoList]
              set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
            }
          }
        } elseif {$canAddRepeater && [expr $violnum > -0.2 && $netLength < [expr $unitOfNetLength * 4] || \
                                    $violnum > -0.4 && $netLength < [expr $unitOfNetLength * 6]]} {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "ls:in_9:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "ls:in_9:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "ls:in_9:4" "A_09" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            }
          }
        } else {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "ls:in_0:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "ls:in_0:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "ls:in_0:4" "A_09" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            }
          }
        }
        
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 7: sequential to logic (related to logic to buffer, add repeater as much as possible )
      } elseif {$driveCellClass in {sequential} && $loadCellClass in {delay logic CLKlogic}} {
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "sl:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "sl:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "sl:in_1:3" "NL" $allInfoList] 
        }
        #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
            } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 6 || [expr  $driveCapacity - $sinkCapacity] < 2]} {
            set leftStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 4 3]
            set rightStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 3 2]
            set leftStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 5 $leftStair]
            set rightStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 4 $rightStair]
            #### songNOTE: TODO: expanded to all case with above method
            if {$debug} { puts "----------------" }
            if {$debug} { puts "driveCapacity: $driveCapacity  | sinkCapacity: $sinkCapacity" }
            if {$debug} { puts "left: $leftStair  right: $rightStair" }
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 2] $leftStair $rightStair] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype] 
            lappend fixedList_1v1 [concat "sl:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "sl:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && $violnum >= -0.005} { ; # songNOTE: situation 01 only changeVT
          # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sl:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sl:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "sl:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.01 && $netLength <= [expr $unitOfNetLength * 1.1]} { ; # songNOTE: situation 02 only changeDriveCapacity
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          #puts "in 2: $driveCelltype $toChangeCelltype"
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity == 0.5} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity in {1 2}} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sl:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "sl:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && $violnum >= -0.03 && $netLength <= [expr $unitOfNetLength * 1.7]} { ; # songNOTE: situation 03 change VT and DriveCapacity
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sl:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sl:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "sl:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "sl:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum >= -0.12 && $netLength < [expr $unitOfNetLength * 5] && $netLength > [expr $unitOfNetLength * 1]} { ; # songNOTE: situation 04 add Repeater near logic cell
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "sl:in_6:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            #puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "sl:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "sl:in_6:4" "A_09" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.18 && $netLength > [expr $unitOfNetLength * 5]} { ; # songNOTE: add two repeater
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "sl:in_7:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            #puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "sl:in_7:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
            } else {
              lappend fixedList_1v1 [concat "sl:in_7:4" "AA_0509" $toAddCelltype $allInfoList]
              set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.22 && $netLength > [expr $unitOfNetLength * 5]} { ; # songNOTE: situation 05 not in above situation
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "sl:in_8:1" "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 8 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "sl:in_8:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              if {$debug} {puts "test : sl:in_8:2"}
              set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
              if {$debug} {puts $cmd1}
            } else {
              lappend fixedList_1v1 [concat "sl:in_8:4" "AA_0509" $toAddCelltype $allInfoList]
              set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
            }
          }
        } elseif {$canAddRepeater && [expr $violnum > -0.2 && $netLength < [expr $unitOfNetLength * 4] || \
                                    $violnum > -0.4 && $netLength < [expr $unitOfNetLength * 6]]} {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "sl:in_9:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "sl:in_9:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "sl:in_9:4" "A_09" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            }
          }
        } else {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "sl:in_0:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "sl:in_0:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "sl:in_0:4" "A_09" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            }
          }
        }
        
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 8: sequential to buffer (related to logic to buffer, add repeater as much as possible)
      } elseif {$driveCellClass in {sequential} && $loadCellClass in {buffer inverter CLKbuffer CLKinverter}} {
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "sb:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "sb:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "sb:in_1:3" "NL" $allInfoList] 
        }
        #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
            } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 6 || [expr  $driveCapacity - $sinkCapacity] < 2]} {
            set leftStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 4 3]
            set rightStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $sinkCapacity] <= -5] 3 2]
            set leftStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 5 $leftStair]
            set rightStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $sinkCapacity] <= -10] 4 $rightStair]
            #### songNOTE: TODO: expanded to all case with above method
            if {$debug} { puts "----------------" }
            if {$debug} { puts "driveCapacity: $driveCapacity  | sinkCapacity: $sinkCapacity" }
            if {$debug} { puts "left: $leftStair  right: $rightStair" }
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 2] $leftStair $rightStair] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype] 
            lappend fixedList_1v1 [concat "sb:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "sb:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && $violnum >= -0.005} { ; # songNOTE: situation 01 only changeVT
          # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sb:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sb:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "sb:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.01 && $netLength <= [expr $unitOfNetLength * 1.1]} { ; # songNOTE: situation 02 only changeDriveCapacity
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          #puts "in 2: $driveCelltype $toChangeCelltype"
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity == 0.5} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity in {1 2}} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sb:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "sb:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && $violnum >= -0.03 && $netLength <= [expr $unitOfNetLength * 1.7]} { ; # songNOTE: situation 03 change VT and DriveCapacity
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sb:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "sb:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "sb:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "sb:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum >= -0.12 && $netLength < [expr $unitOfNetLength * 5] && $netLength > [expr $unitOfNetLength * 1]} { ; # songNOTE: situation 04 add Repeater near logic cell
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "sb:in_6:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            #puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "sb:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "sb:in_6:4" "A_09" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.18 && $netLength > [expr $unitOfNetLength * 5]} { ; # songNOTE: add two repeater
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "sb:in_7:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            #puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "sb:in_7:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
            } else {
              lappend fixedList_1v1 [concat "sb:in_7:4" "AA_0509" $toAddCelltype $allInfoList]
              set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.22 && $netLength > [expr $unitOfNetLength * 5]} { ; # songNOTE: situation 05 not in above situation
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "sb:in_8:1" "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 8 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "sb:in_8:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              if {$debug} {puts "test : sb:in_8:2"}
              set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
              if {$debug} {puts $cmd1}
            } else {
              lappend fixedList_1v1 [concat "sb:in_8:4" "AA_0509" $toAddCelltype $allInfoList]
              set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
            }
          }
        } elseif {$canAddRepeater && [expr $violnum > -0.2 && $netLength < [expr $unitOfNetLength * 4] || \
                                    $violnum > -0.4 && $netLength < [expr $unitOfNetLength * 6]]} {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "sb:in_9:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "sb:in_9:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "sb:in_9:4" "A_09" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            }
          }
        } else {
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "sb:in_0:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "sb:in_0:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "sb:in_0:4" "A_09" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
            }
          }
        }
        
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 9: buffer to sequential (related to buffer to logic, change drive capacity of buffer as much as possible)
      } elseif {$driveCellClass in {buffer inverter CLKbuffer CLKinverter} && $loadCellClass in {sequential}} {
        if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
        set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
        set ifHaveSlowerVT 0
        set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
        if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
        set ifHaveSmallerCapacity 0
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "bs:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "bs:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "bs:in_1:3" "NL" $allInfoList] 
        }
        #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
        if {$violnum < -0.2 && $netLength < 20 || \
            $violnum < -0.1 && $netLength < 10 || \
            $violnum < -0.07 && $netLength < 8 || \
            $violnum < -0.03 && $netLength < 4 \
            } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr  $driveCapacity - $sinkCapacity] < 0]} {
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 3] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype] 
            lappend fixedList_1v1 [concat "bs:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "bs:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.02 || \
                   $violnum >= -0.01 && $netLength > [expr $unitOfNetLength  * 15 ] || \
                   $violnum >= -0.02 && $netLength > [expr $unitOfNetLength  * 30 ] \
                   ]} { ; # songNOTE: situation 01 only changeVT,
          # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
          if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bs:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bs:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "bs:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.04 && $netLength <= [expr $unitOfNetLength * 2.1]} { ; # songNOTE: situation 02 only changeDriveCapacity
          if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          #puts "in 2: $driveCelltype $toChangeCelltype"
          if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity in {0.5 1 2}} { ; # buffer/inverter to logic, don't need change a lot
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bs:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "bs:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && $violnum >= -0.06 && $netLength <= [expr $unitOfNetLength * 2.5]} { ; # songNOTE: situation 03 change VT and DriveCapacity
          if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bs:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bs:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "bs:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "bs:in_5:4" "TD" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && $violnum < -0.06  && $violnum >= -0.1 && $netLength < [expr $unitOfNetLength * 4] && $netLength > [expr $unitOfNetLength * 2]} { ; # songNOTE: situation 04 add Repeater near logic cell
          if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "bs:in_6:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            #puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "bs:in_6:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "bs:in_6:4" "A_05" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            }
          }
        } else { ; # songNOTE: situation 05 not in above situation
          if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
          if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "bs:in_7:1" "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
              if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "bs:in_7:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              lappend fixedList_1v1 [concat "bs:in_7:4" "A_05" $toAddCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
            }
          }
        }
        
      }

      ## songNOTE:FIXED:U001 check all fixed celltype(changed). if it is smaller than X1 (such as X05), it must change to X1 or larger
      # ONLY check $toChangeCelltype, NOT check $toAddCelltype
      #### ADVANCE TODO:U002 can specify logic rule and buffer/inverter rule, you can set it seperately
      if {$debug} { puts "TEST: $toChangeCelltype" }
      if {$cmd1 != "" && $cmd1 != "cantChange" && [get_driveCapacity_of_celltype $toChangeCelltype $cellRegExp] < $largerThanDriveCapacityOfChangedCelltype} { ; # drive capacity of changed cell must be larger than X1
        set checkedSymbol "C"
        set checkedCmd ""
        set preToChangeCell $toChangeCelltype
        set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype $largerThanDriveCapacityOfChangedCelltype 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
        set checkedCmd [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
        if {[llength $cmd1] > 1 && [llength $cmd1] < 5 && ![regexp "0x0" $checkedCmd] && $checkedCmd != ""} {
          set indexChangeCmd [lsearch -regexp $cmd1 "^ecoChangeCell .*"]
          set cmd1 [lreplace $cmd1 $indexChangeCmd $indexChangeCmd $checkedCmd]
        } elseif {[llength $cmd1] >= 5 && [regexp "ecoChangeCell" $cmd1] && ![regexp "0x0" $checkedCmd] && $checkedCmd != ""} {
          set cmd1 $checkedCmd
        }
        set methodColumn [lindex [lindex $fixedList_1v1 end] 1]
        set celltypeToFix [lindex [lindex $fixedList_1v1 end] 2]
        set fixedList_1v1 [lreplace $fixedList_1v1 end end [lreplace [lindex $fixedList_1v1 end] 1 2 [append methodColumn "_" $checkedSymbol ] [regsub $preToChangeCell $celltypeToFix $toChangeCelltype]]]
        if {$debug} { puts "TEST FIXEDLIST large : [llength $fixedList_1v1]" }
        if {$debug} { puts [lindex $fixedList_1v1 end] }
      }
      if {$debug} { puts "TEST END: $cmd1\n   $checkedCmd" }
      
      if {$cmd1 != "cantChange" && $cmd1 != ""} { ; # consider not-checked situation; like ip to ip, mem to mem, r2p
        lappend cmdList "# [lindex $fixedList_1v1 end]"
        if {[llength $cmd1] < 5} { ; # because shortest eco cmd need 5 items at least (ecoChangeCell -inst instname -cell celltype)
          set cmdList [concat $cmdList $cmd1]; #!!!
        } else {
          lappend cmdList $cmd1
        }
      } elseif {$cmd1 == ""} {
        lappend notConsideredList_1v1 [concat "NC" $allInfoList]
      }
if {$debug} { puts "# -----------------" }
    }
##### END OF LOOP FOR 1 v 1
    #
    # BEGIN OF ONE 2 MORE SITUATIONS
    if {[llength $violValue_drivePin_loadPin_numSinks_sinks_D5List]} {
      lappend cmdList " "
      lappend cmdList "# BEGIN OF ONE 2 MORE SITUATIONS:"
      lappend cmdList " "
    }

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
      if {[llength $mergedSinksType] == 1} { ; # if type of sinks is only one class
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 1: (one2more) logic to logic
        if {$driveCellClass in {delay logic CLKlogic} && $mergedSinksType in {delay logic CLKlogic}} {
          set locOffSink 0.8 ; # off relatived to center pt of sinks
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          # some useful flag
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mll:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "mll:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mll:in_1:3" "NL" $allInfoList] 
          }
          #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 10 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 7 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 1 \
                } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "mll:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2] 
              if {$debug} { puts "mll:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "mll:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "mll:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ; # songNOTE: situation 01 only changeVT,
            # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mll:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mll:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mll:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.03 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2]} { ; # songNOTE: situation 02 only changeDriveCapacity
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            #puts "in 2: $driveCelltype $toChangeCelltype2"
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mll:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mll:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.04 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.2] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.4]] || \
                                                                                    [expr $violnum >= -0.02  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2] && $numSinks > 15] ]} { ; # songNOTE: situation 03 change VT and DriveCapacity
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mll:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mll:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "mll:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "mll:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 4] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 5 || \
                                                                   $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 2] && $numSinks > 5]} { ; # songNOTE: situation 04 add Repeater near logic cell
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mll:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mll:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mll:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.12 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.5]} { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mll:in_7:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mll:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : mll:in_7:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                if {$ifHaveFasterVT} {
                  set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                  lappend fixedList_one2more [concat "mll:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                  set cmd2 [concat $cmd_TA_driveInst $cmd_TA_add]
                } else {
                  lappend fixedList_one2more [concat "mll:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                }
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 0.6]} {; # fix viol big and short length
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mll:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ; # specify 8 drive capacity is special set for this case viol > 100ps and net length < 10um
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mll:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mll:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } else { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mll:in_8:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mll:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : mll:in_8:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mll:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          }
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 2: (one2more) buffer to buffer
        } elseif {$driveCellClass in {buffer inverter CLKbuffer CLKinverter} && $mergedSinksType in {buffer inverter CLKbuffer CLKinverter}} {
          set locOffSink 0.6 ; # off relatived to center pt of sinks
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          # some useful flag
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mbb:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "mbb:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mbb:in_1:3" "NL" $allInfoList] 
          }
          #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 10 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 6 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 1 \
                } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "mbb:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2] 
              if {$debug} { puts "mbb:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "mbb:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "mbb:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ; # songNOTE: situation 01 only changeVT,
            # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbb:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbb:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mbb:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.03 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2]} { ; # songNOTE: situation 02 only changeDriveCapacity
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            #puts "in 2: $driveCelltype $toChangeCelltype2"
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbb:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mbb:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.04 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.2] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.4]] || \
                                                                                    [expr $violnum >= -0.02  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2] && $numSinks > 15] ]} { ; # songNOTE: situation 03 change VT and DriveCapacity
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbb:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbb:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "mbb:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "mbb:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 4] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 5 || \
                                                                   $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 2] && $numSinks > 5]} { ; # songNOTE: situation 04 add Repeater near logic cell
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mbb:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mbb:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mbb:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.12 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.5]} { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mbb:in_7:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mbb:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : mbb:in_7:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                if {$ifHaveFasterVT} {
                  set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                  lappend fixedList_one2more [concat "mbb:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                  set cmd2 [concat $cmd_TA_driveInst $cmd_TA_add]
                } else {
                  lappend fixedList_one2more [concat "mbb:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                }
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * $off]} {; # fix viol big and short length
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mbb:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ; # specify 8 drive capacity is special set for this case viol > 100ps and net length < 10um
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mbb:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mbb:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } else { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mbb:in_8:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mbb:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : mbb:in_8:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mbb:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          }
          
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 3: (one2more) logic to buffer
        } elseif {$driveCellClass in {delay logic CLKlogic} && $mergedSinksType in {buffer inverter CLKbuffer CLKinverter}} {
          set locOffSink 0.9 ; # off relatived to center pt of sinks
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          # some useful flag
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mlb:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "mlb:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mlb:in_1:3" "NL" $allInfoList] 
          }
          #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 7 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 4 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 1 \
                } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "mlb:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2] 
              if {$debug} { puts "mlb:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "mlb:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "mlb:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ; # songNOTE: situation 01 only changeVT,
            # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mlb:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mlb:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mlb:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.03 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2]} { ; # songNOTE: situation 02 only changeDriveCapacity
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            #puts "in 2: $driveCelltype $toChangeCelltype2"
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mlb:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mlb:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.04 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.2] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.4]] || \
                                                                                    [expr $violnum >= -0.02  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2] && $numSinks > 15] ]} { ; # songNOTE: situation 03 change VT and DriveCapacity
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mlb:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mlb:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "mlb:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "mlb:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 4] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 5 || \
                                                                   $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 2] && $numSinks > 5]} { ; # songNOTE: situation 04 add Repeater near logic cell
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mlb:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mlb:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mlb:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.12 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.5]} { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mlb:in_7:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mlb:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : mlb:in_7:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                if {$ifHaveFasterVT} {
                  set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                  lappend fixedList_one2more [concat "mlb:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                  set cmd2 [concat $cmd_TA_driveInst $cmd_TA_add]
                } else {
                  lappend fixedList_one2more [concat "mlb:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                }
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 0.6]} {; # fix viol big and short length
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mlb:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ; # specify 8 drive capacity is special set for this case viol > 100ps and net length < 10um
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mlb:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mlb:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } else { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mlb:in_8:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mlb:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : mlb:in_8:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mlb:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          }
          
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 4: (one2more) buffer to logic
        } elseif {$driveCellClass in {buffer inverter CLKbuffer CLKinverter} && $mergedSinksType in {delay logic CLKlogic}} {
          set locOffSink 0.6 ; # off relatived to center pt of sinks
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          # some useful flag
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mbl:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "mbl:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mbl:in_1:3" "NL" $allInfoList] 
          }
          #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 20 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 10 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 5 \
                } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "mbl:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2] 
              if {$debug} { puts "mbl:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "mbl:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "mbl:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ; # songNOTE: situation 01 only changeVT,
            # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbl:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbl:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mbl:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.05 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.7]} { ; # songNOTE: situation 02 only changeDriveCapacity
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            #puts "in 2: $driveCelltype $toChangeCelltype2"
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbl:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mbl:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.07 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.9] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.8]] || \
                                                                                    [expr $violnum >= -0.04  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.8] && $numSinks > 15] ]} { ; # songNOTE: situation 03 change VT and DriveCapacity
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbl:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbl:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "mbl:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "mbl:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.14 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 6] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 7 || \
                                                                   $violnum >= -0.14 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 3.5] && $numSinks > 7]} { ; # songNOTE: situation 04 add Repeater near logic cell
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mbl:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mbl:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mbl:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.17 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.1]} { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mbl:in_7:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mbl:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : mbl:in_7:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                if {$ifHaveFasterVT} {
                  set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                  lappend fixedList_one2more [concat "mbl:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                  set cmd2 [list $cmd_TA_driveInst $cmd_TA_add]
                } else {
                  lappend fixedList_one2more [concat "mbl:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                }
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.16 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * $off]} {; # fix viol big and short length
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mbl:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ; # specify 8 drive capacity is special set for this case viol > 100ps and net length < 10um
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mbl:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mbl:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } else { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mbl:in_8:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mbl:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : mbl:in_8:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mbl:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          }
          
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 5: (one2more) buffer to sequential
        } elseif {$driveCellClass in {buffer inverter CLKbuffer CLKinverter} && $mergedSinksType in {sequential}} {
          set locOffSink 0.6 ; # off relatived to center pt of sinks
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          # some useful flag
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mbs:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "mbs:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mbs:in_1:3" "NL" $allInfoList] 
          }
          #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 20 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 10 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 5 \
                } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "mbs:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2] 
              if {$debug} { puts "mbs:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "mbs:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "mbs:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ; # songNOTE: situation 01 only changeVT,
            # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbs:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbs:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mbs:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.05 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.7]} { ; # songNOTE: situation 02 only changeDriveCapacity
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            #puts "in 2: $driveCelltype $toChangeCelltype2"
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbs:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mbs:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.07 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.9] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.8]] || \
                                                                                    [expr $violnum >= -0.04  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.8] && $numSinks > 15] ]} { ; # songNOTE: situation 03 change VT and DriveCapacity
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbs:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mbs:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "mbs:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "mbs:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.14 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 6] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 7 || \
                                                                   $violnum >= -0.14 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 3.5] && $numSinks > 7]} { ; # songNOTE: situation 04 add Repeater near logic cell
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mbs:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mbs:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mbs:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.17 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.1]} { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mbs:in_7:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mbs:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : mbs:in_7:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                if {$ifHaveFasterVT} {
                  set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                  lappend fixedList_one2more [concat "mbs:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                  set cmd2 [concat $cmd_TA_driveInst $cmd_TA_add]
                } else {
                  lappend fixedList_one2more [concat "mbs:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                }
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.16 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * $off]} {; # fix viol big and short length
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mbs:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ; # specify 8 drive capacity is special set for this case viol > 100ps and net length < 10um
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mbs:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mbs:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } else { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mbs:in_8:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 6 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mbs:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : mbs:in_8:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mbs:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          }

# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 6: (one2more) sequential to buffer
        } elseif {$driveCellClass in {sequential} && $mergedSinksType in {buffer inverter CLKbuffer CLKinverter}} {
          set locOffSink 0.9 ; # off relatived to center pt of sinks
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          # some useful flag
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "msb:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "msb:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "msb:in_1:3" "NL" $allInfoList] 
          }
          #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 7 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 4 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 1 \
                } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "msb:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2] 
              if {$debug} { puts "msb:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "msb:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "msb:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ; # songNOTE: situation 01 only changeVT,
            # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msb:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msb:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "msb:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.03 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2]} { ; # songNOTE: situation 02 only changeDriveCapacity
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            #puts "in 2: $driveCelltype $toChangeCelltype2"
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msb:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "msb:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.04 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.2] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.4]] || \
                                                                                    [expr $violnum >= -0.02  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2] && $numSinks > 15] ]} { ; # songNOTE: situation 03 change VT and DriveCapacity
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msb:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msb:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "msb:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "msb:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 4] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 5 || \
                                                                   $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 2] && $numSinks > 5]} { ; # songNOTE: situation 04 add Repeater near logic cell
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "msb:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "msb:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "msb:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.12 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.5]} { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "msb:in_7:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "msb:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : msb:in_7:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                if {$ifHaveFasterVT} {
                  set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                  lappend fixedList_one2more [concat "msb:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                  set cmd2 [concat $cmd_TA_driveInst $cmd_TA_add]
                } else {
                  lappend fixedList_one2more [concat "msb:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                }
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 0.6]} {; # fix viol big and short length
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "msb:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ; # specify 8 drive capacity is special set for this case viol > 100ps and net length < 10um
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "msb:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "msb:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } else { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "msb:in_8:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "msb:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : msb:in_8:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "msb:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          }

# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 7: (one2more) logic to sequential
        } elseif {$driveCellClass in {delay logic CLKlogic} && $mergedSinksType in {sequential}} {
          set locOffSink 0.8 ; # off relatived to center pt of sinks
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          # some useful flag
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mls:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "mls:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "mls:in_1:3" "NL" $allInfoList] 
          }
          #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 10 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 7 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 1 \
                } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "mls:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2] 
              if {$debug} { puts "mls:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "mls:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "mls:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ; # songNOTE: situation 01 only changeVT,
            # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mls:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mls:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mls:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.03 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2]} { ; # songNOTE: situation 02 only changeDriveCapacity
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            #puts "in 2: $driveCelltype $toChangeCelltype2"
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mls:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "mls:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.04 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.2] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.4]] || \
                                                                                    [expr $violnum >= -0.02  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2] && $numSinks > 15] ]} { ; # songNOTE: situation 03 change VT and DriveCapacity
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mls:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "mls:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "mls:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "mls:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 4] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 5 || \
                                                                   $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 2] && $numSinks > 5]} { ; # songNOTE: situation 04 add Repeater near logic cell
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mls:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mls:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mls:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.12 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.5]} { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mls:in_7:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mls:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : mls:in_7:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                if {$ifHaveFasterVT} {
                  set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                  lappend fixedList_one2more [concat "mls:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                  set cmd2 [concat $cmd_TA_driveInst $cmd_TA_add]
                } else {
                  lappend fixedList_one2more [concat "mls:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                }
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 0.6]} {; # fix viol big and short length
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mls:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ; # specify 8 drive capacity is special set for this case viol > 100ps and net length < 10um
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mls:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mls:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } else { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "mls:in_8:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "mls:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : mls:in_8:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "mls:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          }

# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# SITUATION 8: (one2more) sequential to logic
        } elseif {$driveCellClass in {sequential} && $mergedSinksType in {delay logic CLKlogic}} {
          set locOffSink 0.8 ; # off relatived to center pt of sinks
          set off $locOffSink
          if {$debug} { puts "$distanceOfdrive2CenterPtOfSinks $driveCelltype $sinkCelltype [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] [lindex $violValue_drivePin_loadPin_numSinks_sinks 2]" }
          # some useful flag
          set refVTweightList [eo [regexp CLK $driveCellClass] $clkNeedVtWeightList $normalNeedVtWeightList]
          set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype $refVTweightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have faster vt: $ifHaveFasterVT"}
          set ifHaveSlowerVT 0
          set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1] $driveCelltype]]
          if {$debug} {puts "if have larger capacity: $ifHaveLargerCapacity"}
          set ifHaveSmallerCapacity 0
          if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "msl:in_1:1" "NFL" $allInfoList]
          } elseif {!$ifHaveFasterVT} {
            lappend skippedList_one2more [concat "msl:in_1:2" "NF" $allInfoList]
          } elseif {!$ifHaveLargerCapacity} {
            lappend skippedList_one2more [concat "msl:in_1:3" "NL" $allInfoList] 
          }
          #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
          if {$violnum < -0.2 && $distanceOfdrive2CenterPtOfSinks < 15 || \
              $violnum < -0.1 && $distanceOfdrive2CenterPtOfSinks < 10 || \
              $violnum < -0.07 && $distanceOfdrive2CenterPtOfSinks < 7 || \
              $violnum < -0.03 && $distanceOfdrive2CenterPtOfSinks < 1 \
                } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
            if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $sinkCapacity] < 0]} {
              if {$debug} { puts "------" }
              set toChangeCelltype2 [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
              if {$debug} { puts "msl:in_1:1 FS changeVT : $toChangeCelltype2" }
              set toChangeCelltype2 [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype2 0 [eo [expr $driveCapacity <= 2] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype2] 
              if {$debug} { puts "msl:in_1:1 FS changeDrive : $toChangeCelltype2" }
              lappend fixedList_one2more [concat "msl:in_1:1" "FS" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
            } else {
              lappend cantChangeList_one2more [concat "msl:in_1:1" "S" $allInfoList]
              set cmd2 "cantChange"
            }
          } elseif {$ifHaveFasterVT && $canChangeVT && [expr $violnum >= -0.006 || \
                     $violnum >= -0.01 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 10 ] || \
                     $violnum >= -0.02 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength  * 20 ] \
                     ]} { ; # songNOTE: situation 01 only changeVT,
            # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
            if {$debug} { puts "in 1: only change VT" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msl:in_2:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msl:in_2:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "msl:in_2:3" "T" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && $violnum >= -0.03 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2]} { ; # songNOTE: situation 02 only changeDriveCapacity
            if {$debug} { puts "in 2: only change DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            #puts "in 2: $driveCelltype $toChangeCelltype2"
            if {$debug} { puts $toChangeCelltype2 }
            if {$driveCapacity == 0.5} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 3 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity in {1 2}} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
            } elseif {$driveCapacity >= 3} {
              set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msl:in_4:1" "O" $allInfoList]
              set cmd2 "cantChange"
            } else {
              lappend fixedList_one2more [concat "msl:in_4:2" "D" $toChangeCelltype2 $allInfoList]
              set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
            }
          } elseif {$ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [expr  [expr  $violnum >= -0.04 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 2.2] ||  $violnum >= -0.11 && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.4]] || \
                                                                                    [expr $violnum >= -0.02  && $distanceOfdrive2CenterPtOfSinks <= [expr $unitOfNetLength * 1.2] && $numSinks > 15] ]} { ; # songNOTE: situation 03 change VT and DriveCapacity
            if {$debug} { puts "in 3: change VT and DriveCapacity" }
            set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {[regexp -- {0x0:3} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msl:in_5:1" "V" $allInfoList]
              set cmd2 "cantChange"
            } elseif {[regexp -- {0x0:4} $toChangeCelltype2]} {
              lappend cantChangeList_one2more [concat "msl:in_5:2" "F" $allInfoList]
              set cmd2 "cantChange"
            } else {
              if {$driveCapacity <= 1} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 2 $rangeOfDriveCapacityForChange $cellRegExp 1]
              } elseif {$driveCapacity >= 2} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 0 1 $rangeOfDriveCapacityForChange $cellRegExp 1]
              }
              if {[regexp -- {0x0:3} $toChangeCelltype2]} {
                lappend cantChangeList_one2more [concat "msl:in_5:3" "O" $allInfoList]
                set cmd2 "cantChange"
              } else {
                lappend fixedList_one2more [concat "msl:in_5:4" "TD" $toChangeCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.08  && [expr  $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 4] && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 0.3] && $numSinks <= 5 || \
                                                                   $violnum >= -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 2] && $numSinks > 5]} { ; # songNOTE: situation 04 add Repeater near logic cell
            if {$debug} { puts "in 4: add Repeater" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "msl:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "msl:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "msl:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.12 && $distanceOfdrive2CenterPtOfSinks > [expr $unitOfNetLength * 2.5]} { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "msl:in_7:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "msl:in_7:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : msl:in_7:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                if {$ifHaveFasterVT} {
                  set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]
                  lappend fixedList_one2more [concat "msl:in_7:3" "TA_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                  set cmd2 [concat $cmd_TA_driveInst $cmd_TA_add]
                } else {
                  lappend fixedList_one2more [concat "msl:in_7:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                  set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                }
              }
            }
          } elseif {$canAddRepeater && $violnum < -0.04 && $violnum > -0.1 && $distanceOfdrive2CenterPtOfSinks < [expr $unitOfNetLength * 0.6]} {; # fix viol big and short length
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "msl:in_6:1" "N_forceDrive" $allInfoList]
              set cmd2 "cantChange"
            } else {
              #puts  "in 4: $driveCelltype --  $toChangeCelltype2 song"
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 8 0 $rangeOfDriveCapacityForChange $cellRegExp 1] ; # specify 8 drive capacity is special set for this case viol > 100ps and net length < 10um
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "msl:in_6:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "msl:in_6:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          } else { ; # songNOTE: situation 05 not in above situation
            if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
            if {$debug} { puts "Not in above situation, so NOTICE" }
            set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $mergedSinksType]] $refCLKBufferCelltype $refBufferCelltype]
            set toAddCelltype2 [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
            if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype2]} {
              lappend cantChangeList_one2more [concat "msl:in_8:1" "N" $allInfoList]
              set cmd2 "cantChange"
            } else {
              set toChangeCelltype2 [strategy_changeVT $driveCelltype $specialNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
              if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
                set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
                if {$debug} {puts "$driveCelltype - $toChangeCelltype2"}
                set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype2 -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_one2more [concat "msl:in_8:2" "DA_[fm $off]" ${toChangeCelltype2}_$toAddCelltype2 $allInfoList]
                if {$debug} {puts "test : msl:in_8:2"}
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
                set cmd2 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                lappend fixedList_one2more [concat "msl:in_8:4" "A_[fm $off]" $toAddCelltype2 $allInfoList]
                set cmd2 [print_ecoCommand -type add -celltype $toAddCelltype2 -terms [lindex $violValue_drivePin_loadPin_numSinks_sinks 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_one2more_[ci add] -loc [calculateRelativePoint $centerPtOfSinks $drivePt $off]]
              }
            }
          }

        }
      } elseif {[llength $mergedSinksType] > 1} {; # if type of sinks is different cell class
        # class : buffer inverter logic CLKbuffer CLKinverter CLKlogic delay seqential
        set sinksType [lmap type $sinksType {
          switch $type {
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
        # this will only show the worst situation that sink viol value is biggest, cuz other situ which of similiar drivePin is been continue at AT001.
        lappend one2moreList_diffTypesOfSinks [concat "MT" [join $sinksType "/"] $allInfoList ]
        
      }

      ## songNOTE:FIXED:U001 check all fixed celltype(changed). if it is smaller than X1 (such as X05), it must change to X1 or larger
      # ONLY check $toChangeCelltype2, NOT check $toAddCelltype
      #### ADVANCE TODO:U004 can specify logic rule and buffer/inverter rule, you can set it seperately
if {$debug} { puts "TEST: $toChangeCelltype2" }
      if {$cmd2 != "" && $cmd2 != "cantChange" && [get_driveCapacity_of_celltype $toChangeCelltype2 $cellRegExp] < $largerThanDriveCapacityOfChangedCelltype} { ; # drive capacity of changed cell must be larger than X1
        set checkedSymbol "C"
        set checkedCmd ""
        set preToChangeCell $toChangeCelltype2
        set toChangeCelltype2 [strategy_changeDriveCapacity $toChangeCelltype2 $largerThanDriveCapacityOfChangedCelltype 0 $rangeOfDriveCapacityForChange $cellRegExp 1]
        set checkedCmd [print_ecoCommand -type change -cell $toChangeCelltype2 -inst $driveInstname]
        if {[llength $cmd2] > 1 && [llength $cmd2] < 5 && ![regexp "0x0" $checkedCmd] && $checkedCmd != ""} {
          set indexChangeCmd [lsearch -regexp $cmd2 "^ecoChangeCell .*"]
          set cmd2 [lreplace $cmd2 $indexChangeCmd $indexChangeCmd $checkedCmd]
        } elseif {[llength $cmd2] >= 5 && [regexp "ecoChangeCell" $cmd2] && ![regexp "0x0" $checkedCmd] && $checkedCmd != ""} {
          set cmd2 $checkedCmd
        }
        set methodColumn [lindex [lindex $fixedList_one2more end] 1]
        set celltypeToFix [lindex [lindex $fixedList_one2more end] 2]
        set fixedList_one2more [lreplace $fixedList_one2more end end [lreplace [lindex $fixedList_one2more end] 1 2 [append methodColumn "_" $checkedSymbol ] [regsub $preToChangeCell $celltypeToFix $toChangeCelltype2]]]
        if {$debug} { puts "TEST FIXEDLIST large : [llength $fixedList_one2more]" }
        if {$debug} { puts [lindex $fixedList_one2more end] }
      }
      if {$debug} { puts "TEST END: $cmd2\n   $checkedCmd" }
      
      # label case with 'm' for merged sinks cell class to one cell class
      if {[llength $sinksType] > 1} {
        set situMerged [lindex [lindex $fixedList_one2more end] 0]
        set fixedList_one2more [lreplace $fixedList_one2more end end [lreplace [lindex $fixedList_one2more end] 0 0 [string cat "m" $situMerged]]]
      }
      # dump to cmdList in format of comment
      if {$cmd2 != "cantChange" && $cmd2 != ""} { ; # consider not-checked situation; like ip to ip, mem to mem, r2p
        lappend cmdList "# [lindex $fixedList_one2more end]"
        if {[llength $cmd2] < 5} { ; # because shortest eco cmd need 5 items at least (ecoChangeCell -inst instname -cell celltype)
          set cmdList [concat $cmdList $cmd2]; #!!!
        } else {
          lappend cmdList $cmd2
        }
      } elseif {$cmd2 == "" && [llength $mergedSinksType] == 1} { ; # only view one2more(only one type of sinks)
        lappend notConsideredList_one2more [concat "NC" $allInfoList]
      }
      if {$debug} { puts "# -----------------" }
      
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
    {-ecoNewInstNamePrefix "specify a new name for inst when adding new repeater" AList list optional}
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
# source ../../../incr_integer_inself.common.tcl; # ci(proc counter), don't use array: counters
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/17 17:07:29 Thursday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : related to incr i
#             if you input "a", it will return a number increased one based on previous value,
#             if it is invoked first time, it will return 1 (default), you can specify the beginning value
# update    : 2025/07/18 00:39:49 Friday
#           add $holdon: if it is 1, it return now value(will not increase 1 based on original value) for different situation
# ref       : link url
# --------------------------
alias ci "counter"
catch {unset counters}
proc counter {input {holdon 0} {start 1}} {
    global counters
    if {![info exists counters($input)]} {
        set counters($input) [expr $start - 1]
    }
    if {!$holdon} {
      incr counters($input)
    }
    return "$counters($input)"
}

# source ./proc_getPt_ofObj.invs.tcl; # gpt - return pt(location) of object
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/20 15:47:17 Sunday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : get pt(location) of object(pin/inst/...)
# ref       : link url
# --------------------------
alias gpt "getPt_ofObj"
proc getPt_ofObj {{obj ""}} {
  if {$obj == ""} { 
    set obj [dbget selected.name -e] ; # now support case that is only one obj
  }
  if {$obj == "" || [dbget top.insts.name $obj -e] == "" && [dbget top.insts.instTerms.name $obj -e] == ""} {
    return "0x0:1"; # check your input 
  } else {
    set inst_ptr [dbget top.insts.name $obj -e -p]
    set pin_ptr  [dbget top.insts.instTerms.name $obj -e -p]
    if {$inst_ptr != ""} {
      set inst_pt [lindex [dbget $inst_ptr.pt] 0]
      return $inst_pt
    } elseif {$pin_ptr != ""} {
      set pin_pt [lindex [dbget $pin_ptr.pt] 0]
      return $pin_pt
    }
  }
}

# source ../../../logic_or_and.common.tcl; # operators: lo la ol al re eo - return 0|1
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/16 19:17:29 Wednesday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : logic or(lo) / logic and(la) (string comparition): check if variable is equaled to string
# update    : 2025/07/16 23:18:45 Wednesday
#             add ol/al proc: check empty string or zero value
# update    : 2025/07/17 10:11:36 Thursday
#             add eo proc: judge if the first arg is empty string or number 0. advanced version of [expr $test ? trueValue : falseValue ]
#             it(eo) can input string and the trueValue and falseValue can also be string
# ref       : link url
# --------------------------

# (la = Logic AND)
#  la $var1 "value1" $var2 "value2" ...
proc la {args} {
	if {[llength $args] == 0} {
		error "la: requires at least one argument"; # error command , you can try it 
	}
	if {[llength $args] % 2 != 0} {
		error "la: requires arguments in pairs: variable value"
	}
	for {set i 0} {$i < [llength $args]} {incr i 2} {
		set varName [lindex $args $i]
		set expectedValue [lindex $args [expr {$i+1}]]
		if {$varName ne $expectedValue} {
			return 0  ;# 不匹配，立即返回假
		}
	}
	return 1  ;# 全部匹配，返回真
}

# (lo = Logic OR)
#  lo $var1 "value1" $var2 "value2" ...
proc lo {args} {
	if {[llength $args] == 0} {
		error "lo: requires at least one argument"
	}
	if {[llength $args] % 2 != 0} {
		error "lo: requires arguments in pairs: variable value"
	}
	for {set i 0} {$i < [llength $args]} {incr i 2} {
		set varName [lindex $args $i]
		set expectedValue [lindex $args [expr {$i+1}]]
		if {$varName eq $expectedValue} {
			return 1  ;# 匹配，立即返回真
		}
	}
	return 0  ;# 全部不匹配，返回假
}

# (al = AND Logic for arbitrary number of arguments)
#  al $arg1 $arg2 ...
proc al {args} {
	if {[llength $args] == 0} {
		error "al: requires at least one argument"
	}

	foreach arg $args {
		if {$arg eq "" || ([string is integer -strict $arg] && $arg == 0)} {
			return 0  ;# 遇到空字符串或值为0的整数字符串，立即返回假
		}
	}

	return 1  ;# 所有参数都满足条件，返回真
}

# (ol = OR Logic for arbitrary number of arguments)
#  ol $arg1 $arg2 ...
proc ol {args} {
	if {[llength $args] == 0} {
		error "ol: requires at least one argument"
	}

	foreach arg $args {
		if {$arg ne "" && (![string is integer -strict $arg] || $arg != 0)} {
			return 1  ;# 遇到非空字符串，且不是值为0的整数字符串，立即返回真
		}
	}

	return 0  ;# 所有参数都不满足条件，返回假
}

proc re {args} {
	# 支持多种调用方式：
	# 1. re <value>         - 直接取反单个值
	# 2. re -list <list>    - 对列表中每个元素取反
	# 3. re -dict <dict>    - 对字典中每个值取反
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
	# 处理剩余参数
	if {[info exist list]} {
		# 列表模式：对每个元素取反
		return [lmap item $list {expr {![_to_boolean $item]}}]
	} elseif {[info exist dict]} {
		# 字典模式：对每个值取反
		if {[llength $args] != 1} {
			error "Dictionary mode requires exactly one dictionary argument"
		}
		set resultDict [dict create]
		dict for {key value} [lindex $dict 0] {
			dict set resultDict $key [expr {![_to_boolean $value]}]
		}
		return $resultDict
	} else {
		# 单值模式：直接取反
		if {[llength $args] != 1} {
			error "Single value mode requires exactly one argument"
		}
		return [expr {![_to_boolean [lindex $args 0]]}]
	}
}
# TODO(FIXED) : 这里设置了option，但是假如没有写option，直接写了值或者字符串，该如何解析？
define_proc_arguments re \
  -info ":re ?-list|-dict? value(s) - Logical negation of values"\
  -define_args {
	  {value "boolean value" "" boolean optional}
    {-list "list mode" AList list optional}
    {-dict "dict mode" ADict list optional}
  }

# 内部辅助函数：将各种类型的值转换为布尔值
proc _to_boolean {value} {
	switch -exact -- [string tolower $value] {
		"1" - "true" - "yes" - "on" { return 1 }
		"0" - "false" - "no" - "off" { return 0 }
		default {
			# 尝试将数值字符串转换为布尔值
			if {[string is integer -strict $value]} {
				return [expr {$value != 0}]
			}
			# 其他情况视为无效值
			error "Cannot convert '$value' to boolean"
		}
	}
}

# test if firstArg is empty string or number 0
#     if it is, return secondArg(trueValue)
#     if it is not , return thirdArg(falseValue)
alias eo "ifEmptyZero"
proc ifEmptyZero {value trueValue falseValue} {
    # 错误检查：使用 [info level 0] 获取当前过程的参数数量
    if {[llength [info level 0]] != 4} {
        error "Usage: ifEmptyZero value trueValue falseValue"
    }
    # 处理空值或空白字符串
    if {$value eq "" || [string trim $value] eq ""} {
        return $falseValue
    }
    # 尝试将值转换为数字进行判断
    set numericValue [string is double -strict $value]
    if {$numericValue} {
        # 数值为0时返回falseValue
        if {[expr {$value == 0}]} {
            return $falseValue
        }
    } elseif {$value eq "0"} {
        # 字符串"0"返回falseValue
        return $falseValue
    }
    # 其他情况返回trueValue
    return $trueValue
}


# source ./proc_get_net_lenth.invs.tcl; # get_net_length - num
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
# descrip   : get net length. ONLY one net!!!
# ref       : link url
# --------------------------
proc get_net_length {{net ""}} {
	if {$net == "0x0" || [dbget top.nets.name $net -e] == ""} { 
		return "0x0:1"
	} else {
    set wires_split_length [dbget [dbget top.nets.name $net -u -p].wires.length]
    set net_length 0
    foreach wire_len $wires_split_length {
      set net_length [expr $net_length + $wire_len]
    }
    return $net_length
	}
}
alias gl "get_net_length"

# source ./proc_if_driver_or_load.invs.tcl; # if_driver_or_load - 1: driver  0: load
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
# descrip   : judge if a pin is output! ONLY one pin 
# ref       : link url
# --------------------------
proc if_driver_or_load {{pin ""}} {
  if {$pin == "" || $pin == "0x0" || [dbget top.insts.instTerms.name $pin -e] == ""} {
    return "0x0:1"
  } else {
    if {[dbget [dbget top.insts.instTerms.name $pin -p].isOutput] == 1} {
      return 1 
    } else {
      return 0 
    }
  }
}

# source ./proc_get_fanoutNum_and_inputTermsName_of_pin.invs.tcl; # get_fanoutNum_and_inputTermsName_of_pin - return list [num termsNameList] || get_driverPin - return drivePin
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
# descrip   : get number of fanout and name of input terms of a pin. ONLY one pin!!! this pin is output
# ref       : link url
# --------------------------
proc get_fanoutNum_and_inputTermsName_of_pin {{pin ""}} {
  # this pin must be output pin
  if {$pin == "" || $pin == "0x0" || [dbget top.insts.instTerms.name $pin -e] == ""} {
    return "0x0:1"
  } else {
    set netOfPinPtr  [dbget [dbget top.insts.instTerms.name $pin -p].net.]
    set netNameOfPin [dbget $netOfPinPtr.name]
    set fanoutNum    [dbget $netOfPinPtr.numInputTerms]
    set allinstTerms [dbget $netOfPinPtr.instTerms.name]
    #set inputTermsName "[lreplace $allinstTerms [lsearch $allinstTerms $pin] [lsearch $allinstTerms $pin]]"
    set inputTermsName "[lsearch -all -inline -not -exact $allinstTerms $pin]"
    #puts "$fanoutNum"
    #puts "$inputTermsName"
    set numToInputTermName [list ]
    lappend numToInputTermName $fanoutNum
    lappend numToInputTermName $inputTermsName
    return $numToInputTermName
  }
}
proc get_driverPin {{pin ""}} {
  if {$pin == "" || [dbget top.insts.instTerms.name $pin -e] == ""} {
    return "0x0:1"; # no pin
  } else {
    set driver [lindex [dbget [dbget [dbget top.insts.instTerms.name $pin -p].net.instTerms.isOutput 1 -p].name ] 0]
    return $driver
  }
}

# source ./proc_get_cellDriveLevel_and_VTtype_of_inst.invs.tcl; # get_cellDriveLevel_and_VTtype_of_inst - return [instname cellName driveLevel VTtype]
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:20:11 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
# descrip   : get cell drive capacibility and VT type of a inst. ONLY one instance!!!
# ref       : link url
# --------------------------
proc get_cellDriveLevel_and_VTtype_of_inst {{inst ""} {regExp "D(\\d+).*CPD(U?L?H?VT)?"}} {
  # NOTE: $regExp need specific pattern to match info correctly!!! search doubao AI
  # \ need use \\ to adapt. like : \\d+
  if {$inst == "" || $inst == "0x0" || [dbget top.insts.name $inst -e] == ""} {
    return "0x0:1"
  } else {
    set cellName [dbget [dbget top.insts.name $inst -p].cell.name] 
    # NOTE: expression of get drive level need modify by different design and standard cell library.
    set wholeName 0
    set levelNum 0
    set VTtype 0
    set runError [catch {regexp $regExp $cellName wholeName levelNum VTtype} errorInfo]
    if {$runError || $wholeName == ""} {
      # if error, check your regexp expression
      return "0x0:2" 
    } else {
      if {$VTtype == ""} {set VTtype "SVT"}
      if {$levelNum == "05"} {set levelNumTemp 0.5} else {set levelNumTemp [expr int($levelNum)]}
      set instName_cellName_driveLevel_VTtype_List [list ]
      lappend instName_cellName_driveLevel_VTtype_List $inst
      lappend instName_cellName_driveLevel_VTtype_List $cellName
      lappend instName_cellName_driveLevel_VTtype_List $levelNumTemp
      lappend instName_cellName_driveLevel_VTtype_List $VTtype
      return $instName_cellName_driveLevel_VTtype_List
    }
  }
}

# source ./proc_get_cell_class.invs.tcl; # get_cell_class - return logic|buffer|inverter|CLKcell|sequential|gating|other
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Sun Jul  6 00:41:35 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|task_proc)
# descrip   : get class of cell, like logic/sequential/buffer/inverter/CLKcell/gating/other
# ref       : link url
# --------------------------
proc get_cell_class {{instOrPin ""}} {
  if {$instOrPin == "" || $instOrPin == "0x0" || [expr  {[dbget top.insts.name $instOrPin -e] == "" && [dbget top.insts.instTerms.name $instOrPin -e] == ""}]} {
    return "0x0:1"; # have no instOrPin 
  } else {
    if {[dbget top.insts.name $instOrPin -e] != ""} {
      return [logic_of_mux $instOrPin]
    } elseif {[dbget top.insts.instTerms.name $instOrPin -e] != ""} {
      set inst_ofPin [dbget [dbget top.insts.instTerms.name $instOrPin -p2].name]
      return [logic_of_mux $inst_ofPin]
    }
  }
}

# songNOTE: NOTICE: if you open invs db without timing info, you will get incorrect judgement for cell class, you can only get logic and sequential!
#           ADVANCE: it can test if you open noTiming invs db. if it is, it judge it by other rule
# now : please open invs db with timing info
proc logic_of_mux {inst} {
  set celltype [dbget [dbget top.insts.name $inst -p].cell.name]
  if {[get_property [get_cells $inst] is_memory_cell]} {
    return "mem"
  } elseif {[get_property [get_cells $inst] is_sequential]} {
    return "sequential"
  } elseif {[regexp {CLK} $celltype]} {
    if {[get_property [get_cells $inst] is_buffer]} {
      return "CLKbuffer"
    } elseif {[get_property [get_cells $inst] is_inverter]} {
      return "CLKinverter"
    } elseif {[get_property [get_cells $inst] is_combinational]} {
      return "CLKlogic" 
    } else {
      return "CLKcell" 
    }
  } elseif {[regexp {^DEL} $celltype] && [get_property [get_cells $inst] is_buffer]} {
    return "delay"
  } elseif {[get_property [get_cells $inst] is_buffer]} {
    return "buffer" 
  } elseif {[get_property [get_cells $inst] is_inverter]} {
    return "inverter" 
  } elseif {[get_property [get_cells $inst] is_integrated_clock_gating_cell]} {
    return "gating"
  } elseif {[get_property [get_cells $inst] is_combinational]} {
    return "logic" 
  } else {
    return "other" 
  }
}

# source ./proc_strategy_changeVT.invs.tcl; # strategy_changeVT - return VT-changed cellname
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
# descrip   : strategy of fixing transition: change VT type of a cell. you can specify the weight of every VT type and speed index of VT. weight:0 will be forbidden to use
# update    : 2025/07/15 16:51:34 Tuesday
#             1) add switch $ifForceValid: if you turn on it, it will change vt to one which weight is not 0. That is legalize VT
#             2) if available vt list that is remove weight:0 vt is only now vt type, return now celltype
#             3) if have no faster VT, return original celltype
# ref       : link url
# --------------------------
# TODO: consider mix fluence between speed and weight!!!
proc strategy_changeVT {{celltype ""} {weight {{SVT 3} {LVT 1} {ULVT 0}}} {speed {ULVT LVT SVT}} {regExp "D(\\d+).*CPD(U?L?H?VT)?"} {ifForceValid 1}} {
  # $weight:0 is stand for no using
  # $speed: the fastest must be in front. like ULVT must be the first
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e] == ""} {
    return "0x0:1" 
  } else {
    # get now VTtype
    set runError [catch {regexp $regExp $celltype wholeName driveLevel VTtype} errorInfo]
    if {$runError || $wholeName == ""} {
      return "0x0:2"; # check if $regExp pattern is correct 
    } else {
      set processType [whichProcess_fromStdCellPattern $celltype]
      if {$VTtype == ""} {set VTtype "SVT"; puts "notice: blank vt type"} 
      set weight0VTList [lmap vt_weight [lsort -unique -index 0 [lsearch -all -inline -index 1 -regexp $weight "0"]] {set vt [lindex $vt_weight 0]}]
      set avaiableVT [lsearch -all -inline -index 1 -regexp $weight "\[1-9\]"]; # remove weight:0 VT
      # user-defined avaiable VT type
      set availableVTsorted [lsort -index 1 -integer -decreasing $avaiableVT]
      set ifInAvailableVTList [lsearch -index 0 $availableVTsorted $VTtype]
      set availableVTnameList [lmap vt_weight $availableVTsorted {set temp [lindex $vt_weight 0]}]

#puts "-ifInAvailabeVTList $ifInAvailableVTList VTtype $VTtype $celltype -"
      if {$availableVTnameList == $VTtype} {
        return $celltype; # if list only have now vt type, return now celltype
      } elseif {$ifInAvailableVTList == -1} {
        if {$ifForceValid} {
          if {[lsearch -inline $weight0VTList $VTtype] != ""} {
            set speedList_notWeight0 $speed
            foreach weight0 $weight0VTList {
              set speedList_notWeight0 [lsearch -exact -inline -all -not $speedList_notWeight0 $weight0]
            }
#puts "$celltype -$speedList_notWeight0- "
            if {$processType == "TSMC"} {
              set useVT [lindex $speedList_notWeight0 end]
              if {$useVT == ""} {
                return "0x0:4"; # don't have faster VT
              } else {
                #return $useVT 
                if {$useVT == "SVT"} {
                  return [regsub "$VTtype" $celltype ""]
                } elseif {$VTtype == "SVT"} {
                  return [regsub "$" $celltype $useVT] 
                } else {
                  return [regsub $VTtype $celltype $useVT] 
                }
              }
            } elseif {$processType == "HH"} {
              return [regsub $VTtype $celltype [lindex $speedList_notWeight0 end]] 
            }
          } 
        } else {
          return "0x0:3"; # cell type can't be allowed to use, don't change VT type
        }
      } else {
        # get changeable VT type according to provided cell type 
        set changeableVT [lsearch -exact -index 0 -all -inline -not $availableVTsorted $VTtype]
        #puts $changeableVT
        # judge if changeable VT types have faster type than nowVTtype of provided cell type
        set nowSpeedIndex [lsearch -exact $speed $VTtype]
        set moreFastVTinSpeed [lreplace $speed $nowSpeedIndex end]
        set useVT ""
        foreach vt $changeableVT {
          if {[lsearch -exact $moreFastVTinSpeed [lindex $vt 0]] > -1} {
            set useVT "[lindex $vt 0]"
            break
          } else {
            return $celltype ; # if have no faster vt, it will return original celltype
          }
        }
        if {$processType == "TSMC"} {
          # NOTE: these VT type set now is only for TSMC cell pattern
          # TSMC cell VT type pattern: (special situation!!!)
          #   SVT: xxxCPD
          #   LVT: xxxCPDLVT
          #   ULVT: xxxCPDULVT
          if {$useVT == ""} {
            return "0x0:4"; # don't have faster VT
          } else {
            #return $useVT 
            if {$useVT == "SVT"} {
              return [regsub "$VTtype" $celltype ""]
            } elseif {$VTtype == "SVT"} {
              return [regsub "$" $celltype $useVT] 
            } else {
              return [regsub $VTtype $celltype $useVT] 
            }
          }
        } elseif {$processType == "HH"} {
          # HH40 :
          # AR9 AL9 AH9
          return [regsub $VTtype $celltype $useVT] 
        }
      }
    }
  }
}
# source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Tue Jul  8 11:22:06 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
# descrip   : judge which process specified celltype is 
# ref       : link url
# --------------------------
proc whichProcess_fromStdCellPattern {{celltype ""}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e] == ""} {
    return "0x0:1"; # can't find celltype in this design and library 
  } else {
    if {[regexp BWP $celltype]} {
      set processType "TSMC" 
    } elseif {[regexp {A[HRL]\d+$} $celltype]} {
      set processType "HH" 
    } else {
      return "0x0:1"; # can't indentify where the celltype is come from
    }
    return $processType
  }
}


# source ./proc_strategy_addRepeaterCelltype.invs.tcl; # strategy_addRepeaterCelltype - return toAddCelltype
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/15 13:30:32 Tuesday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : strategy of fixing transition: add repeater cell to fix long net or weak drive capacity
# ref       : link url
# --------------------------
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
# source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # proc: whichProcess_fromStdCellPattern
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Tue Jul  8 11:22:06 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
# descrip   : judge which process specified celltype is 
# ref       : link url
# --------------------------
proc whichProcess_fromStdCellPattern {{celltype ""}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e] == ""} {
    return "0x0:1"; # can't find celltype in this design and library 
  } else {
    if {[regexp BWP $celltype]} {
      set processType "TSMC" 
    } elseif {[regexp {A[HRL]\d+$} $celltype]} {
      set processType "HH" 
    } else {
      return "0x0:1"; # can't indentify where the celltype is come from
    }
    return $processType
  }
}

# source ./proc_find_nearestNum_atIntegerList.invs.tcl; # find_nearestNum_atIntegerList list num big?
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Tue Jul  8 11:05:01 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
# descrip   : find the nearest number from list, you can control which one of bigger or smaller
#             if $returnBigOneFlag is 1, return big one near number
#             if $returnBigOneFlag is 0, return small one near number
#             if $ifClamp is 1 and $number is out of $realList, return the maxOne or small one of $realList
#             if $ifClamp is 0 and $number is out of $realList, return "0x0:1"(error)
# update    : 2025/07/18 12:15:10 Friday
#             adapt to list with only one item
# ref       : link url
# --------------------------
proc find_nearestNum_atIntegerList {{realList {}} number {returnBigOneFlag 1} {ifClamp 1}} {
  # $ifClamp: When out of range, take the boundary value.
  set s [lsort -unique -increasing -real $realList]
  set idx [lsearch -exact -real $s $number]
  if {$idx != -1} {
    return [lsearch -inline -real -exact $s $number] ; # number is not equal every real digit of list
  }
  if {[llength $realList] == 1 && $ifClamp} {
    return [lindex $realList 0]
  } elseif {$ifClamp && $number < [lindex $s 0]} {
    return [lindex $s 0] 
  } elseif {$ifClamp && $number > [lindex $s end]} { ; # adapt to list with only one item
    return [lindex $s 1] 
  } elseif {$number < [lindex $s 0] || $number > [lindex $s end]} {
    error "proc find_nearestNum_atIntegerList: your number is not in the range of list (without turning on switch \$ifClamp)"; # your number is not in the range of list
  }
  foreach i $s {
    set next_i [lindex $s [expr [lsearch $s $i] + 1]]
    if {$i < $number && $number < $next_i} {
      set lowerIdx [lsearch $s $i]
      break
    } 
  }
  set upperIdx [expr {$lowerIdx + 1}]
  return [lindex $s [expr {$returnBigOneFlag ? $upperIdx : $lowerIdx}]]
}

# source ./proc_changeDriveCapacity_of_celltype.invs.tcl; # changeDriveCapacity_of_celltype
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/21 23:24:37 Monday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : change cell drive capacity of cell type according to different std process
# ref       : link url
# --------------------------
source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
proc changeDriveCapacity_of_celltype {{refType "BUFD4BWP6T16P96CPD"} {originalDriveCapacibility 0} {toDriverCapacibility 0}} {
  set processType [whichProcess_fromStdCellPattern $refType]
  if {$processType == "TSMC"} { ; # TSMC
    regsub "D${originalDriveCapacibility}BWP" $refType "D${toDriverCapacibility}BWP" toCelltype
    return $toCelltype
  } elseif {$processType == "HH"} { ; # HH40 huahonghongli
    if {$toDriverCapacibility == 0.5} {set toDriverCapacibility "05"}
    regsub [subst {(.*)X${originalDriveCapacibility}}] $refType [subst {\\1X${toDriverCapacibility}}] toCelltype
    return $toCelltype
  } else {
    error "proc changeDriveCapacity_of_celltype: process of std cell is not belong to TSMC or HH!!!"
  }
}


# source ./proc_strategy_changeDriveCapacity_of_driveCell.invs.tcl; # strategy_changeDriveCapacity - return toChangeCelltype
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
# source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Tue Jul  8 11:22:06 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
# descrip   : judge which process specified celltype is 
# ref       : link url
# --------------------------
proc whichProcess_fromStdCellPattern {{celltype ""}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e] == ""} {
    return "0x0:1"; # can't find celltype in this design and library 
  } else {
    if {[regexp BWP $celltype]} {
      set processType "TSMC" 
    } elseif {[regexp {A[HRL]\d+$} $celltype]} {
      set processType "HH" 
    } else {
      return "0x0:1"; # can't indentify where the celltype is come from
    }
    return $processType
  }
}

# source ./proc_find_nearestNum_atIntegerList.invs.tcl; # find_nearestNum_atIntegerList
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Tue Jul  8 11:05:01 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
# descrip   : find the nearest number from list, you can control which one of bigger or smaller
#             if $returnBigOneFlag is 1, return big one near number
#             if $returnBigOneFlag is 0, return small one near number
#             if $ifClamp is 1 and $number is out of $realList, return the maxOne or small one of $realList
#             if $ifClamp is 0 and $number is out of $realList, return "0x0:1"(error)
# update    : 2025/07/18 12:15:10 Friday
#             adapt to list with only one item
# ref       : link url
# --------------------------
proc find_nearestNum_atIntegerList {{realList {}} number {returnBigOneFlag 1} {ifClamp 1}} {
  # $ifClamp: When out of range, take the boundary value.
  set s [lsort -unique -increasing -real $realList]
  set idx [lsearch -exact -real $s $number]
  if {$idx != -1} {
    return [lsearch -inline -real -exact $s $number] ; # number is not equal every real digit of list
  }
  if {[llength $realList] == 1 && $ifClamp} {
    return [lindex $realList 0]
  } elseif {$ifClamp && $number < [lindex $s 0]} {
    return [lindex $s 0] 
  } elseif {$ifClamp && $number > [lindex $s end]} { ; # adapt to list with only one item
    return [lindex $s 1] 
  } elseif {$number < [lindex $s 0] || $number > [lindex $s end]} {
    error "proc find_nearestNum_atIntegerList: your number is not in the range of list (without turning on switch \$ifClamp)"; # your number is not in the range of list
  }
  foreach i $s {
    set next_i [lindex $s [expr [lsearch $s $i] + 1]]
    if {$i < $number && $number < $next_i} {
      set lowerIdx [lsearch $s $i]
      break
    } 
  }
  set upperIdx [expr {$lowerIdx + 1}]
  return [lindex $s [expr {$returnBigOneFlag ? $upperIdx : $lowerIdx}]]
}


# source ./proc_print_ecoCommands.invs.tcl; # print_ecoCommand - return command string (only one command)
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Mon Jul  7 20:42:42 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
# descrip   : print eco command refering to args, you can specify instname/celltype/terms/newInstNamePrefix/loc/relativeDistToSink to control one to print
# ref       : link url
# --------------------------
proc print_ecoCommand {args} {
  set type                "change"; # change|add|delete
  set inst                ""
  set terms               ""
  set celltype            ""
  set newInstNamePrefix   ""
  set loc                 {}
  set relativeDistToSink  ""
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$type == ""} {
    return "0x0:1"; # check your input $type
  } else {
    if {$type == "change"} {
      if {$inst == "" || $celltype == "" || [dbget top.insts.name $inst -e] == "" || [dbget head.libCells.name $celltype -e] == ""} {
        return "pe:0x0:2"; # change: error instname or celltype 
      }
      return "ecoChangeCell -cell $celltype -inst $inst"
    } elseif {$type == "add"} {
      if {$celltype == "" || [dbget head.libCells.name $celltype -e] == "" || ![llength $terms]} {
        return "0x0:3"; # add: error celltype/terms or loc is out of FPlan boxes
      }
      if {$newInstNamePrefix != ""} {
        if {[llength $loc] && [ifInBoxes $loc]} {
          if {$relativeDistToSink != "" && $relativeDistToSink > 0 && $relativeDistToSink < 1} {
            return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\} -loc \{$loc\} -relativeDistToSink $relativeDistToSink" 
          } elseif {$relativeDistToSink != "" && $relativeDistToSink < 0 || $relativeDistToSink != "" && $relativeDistToSink > 1} {
            return "0x0:5"; # check $relativeDistToSink 
          } else {
            return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\} -loc \{$loc\}" 
          }
        } elseif {[llength $loc] && ![ifInBoxes $loc]} {
          return "0x0:4"; # check your loc value, it is out of fplan boxes
        } elseif {![llength $loc] && $relativeDistToSink != "" && $relativeDistToSink > 0 && $relativeDistToSink < 1} {
          return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\} -relativeDistToSink $relativeDistToSink" 
        } else {
          return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\}"
        }
      } else {
        if {[llength $loc] && [ifInBoxes $loc]} {
          if {$relativeDistToSink != "" && $relativeDistToSink > 0 && $relativeDistToSink < 1} {
            return "ecoAddRepeater -cell $celltype -term \{$terms\} -loc \{$loc\} -relativeDistToSink $relativeDistToSink" 
          } elseif {$relativeDistToSink != "" && $relativeDistToSink < 0 || $relativeDistToSink != "" && $relativeDistToSink > 1} {
            return "0x0:5"; # check $relativeDistToSink 
          } else {
            return "ecoAddRepeater -cell $celltype -term \{$terms\} -loc \{$loc\}" 
          }
        } elseif {[llength $loc] && ![ifInBoxes $loc]} {
          return "0x0:6"; # check your loc value, it is out of fplan boxes
        } elseif {![llength $loc] && $relativeDistToSink != "" && $relativeDistToSink > 0 && $relativeDistToSink < 1} {
          return "ecoAddRepeater -cell $celltype -term \{$terms\} -relativeDistToSink $relativeDistToSink" 
        } elseif {$relativeDistToSink != "" && $relativeDistToSink <= 0 || $relativeDistToSink >= 1} {
          return "0x0:7"; # $relativeDistToSink range error
        } else {
          return "ecoAddRepeater -cell $celltype -term \{$terms\}"
        }
      }
    } elseif {$type == "delete"} {
      if {$inst == "" || [dbget top.insts.name $inst -e] == ""} {
        return "0x0:5"; # delete: error instname
      }
      return "ecoDeleteRepeater -inst $inst" 
    } else {
      return "0x0:0"; # have no choice in type
    }
  }
}
define_proc_arguments print_ecoCommand \
  -info "print eco command"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delete}}}}
    {-inst "specify inst to eco when type is add/delete" AString string optional}
    {-terms "specify terms to eco when type is add" AString string optional}
    {-celltype "specify celltype to add when type is add" AString string optional}
    {-newInstNamePrefix "specify new inst name prefix when type is add" AString string optional}
    {-loc "specify location of new inst when type is add" AString string optional}
    {-relativeDistToSink "specify relative value when type is add.(use it when loader is only one)" AFloat float optional}
  }
proc ifInBoxes {{loc {0 0}} {boxes {{}}}} {
  if {![llength [lindex $boxes 0]]} {
    set fplanBoxes [lindex [dbget top.fplan.boxes] 0]
  }
  foreach box $fplanBoxes {
    if {[ifInBox $loc $box]} {
      return 1 
    }
  }
  return 0
}
proc ifInBox {{loc {0 0}} {box {0 0 10 10}}} {
  set xRange [list [lindex $box 0] [lindex $box 2]]
  set yRange [list [lindex $box 1] [lindex $box 3]]
  set x [lindex $loc 0]
  set y [lindex $loc 1]
  if {[lindex $xRange 0] < $x && $x < [lindex $xRange 1] && [lindex $yRange 0] < $y && $y < [lindex $yRange 1]} {
    return 1 
  } else {
    return 0 
  }
}

# source ./proc_print_formatedTable.common.tcl; # print_formatedTable D2 list - return 0, puts formated table
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/13 17:23:21 Sunday
# label     : display_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : format input List(only for D2 List), print table using linux command column
# ref       : link url
# --------------------------
proc print_formatedTable {{dataList {}}} {
  set text ""
  foreach row $dataList {
      append text [join $row "\t"]
      append text "\n"
  }
  # 通过管道传递给column命令
  set pipe [open "| column -t" w+]
  puts -nonewline $pipe $text
  close $pipe w
  set formattedLines [list ]
  while {[gets $pipe line] > -1} {
    lappend formattedLines $line
  }
  close $pipe
  return [join $formattedLines \n]
}

# source ./proc_pw_puts_message_to_file_and_window.common.tcl; # pw - advanced puts
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/15 10:09:06 Tuesday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : puts message to file and window
# ref       : link url
# --------------------------
proc pw {{fileId ""} {message ""}} {
  puts $message
  puts $fileId $message
}

# source ./proc_strategy_clampDriveCapacity_BetweenDriverSink.invs.tcl; # strategy_clampDriveCapacity_BetweenDriverSink - return celltype
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/21 20:52:47 Monday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : 
# ref       : link url
# --------------------------
proc strategy_clampDriveCapacity_BetweenDriverSink {{driverCelltype ""} {sinkCelltype ""} {toCheckCelltype} {regExp "D(\\d+)BWP.*CPD(U?L?H?VT)?"} {refDriverOrSink "refSink"} {maxExcessRatio 0.5}} {
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
# source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Tue Jul  8 11:22:06 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
# descrip   : judge which process specified celltype is 
# ref       : link url
# --------------------------
proc whichProcess_fromStdCellPattern {{celltype ""}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget head.libCells.name $celltype -e] == ""} {
    return "0x0:1"; # can't find celltype in this design and library 
  } else {
    if {[regexp BWP $celltype]} {
      set processType "TSMC" 
    } elseif {[regexp {A[HRL]\d+$} $celltype]} {
      set processType "HH" 
    } else {
      return "0x0:1"; # can't indentify where the celltype is come from
    }
    return $processType
  }
}

# source ./proc_find_nearestNum_atIntegerList.invs.tcl; # find_nearestNum_atIntegerList
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Tue Jul  8 11:05:01 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
# descrip   : find the nearest number from list, you can control which one of bigger or smaller
#             if $returnBigOneFlag is 1, return big one near number
#             if $returnBigOneFlag is 0, return small one near number
#             if $ifClamp is 1 and $number is out of $realList, return the maxOne or small one of $realList
#             if $ifClamp is 0 and $number is out of $realList, return "0x0:1"(error)
# update    : 2025/07/18 12:15:10 Friday
#             adapt to list with only one item
# ref       : link url
# --------------------------
proc find_nearestNum_atIntegerList {{realList {}} number {returnBigOneFlag 1} {ifClamp 1}} {
  # $ifClamp: When out of range, take the boundary value.
  set s [lsort -unique -increasing -real $realList]
  set idx [lsearch -exact -real $s $number]
  if {$idx != -1} {
    return [lsearch -inline -real -exact $s $number] ; # number is not equal every real digit of list
  }
  if {[llength $realList] == 1 && $ifClamp} {
    return [lindex $realList 0]
  } elseif {$ifClamp && $number < [lindex $s 0]} {
    return [lindex $s 0] 
  } elseif {$ifClamp && $number > [lindex $s end]} { ; # adapt to list with only one item
    return [lindex $s 1] 
  } elseif {$number < [lindex $s 0] || $number > [lindex $s end]} {
    error "proc find_nearestNum_atIntegerList: your number is not in the range of list (without turning on switch \$ifClamp)"; # your number is not in the range of list
  }
  foreach i $s {
    set next_i [lindex $s [expr [lsearch $s $i] + 1]]
    if {$i < $number && $number < $next_i} {
      set lowerIdx [lsearch $s $i]
      break
    } 
  }
  set upperIdx [expr {$lowerIdx + 1}]
  return [lindex $s [expr {$returnBigOneFlag ? $upperIdx : $lowerIdx}]]
}

# source ./proc_changeDriveCapacity_of_celltype.invs.tcl; # changeDriveCapacity_of_celltype
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/21 23:24:37 Monday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : change cell drive capacity of cell type according to different std process
# ref       : link url
# --------------------------
source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
proc changeDriveCapacity_of_celltype {{refType "BUFD4BWP6T16P96CPD"} {originalDriveCapacibility 0} {toDriverCapacibility 0}} {
  set processType [whichProcess_fromStdCellPattern $refType]
  if {$processType == "TSMC"} { ; # TSMC
    regsub "D${originalDriveCapacibility}BWP" $refType "D${toDriverCapacibility}BWP" toCelltype
    return $toCelltype
  } elseif {$processType == "HH"} { ; # HH40 huahonghongli
    if {$toDriverCapacibility == 0.5} {set toDriverCapacibility "05"}
    regsub [subst {(.*)X${originalDriveCapacibility}}] $refType [subst {\\1X${toDriverCapacibility}}] toCelltype
    return $toCelltype
  } else {
    error "proc changeDriveCapacity_of_celltype: process of std cell is not belong to TSMC or HH!!!"
  }
}


# source ./proc_calculateResistantCenter_advanced.invs.tcl; # calculateResistantCenter_fromPoints - input pointsList, return center pt
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/20 14:15:19 Sunday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# ref       : link url
# --------------------------
proc calculateResistantCenter_fromPoints {pointsList {filterStrategy "auto"} {threshold 3.0} {densityThreshold 0.75} {minPoints 5}} {
  # 检查点数量是否足够
  set pointCount [llength $pointsList]
  if {$pointCount == 0} {
    return "0x0:1"; # check your input
  }

  # 直接计算所有点的均值（用于不过滤或过滤失败的情况）
  set sumX 0.0
  set sumY 0.0
  foreach point $pointsList {
    lassign $point x y
    set sumX [expr {$sumX + $x}]
    set sumY [expr {$sumY + $y}]
  }
  set rawMeanX [expr {$sumX / $pointCount}]
  set rawMeanY [expr {$sumY / $pointCount}]

  # 提前计算距离数组，解决变量作用域问题
  set distances {}
  foreach point $pointsList {
    lassign $point x y
    set dx [expr {$x - $rawMeanX}]
    set dy [expr {$y - $rawMeanY}]
    lappend distances [expr {sqrt($dx*$dx + $dy*$dy)}]
  }

  # 根据过滤策略决定是否执行过滤
  switch -- $filterStrategy {
    "never" {
      # 强制不过滤，直接返回原始均值
      return [list $rawMeanX $rawMeanY]
    }
    "always" {
      # 强制过滤，无论点分布如何
      set shouldFilter 1
    }
    "auto" {
      # 自动判断是否需要过滤
      # 计算平均距离和标准差
      set sumDist 0.0
      foreach dist $distances {
        set sumDist [expr {$sumDist + $dist}]
      }
      set avgDist [expr {$sumDist / $pointCount}]

      set sumSqDiff 0.0
      foreach dist $distances {
        set diff [expr {$dist - $avgDist}]
        set sumSqDiff [expr {$sumSqDiff + ($diff * $diff)}]
      }
      set stdDev [expr {sqrt($sumSqDiff / $pointCount)}]

      # 处理标准差为零的情况（所有点距离相等）
      if {$stdDev < 1e-10} {
        # 所有点到中心点的距离几乎相同，没有明显异常值
        set shouldFilter 0
        set skewness 0.0
      } else {
        # 计算分布偏态系数
        set sumCubedDiff 0.0
        foreach dist $distances {
          set diff [expr {$dist - $avgDist}]
          set sumCubedDiff [expr {$sumCubedDiff + ($diff * $diff * $diff)}]
        }
        set skewness [expr {$sumCubedDiff / ($pointCount * ($stdDev ** 3))}]
      }

      # 自动调整参数
      set adjustedOutlierThreshold $threshold
      set adjustedDensityThreshold $densityThreshold

      if {$skewness > 1.0} {
        set adjustedOutlierThreshold [expr {$threshold * (1.0 + $skewness/5.0)}]
      }

      # 处理avgDist为零的情况（所有点重合）
      if {$avgDist < 1e-10} {
        # 所有点几乎重合，无需过滤
        set shouldFilter 0
        set relativeStdDev 0.0
      } else {
        set relativeStdDev [expr {$stdDev / $avgDist}]
        if {$relativeStdDev > 0.5} {
          set reductionFactor [expr {0.2 * ($relativeStdDev - 0.5)}]
          set adjustedDensityThreshold [expr {$densityThreshold * (1.0 - $reductionFactor)}]
        }
      }

      # 只有当标准差不为零时才计算inlierRatio
      if {$stdDev >= 1e-10} {
        # 计算在调整后的阈值内的点的比例
        set inlierCount 0
        foreach dist $distances {
          if {$dist <= $adjustedOutlierThreshold * $stdDev} {
            incr inlierCount
          }
        }
        set inlierRatio [expr {$inlierCount / double($pointCount)}]

        # 判断是否需要过滤
        if {$inlierRatio < $adjustedDensityThreshold} {
          set shouldFilter 1
        } else {
          set shouldFilter 0
        }
      }
    }
    default {
      error "Invalid filterStrategy: must be 'auto', 'always', or 'never'"
    }
  }

  # 如果不需要过滤或点太少，直接返回原始均值
  if {!$shouldFilter || $pointCount < $minPoints} {
    return [list $rawMeanX $rawMeanY]
  }

  # 执行距离过滤（使用原始threshold，而非调整后的）
  # 重新计算标准差（避免之前的early return影响）
  set sumDist 0.0
  foreach dist $distances {
    set sumDist [expr {$sumDist + $dist}]
  }
  set avgDist [expr {$sumDist / $pointCount}]

  set sumSqDiff 0.0
  foreach dist $distances {
    set diff [expr {$dist - $avgDist}]
    set sumSqDiff [expr {$sumSqDiff + ($diff * $diff)}]
  }
  set stdDev [expr {sqrt($sumSqDiff / $pointCount)}]

  # 处理标准差为零的情况（强制不过滤）
  if {$stdDev < 1e-10} {
    return [list $rawMeanX $rawMeanY]
  }

  set filteredPoints {}
  for {set i 0} {$i < $pointCount} {incr i} {
    if {[lindex $distances $i] <= $threshold * $stdDev} {
      lappend filteredPoints [lindex $pointsList $i]
    }
  }

  # 如果过滤后没有点了，返回原始均值
  if {[llength $filteredPoints] == 0} {
    return [list $rawMeanX $rawMeanY]
  }

  # 重新计算过滤后的均值
  set sumX 0.0
  set sumY 0.0
  foreach point $filteredPoints {
    lassign $point x y
    set sumX [expr {$sumX + $x}]
    set sumY [expr {$sumY + $y}]
  }

  return [list [expr {$sumX / [llength $filteredPoints]}] [expr {$sumY / [llength $filteredPoints]}]]
}

# 辅助函数：模拟Python的zip功能
proc zip {list1 list2} {
  set result {}
  for {set i 0} {$i < [min [llength $list1] [llength $list2]]} {incr i} {
    lappend result [list [lindex $list1 $i] [lindex $list2 $i]]
  }
  return $result
}

# 辅助函数：返回最小值
proc min {a b} {
  expr {$a < $b ? $a : $b}
}

# source ./proc_calculateRelativePoint.invs.tcl; # calculateRelativePoint - return relative point
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/20 16:10:10 Sunday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : Calculate relative point between two coordinates based on relative value
# ref       : link url
# --------------------------
proc calculateRelativePoint {startPoint endPoint {relativeValue 0.5} {clampValue 1} {epsilon 1e-10}} {
  if {[llength $startPoint] != 2 || [llength $endPoint] != 2} {
    error "Both startPoint and endPoint must be 2D coordinates in the format {x y}"
  }
  lassign $startPoint startX startY
  lassign $endPoint endX endY
  # 检查relativeValue是否需要被限制在[0,1]范围内
  if {$clampValue} {
    # 限制relativeValue在[0,1]范围内
    if {$relativeValue < 0.0} {
      set relativeValue 0.0
    } elseif {$relativeValue > 1.0} {
      set relativeValue 1.0
    }
  } else {
    # 检查relativeValue是否在有效范围内
    if {$relativeValue < 0.0 - $epsilon || $relativeValue > 1.0 + $epsilon} {
      error "relativeValue must be between 0 and 1 (or use clampValue=1 to auto-clamp)"
    }
  }
  # 计算中间点坐标
  set x [expr {$startX + $relativeValue * ($endX - $startX)}]
  set y [expr {$startY + $relativeValue * ($endY - $startY)}]
  # 处理边界情况，确保数值稳定性
  if {abs($relativeValue - 0.0) < $epsilon} {
    set x $startX
    set y $startY
  } elseif {abs($relativeValue - 1.0) < $epsilon} {
    set x $endX
    set y $endY
  }
  set x [format "%.3f" $x]
  set y [format "%.3f" $y]
  return [list $x $y]
}

# source ./proc_calculateDistance_betweenTwoPoint.invs.tcl; # calculateDistance - return value of distance
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/20 18:07:26 Sunday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : Calculate Euclidean distance between two points with error handling
# ref       : link url
# --------------------------
proc calculateDistance {point1 point2 {epsilon 1e-10} {maxValue 1.0e+100}} {
  # 验证输入点格式
  if {[llength $point1] != 2 || [llength $point2] != 2} {
    error "Both points must be 2D coordinates in the format {x y}"
  }
  # 提取坐标值
  lassign $point1 x1 y1
  lassign $point2 x2 y2
  # 验证坐标是否为数值
  if {![string is double -strict $x1] || ![string is double -strict $y1] || ![string is double -strict $x2] || ![string is double -strict $y2]} {
    error "Coordinates must be valid numeric values"
  }
  # 检查数值范围（防止溢出）
  foreach coord [list $x1 $y1 $x2 $y2] {
    if {abs($coord) > $maxValue} {
      error "Coordinate value exceeds maximum allowed ($maxValue)"
    }
  }
  # 计算坐标差值
  set dx [expr {$x2 - $x1}]
  set dy [expr {$y2 - $y1}]
  # 检查差值是否过大（防止平方运算溢出）
  if {abs($dx) > $maxValue || abs($dy) > $maxValue} {
    error "Coordinate difference exceeds maximum allowed ($maxValue)"
  }
  # 计算平方和
  set sumSq [expr {$dx*$dx + $dy*$dy}]
  # 处理平方和为零的情况（避免开方运算误差）
  if {$sumSq < $epsilon} {
    return 0.0
  }
  # 计算并返回距离
  return [expr {sqrt($sumSq)}]
}

# source ./proc_findMostFrequentElementOfList.invs.tcl; # findMostFrequentElement - return string
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/20 23:35:41 Sunday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : Find the most frequent element in a list with frequency threshold
# ref       : link url
# --------------------------
proc findMostFrequentElement {inputList {minPercentage 50.0} {returnUnique 1}} {
	# 检查输入是否为有效列表
	set listLength [llength $inputList]
	if {$listLength == 0} {
		error "proc findMostFrequentElement: input list is empty!!!"
	}
	# 创建哈希表统计每个元素的出现次数
	array set count {}
	foreach element $inputList {
		incr count($element)
	}
	# 找出最大出现次数
	set maxCount 0
	foreach element [array names count] {
		if {$count($element) > $maxCount} {
			set maxCount $count($element)
		}
	}
	# 计算最大频率百分比
	set frequencyPercentage [expr {($maxCount * 100.0) / $listLength}]
	# 检查是否达到最小百分比阈值
	if {$frequencyPercentage < $minPercentage} {
		if {$returnUnique} {
			return [lsort -unique $inputList]  ;# 返回唯一元素列表
		} else {
			return ""  ;# 未达到阈值且不返回唯一元素时返回空字符串
		}
	}
	# 收集所有达到最大次数的元素
	set mostFrequentElements {}
	foreach element [array names count] {
		if {$count($element) == $maxCount} {
			lappend mostFrequentElements $element
		}
	}
	# 如果有多个元素出现次数相同，返回第一个遇到的元素
	return [lindex $mostFrequentElements 0]
}

# source ./proc_reverseListRange.invs.tcl; # reverseListRange - return reversed list
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/21 00:56:19 Monday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : Reverse elements in a list with range support and optional recursive sublist reversal
# ref       : link url
# --------------------------
proc reverseListRange {listVar {startIdx ""} {endIdx ""} {deep 0}} {
	# 检查输入列表是否有效
	if {![string is list -strict $listVar]} {
		error "Input is not a valid list: '$listVar'"
	}
	set listLen [llength $listVar]
	# 处理特殊值 "end"
	if {$startIdx eq "end"} {
		set startIdx [expr {$listLen - 1}]
	}
	if {$endIdx eq "end"} {
		set endIdx [expr {$listLen - 1}]
	}
	# 处理索引参数
	if {$startIdx eq ""} {
		set startIdx 0  ;# 默认从第一个元素开始
	} elseif {![string is integer -strict $startIdx]} {
		error "Start index '$startIdx' is not a valid integer or 'end'"
	}
	if {$endIdx eq ""} {
		set endIdx [expr {$listLen - 1}]  ;# 默认到最后一个元素结束
	} elseif {![string is integer -strict $endIdx]} {
		error "End index '$endIdx' is not a valid integer or 'end'"
	}
	# 处理负索引（支持Python风格的负索引）
	if {$startIdx < 0} {
		set startIdx [expr {$listLen + $startIdx}]
	}
	if {$endIdx < 0} {
		set endIdx [expr {$listLen + $endIdx}]
	}
	# 验证索引范围
	if {$startIdx < 0 || $startIdx >= $listLen} {
		error "Start index '$startIdx' out of bounds (list length $listLen)"
	}
	if {$endIdx < 0 || $endIdx >= $listLen} {
		error "End index '$endIdx' out of bounds (list length $listLen)"
	}
	if {$startIdx > $endIdx} {
		error "Start index '$startIdx' is greater than end index '$endIdx'"
	}
	# 执行列表反转
	set result {}
	for {set i 0} {$i < $listLen} {incr i} {
		if {$i >= $startIdx && $i <= $endIdx} {
			set element [lindex $listVar $i]
			if {$deep && [llength $element] > 1 && [string is list -strict $element]} {
				lappend result [reverseListRange $element "" "" $deep]
			} else {
				lappend result $element
			}
		} else {
			lappend result [lindex $listVar $i]
		}
	}
	# 反转指定范围内的元素
	set reversedRange [lreverse [lrange $result $startIdx $endIdx]]
	return [lreplace $result $startIdx $endIdx {*}$reversedRange]
}

# source ./proc_formatDecimal.invs.tcl; # formatDecimal/fm - return string converted from number
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/21 03:07:46 Monday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : Convert decimal between 0-1 to fixed-length string starting with '0'
# ref       : link url
# --------------------------
alias fm "formatDecimal"
proc formatDecimal {value {fixedLength 2} {strictRange 1} {padZero 1}} {
	# 错误防御：验证输入是否为有效小数
	if {![string is double -strict $value]} {
		error "Invalid input: '$value' is not a valid decimal number"
	}
	# 错误防御：验证数值范围
	if {$strictRange && ($value <= 0.0 || $value >= 1.0)} {
		error "Value must be between 0 and 1 (exclusive)"
	}
	# 转换为字符串并移除前导0和小数点
	set strValue [string map {"0." ""} [format "%.15g" $value]]
	# 处理特殊情况：纯零值（如0.000）
	if {$strValue eq ""} {
		if {$padZero} {
			# 确保至少有一个0（加上前缀0后长度为2）
			return "0[string repeat "0" [expr {$fixedLength - 1}]]"
		} else {
			return "0"
		}
	}
	# 确保字符串以0开头，并应用固定长度
	if {$fixedLength > 0} {
		# 计算需要的剩余长度（包括前缀0）
		set remainingLength [expr {$fixedLength - 1}]

		if {$remainingLength <= 0} {
			# 至少保留前缀0
			return "0"
		}
		if {$padZero} {
			# 补零至剩余长度
			set paddedValue [string range [format "%0*s" $remainingLength $strValue] 0 $remainingLength-1]
		} else {
			# 直接截断
			set paddedValue [string range $strValue 0 $remainingLength-1]
		}
		return "0$paddedValue"
	} else {
		# 不限制长度时，直接添加前缀0
		return "0$strValue"
	}
}

# source ./proc_checkRoutingLoop.invs.tcl; # checkRoutingLoop - return number
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/21 12:16:50 Monday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : check routing loop in invs
# ref       : link url
# --------------------------
# 判断布线绕圈情况并分级的过程
# 参数:
#   - 直线距离: 两点间的最短距离(um)
#   - 实际线长: 网络的实际走线长度(um)
#   - 严重级别: 可选参数，用于调整各级别的阈值
# 返回值:
#   0: 无绕圈
#   1: 轻微绕圈
#   2: 中度绕圈
#   3: 严重绕圈
#   -1: 输入错误
proc checkRoutingLoop {straightDistance netLength {severityLevel "normal"}} {
	# 错误防御: 检查输入是否为有效数值
	if {![string is double -strict $straightDistance] || $straightDistance <= 0} {
		error "PROC checkRoutingLoop: Invalid parameter 'straightDistance' - must be a positive number ($straightDistance)"
	}
	if {![string is double -strict $netLength] || $netLength <= 0} {
		error "PROC checkRoutingLoop: Invalid parameter 'netLength' - must be a positive number ($netLength)"
	}
	# 将输入参数转换为double类型，确保除法运算精度
	set straightDistance [expr {double($straightDistance)}]
	set netLength [expr {double($netLength)}]
	# 根据严重级别设置阈值
	set thresholds [dict create \
		normal  {1.5 2.0 3.0} \
		relaxed {1.8 2.5 3.5} \
		strict  {1.2 1.8 2.5}
	]
	if {![dict exists $thresholds $severityLevel]} {
		puts "WARNING: Unknown severity level '$severityLevel', using default 'normal'"
		set severityLevel "normal"
	}
	lassign [dict get $thresholds $severityLevel] mildThreshold moderateThreshold severeThreshold
	# 计算线长比
	set lengthRatio [expr {$netLength / $straightDistance}]
	# 判断绕圈等级
	if {$lengthRatio <= $mildThreshold} {
		return 0 ;# No loop
	} elseif {$lengthRatio <= $moderateThreshold} {
		return 1 ;# Mild loop
	} elseif {$lengthRatio <= $severeThreshold} {
		return 2 ;# Moderate loop
	} else {
		return 3 ;# Severe loop
	}
}

# 辅助过程: 获取绕圈等级的文本描述
proc getLoopDescription {loopLevel} {
	switch -- $loopLevel {
		0 { return "No Loop" }
		1 { return "Mild Loop" }
		2 { return "Moderate Loop" }
		3 { return "Severe Loop" }
		default { return "Unknown Level" }
	}
}

# 示例用法
if {0} {
	# 测试案例
	puts "Testing checkRoutingLoop procedure:"
	puts "Straight Distance\tNet Length\tSeverity Level\tLoop Level\tDescription"
	puts "------------------------------------------------------------"

	foreach {dist length level} {
		10.0   12.0   normal
		10.0   18.0   normal
		10.0   22.0   normal
		10.0   35.0   normal
		10.0   12.0   strict
		10.0   12.0   relaxed
		10.0   -5.0   normal
		abc    20.0   normal
	} {
		puts -nonewline "$dist\t\t$length\t\t$level\t\t"
		# 使用错误捕获机制，避免测试时因错误中断
		if {[catch {set result [checkRoutingLoop $dist $length $level]} errMsg]} {
			puts "ERROR: $errMsg"
		} else {
			set desc [getLoopDescription $result]
			puts "$result\t\t$desc"
		}
	}
}

