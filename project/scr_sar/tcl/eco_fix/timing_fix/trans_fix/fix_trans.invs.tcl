#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/13 15:25:05 Sunday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : what?
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
source -v ./proc_get_net_lenth.invs.tcl; # get_net_length - num
source -v ./proc_if_driver_or_load.invs.tcl; # if_driver_or_load - 1: driver  0: load
source -v ./proc_get_fanoutNum_and_inputTermsName_of_pin.invs.tcl; # get_fanoutNum_and_inputTermsName_of_pin - return list [num termsNameList] || get_driverPin - return drivePin
source -v ./proc_get_cellDriveLevel_and_VTtype_of_inst.invs.tcl; # get_cellDriveLevel_and_VTtype_of_inst - return [instname cellName driveLevel VTtype]
source -v ./proc_get_cell_class.invs.tcl; # get_cell_class - return logic|buffer|inverter|CLKcell|sequential|gating|other
source -v ./proc_strategy_changeVT.invs.tcl; # strategy_changeVT - return VT-changed cellname
source -v ./proc_strategy_addRepeaterCelltype.invs.tcl; # strategy_addRepeaterCelltype - return toAddCelltype
source -v ./proc_strategy_changeDriveCapacity_of_driveCell.invs.tcl; # strategy_changeDriveCapacity - return toChangeCelltype
source -v ./proc_print_ecoCommands.invs.tcl; # print_ecoCommand - return command string (only one command)
source -v ./proc_print_formatedTable.common.tcl; # print_formatedTable D2 list - return 0, puts formated table
source -v ./proc_pw_puts_message_to_file_and_window.common.tcl; # pw - advanced puts

# The principle of minimum information
proc fix_trans {{viol_pin_file ""} {violValue_pin_columnIndex {4 1}} {canChangeVT 1} {canChangeDriveCapacity 1} {canChangeVTandDriveCapacity 1} {canAddRepeater 1} {ecoName "test_econame"} {logicToBufferDistanceThreshold 10} {cellRegExp "X(\\d+).*(A\[HRL\]\\d+)$"} {newInstNamePrefix "sar_fix_trans_clk_070716"} {sumFile "sor_summary_of_result.list"} {cantExtractFile "sor_cantExtract.list"} {cmdFile "sor_commands_to_eco.tcl"} {debug 0}} {
  # songNOTE: only deal with loadPin viol situation, ignore drivePin viol situation
  # $violValue_pin_columnIndex  : for example : {3 1}
  #   violPin   xxx   violValue   xxx   xxx
  #   you can specify column of violValue and violPin
  if {$viol_pin_file == "" || [glob -nocomplain $viol_pin_file] == ""} {
    return "0x0:1"; # check your file 
  } else {
    set fi [open $viol_pin_file r]
    set violValue_driverPin_onylOneLoaderPin_D3List [list ]; # one to one
    set violValue_driver_severalLoader_D3List [list ]; # one to more
    set oneToMoreList [list [list violValue drivePin loadPin]]
    # ------------------------------------
    # sort two class for all viol situations
    set i 0
    while {[gets $fi line] > -1} {
      incr i
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
        }
      } else {
        lappend cantExtractList "(Line $i) drivePin - not extract! : $line"
      }
    }
    close $fi
    # report some info of two D3 List
    set violValue_driverPin_onylOneLoaderPin_D3List [lsort -index 0 -real -decreasing $violValue_driverPin_onylOneLoaderPin_D3List]
    set violValue_driverPin_onylOneLoaderPin_D3List [lsort -index 0 -real -decreasing [lsort -unique -index 1 $violValue_driverPin_onylOneLoaderPin_D3List]]
    set violValue_driver_severalLoader_D3List [lsort -index 0 -real -decreasing $violValue_driver_severalLoader_D3List]
    set violValue_driver_severalLoader_D3List [lsort -index 0 -real -decreasing [lsort -unique -index 1 $violValue_driver_severalLoader_D3List]]
if {$debug} { puts [join $violValue_driverPin_onylOneLoaderPin_D3List \n] }
    # -----------------------
    # sort and check D3List correction : $violValue_driverPin_onylOneLoaderPin_D3List and $violValue_driver_severalLoader_D3List
    
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
    }
    set cantChangeList_1v1 [list [list sym violValue netLength driveCellClass driveCelltype driveViolPin loadCellClass loadCelltype loadViolPin]]
    ## changed info
    set fixedPrompts {
      "# symbols of methods for changed cell"
      "# changeVT:"
      "## T - changedVT, below is toChangeCelltype"
      "# changeDriveCapacity"
      "## D - changedDriveCapacity, below is toChangeCelltype"
      "# addRepeaterCell"
      "## A_0.9 - near the driver - addedRepeaterCell, below is toAddCelltype"
      "## A_0.5 - in the middle of driver and sink - addedRepeaterCell, below is toAddCelltype"
      "## A_0.1 - near the sink   - addedRepeaterCell, below is toAddCelltype"
    }
    set fixedList_1v1 [list [list sym celltypeToFix violValue netLength driveCellClass driveCelltype driveViolPin loadCellClass loadCelltype loadViolPin]]
    # ------
    set cmdList $fixedPrompts
    lappend cmdList "setEcoMode -reset"
    lappend cmdList "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"
    lappend cmdList " "

    # ---------------------------------
    # begin deal with different situation
    ## only load one cell
    foreach viol_driverPin_loadPin $violValue_driverPin_onylOneLoaderPin_D3List {; # violValue: ns
      ### 1 loader is a buffer, but driver is a logic cell
if {$debug} { puts "drive: [get_cell_class [lindex $viol_driverPin_loadPin 1]] load: [get_cell_class [lindex $viol_driverPin_loadPin 2]]" }
      set driveCellClass [get_cell_class [lindex $viol_driverPin_loadPin 1]]
      set loadCellClass  [get_cell_class [lindex $viol_driverPin_loadPin 2]]
      if {$driveCellClass != "" && $loadCellClass != ""} { ; # songNOTE: now dont split between different cell classes
        set netName [get_object_name [get_nets -of_objects [lindex $viol_driverPin_loadPin 1]]]
        set netLength [get_net_length $netName] ; # net length: um
        set driveInstname [dbget [dbget top.insts.instTerms.name [lindex $viol_driverPin_loadPin 1] -p2].name]
        set driveInstname_celltype_driveLevel_VTtype [get_cellDriveLevel_and_VTtype_of_inst $driveInstname $cellRegExp]
        set driveCelltype [lindex $driveInstname_celltype_driveLevel_VTtype 1]
        set driveCapacity [lindex $driveInstname_celltype_driveLevel_VTtype 2]
        set loadCelltype [dbget [dbget top.insts.name [get_object_name [get_cells -quiet -of_objects  [lindex $viol_driverPin_loadPin 2]]] -p].cell.name]
        set loadCapacity [get_driveCapacity_of_celltype $loadCelltype $cellRegExp]
        set allInfoList [concat [lindex $viol_driverPin_loadPin 0] $netLength \
                                $driveCellClass $driveCelltype [lindex $viol_driverPin_loadPin 1] \
                                $loadCellClass $loadCelltype [lindex $viol_driverPin_loadPin 2] ]
if {$debug} { puts "$netLength $driveCelltype $loadCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
        set cmd1 ""
        set toChangeCelltype ""
        set toAddCelltype ""
        if {$canChangeVT && [lindex $viol_driverPin_loadPin 0] >= -0.009} { ; # songNOTE: situation 01 only changeVT,
          # TODO: this situation need judge if the celltype has been fastest VT. if it has, you need consider other methods
if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 1} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
          }
        } elseif {$canChangeDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.04 && $netLength <= $logicToBufferDistanceThreshold} { ; # songNOTE: situation 02 only changeDriveCapacity
if {$debug} { puts "in 2: only change DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
puts "in 2: $driveCelltype $toChangeCelltype"
if {$debug} { puts $toChangeCelltype }
          if {$driveCapacity == 0.5} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 3 {1 12} $cellRegExp]
          } elseif {$driveCapacity == 1} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 {1 12} $cellRegExp]
          } elseif {$driveCapacity >= 2} {
            set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 {1 12} $cellRegExp]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
          }
        } elseif {$canChangeVTandDriveCapacity && [lindex $viol_driverPin_loadPin 0] >= -0.06 && $netLength <= [expr $logicToBufferDistanceThreshold + 5]} { ; # songNOTE: situation 03 change VT and DriveCapacity
if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 1} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 2 {1 12} $cellRegExp]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 0 1 {1 12} $cellRegExp]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "T_D" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
            }
          }
        } elseif {$canAddRepeater && [lindex $viol_driverPin_loadPin 0] >= -0.1 && $netLength < [expr $logicToBufferDistanceThreshold * 4]} { ; # songNOTE: situation 04 add Repeater near logic cell
if {$debug} { puts "in 4: add Repeater" }
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $loadCelltype "" 3 {} 0 "BUFX4AR9" $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "N_forceDrive" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCellClass == "logic"} {
              set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
puts  "in 4: $driveCelltype --  $toChangeCelltype song"
              if {$driveCapacity < 4} {
                set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 4 0 {1 12} $cellRegExp] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
                set cmd_DA_driveInst [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_1v1 [concat "DA_0.9" ${toChangeCelltype}_$toAddCelltype $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix $newInstNamePrefix -relativeDistToSink 0.9]
                set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                if {$toChangeCelltype == $driveCelltype} {
                  lappend fixedList_1v1 [concat "A_0.9" $toAddCelltype $allInfoList]
                  set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix $newInstNamePrefix -relativeDistToSink 0.9]
                } else {
                  set cmd_TA_driveInst [print_ecoCommand -type change -inst $toChangeCelltype -celltype $toChangeCelltype]
                  lappend fixedList_1v1 [concat "TA_0.9" $toAddCelltype $allInfoList]
                  set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix $newInstNamePrefix -relativeDistToSink 0.9]
                  set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
                }
              }
            } elseif {$driveCellClass == "buffer" || $driveCellClass == "inverter"} {
              set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
puts  "in 4: $driveCelltype --  $toChangeCelltype song"
              if {$driveCapacity < 3} {
                set toChangeCelltype [strategy_changeDriveCapacity $driveCelltype 3 0 {1 12} $cellRegExp] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
                set cmd_DA_driveInst [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_1v1 [concat "DA_0.5" ${toChangeCelltype}_$toAddCelltype $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix $newInstNamePrefix -relativeDistToSink 0.5]
                set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                if {$toChangeCelltype == $driveCelltype} {
                  lappend fixedList_1v1 [concat "A_0.5" $toAddCelltype $allInfoList]
                  set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix $newInstNamePrefix -relativeDistToSink 0.5]
                } else {
                  set cmd_TA_driveInst [print_ecoCommand -type change -inst $toChangeCelltype -celltype $toChangeCelltype]
                  lappend fixedList_1v1 [concat "TA_0.5" $toAddCelltype $allInfoList]
                  set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix $newInstNamePrefix -relativeDistToSink 0.5]
                  set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
                }
              }
            }
          }
        } else { ; # songNOTE: situation 05 not in above situation
if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
if {$debug} { puts "Not in above situation, so NOTICE" }
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $loadCelltype "refDriver" 0 {4 12} 1 "BUFX4AR9" $cellRegExp ]; # have a lot of situation, logic/buffer/inverter
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCellClass == "logic"} {
              set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
              if {$driveCapacity < 4} {
                set toChangeCelltype [strategy_changeDriveCapacity $driveCelltype 4 0 {1 12} $cellRegExp] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
                set cmd_DA_driveInst [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_1v1 [concat "DA_0.9" ${toChangeCelltype}_$toAddCelltype $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix $newInstNamePrefix -relativeDistToSink 0.9]
                set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                if {$toChangeCelltype == $driveCelltype} {
                  lappend fixedList_1v1 [concat "A_0.9" $toAddCelltype $allInfoList]
                  set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix $newInstNamePrefix -relativeDistToSink 0.9]
                } else {
                  set cmd_TA_driveInst [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
                  lappend fixedList_1v1 [concat "TA_0.9" $toAddCelltype $allInfoList]
                  set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix $newInstNamePrefix -relativeDistToSink 0.9]
                  set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
                }
              }
            } elseif {$driveCellClass == "buffer" || $driveCellClass == "inverter"} {
              set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 0} {AH9 0}} {AL9 AR9 AH9} $cellRegExp 1]
              if {$driveCapacity < 3} {
                set toChangeCelltype [strategy_changeDriveCapacity $driveCelltype 3 0 {1 12} $cellRegExp] 
if {$debug} {puts "$driveCelltype - $toChangeCelltype"}
                set cmd_DA_driveInst [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]; # pre fix: first, change driveInst DriveCapacity, second add repeater
                lappend fixedList_1v1 [concat "DA_0.5" ${toChangeCelltype}_$toAddCelltype $allInfoList]
                set cmd_DA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix $newInstNamePrefix -relativeDistToSink 0.5]
                set cmd1 [list $cmd_DA_driveInst $cmd_DA_add]
              } else {
                if {$toChangeCelltype == $driveCelltype} {
                  lappend fixedList_1v1 [concat "A_0.5" $toAddCelltype $allInfoList]
                  set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix $newInstNamePrefix -relativeDistToSink 0.5]
                } else {
                  set cmd_TA_driveInst [print_ecoCommand -type change -inst $driveInstname -celltype $toChangeCelltype]
                  lappend fixedList_1v1 [concat "TA_0.5" $toAddCelltype $allInfoList]
                  set cmd_TA_add [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix $newInstNamePrefix -relativeDistToSink 0.5]
                  set cmd1 [concat $cmd_TA_driveInst $cmd_TA_add]
                }
              }
            }
          }
        }
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
      ### loader is a logic cell, driver is a buffer(simple, upsize drive capacity, but consider previous cell drive range)
      ### loader is a buffer, and driver is a buffer too
      ### loader is a logic cell, and driver is a logic cell
      ### !!!CLK cell : need specific cell type buffer/inverter
    }
    lappend cmdList " "
    lappend cmdList "setEcoMode -reset"

    # --------------------
    # summary of result
    set fixedMethodSortNumber [lmap item $fixedList_1v1 {
      set symbol [lindex $item 0]
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
    pw $ce [join $cantExtractList \n]
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
    pw $sf "sym   num"
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

proc get_driveCapacity_of_celltype {{celltype ""} {regExp "X(\\d+).*(A\[HRL\]\\d+)$"}} {
  if {$celltype == "" || $celltype == "0x0" || [dbget top.insts.cell.name $celltype -e ] == ""} {
    return "0x0:1"; # check your input 
  } else {
    regexp $regExp $celltype wholename driveLevel VTtype 
    if {$driveLevel == "05"} {set driveLevel 0.5}
    return $driveLevel
  }
}
