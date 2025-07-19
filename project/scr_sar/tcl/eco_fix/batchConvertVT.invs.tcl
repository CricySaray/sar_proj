#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/16 11:17:22 Wednesday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : convert VT to another VT in batch mode. Finally, generate eco script
# ref       : link url
# related   : ~/project/scr_sar/tcl/eco_fix/timing_fix/trans_fix/proc_strategy_changeVT.invs.tcl - (it can also reach destination, but this proc is simpler)
# --------------------------

source ./timing_fix/trans_fix/proc_print_formatedTable.common.tcl; # print_formatedTable
source ./timing_fix/trans_fix/proc_print_ecoCommands.invs.tcl; # print_ecoCommand
proc batchConvertVT {{outputfile ""} {fromVT "AH9"} {toVT "AR9"} {regExp "X(\\d+).*(A\[HRL\]\\d+)$"}} { ; # AH9 AR9 is stand for HH40/M31 std cell library
  if {$fromVT == "" || $toVT == "" || $regExp == ""} {
    return "0x0:1"; # check your input 
  } else {
    set cmdList {
      "# $fromVT to $toVT" 
      "setEcoMode -reset"
      "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"
      " "
    }
    set instsFromVT_ptr [dbget top.insts.cell.name *$fromVT -e -p2]
    if {[llength $instsFromVT_ptr]} {
      foreach inst_ptr $instsFromVT_ptr {
        set fromInstname [dbget $inst_ptr.name]
        set fromCelltype [dbget $inst_ptr.cell.name]
        regsub $fromVT $fromCelltype $toVT toCelltype
        set cmd1 [print_ecoCommand -type change -inst $fromInstname -celltype $toCelltype]
        lappend cmdList $cmd1
      }
      lappend cmdList " "
      lappend cmdList "setEcoMode -reset"
      set fo [open $outputfile w]
      pw $fo [join $cmdList \n]
      close $fo
    } else {
      puts "no *$fromVT cell to inst" 
    }
  }
}
