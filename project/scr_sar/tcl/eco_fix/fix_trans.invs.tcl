#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:41 CST 2025
# label     : task_proc
#   -> (atomic_proc|display_proc|task_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, focusing on data display and aesthetics
#   -> task_proc  : composed of multiple atomic procs, focus on logical integrity, process control, error recovery, and the output of files and reports when solving problems.
# descrip   : what?
# ref       : link url
# --------------------------
# API:
set fi [open "$1" "r"]

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
source -v ./proc_get_net_lenth.invs.tcl; # get_net_length - num
source -v ./proc_if_driver_or_load.invs.tcl; # if_driver_or_load - 1: driver  0: load
source -v ./proc_get_fanoutNum_and_inputTermsName_of_pin.invs.tcl; # get_fanoutNum_and_inputTermsName_of_pin - return list [num termsNameList]
source -v ./proc_get_cellDriveLevel_and_VTtype_of_inst.invs.tcl; # get_cellDriveLevel_and_VTtype_of_inst - return [instName cellName driveLevel VTtype]
source -v ./proc_get_cell_class.invs.tcl; # get_cell_class - return logic|buffer|inverter|CLKcell|sequential|gating|other
source -v ./proc_strategy_changeVT.invs.tcl; # strategy_changeVT - return VT-changed cellname
source -v ./proc_strategy_addRepeaterCelltype.invs.tcl; 
source -v ./proc_strategy_changeDriveCapacibility_of_driveCell.invs.tcl; # strategy_changeDriveCapacibility - return toCelltype
source -v ./proc_print_ecoCommands.invs.tcl; # print_ecoCommand - return command string (only one command)

proc fix_trans {{viol_pin_file ""} {canChangeVT 1} {canChangeDriveCapacibility 1} {canChangeVTandDriveCapacibility 1} {canAddRepeater 1} {ecoName "test_econame"} {logicToBufferDistanceThreshold 10} {cellRegExp "X(\\d+).*(A\[HRL\]9)"}} {
  if {$viol_pin_file == "" || [glob -nocomplain $viol_pin_file] == ""} {
    return "0x0:1"; # check your file 
  } else {
    set violValue_driverPin_onylOneLoaderPin_D3List [list ]; # one to one
    set violValue_driver_severalLoader_D3List [list ]; # one to more
    # ------
    # sort two class for all viol situations
    while {[gets $viol_pin_file line] > -1} {
      set value_viol [lindex $line 0]
      set pin_viol   [lindex $line 1]
      if {[if_driver_or_load $pin]} {
        set output_pin $pin_viol 
        set num_termName_D2List [get_fanoutNum_and_inputTermsName_of_pin $output_pin]
        if {[lindex $num_termName_D2List 0] == 1} { ; # load cell is only one. you can use option: -relativeDistToSink to ecoAddRepeater
          lappend violValue_driverPin_onylOneLoaderPin_D3List [list $value_viol $output_pin [lindex $num_termName_D2List 1]]
        } else { ; # load cell are several, need consider other method
          lappend violValue_driver_severalLoader_D3List [list $value_viol $output_pin [lindex $num_termName_D2List 1]]
        }
      } else {
        set input_pin $pin_viol 
      }
    }
    # ------
    # sort and check D3List correction : $violValue_driverPin_onylOneLoaderPin_D3List and $violValue_driver_severalLoader_D3List
    
    # ------
    # begin deal with different situation
    ## only load one cell
    foreach viol_driverPin_loadPin $violValue_driverPin_onylOneLoaderPin_D3List {
      ### 1 loader is a buffer, but driver is a logic cell
      if {[get_cell_class [lindex $viol_driverPin_loadPin 2]] == "buffer" && [get_cell_class [lindex $viol_driverPin_loadPin 1]] == "logic"} {
        set netName [get_object_name [get_nets -of_objects [lindex $viol_driverPin_loadPin 1]]]
        set netLength [get_net_length $netName]
        regsub {(.*)\/.*} [lindex $viol_driverPin_loadPin 1] wholename instname
        set inst_celltype_driveLevel_VTtype [get_cellDriveLevel_and_VTtype_of_inst $instname $cellRegExp]
        set driveCelltype [lindex $inst_celltype_driveLevel_VTtype 1]
        set driveCapacibility [lindex $inst_celltype_driveLevel_VTtype 2]
        #### onlyChangeVT / changeVTandSizeupDriveCapacibility / onlySizeupDriveCapacibility
        if {$canChangeVT && [lindex $viol_driverPin_loadPin 0] <= -0.009} { ; # only changeVT
          set toCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 1} {AH9 0}} {AL9 AR9 AH9} $cellRegExp]
          set cmd1 [print_ecoCommand -type change -inst $instname -celltype $driveCelltype]
        } elseif {$canChangeDriveCapacibility && $netLength <= $logicToBufferDistanceThreshold} { ; #only changeDriveCapacibility
          if {$driveCapacibility <= 1} {
            set toCelltype [strategy_changeDriveCapacibility $driveCelltype 2]
          } elseif {$driveCapacibility >= 2} {
            set toCelltype [strategy_changeDriveCapacibility $driveCelltype 1]
          }
          set cmd1 [print_ecoCommand -type change -inst $instname -celltype $toCelltype]
        } elseif {$canChangeVTandDriveCapacibility && <= [expr $logicToBufferDistanceThreshold + 5]} { ; # change VT and DriveCapacibility
          set toCelltype [strategy_changeVT $driveCelltype {{AR9 3} {AL9 1} {AH9 0}} {AL9 AR9 AH9} $cellRegExp]
          if {$toCelltype <= 1} {
            set toCelltype [strategy_changeDriveCapacibility $toCelltype 2]
          } elseif {$driveCapacibility >= 2} {
            set toCelltype [strategy_changeDriveCapacibility $toCelltype 1]
          }
          set cmd1 [print_ecoCommand -type change -inst $instname -celltype $toCelltype]
        } elseif {$canAddRepeater && $netLength < [expr $logicToBufferDistanceThreshold + 5]} { ; # add Repeater near logic cell
          set addCelltype [] ; # strategy addRepeater Celltype to select buffer/inverter celltype(driveCapacibility and VTtype)
        }
      }
      ### loader is a logic cell, driver is a buffer(simple, upsize drive capacibility, but consider previous cell drive range)
      ### loader is a buffer, and driver is a buffer too
      ### loader is a logic cell, and driver is a logic cell
      ### !!!CLK cell : need specific cell type buffer/inverter
    }


    ## load several cells
    ### primarily focus on driver capacibility and cell type, if have too many loaders, can fix fanout! (need notice some sticks)
  }
}
