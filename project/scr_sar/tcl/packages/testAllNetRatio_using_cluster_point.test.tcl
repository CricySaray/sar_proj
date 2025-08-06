source ../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl; # get_net_length
source ../eco_fix/timing_fix/trans_fix/proc_judgeIfLoop_forOne2More.invs.tcl; # judgeIfLoop_forOne2More
source ./print_formattedTable.package.tcl; # print_formattedTable
proc testAllNetLength {} { ; # test math method
  set allNetNames [get_object_name [get_nets -hier *]]
  set ratio_AllNet [lmap netname $allNetNames {
    set netLength [get_net_length $netname]
    if {!$netLength} { continue }
    set driverPinPt [lindex [dbget [dbget [dbget top.nets.name $netname -p].allTerms {.isOutput == 1}].pt] 0] 
    set sinksPinPt [dbget [dbget [dbget top.nets.name $netname -p].allTerms {.isInput == 1}].pt]
    set numSinks [dbget [dbget top.nets.name $netname -p].numInputTerms]
    if {$numSinks == 1} { continue }
    set ratio [judgeIfLoop_forOne2More $driverPinPt $sinksPinPt $netLength]
    set temp [list $ratio $netname]
  }]
  set ratio_AllNet [lsort -index 0 -real -decreasing $ratio_AllNet]
  set fo [open netRatios.list w]
  puts $fo [print_formattedTable $ratio_AllNet]
  close $fo
  puts ""
  puts "total processed net length: [llength $ratio_AllNet]"
  puts ""
}

proc checkInvalidPath {pin} {
  set driverPinPt [lindex [dbget [dbget [dbget top.insts.instTerms.name $pin -p].net.allTerms {.isOutput == 1}].pt] 0]
  set sinksPinPt [dbget [dbget [dbget top.insts.instTerms.name $pin -p].net.allTerms {.isInput == 1}].pt]
  set netName [dbget [dbget top.insts.instTerms.name $pin -p].net.name]
  set netLength [get_net_length $netName]
  puts [judgeIfLoop_forOne2More $driverPinPt $sinksPinPt $netLength]
}
