#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/06 22:45:01 Wednesday
# label     : test_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : run(test) the proc judgeIfLoop_forOne2More for all nets in the design, and check the loop distribution under the condition of large samples.
# return    : rpt for loopped net
# ref       : link url
# --------------------------
source ../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl; # get_net_length
source ../eco_fix/timing_fix/trans_fix/proc_judgeIfLoop_forOne2More.invs.tcl; # judgeIfLoop_forOne2More
source ./print_formattedTable.package.tcl; # print_formattedTable
proc test_ifLoop_forAllNets {{rpt_name "netRatios.list"}} {
  set allNetNames [get_object_name [get_nets -hier *]]
  set ratio_AllNet [lmap netname $allNetNames {
    set netLength [get_net_length $netname]
    if {!$netLength} { continue }
    set driverPinPt [lindex [dbget [dbget [dbget top.nets.name $netname -p].allTerms {.isOutput == 1}].pt] 0] 
    set sinksPinPt [dbget [dbget [dbget top.nets.name $netname -p].allTerms {.isInput == 1}].pt]
    set numSinks [dbget [dbget top.nets.name $netname -p].numInputTerms]
    if {$numSinks == 1} { continue }
    set ratio [judgeIfLoop_forOne2More $driverPinPt $sinksPinPt $netLength]
    # if {![lindex $ratio 0]} { continue }
    set temp [list {*}$ratio $numSinks $netname]
  }]
  set ratio_AllNet [lsort -index 0 -real -decreasing $ratio_AllNet]
  set fo [open $rpt_name w]
  set ratio_AllNet [linsert $ratio_AllNet 0 [list ifLoop ratio realNetLen ruleNetLen numSinks netName]]
  puts $fo [print_formattedTable $ratio_AllNet]
  close $fo
  puts ""
  puts "total processed net length: [llength $ratio_AllNet]"
  puts ""
}

# your can use this proc to test if this net(of pin) is loopped, you need input a pin which is on tested net
proc checkInvalidPath {pin {debug 0}} {
  set driverPinPt [lindex [dbget [dbget [dbget top.insts.instTerms.name $pin -p].net.allTerms {.isOutput == 1}].pt] 0]
  set sinksPinPt [dbget [dbget [dbget top.insts.instTerms.name $pin -p].net.allTerms {.isInput == 1}].pt]
  set netName [dbget [dbget top.insts.instTerms.name $pin -p].net.name]
  set netLength [get_net_length $netName]
  if {$debug} { puts "driverPinPt: $driverPinPt | sinksPinPt: $sinksPinPt | netLength: $netLength" }
  puts [judgeIfLoop_forOne2More $driverPinPt $sinksPinPt $netLength]
}
