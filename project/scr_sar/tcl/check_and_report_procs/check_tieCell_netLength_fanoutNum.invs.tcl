#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/30 11:33:58 Wednesday
# label     : check_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : check net length and fanout num of tie cell
# return    : viol tie rpt of long nets and much fanout
# ref       : link url
# --------------------------
source ../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl; # get_net_length
source ../packages/print_formattedTable_D2withCategory.package.tcl; # print_formattedTable_D2withCategory
source ../packages/print_formattedTable.package.tcl; # print_formattedTable
source ../packages/pw_puts_message_to_file_and_window.package.tcl; # pw
source ../packages/categorize_overlapping_sets.package.tcl; # categorize_overlapping_sets
source ../packages/stringstore.package.tcl; # stringstore::ss_init/ss_process/ss_get_id/ss_get_string/ss_clear/ss_size/ss_get_max_length/ss_set_max_length/ss_get_all
source ../packages/count_categories.package.tcl; # count_categories
source ../packages/sort_nested_list.package.tcl; # sort_nested_list
proc checkTieNetLengthFanout {{maxNetLength 20} {maxFanout 5} {sumFile "sor_tieLongnet_maxfanout.list"}} {
  set tieInsts_ptr [dbget top.insts.cell.name *TIE* -p2]
  set tiePins [dbget $tieInsts_ptr.instTerms.cellTerm.name -u]
  ss_init 200
  set netLength_numFanout_tiePinName_netName [lmap tie_ptr $tieInsts_ptr {
    set tieName [dbget $tie_ptr.name]
    set tiePin_ptr [dbget $tie_ptr.instTerms.]
    set tiePinName [dbget $tiePin_ptr.name]
    set netName [dbget $tiePin_ptr.net.name]
    set netLength [get_net_length $netName] 
    set numFanout [dbget $tiePin_ptr.net.numInputTerms]
    set tempList [list $netLength $numFanout $tiePinName $netName]
  }]
  set violMaxNetLength [list] ; set violMaxFanout [list]
  foreach nntn $netLength_numFanout_tiePinName_netName {
    if {[lindex $nntn 0] > $maxNetLength} { lset nntn 3 [ss_process [lindex $nntn 3]]; lset nntn 2 [ss_process [lindex $nntn 2]]; lappend violMaxNetLength $nntn }
    if {[lindex $nntn 1] > $maxFanout} { lset nntn 3 [ss_process [lindex $nntn 3]]; lset nntn 2 [ss_process [lindex $nntn 2]]; lappend violMaxFanout $nntn }
  }
  set classifiedCates [categorize_overlapping_sets [list [list violMaxNetLength_greaterThan$maxNetLength $violMaxNetLength] [list violMaxFanout_greaterThan$maxFanout $violMaxFanout]]]
  set sortMethods {
    {NetLength {-index 0 -decreasing -real}}
    {Fanout    {-index 1 -decreasing -integer}} 
  }
  set sortedClassifiedCates [sort_nested_list $classifiedCates $sortMethods]
  set count_sortedClassifiedCates [count_categories $sortedClassifiedCates]
  set netLength_numFanout_tiePinName_netName [linsert $netLength_numFanout_tiePinName_netName 0 [list netLength numFanout tiePinName netName]]
  set fo [open $sumFile w]
  puts $fo [print_formattedTable_D2withCategory $sortedClassifiedCates]
  puts $fo ""
  if {[llength [ss_get_all]]} {
    puts $fo "shortened long-string:"
    puts $fo [print_formattedTable [ss_get_all]]
  }
  pw $fo ""
  pw $fo "------------------------"
  pw $fo "STATISTICS OF CATEGORIES:"
  pw $fo [print_formattedTable $count_sortedClassifiedCates]
  pw $fo ""
  close $fo
}

