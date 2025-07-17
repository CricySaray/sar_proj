#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/13 15:25:05 Sunday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : fix trans
# ref       : link url
# --------------------------
# API:
#set fi [open "$1" "r"]

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
#
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
  set file_viol_pin                     ""
  set violValue_pin_columnIndex         {4 1}
  set canChangeVT                       1
  set canChangeDriveCapacity            1
  set canChangeVTandDriveCapacity       1
  set canAddRepeater                    1
  set logicToBufferDistanceThreshold    10
  set refBufferCelltype                 "BUFX4AR9"
  set refInverterCelltype               "INVX4AR9"
  set refCLKBufferCelltype              "CLKBUFX4AL9"
  set refCLKInverterCelltype            "CLKINVX4AL9"
  set cellRegExp                        "X(\\d+).*(A\[HRL\]\\d+)$"
  set ecoNewInstNamePrefix              "sar_fix_trans_clk_071615"
  set suffixFilename                    ""; # for example : eco4
  set sumFile                           [eo $suffixFilename "sor_summary_of_result_$suffixFilename.list" "sor_summary_of_result.list" ]
  set cantExtractFile                   [eo $suffixFilename "sor_cantExtract_$suffixFilename.list" "sor_cantExtract.list"]
  set cmdFile                           [eo $suffixFilename "sor_commands_to_eco_$suffixFilename.tcl" "sor_commands_to_eco.tcl"]
  set debug                             0
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
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
    set oneToMoreList [lsort -index 0 -real -decreasing [lsort -unique -index 1 $oneToMoreList]]
    #set oneToMoreList [lreplace $oneToMoreList 0 0 [list violValue drivePin loadPin]]
    # ----------------------
    # info collections
    ## cant change info
    set cantChangePrompts {
      "# error/warning symbols"
      "# changeVT:"
      "## V - the celltype to changeVT is forbidden to use, like {AL9 0} which of weight:0 is forbidden to use"
      "## F - don't have faster VT to change, like celltype is LVT or ULVT, which is no faster VT than LVT or ULVT"
      "# changeDriveCapacity"
      "## O - out of acceptable drive capacity list. if you specify the range of useful drive capacity like {1 12}, toChangeCelltype capacity can't be out of it."
      "# addRepeaterCelltype"
      "## N - toAddCelltype is not acceptable celltype from std cell library"
      "# special situation:(need fix by your hand)"
      "## S - violation value is very huge but net length is short"
      "# special inst"
      "## M_D - drive inst is mem"
      "## M_S - sink inst is mem"
    }
    set cantChangeList_1v1 [list [list situ method violValue netLength driveCellClass driveCelltype driveViolPin loadCellClass sinkCelltype loadViolPin]]
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
      ""
      "# symbol of situations:"
      "## ll - logic to logic"
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
    set fixedList_1v1 [list [list situ method celltypeToFix violValue netLength driveCellClass driveCelltype driveViolPin loadCellClass sinkCelltype loadViolPin]]
    # skipped situation info
    set skippedSituationsPrompt {
      "# NF - have no faster vt" 
      "# NL - have no lager drive capacity"
      "# NFL - have no both faster vt and lager drive capacity"
    }
    set skippedList_1v1 [list [list ]]
    # ------
    # init LIST
    set cmdList $fixedPrompts
    lappend cmdList "setEcoMode -reset"
    lappend cmdList "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"
    lappend cmdList " "

    # ---------------------------------
    # begin deal with different situation
    ## only load one cell
    set i 0
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
      # some useful flag
      set ifHaveFasterVT [re [la [strategy_changeVT $driveCelltype {{AR9 3} {AL9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1] $driveCelltype]]
puts "if have faster vt: $ifHaveFasterVT"
      set ifHaveSlowerVT 0
      set ifHaveLargerCapacity [re [la [strategy_changeDriveCapacity $driveCelltype 0 3 {1 12} $cellRegExp 1] $driveCelltype]]
puts "if have larger capacity: $ifHaveLargerCapacity"
      set ifHaveSmallerCapacity 0
      # initialize some iterative vars
      set cmd1 ""
      set toChangeCelltype ""
      set toAddCelltype ""
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
      if {$driveCellClass == "mem"} {
        lappend cantChangeList_1v1 [concat "in_0" "M_D" $allInfoList]
        set cmd1 "cantChange"
      } elseif {$loadCellClass == "mem"} {
        lappend cantChangeList_1v1 [concat "in_0" "M_S" $allInfoList]
        set cmd1 "cantChange"
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
      } elseif {$driveCellClass in {logic} && $loadCellClass in {logic}} { ; # songNOTE: now dont split between different cell classes
if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "ll:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "ll:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "ll:in_1:3" "NL" $allInfoList] 
        }
        #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
        if {[lindex $viol_driverPin_loadPin 0] < -0.2 && $netLength < 20} { ; # songNOTE: special situation
          lappend cantChangeList_1v1 [concat "ll:in_1:1" "S" $allInfoList]
          set cmd1 "cantChange"
        } elseif {[lindex $viol_driverPin_loadPin 0] < -0.1 && $netLength < 10} { ; # songNOTE: special situation
          lappend cantChangeList_1v1 [concat "ll:in_1:2" "S" $allInfoList]
          set cmd1 "cantChange"
        } elseif {[lindex $viol_driverPin_loadPin 0] < -0.07 && $netLength < 8 } { ; # songNOTE: special situation: big violValue , short net length
          lappend cantChangeList_1v1 [concat "ll:in_1:3" "S" $allInfoList]
          set cmd1 "cantChange"
        } elseif {[lindex $viol_driverPin_loadPin 0] < -0.03 && $netLength < 4} { ; # songNOTE: special situation
          lappend cantChangeList_1v1 [concat "ll:in_1:4" "S" $allInfoList]
          set cmd1 "cantChange"
        } elseif {$ifHaveFasterVT && $canChangeVT && [lindex $viol_driverPin_loadPin 0] >= -0.015} { ; # songNOTE: situation 01 only changeVT,
          # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 1} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "ll:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.04 && $netLength <= [expr $logicToBufferDistanceThreshold * 1.5]} { ; # songNOTE: situation 02 only changeDriveCapacity
if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
#puts "in 2: $driveCelltype $toChangeCelltype"
if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity == 0.5} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 3 {1 12} $cellRegExp 1]
          } elseif {$driveCapacity in {1 2}} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 {1 12} $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 {1 12} $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "ll:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
          }
        } elseif {$ifHaveFasterVT && $ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.05 && $netLength <= [expr $logicToBufferDistanceThreshold * 2.2]} { ; # songNOTE: situation 03 change VT and DriveCapacity
if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 1} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 {1 12} $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 {1 12} $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "ll:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "ll:in_5:4" "T_D" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
            }
          }
        } elseif {$canAddRepeater && [lindex $viol_driverPin_loadPin 0] < -0.08  && [lindex $viol_driverPin_loadPin 0] >= -0.1 && $netLength < [expr $logicToBufferDistanceThreshold * 4] && $netLength > [expr $logicToBufferDistanceThreshold * 2]} { ; # songNOTE: situation 04 add Repeater near logic cell
if {$debug} { puts "in 4: add Repeater" }
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 {} 0 $refBufferCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_6:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
#puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
            if {$driveCapacity < 4} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 {1 12} $cellRegExp 1] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "ll:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -inst $toChangeCelltype -celltype $toChangeCelltype]
                lappend fixedList_1v1 [concat "ll:in_6:3" "TA_09" $toAddCelltype $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_1v1 [concat "ll:in_6:4" "A_09" $toAddCelltype $allInfoList]
                set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              }
            }
          }
        } else { ; # songNOTE: situation 05 not in above situation
if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
if {$debug} { puts "Not in above situation, so NOTICE" }
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 2 {2 12} 1 $refBufferCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "ll:in_7:1" "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
            if {$driveCapacity < 4} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 {1 12} $cellRegExp 1] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "ll:in_7:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
                lappend fixedList_1v1 [concat "ll:in_7:3" "TA_09" $toAddCelltype $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_1v1 [concat "ll:in_7:4" "A_09" $toAddCelltype $allInfoList]
                set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.9]
              }
            }
          }
        }
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
      } elseif {$driveCellClass in {buffer inverter} && $loadCellClass in {buffer inverter}} { ; # songNOTE: now dont split between different cell classes
if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "bb:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "bb:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "bb:in_1:3" "NL" $allInfoList] 
        }
        #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
        if {[lindex $viol_driverPin_loadPin 0] < -0.2 && $netLength < 20} { ; # songNOTE: special situation
          lappend cantChangeList_1v1 [concat "bb:in_1:1" "S" $allInfoList]
          set cmd1 "cantChange"
        } elseif {[lindex $viol_driverPin_loadPin 0] < -0.1 && $netLength < 10} { ; # songNOTE: special situation
          lappend cantChangeList_1v1 [concat "bb:in_1:2" "S" $allInfoList]
          set cmd1 "cantChange"
        } elseif {[lindex $viol_driverPin_loadPin 0] < -0.07 && $netLength < 8 } { ; # songNOTE: special situation: big violValue , short net length
          lappend cantChangeList_1v1 [concat "bb:in_1:3" "S" $allInfoList]
          set cmd1 "cantChange"
        } elseif {[lindex $viol_driverPin_loadPin 0] < -0.03 && $netLength < 4} { ; # songNOTE: special situation
          lappend cantChangeList_1v1 [concat "bb:in_1:4" "S" $allInfoList]
          set cmd1 "cantChange"
        } elseif {$ifHaveFasterVT && $canChangeVT && [lindex $viol_driverPin_loadPin 0] >= -0.015} { ; # songNOTE: situation 01 only changeVT,
          # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 1} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "bb:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.04 && $netLength <= [expr $logicToBufferDistanceThreshold * 1.5]} { ; # songNOTE: situation 02 only changeDriveCapacity
if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
#puts "in 2: $driveCelltype $toChangeCelltype"
if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity in {0.5 1 2}} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 {1 12} $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 {1 12} $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "bb:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
          }
        } elseif {$ifHaveFasterVT && $ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.07 && $netLength <= [expr $logicToBufferDistanceThreshold * 2.2]} { ; # songNOTE: situation 03 change VT and DriveCapacity
if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 1} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 {1 12} $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 {1 12} $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "bb:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "bb:in_5:4" "T_D" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
            }
          }
        } elseif {$canAddRepeater && [lindex $viol_driverPin_loadPin 0] < -0.08  && [lindex $viol_driverPin_loadPin 0] >= -0.1 && $netLength < [expr $logicToBufferDistanceThreshold * 4] && $netLength > [expr $logicToBufferDistanceThreshold * 2]} { ; # songNOTE: situation 04 add Repeater near logic cell
if {$debug} { puts "in 4: add Repeater" }
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 {} 0 $refBufferCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_6:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
#puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
            if {$driveCapacity < 4} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 {1 12} $cellRegExp 1] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "bb:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -inst $toChangeCelltype -celltype $toChangeCelltype]
                lappend fixedList_1v1 [concat "bb:in_6:3" "TA_09" $toAddCelltype $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_1v1 [concat "bb:in_6:4" "A_09" $toAddCelltype $allInfoList]
                set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              }
            }
          }
        } else { ; # songNOTE: situation 05 not in above situation
if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
if {$debug} { puts "Not in above situation, so NOTICE" }
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 {2 12} 1 $refBufferCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "bb:in_7:1" "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
            if {$driveCapacity < 4} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 {1 12} $cellRegExp 1] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "bb:in_7:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
                lappend fixedList_1v1 [concat "bb:in_7:3" "TA_09" $toAddCelltype $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_1v1 [concat "bb:in_7:4" "A_09" $toAddCelltype $allInfoList]
                set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              }
            }
          }
        }
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
      } elseif {$driveCellClass in {CLKcell buffer inverter} && $loadCellClass in {CLKcell} || $driveCellClass in {CLKcell} && $loadCellClass in {buffer inverter}} { ; # songNOTE: now dont split between different cell classes
if {$debug} { puts "$netLength $driveCelltype $sinkCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        if {!$ifHaveFasterVT && !$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "cc:in_1:1" "NFL" $allInfoList]
        } elseif {!$ifHaveFasterVT} {
          lappend skippedList_1v1 [concat "cc:in_1:2" "NF" $allInfoList]
        } elseif {!$ifHaveLargerCapacity} {
          lappend skippedList_1v1 [concat "cc:in_1:3" "NL" $allInfoList] 
        }
        #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
        if {[lindex $viol_driverPin_loadPin 0] < -0.2 && $netLength < 20} { ; # songNOTE: special situation
          lappend cantChangeList_1v1 [concat "cc:in_1:1" "S" $allInfoList]
          set cmd1 "cantChange"
        } elseif {[lindex $viol_driverPin_loadPin 0] < -0.1 && $netLength < 10} { ; # songNOTE: special situation
          lappend cantChangeList_1v1 [concat "cc:in_1:2" "S" $allInfoList]
          set cmd1 "cantChange"
        } elseif {[lindex $viol_driverPin_loadPin 0] < -0.07 && $netLength < 8 } { ; # songNOTE: special situation: big violValue , short net length
          lappend cantChangeList_1v1 [concat "cc:in_1:3" "S" $allInfoList]
          set cmd1 "cantChange"
        } elseif {[lindex $viol_driverPin_loadPin 0] < -0.03 && $netLength < 4} { ; # songNOTE: special situation
          lappend cantChangeList_1v1 [concat "cc:in_1:4" "S" $allInfoList]
          set cmd1 "cantChange"
        } elseif {$ifHaveFasterVT && $canChangeVT && [lindex $viol_driverPin_loadPin 0] >= -0.015} { ; # songNOTE: situation 01 only changeVT,
          # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 1} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "cc:in_2:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "cc:in_2:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "cc:in_2:3" "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
          }
        } elseif {$ifHaveLargerCapacity && $canChangeDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.04 && $netLength <= [expr $logicToBufferDistanceThreshold * 1.5]} { ; # songNOTE: situation 02 only changeDriveCapacity
if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
#puts "in 2: $driveCelltype $toChangeCelltype"
if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity in {0.5 1 2}} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 {1 12} $cellRegExp 1]
          } elseif {$driveCapacity >= 3} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 {1 12} $cellRegExp 1]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "cc:in_4:1" "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "cc:in_4:2" "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
          }
        } elseif {$ifHaveFasterVT && $ifHaveLargerCapacity && $canChangeVTandDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.07 && $netLength <= [expr $logicToBufferDistanceThreshold * 2.2]} { ; # songNOTE: situation 03 change VT and DriveCapacity
if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 1} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "cc:in_5:1" "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "cc:in_5:2" "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 {1 12} $cellRegExp 1]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 {1 12} $cellRegExp 1]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "cc:in_5:3" "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "cc:in_5:4" "T_D" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
            }
          }
        } elseif {$canAddRepeater && [lindex $viol_driverPin_loadPin 0] < -0.08  && [lindex $viol_driverPin_loadPin 0] >= -0.1 && $netLength < [expr $logicToBufferDistanceThreshold * 4] && $netLength > [expr $logicToBufferDistanceThreshold * 2]} { ; # songNOTE: situation 04 add Repeater near logic cell
if {$debug} { puts "in 4: add Repeater" }
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 4 {} 0 $refCLKBufferCelltype $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "cc:in_6:1" "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
#puts  "in 4: $driveCelltype --  $toChangeCelltype song"
            set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
            if {$driveCapacity < 4} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 {1 12} $cellRegExp 1] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "cc:in_6:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -inst $toChangeCelltype -celltype $toChangeCelltype]
                lappend fixedList_1v1 [concat "cc:in_6:3" "TA_09" $toAddCelltype $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_1v1 [concat "cc:in_6:4" "A_09" $toAddCelltype $allInfoList]
                set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              }
            }
          }
        } else { ; # songNOTE: situation 05 not in above situation
if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
if {$debug} { puts "Not in above situation, so NOTICE" }
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $sinkCelltype "" 3 {2 12} 1 $refCLKBufferCelltype $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "cc:in_7:1" "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
            if {$driveCapacity < 4} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 {1 12} $cellRegExp 1] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
              set cmd_DA_driveInst [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]; # pre fix: first, change driveInst DriveCapacity, second add repeater
              lappend fixedList_1v1 [concat "cc:in_7:2" "DA_09" ${toChangeCelltype}_$toAddCelltype $allInfoList]
              set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
              set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
            } else {
              if {$ifHaveFasterVT} {
                set cmd_TA_driveInst [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
                lappend fixedList_1v1 [concat "cc:in_7:3" "TA_09" $toAddCelltype $allInfoList]
                set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix ${ecoNewInstNamePrefix}_[ci add] -relativeDistToSink 0.5]
                set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
              } else {
                lappend fixedList_1v1 [concat "cc:in_7:4" "A_09" $toAddCelltype $allInfoList]
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
      if {$cmd1 != "cantChange"} { 
        lappend cmdList "# [lindex $fixedList_1v1 end]"; 
        if {[llength $cmd1] == 2} {
          set cmdList [concat $cmdList $cmd1]
        } else {
          lappend cmdList $cmd1 
        }
      }
if {$debug} { puts "# -----------------" }
    }
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
    pw $sf [print_formatedTable $oneToMoreList]
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
    {-ecoNewInstNamePrefix "specify a new name for inst when adding new repeater"}
    {-suffixFilename "specify suffix of result filename" AString string optional}
    {-sumFile "specify summary filename" AString string optional}
    {-cantExtractFile "specify cantExtract file name" AString string optional}
    {-cmdFile "specify cmd file name" AString string optional}
    {-debug "debug mode" "" boolean optional}
  }

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
