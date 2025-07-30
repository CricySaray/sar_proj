#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/30 11:33:58 Wednesday
# label     : check_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : check net length and fanout num of tie cell
# return    : 
# ref       : link url
# --------------------------
source ../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl; # get_net_length
source ../eco_fix/timing_fix/trans_fix/proc_print_formatedTable.common.tcl; # print_formatedTable
proc checkTieNetLengthFanout {} {
  set tieInsts_ptr [dbget top.insts.cell.name *TIE* -p2]
  set tiePins [dbget $tieInsts_ptr.instTerms.cellTerm.name -u]
  set tieInst_pin_netName_netLength_numFanout [lmap tie_ptr $tieInsts_ptr {
    set tieName [dbget $tie_ptr.name]
    set tiePin_ptr [dbget $tie_ptr.instTerms.]
    set tiePinName [dbget $tiePin_ptr.name]
    set netName [dbget $tiePin_ptr.net.name]
    set netLength [get_net_length $netName] 
    set numFanout [dbget $tiePin_ptr.net.numInputTerms]
    set tempList [list $tieName $tiePinName $netName $netLength $numFanout]
  }]
  linsert $tieInst_pin_netName_netLength_numFanout 0 [list tieName tiePinName netName netLength numFanout]
  puts [print_formatedTable $tieInst_pin_netName_netLength_numFanout]
}
