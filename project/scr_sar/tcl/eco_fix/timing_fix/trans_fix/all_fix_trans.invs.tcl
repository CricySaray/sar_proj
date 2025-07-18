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
        set fixedList_1v1 [lreplace $fixedList_1v1 end end [lreplace [lindex $fixedList_1v1 end] 1 2 [append methodColumn "_" $checkedSymbol ] [regsub $preToChangeCell $celltypeToFix $toChangeCelltype]]]
puts "TEST FIXEDLIST large : [llength $fixedList_1v1]"
puts [lindex $fixedList_1v1 end]
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
  } elseif {[regexp {DEL} $celltype] && [get_property [get_cells $inst] is_buffer]} {
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
    return "0x0:1"; # check your input 
  } else {
    set runError0 [catch {regexp $regExp $refType wholeNameR levelNumR VTtypeR} errorInfoR]
    set runError1 [catch {regexp $regExp $driverCelltype wholeNameD levelNumD VTtypeD} errorInfoD]
    set runError2 [catch {regexp $regExp $loaderCelltype wholeNameL levelNumL VTtypeL} errorInfoL]
    if {$runError1 || $runError2} {
      return "0x0:2"; # check regexp expression 
    } else {
      # check driveRange correction
      if {[llength $driveRange] == 2 && [expr {"[dbget head.libCells.name [changeDriveCapacibility_of_celltype $refType $levelNumR [lindex $driveRange 0]] -e]" == "" || "[dbget head.libCells.name [changeDriveCapacibility_of_celltype $refType $levelNumR [lindex $driveRange 1]] -e]" == ""}]} {
        return "0x0:3"; # check your $driveRange , have no celltype in std cell library for min or max driveCapacity from driveRange 
      } elseif {[llength $driveRange] == 2} {
        set driveRangeRight [lsort -integer -increasing $driveRange] 
      }
      # if specify the value of drvie capacibility
      # force mode will ignore $driveRange
      if {$forceSpecifyDriveCapacibility} {
        set toCelltype [changeDriveCapacibility_of_celltype $refType $levelNumR $forceSpecifyDriveCapacibility]
        if {$toCelltype == "0x0:1"} {
          return "0x0:3"; # can't identify where the celltype is come from
        } elseif {[dbget head.libCells.name $toCelltype -e] == ""} {
          return "0x0:6"; # forceSpecifyDriveCapacibility: toCelltype is not acceptable celltype in std cell libray
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
          if {$toDriveNum == "0x0:1"} {
            return "0x0:4";  # can't identify where the celltype is come from
          } elseif {$toDriveNum <  [lindex $driveRangeRight 0]} {
            set toCelltype [changeDriveCapacibility_of_celltype $refType $levelNumR [lindex $driveRangeRight 0]]
            return $toCelltype 
          } elseif {$toDriveNum > [lindex $driveRangeRight 1]} {
            set toCelltype [changeDriveCapacibility_of_celltype $refType $levelNumR [lindex $driveRangeRight 1]]
            return $toCelltype 
          } else {
            set toCelltype [changeDriveCapacibility_of_celltype $refType $levelNumR $toDriveNum]
            return $toCelltype 
          }
        } 
        "refLoader" {
          if {$levelNumL == "05"} {set levelNumD 0.5}; # fix situation that it has 0.5 drive capacity at HH40 process/ M31 std cell library
          set toDriveNum [find_nearestNum_atIntegerList $availableDriveCapacityIntegerList $levelNumL $ifGetBigDriveNumInAvaialbeDriveCapacityList 1]
          if {$toDriveNum == "0x0:1"} {
            return "0x0:5";  # can't identify where the celltype is come from
          } elseif {$toDriveNum <  [lindex $driveRangeRight 0]} {
            set toCelltype [changeDriveCapacibility_of_celltype $refType $levelNumR [lindex $driveRangeRight 0]]
            return $toCelltype 
          } elseif {$toDriveNum > [lindex $driveRangeRight 1]} {
            set toCelltype [changeDriveCapacibility_of_celltype $refType $levelNumR [lindex $driveRangeRight 1]]
            return $toCelltype 
          } else {
            set toCelltype [changeDriveCapacibility_of_celltype $refType $levelNumR $toDriveNum]
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
proc changeDriveCapacibility_of_celltype {{refType "BUFD4BWP6T16P96CPD"} {originalDriveCapacibility 0} {toDriverCapacibility 0}} {
  set processType [whichProcess_fromStdCellPattern $refType]
  if {$processType == "TSMC"} { ; # TSMC
    regsub D${originalDriveCapacibility}BWP $refType D${toDriverCapacibility}BWP toCelltype
    return $toCelltype
  } elseif {$processType == "HH"} { ; # HH40 huahonghongli
    regsub X${originalDriveCapacibility} $refType X${toDriverCapacibility} toCelltype
    return $toCelltype
  } else {
    return "0x0:1"
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
    return "0x0:1"; # your number is not in the range of list
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
    return "0x0:1" 
  } else {
    #get now Drive Capacibility
    set runError [catch {regexp $regExp $celltype wholename driveLevel VTtype} errorInfo]
    if {$runError || $wholename == ""} {
      return "0x0:2" 
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
    return "0x0:1"; # your number is not in the range of list
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
  set newInstNamePrefix   "sar_fix_tran_070521"
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
            return "ecoAddRepeater -cell $celltype -term \{$terms\} -loc \{$loc\} -relativeDistToSink $relativeDistToSink" 
          } elseif {$relativeDistToSink != "" && $relativeDistToSink < 0 || $relativeDistToSink != "" && $relativeDistToSink > 1} {
            return "0x0:5"; # check $relativeDistToSink 
          } else {
            return "ecoAddRepeater -cell $celltype -term \{$terms\} -loc \{$loc\}" 
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

