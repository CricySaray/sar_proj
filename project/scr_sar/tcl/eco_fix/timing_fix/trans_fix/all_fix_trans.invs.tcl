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
# return time
#
# fix long net:
#   get drive net len in PT:看看一个buf驱动和他同级的buffer时，不违例的net len最长长度，这个需要大量测试，每个项目都不一样。（脚本处理） tcl在pt里面获取海量原始数据，然后perl来处理和统计。为了给fix long net和fix trans脚本提供判断依据。
#     buf/inv cell | drive net len
# --------
# 01 get info of viol cell: pin cellname celltype driveNum netlength

# The principle of minimum information
proc fix_trans {{viol_pin_file ""} {violValue_pin_columnIndex {4 1}} {canChangeVT 1} {canChangeDriveCapacity 1} {canChangeVTandDriveCapacity 1} {canAddRepeater 1} {ecoName "test_econame"} {logicToBufferDistanceThreshold 10} {cellRegExp "X(\\d+).*(A\[HRL\]\\d+)$"} {newInstNamePrefix "sar_fix_trans_clk_070716"} {sumFile "sor_summary_of_result.list"} {cantExtractFile "sor_cantExtract.list"} {cmdFile "sor_commands_to_eco.tcl"} {debug 0}} {
  # $violValue_pin_columnIndex  : for example : {3 1}
  #   violPin   xxx   violValue   xxx   xxx
  #   you can specify column of violValue and violPin
  if {$viol_pin_file == "" || [glob -nocomplain $viol_pin_file] == ""} {
    return "0x0:1"; # check your file 
  } else {
    set fi [open $viol_pin_file r]
    set violValue_driverPin_onylOneLoaderPin_D3List [list ]; # one to one
    set violValue_driver_severalLoader_D3List [list ]; # one to more
    # ------
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
        }
      } else {
        lappend cantExtractList "(Line $i) drivePin - not extract! : $line"
      }
    }
    close $fi
    # report some info of two D3 List
    set violValue_driverPin_onylOneLoaderPin_D3List [lsort -index 0 -real -decreasing $violValue_driverPin_onylOneLoaderPin_D3List]
    set violValue_driverPin_onylOneLoaderPin_D3List [lsort -unique -index 1 $violValue_driverPin_onylOneLoaderPin_D3List]
    set violValue_driver_severalLoader_D3List [lsort -index 0 -real -decreasing $violValue_driver_severalLoader_D3List]
    set violValue_driver_severalLoader_D3List [lsort -unique -index 1 $violValue_driver_severalLoader_D3List]
if {$debug} { puts [join $violValue_driverPin_onylOneLoaderPin_D3List \n] }
    # ------
    # sort and check D3List correction : $violValue_driverPin_onylOneLoaderPin_D3List and $violValue_driver_severalLoader_D3List
    
    # ------
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
      "## A - addedRepeaterCell, below is toAddCelltype"
    }
    set fixedList_1v1 [list [list sym celltypeToFix violValue netLength driveCellClass driveCelltype driveViolPin loadCellClass loadCelltype loadViolPin]]
    # ------
    set cmdList $fixedPrompts
    lappend cmdList "setEcoMode -reset"
    lappend cmdList "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"
    lappend cmdList " "

    # begin deal with different situation
    ## only load one cell
    foreach viol_driverPin_loadPin $violValue_driverPin_onylOneLoaderPin_D3List {; # violValue: ns
      ### 1 loader is a buffer, but driver is a logic cell
if {$debug} { puts "drive: [get_cell_class [lindex $viol_driverPin_loadPin 1]] load: [get_cell_class [lindex $viol_driverPin_loadPin 2]]" }
      set driveCellClass [get_cell_class [lindex $viol_driverPin_loadPin 1]]
      set loadCellClass  [get_cell_class [lindex $viol_driverPin_loadPin 2]]
      if {$driveCellClass != "" && $loadCellClass != ""} {
        set netName [get_object_name [get_nets -of_objects [lindex $viol_driverPin_loadPin 1]]]
        set netLength [get_net_length $netName] ; # net length: um
        set instname [dbget [dbget top.insts.instTerms.name [lindex $viol_driverPin_loadPin 1] -p2].name]
        set inst_celltype_driveLevel_VTtype [get_cellDriveLevel_and_VTtype_of_inst $instname $cellRegExp]
        set driveCelltype [lindex $inst_celltype_driveLevel_VTtype 1]
        set driveCapacity [lindex $inst_celltype_driveLevel_VTtype 2]
        set loadCelltype [dbget [dbget top.insts.name [get_object_name [get_cells -quiet -of_objects  [lindex $viol_driverPin_loadPin 2]]] -p].cell.name]
        set allInfoList [concat [lindex $viol_driverPin_loadPin 0] $netLength \
                                $driveCellClass $driveCelltype [lindex $viol_driverPin_loadPin 1] \
                                $loadCellClass $loadCelltype [lindex $viol_driverPin_loadPin 2] ]
if {$debug} { puts "$netLength $driveCelltype $loadCelltype [lindex $viol_driverPin_loadPin 1] [lindex $viol_driverPin_loadPin 2]" }
        #### onlyChangeVT / changeVTandSizeupDriveCapacity / onlySizeupDriveCapacity
        set cmd1 ""
        set toChangeCelltype ""
        set toAddCelltype ""
        if {$canChangeVT && [lindex $viol_driverPin_loadPin 0] >= -0.009} { ; # only changeVT,
if {$debug} { puts "in 1: only change VT" }
          set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 1} {AH9 0}} {AL9 AR9 AH9} $cellRegExp]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "T" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -inst $instname -celltype $toChangeCelltype]
          }
        } elseif {$canChangeDriveCapacity && $netLength <= $logicToBufferDistanceThreshold} { ; #only changeDriveCapacity
if {$debug} { puts "in 2: only change DriveCapacity" }
          if {$driveCapacity == 0.5} {
            set toChangeCelltype [strategy_changeDriveCapacity $driveCelltype 3 {1 12} $cellRegExp]
          } elseif {$driveCapacity == 1} {
            set toChangeCelltype [strategy_changeDriveCapacity $driveCelltype 2 {1 12} $cellRegExp]
          } elseif {$driveCapacity >= 2} {
            set toChangeCelltype [strategy_changeDriveCapacity $driveCelltype 1 {1 12} $cellRegExp]
          }
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "O" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "D" $toChangeCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type change -inst $instname -celltype $toChangeCelltype]
          }
        } elseif {$canChangeVTandDriveCapacity && $netLength <= [expr $logicToBufferDistanceThreshold + 5]} { ; # change VT and DriveCapacity
if {$debug} { puts "in 3: change VT and DriveCapacity" }
          set toChangeCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 1} {AH9 0}} {AL9 AR9 AH9} $cellRegExp]
          if {[regexp -- {0x0:3} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "V" $allInfoList]
            set cmd1 "cantChange"
          } elseif {[regexp -- {0x0:4} $toChangeCelltype]} {
            lappend cantChangeList_1v1 [concat "F" $allInfoList]
            set cmd1 "cantChange"
          } else {
            if {$driveCapacity <= 1} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 2 {1 12} $cellRegExp]
            } elseif {$driveCapacity >= 2} {
              set toChangeCelltype [strategy_changeDriveCapacity $toChangeCelltype 1 {1 12} $cellRegExp]
            }
            if {[regexp -- {0x0:3} $toChangeCelltype]} {
              lappend cantChangeList_1v1 [concat "O" $allInfoList]
              set cmd1 "cantChange"
            } else {
              lappend fixedList_1v1 [concat "T_D" $toChangeCelltype $allInfoList]
              set cmd1 [print_ecoCommand -type change -inst $instname -celltype $toChangeCelltype]
            }
          }
        } elseif {$canAddRepeater && $netLength < [expr $logicToBufferDistanceThreshold + 5]} { ; # add Repeater near logic cell
if {$debug} { puts "in 4: add Repeater" }
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $loadCelltype "" 3 "BUFX4AR9" $cellRegExp] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacity and VTtype)
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "A" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix $newInstNamePrefix -relativeDistToSink 0.9]
          }
        } else { ; # not in above situation
if {$debug} { puts "in 5: add Repeater refDriver, uncertainly, conservative" }
if {$debug} { puts "Not in above situation, so NOTICE" }
          set toAddCelltype [strategy_addRepeaterCelltype $driveCelltype $loadCelltype "refDriver" 0 "BUFX4AR9" $cellRegExp ]
          if {[regexp -- {0x0:6|0x0:7|0x0:8} $toAddCelltype]} {
            lappend cantChangeList_1v1 [concat "N" $allInfoList]
            set cmd1 "cantChange"
          } else {
            lappend fixedList_1v1 [concat "A" $toAddCelltype $allInfoList]
            set cmd1 [print_ecoCommand -type add -celltype $toAddCelltype -terms [lindex $viol_driverPin_loadPin 1] -newInstNamePrefix $newInstNamePrefix -relativeDistToSink 0.9]
          }
        }
        if {$cmd1 != "cantChange"} { lappend cmdList "# [lindex $fixedList_1v1 end]"; lappend cmdList $cmd1 }
if {$debug} { puts "# -----------------" }
      }
      ### loader is a logic cell, driver is a buffer(simple, upsize drive capacity, but consider previous cell drive range)
      ### loader is a buffer, and driver is a buffer too
      ### loader is a logic cell, and driver is a logic cell
      ### !!!CLK cell : need specific cell type buffer/inverter
    }
    lappend cmdList " "
    lappend cmdList "setEcoMode -reset"

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
    close $sf


    ## load several cells
    ### primarily focus on driver capacity and cell type, if have too many loaders, can fix fanout! (need notice some sticks)
  }
}
# puts message to file and print to window
proc pw {{fileId ""} {message ""}} {
  puts $message
  puts $fileId $message
}
# source -v ./proc_get_net_lenth.invs.tcl; # get_net_length - num
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, focusing on data display and aesthetics
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

# source -v ./proc_if_driver_or_load.invs.tcl; # if_driver_or_load - 1: driver  0: load
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, focusing on data display and aesthetics
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

# source -v ./proc_get_fanoutNum_and_inputTermsName_of_pin.invs.tcl; # get_fanoutNum_and_inputTermsName_of_pin - return list [num termsNameList] || get_driverPin - return drivePin
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, focusing on data display and aesthetics
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

# source -v ./proc_get_cellDriveLevel_and_VTtype_of_inst.invs.tcl; # get_cellDriveLevel_and_VTtype_of_inst - return [instName cellName driveLevel VTtype]
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:20:11 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, focusing on data display and aesthetics
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

# source -v ./proc_get_cell_class.invs.tcl; # get_cell_class - return logic|buffer|inverter|CLKcell|sequential|gating|other
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Sun Jul  6 00:41:35 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|task_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
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
  if {[get_property [get_cells $inst] is_sequential]} {
    return "sequential"
  } elseif {[regexp {CLK} [dbget [dbget top.insts.name $inst -p].cell.name]]} {
    return "CLKcell" 
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

# source -v ./proc_strategy_changeVT.invs.tcl; # strategy_changeVT - return VT-changed cellname
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, focusing on data display and aesthetics
# descrip   : strategy of fixing transition: change VT type of a cell. you can specify the weight of every VT type and speed index of VT. weight:0 will be forbidden to use
# ref       : link url
# --------------------------
proc strategy_changeVT {{celltype ""} {weight {{SVT 3} {LVT 1} {ULVT 0}}} {speed {ULVT LVT SVT}} {regExp "D(\\d+).*CPD(U?L?H?VT)?"}} {
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
      if {$VTtype == ""} {set VTtype "SVT"} 
      set avaiableVT [lsearch -all -inline -index 1 -regexp $weight "\[1-9\]"]; # remove weight:0 VT
      # user-defined avaiable VT type
      set avaiableVTsorted [lsort -index 1 -integer -decreasing $avaiableVT]
      set nowVTindex [lsearch -all -index 0 $avaiableVTsorted $VTtype]
      if {$nowVTindex == ""} {
        return "0x0:3"; # cell type can't be allowed to use, don't change VT type
      } else {
        # get changeable VT type according to provided cell type 
        set changeableVT [lsearch -exact -index 0 -all -inline -not $avaiableVTsorted $VTtype]
        #puts $changeableVT
        # judge if changeable VT types have faster type than nowVTtype of provided cell type
        set nowSpeedIndex [lsearch -exact $speed $VTtype]
        set moreFastVTinSpeed [lreplace $speed $nowSpeedIndex end]
        set useVT ""
        foreach vt $changeableVT {
          if {[lsearch -exact $moreFastVTinSpeed [lindex $vt 0]] > -1} {
            set useVT "[lindex $vt 0]"
            break
          }
        }
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
      }
    }
  }
}

# source -v ./proc_strategy_addRepeaterCelltype.invs.tcl; # strategy_addRepeaterCelltype - return toAddCelltype
proc strategy_addRepeaterCelltype {{driverCelltype ""} {loaderCelltype ""} {method "refDriver|refLoader|auto"} {forceSpecifyDriveCapacibility 4} {refType "BUFD4BWP6T16P96CPD"} {regExp "D(\\d+).*CPD(U?L?H?VT)?"}} {
  if {$driverCelltype == "" || $loaderCelltype == "" || [dbget top.insts.cell.name $driverCelltype -e] == "" || [dbget top.insts.cell.name $loaderCelltype -e] == ""} {
    return "0x0:1"; # check your input 
  } else {
    set runError0 [catch {regexp $regExp $refType wholeNameR levelNumR VTtypeR} errorInfoR]
    set runError1 [catch {regexp $regExp $driverCelltype wholeNameD levelNumD VTtypeD} errorInfoD]
    set runError2 [catch {regexp $regExp $loaderCelltype wholeNameL levelNumL VTtypeL} errorInfoL]
    if {$runError1 || $runError2} {
      return "0x0:2"; # check regexp expression 
    } else {
      # if specify the value of drvie capacibility
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
      switch $method {
        "refDriver" {
          set toCelltype [changeDriveCapacibility_of_celltype $refType $levelNumR $levelNumD]
          if {$toCelltype == "0x0:1"} {
            return "0x0:4";  # can't identify where the celltype is come from
          } elseif {[dbget head.libCells.name $toCelltype -e] == ""} {
            return "0x0:7"; # refDriver: toCelltype is not acceptable celltype in std cell libray
          } else {
            return $toCelltype 
          }
        } 
        "refLoader" {
          set toCelltype [changeDriveCapacibility_of_celltype $refType $levelNumR $levelNumL] 
          if {$toCelltype == "0x0:1"} {
            return "0x0:5"; # can't identify where the celltype is come from
          } elseif {[dbget head.libCells.name $toCelltype -e] == ""} {
            return "0x0:8"; # refLoader: toCelltype is not acceptable celltype in std cell libray
          } else {
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
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> gui_proc   : for gui display, or effort can be viewed in invs GUI
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
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


# source -v ./proc_strategy_changeDriveCapacity_of_driveCell.invs.tcl; # strategy_changeDriveCapacity - return toChangeCelltype
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:25 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|task_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, focusing on data display and aesthetics
#   -> task_proc  : composed of multiple atomic_proc s, focus on logical integrity, process control, error recovery, and the output of files and reports when solving problems.
# descrip   : strategy of fixing transition: change drive capacibility of cell. ONLY one celltype
# ref       : link url
# --------------------------
proc strategy_changeDriveCapacity {{celltype ""} {changeStairs 1} {driveRange {1 16}} {regExp "D(\\d+)BWP.*CPD(U?L?H?VT)?"}} {
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
if {$driveLevel == "05"} {
  set driveLevelNum 0.5
} else {
  set driveLevelNum [expr int($driveLevel)]
}
      set toDrive 0
      set driveRangeRight [lsort -integer -increasing $driveRange]
      # simple version, provided fixed drive capacibility for 
      set toDrive_temp [expr int([expr $driveLevelNum * ($changeStairs * 2)])]
      set processType [whichProcess_fromStdCellPattern $celltype]
      if {$processType == "TSMC"} {
        regsub D$driveLevel $celltype D* searchCelltypeExp
      } elseif {$processType == "HH"} {
        regsub X$driveLevel $celltype X* searchCelltypeExp
      }
      set availableCelltypeList [dbget head.libCells.name $searchCelltypeExp]
      set availableDriveCapacityList [lmap celltype $availableCelltypeList {
        regexp $regExp $celltype wholename driveLevel VTtype
        if {$driveLevel == "05"} {continue} else { set driveLevel [expr int($driveLevel)]}
      }]
  #puts $availableDriveCapacityList
      if {$toDrive_temp <= 8} {
        set toDrive [find_nearest $availableDriveCapacityList $toDrive_temp 1]
      } else {
        set toDrive [find_nearest $availableDriveCapacityList $toDrive_temp 0]
      }
      if {$toDrive > [lindex $driveRangeRight end] || $toDrive < [lindex $driveRangeRight 0] } {
        return "0x0:3"; # toDrive is out of acceptable driveCapacity list ($driveRange)
      }
      if {[regexp BWP $celltype]} { ; # TSMC standard cell keyword
        regsub "D${driveLevel}BWP" $celltype "D${toDrive}BWP" toCelltype
        return $toCelltype
      } elseif {[regexp {.*X\d+.*A[RHL]\d+} $celltype]} { ; # M31 standard cell keyword
        regsub "X${driveLevel}" $celltype "X${toDrive}" toCelltype
        return $toCelltype
      }
    }
  }
}

#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Tue Jul  8 11:05:01 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> gui_proc   : for gui display, or effort can be viewed in invs GUI
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
# descrip   : find the nearest number from list, you can control which one of bigger or smaller
# ref       : link url
# --------------------------
proc find_nearest {{realList {}} number {returnBigOneFlag 1}} {
  set s [lsort -unique -increasing -real $realList]
  set idx [lsearch -exact $s $number]
  if {$idx != -1} {
    return $number ; # number is not equal every real digit of list
  }
  if {$number < [lindex $s 0] || $number > [lindex $s end]} {
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
# source ./proc_whichProcess_fromStdCellPattern.invs.tcl; # whichProcess_fromStdCellPattern
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Tue Jul  8 11:22:06 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> gui_proc   : for gui display, or effort can be viewed in invs GUI
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
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


# source -v ./proc_print_ecoCommands.invs.tcl; # print_ecoCommand - return command string (only one command)
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Mon Jul  7 20:42:42 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> gui_proc   : for gui display, or effort can be viewed in invs GUI
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
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
        return "0x0:2"; # change: error instname or celltype 
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

# source -v ./proc_print_formatedTable.common.tcl; # print_formatedTable D2 list - return 0, puts formated table
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

