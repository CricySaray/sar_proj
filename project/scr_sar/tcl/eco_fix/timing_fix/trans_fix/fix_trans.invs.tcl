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
# ref       : link url
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

# The principle of minimum information
proc fix_trans {args} {
  # default value for all var
  set file_viol_pin                            ""
  set violValue_pin_columnIndex                {4 1}
  set canChangeVT                              1
  set canChangeDriveCapacity                   1
  set canChangeVTandDriveCapacity              1
  set canAddRepeater                           1
  set logicToBufferDistanceThreshold           10
  set refBufferCelltype                        "BUFX4AR9"
  set refInverterCelltype                      "INVX4AR9"
  set refCLKBufferCelltype                     "CLKBUFX4AL9"
  set refCLKInverterCelltype                   "CLKINVX4AL9"
  set cellRegExp                               "X(\\d+).*(A\[HRL\]\\d+)$"
  set rangeOfVtSpeed                           {AL9 AR9 AH9}
  set clkNeedVtWeightList                      {{AL9 3} {AR9 0} {AH9 0}}; # weight:0 is stand for forbidden using
  set normalNeedVtWeightList                   {{AL9 1} {AR9 3} {AH9 0}}; # normal std cell can use AL9 and AR9, but weight of AR9 is larger
  set rangeOfDriveCapacityForChange            {1 12}
  set rangeOfDriveCapacityForAdd               {3 12}
  set largerThanDriveCapacityOfChangedCelltype 2
  set ecoNewInstNamePrefix                     "sar_fix_trans_clk_071615"
  set suffixFilename                           ""; # for example : eco4
  set debug                                    0
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set sumFile                                 [eo $suffixFilename "sor_summary_of_result_$suffixFilename.list" "sor_summary_of_result.list" ]
  set cantExtractFile                         [eo $suffixFilename "sor_cantExtract_$suffixFilename.list" "sor_cantExtract.list"]
  set cmdFile                                 [eo $suffixFilename "sor_ecocmds_$suffixFilename.tcl" "sor_ecocmds.tcl"]
  # songNOTE: only deal with loadPin viol situation, ignore drivePin viol situation
  # $violValue_pin_columnIndex  : for example : {3 1}
  #   violPin   xxx   violValue   xxx   xxx
  #   you can specify column of violValue and violPin
  if {$file_viol_pin == "" || [glob -nocomplain $file_viol_pin] == ""} {
    return "0x0:1"; # check your file 
  } else {
    set fi [open $file_viol_pin r]
    set violValue_driverPin_onylOneLoaderPin_D3List [list ]; # one to one
    set violValue_driver_severalLoader_D3List [list ]; # one to more
    set oneToMoreList [list ]
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
          lappend violValue_driver_severalLoader_D3List [list $viol_value $drive_pin [lindex $num_termName_D2List 1]]
          lappend oneToMoreList [list $viol_value $drive_pin $load_pin]
          # songNOTE: TODO show one drivePin , but all sink Pins
          #           annotate a X flag in violated sink Pin
        }
      } else {
        lappend cantExtractList "(Line $j) drivePin - not extract! : $line"
      }
    }
    close $fi
    # -----------------------
    # sort and check D3List correction : $violValue_driverPin_onylOneLoaderPin_D3List and $violValue_driver_severalLoader_D3List
    # 1 v 1
    set violValue_driverPin_onylOneLoaderPin_D3List [lsort -index 0 -real -decreasing $violValue_driverPin_onylOneLoaderPin_D3List]
    set violValue_driverPin_onylOneLoaderPin_D3List [lsort -index 0 -real -decreasing [lsort -unique -index 1 $violValue_driverPin_onylOneLoaderPin_D3List]]
    set violValue_driver_severalLoader_D3List [lsort -index 0 -real -decreasing $violValue_driver_severalLoader_D3List]
    set violValue_driver_severalLoader_D3List [lsort -index 0 -real -decreasing [lsort -unique -index 1 $violValue_driver_severalLoader_D3List]]
if {$debug} { puts [join $violValue_driverPin_onylOneLoaderPin_D3List \n] }
    # 1 v more
    set oneToMoreList [lsort -index 0 -real -decreasing $oneToMoreList]
    set oneToMoreList [lsort -index 1 -increasing [lsort -unique -index 2 $oneToMoreList]]
    set oneToMoreList [linsert $oneToMoreList 0 [list violValue drivePin loadPin]]
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
    set cantChangeList_1v1 [list [list situation method violValue netLength driveCellClass driveCelltype driveViolPin loadCellClass sinkCelltype loadViolPin]]
    ## changed info
    set fixedPrompts {
      "# symbols of methods for changed cell"
      "# changeVT:"
      "## T - changedVT, below is toChangeCelltype"
      "# changeDriveCapacity"
      "## D - changedDriveCapacity, below is toChangeCelltype"
      "# addRepeaterCell"
      "## A_09 A_0.9 - near the driver - addedRepeaterCell, below is toAddCelltype"
      "## A_05 A_0.5 - in the middle of driver and sink - addedRepeaterCell, below is toAddCelltype"
      "## A_01 A_0.1 - near the sink   - addedRepeaterCell, below is toAddCelltype"
      "# special fixed"
      "## FS - fix special situation: change driveCelltype (changeVT and changeDriveCapacity)"
      ""
      "# symbol of situations:"
      "## ll - logic/CLKlogic to logic/CLKlogic"
      "## bb/vv - buffer/inverter to buffer/inverter"
      "## lb - logic to buffer/inverter"
      "## bl - buffer to logic"

      "## lc - logic to clockcell"
      "## cl - clockcell to logic"
      "## bc - buffer/inverter/clockcell to clockcell"
      "## cb - clockcell to buffer/inverter/clockcell"

      "## lm - logic to mem"
      "## ml - mem to logic"
      "## bm - buffer/inverter to mem"
      "## mb - mem to buffer/inverter"

      "## li - logic to ip (maybe never)"
      "## il - ip to logic (maybe never)"
      "## bi - buffer/inverter to ip"
      "## ib - ip to buffer/inverter"

      "## lp - logic to IOpad"
      "## pl - IOpad to logic"
      "## bp - buffer/inverter to IOpad"
      "## pb - IOpad to buffer/inverter"

      "## dt - dont touch cell"
      "## du - dont use cell"
    }
    set fixedList_1v1 [list [list situation method celltypeToFix violValue netLength driveCellClass driveCelltype driveViolPin loadCellClass sinkCelltype loadViolPin]]
    # skipped situation info
    set skippedSituationsPrompt {
      "# NF - have no faster vt" 
      "# NL - have no lager drive capacity"
      "# NFL - have no both faster vt and lager drive capacity"
    }
    set skippedList_1v1 [list [list situation method violValue netLength driveCellClass driveCelltype driveViolPin loadCellClass sinkCelltype loadViolPin]]
    set notConsideredPrompt {
      "# NC - not considered situation"
    }
    set notConsideredList_1v1 [list [list situation violValue netLength driveCellClass driveCelltype driveViolPin loadCellClass sinkCelltype loadViolPin]]
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
      ### 1 loader is a buffer, but driver is a logic cell
if {$debug} { puts "drive: [get_cell_class [lindex $viol_driverPin_loadPin 1]] load: [get_cell_class [lindex $viol_driverPin_loadPin 2]]" }
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

      set sinkCelltype [dbget [dbget top.insts.name [get_object_name [get_cells -quiet -of_objects  [lindex $viol_driverPin_loadPin 2]]] -p].cell.name]
      set loadCapacity [get_driveCapacity_of_celltype $sinkCelltype $cellRegExp]
      set allInfoList [concat [lindex $viol_driverPin_loadPin 0] $netLength \
                              $driveCellClass $driveCelltype [lindex $viol_driverPin_loadPin 1] \
                              $loadCellClass $sinkCelltype [lindex $viol_driverPin_loadPin 2] ]
      # initialize some iterative vars
      set cmd1 ""
      set toChangeCelltype ""
      set toAddCelltype ""
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
        if {[lindex $viol_driverPin_loadPin 0] < -0.2 && $netLength < 20 || \
            [lindex $viol_driverPin_loadPin 0] < -0.1 && $netLength < 10 || \
            [lindex $viol_driverPin_loadPin 0] < -0.07 && $netLength < 8 || \
            [lindex $viol_driverPin_loadPin 0] < -0.03 && $netLength < 4 \
              } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr $driveCapacity - $loadCapacity] < 0]} {
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
        } elseif {$ifHaveFasterVT && $canChangeVT && [expr [lindex $viol_driverPin_loadPin 0] >= -0.006 || \
                   [lindex $viol_driverPin_loadPin 0] >= -0.01 && $netLength > [expr $logicToBufferDistanceThreshold  * 15 ] || \
                   [lindex $viol_driverPin_loadPin 0] >= -0.02 && $netLength > [expr $logicToBufferDistanceThreshold  * 30 ] \
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
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.04 && $netLength <= [expr $logicToBufferDistanceThreshold * 1.5]} { ; # songNOTE: situation 02 only changeDriveCapacity
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
        } elseif {$ifHaveFasterVT && $ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.05 && $netLength <= [expr $logicToBufferDistanceThreshold * 2.2]} { ; # songNOTE: situation 03 change VT and DriveCapacity
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
              lappend fixedList_1v1 [concat "ll:in_5:4" "T_D" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && [lindex $viol_driverPin_loadPin 0] < -0.08  && [lindex $viol_driverPin_loadPin 0] >= -0.1 && $netLength < [expr $logicToBufferDistanceThreshold * 4] && $netLength > [expr $logicToBufferDistanceThreshold * 2]} { ; # songNOTE: situation 04 add Repeater near logic cell
if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_6:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
#puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "ll:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $toChangeCelltype]
                lappend fixedList_1v1 [concat "ll:in_6:3" "TA_09" $toAddCelltype $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_1v1 [concat "ll:in_6:4" "A_09" $toAddCelltype $allInfoList]
                set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              }
            }
          }
        } elseif {$canAddRepeater && [lindex $viol_driverPin_loadPin 0] < -0.12 && $netLength > [expr $logicToBufferDistanceThreshold * 9]} { ; # songNOTE: situation 05 not in above situation
if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_7:1" "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
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
        } else { ; # songNOTE: situation 05 not in above situation
if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_8:1" "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "ll:in_8:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
if {$debug} {puts "test : ll:in_8:2"}
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
                lappend fixedList_1v1 [concat "ll:in_8:3" "TA_09" $toAddCelltype $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_1v1 [concat "ll:in_8:4" "A_09" $toAddCelltype $allInfoList]
                set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              }
            }
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
        if {[lindex $viol_driverPin_loadPin 0] < -0.2 && $netLength < 20 || \
            [lindex $viol_driverPin_loadPin 0] < -0.1 && $netLength < 10 || \
            [lindex $viol_driverPin_loadPin 0] < -0.07 && $netLength < 8 || \
            [lindex $viol_driverPin_loadPin 0] < -0.03 && $netLength < 4 \
            } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 6 || [expr  $driveCapacity - $loadCapacity] < 2]} {
            set leftStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $loadCapacity] <= -5] 4 3]
            set rightStair [eo [expr $driveCapacity <= 1 && [expr $driveCapacity - $loadCapacity] <= -5] 3 2]
            set leftStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $loadCapacity] <= -10] 5 $leftStair]
            set rightStair [eo [expr $driveCapacity < 1 && [expr $driveCapacity - $loadCapacity] <= -10] 4 $rightStair]
puts "----------------"
puts "driveCapacity: $driveCapacity  | loadCapacity: $loadCapacity"
puts "left: $leftStair  right: $rightStair"
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 2] $leftStair $rightStair] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype] 
            lappend fixedList_1v1 [concat "lb:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "lb:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && [lindex $viol_driverPin_loadPin 0] >= -0.005} { ; # songNOTE: situation 01 only changeVT
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
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.015 && $netLength <= [expr $logicToBufferDistanceThreshold * 1.1]} { ; # songNOTE: situation 02 only changeDriveCapacity
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
        } elseif {$ifHaveFasterVT && $ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.04 && $netLength <= [expr $logicToBufferDistanceThreshold * 1.8]} { ; # songNOTE: situation 03 change VT and DriveCapacity
if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
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
              lappend fixedList_1v1 [concat "lb:in_5:4" "T_D" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && [lindex $viol_driverPin_loadPin 0] >= -0.12 && $netLength < [expr $logicToBufferDistanceThreshold * 5] && $netLength > [expr $logicToBufferDistanceThreshold * 1]} { ; # songNOTE: situation 04 add Repeater near logic cell
if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_6:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
#puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "lb:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $toChangeCelltype]
                lappend fixedList_1v1 [concat "lb:in_6:3" "TA_09" $toAddCelltype $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_1v1 [concat "lb:in_6:4" "A_09" $toAddCelltype $allInfoList]
                set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              }
            }
          }
        } elseif {$canAddRepeater && [lindex $viol_driverPin_loadPin 0] < -0.18 && $netLength > [expr $logicToBufferDistanceThreshold * 4]} { ; # songNOTE: add two repeater
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_7:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
#puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "lb:in_7:2" "DAA_0509" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd_DA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add1 $cmd_DA_add2]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $toChangeCelltype]
                lappend fixedList_1v1 [concat "lb:in_7:3" "TAA_0509" $toAddCelltype $allInfoList]
                set cmd_TA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
                set cmd_TA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add1 $cmd_TA_add2]
              } else {
                lappend fixedList_1v1 [concat "lb:in_7:4" "AA_0509" $toAddCelltype $allInfoList]
                set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
                set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
                set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
              }
            }
          }
        } elseif {$canAddRepeater && [lindex $viol_driverPin_loadPin 0] < -0.22 && $netLength > [expr $logicToBufferDistanceThreshold * 4]} { ; # songNOTE: situation 05 not in above situation
if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
if {$debug} { puts "Not in above situation, so NOTICE" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 1 $refCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "lb:in_8:1" "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
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
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
                lappend fixedList_1v1 [concat "lb:in_8:3" "TAA_0509" $toAddCelltype $allInfoList]
                set cmd_TA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
                set cmd_TA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add1 $cmd_TA_add2]
              } else {
                lappend fixedList_1v1 [concat "lb:in_8:4" "AA_0509" $toAddCelltype $allInfoList]
                set cmd_AA_add1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
                set cmd_AA_add2 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
                set cmd1 [concat $cmd_AA_add1 $cmd_AA_add2]
              }
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
        if {[lindex $viol_driverPin_loadPin 0] < -0.2 && $netLength < 20 || \
            [lindex $viol_driverPin_loadPin 0] < -0.1 && $netLength < 10 || \
            [lindex $viol_driverPin_loadPin 0] < -0.07 && $netLength < 8 || \
            [lindex $viol_driverPin_loadPin 0] < -0.03 && $netLength < 4 \
            } { ; # songNOTE: special situation NOTICE: for fixing special situation(large violation but short net lenth)
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity <= 4 || [expr  $driveCapacity - $loadCapacity] < 0]} {
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 3] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype] 
            lappend fixedList_1v1 [concat "bl:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "bl:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && [expr [lindex $viol_driverPin_loadPin 0] >= -0.02 || \
                   [lindex $viol_driverPin_loadPin 0] >= -0.01 && $netLength > [expr $logicToBufferDistanceThreshold  * 15 ] || \
                   [lindex $viol_driverPin_loadPin 0] >= -0.02 && $netLength > [expr $logicToBufferDistanceThreshold  * 30 ] \
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
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.04 && $netLength <= [expr $logicToBufferDistanceThreshold * 2.1]} { ; # songNOTE: situation 02 only changeDriveCapacity
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
        } elseif {$ifHaveFasterVT && $ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.06 && $netLength <= [expr $logicToBufferDistanceThreshold * 2.5]} { ; # songNOTE: situation 03 change VT and DriveCapacity
if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
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
              lappend fixedList_1v1 [concat "bl:in_5:4" "T_D" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && [lindex $viol_driverPin_loadPin 0] < -0.06  && [lindex $viol_driverPin_loadPin 0] >= -0.1 && $netLength < [expr $logicToBufferDistanceThreshold * 4] && $netLength > [expr $logicToBufferDistanceThreshold * 2]} { ; # songNOTE: situation 04 add Repeater near logic cell
if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "bl:in_6:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
#puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "bl:in_6:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $toChangeCelltype]
                lappend fixedList_1v1 [concat "bl:in_6:3" "TA_05" $toAddCelltype $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_1v1 [concat "bl:in_6:4" "A_05" $toAddCelltype $allInfoList]
                set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              }
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
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "bl:in_7:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
                lappend fixedList_1v1 [concat "bl:in_7:3" "TA_05" $toAddCelltype $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_1v1 [concat "bl:in_7:4" "A_05" $toAddCelltype $allInfoList]
                set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              }
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
        if {[lindex $viol_driverPin_loadPin 0] < -0.2 && $netLength < 20 || \
            [lindex $viol_driverPin_loadPin 0] < -0.1 && $netLength < 10 || \
            [lindex $viol_driverPin_loadPin 0] < -0.07 && $netLength < 8 || \
            [lindex $viol_driverPin_loadPin 0] < -0.03 && $netLength < 4 \
            } { ; # songNOTE: special situation
          if {[expr $ifHaveFasterVT || $ifHaveLargerCapacity] && [expr $driveCapacity < 4 || [expr  $driveCapacity - $loadCapacity] < 0]} {
            set toChangeCelltype [eo $ifHaveFasterVT [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1] $driveCelltype]
            set toChangeCelltype [eo $ifHaveLargerCapacity [strategy_changeDriveCapacity $toChangeCelltype 0 [eo [expr $driveCapacity <= 4] 2 1] $rangeOfDriveCapacityForChange $cellRegExp 1] $toChangeCelltype] 
            lappend fixedList_1v1 [concat "bb:in_1:1" "FS" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -cell $toChangeCelltype -inst $driveInstname]
          } else {
            lappend cantChangeList_1v1 [concat "bb:in_1:1" "S" $allInfoList]
            set cmd1 "cantChange"
          }
        } elseif {$ifHaveFasterVT && $canChangeVT && [expr [lindex $viol_driverPin_loadPin 0] >= -0.015 || \
           [lindex $viol_driverPin_loadPin 0] >= -0.02 && $netLength >= [expr $logicToBufferDistanceThreshold * 20]  || \
           [lindex $viol_driverPin_loadPin 0] >= -0.03 && $netLength >= [expr $logicToBufferDistanceThreshold * 30] \
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
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.04 && $netLength <= [expr $logicToBufferDistanceThreshold * 1.5]} { ; # songNOTE: situation 02 only changeDriveCapacity
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
        } elseif {$ifHaveFasterVT && $ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.07 && $netLength <= [expr $logicToBufferDistanceThreshold * 2.2]} { ; # songNOTE: situation 03 change VT and DriveCapacity
if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
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
              lappend fixedList_1v1 [concat "bb:in_5:4" "T_D" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
            }
          }
        } elseif {$canAddRepeater && [lindex $viol_driverPin_loadPin 0] < -0.08  && [lindex $viol_driverPin_loadPin 0] >= -0.1 && $netLength < [expr $logicToBufferDistanceThreshold * 4] && $netLength > [expr $logicToBufferDistanceThreshold * 2]} { ; # songNOTE: situation 04 add Repeater near logic cell
if {$debug} { puts "in 4: add Repeater" }
          set refCelltype [eo [expr [regexp CLK $driveCellClass] || [regexp CLK $loadCellClass]] $refCLKBufferCelltype $refBufferCelltype]
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 $rangeOfDriveCapacityForAdd 0 $refCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_6:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
#puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "bb:in_6:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $toChangeCelltype]
                lappend fixedList_1v1 [concat "bb:in_6:3" "TA_05" $toAddCelltype $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_1v1 [concat "bb:in_6:4" "A_05" $toAddCelltype $allInfoList]
                set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              }
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
            set toChangeCelltype [strategy_changeVT $driveCelltype $normalNeedVtWeightList $rangeOfVtSpeed $cellRegExp 1]
            if {$driveCapacity < 4 && $ifHaveLargerCapacity} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 $rangeOfDriveCapacityForChange $cellRegExp 1] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "bb:in_7:2" "DA_05" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -celltype $toChangeCelltype -inst $driveInstname]
                lappend fixedList_1v1 [concat "bb:in_7:3" "TA_05" $toAddCelltype $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_1v1 [concat "bb:in_7:4" "A_05" $toAddCelltype $allInfoList]
                set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              }
            }
          }
        }
      }


      ### loader is a logic cell, driver is a buffer(simple, upsize drive capacity, but consider previous cell drive range)
      ### loader is a buffer, and driver is a buffer too
      ### loader is a logic cell, and driver is a logic cell
      ### !!!CLK cell : need specific cell type buffer/inverter
      

      ## songNOTE:FIXED:U001 check all fixed celltype(changed). if it is smaller than X1 (such as X05), it must change to X1 or larger
      # ONLY check $toChangeCelltype, NOT check $toAddCelltype
puts "TEST: $toChangeCelltype"
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
        set fixedList_1v1 [lreplace $fixedList_1v1 end end [lreplace $fixedList_1v1 1 2 [append methodColumn "_" $checkedSymbol ] [regsub $preToChangeCell $celltypeToFix $toChangeCelltype]]]
      }
puts "TEST END: $cmd1\n   $checkedCmd"
      
      if {$cmd1 != "cantChange" && $cmd1 != ""} { ; # consider not-checked situation; like ip to ip, mem to mem, r2p
        lappend cmdList "# [lindex $fixedList_1v1 end]"
        if {[llength $cmd1] < 5} { ; # because shortest eco cmd need 5 items at least (ecoChangeCell -inst instname -cell celltype)
          set cmdList [concat $cmdList $cmd1]; #!!!
        } else {
          lappend cmdList $cmd1
        }
      } elseif {$cmd1 == ""} {
        lappend notConsideredList_1v1 [list "NC" $allInfoList]
      }
if {$debug} { puts "# -----------------" }
    }
##### END OF LOOP


    lappend cmdList " "
    lappend cmdList "setEcoMode -reset"

    # --------------------
    # summary of result
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
    # print to window
    ## file that can't extract cuz it is drivePin
    set ce [open $cantExtractFile w]
    pw $ce "CANT EXTRACT:"
    pw $ce ""
    if {[info exists cantExtractList]} { pw $ce [join $cantExtractList \n] }
    close $ce
    ## file of cmds 
    set co [open $cmdFile w]
    pw $co [join $cmdList \n]
    close $co
    ## file of summary
    set sf [open $sumFile w]
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
    pw $sf ""
    pw $sf "TWO SITUATIONS OF ALL VIOLATIONS:"
    pw $sf "1 v 1    number: [llength $violValue_driverPin_onylOneLoaderPin_D3List]"
    pw $sf "1 v more number: [llength $violValue_driver_severalLoader_D3List]"
    pw $sf ""
    pw $sf "ONE to MORE SITUATIONS"
    pw $sf [print_formatedTable $oneToMoreList]
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
    close $sf


    ## load several cells
    ### primarily focus on driver capacity and cell type, if have too many loaders, can fix fanout! (need notice some sticks)
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
    {-logicToBufferDistanceThreshold "sepcify threshold of min net length" AFloat float optional}
    {-refBufferCelltype "specify ref buffer cell type name" AString string optional}
    {-refInverterCelltype "specify ref inverter cell type name" AString string optional}
    {-refCLKBufferCelltype "specify ref clk buffer cell type name" AString string optional}
    {-refCLKInverterCelltype "specify ref clk inverter cell type name" AString string optional}
    {-cellRegExp "specify universal regExp for this process celltype, need pick out driveCapacity and VTtype" AString string optional}
    {-rangeOfVtSpeed "specify range of vt speed, it will be different from every process" AList list optional}
    {-clkNeedVtWeightList "specify vt weight list clock-needed" AList list optional}
    {-normalNeedVtWeightList "specify normal(std cell need) vt weight list" AList list optional}
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

proc get_driveCapacity_of_celltype {{celltype ""} {regExp "X(\\d+).*(A\[HRL\]\\d+)$"}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget top.insts.cell.name $celltype -e ] == ""} {
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
