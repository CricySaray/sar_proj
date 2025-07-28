#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/26 17:13:34 Saturday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : get name and locations info of driver-sinks group for one2more situation.
# ref       : link url
# --------------------------
proc get_driverSinksNameLocations {{pinName ""}} { ; # pin can be driverpin or sinkpin, it can get driver and sink automatically
  if {$pinName == "" || [dbget top.insts.instTerms.name $pinName -e] == ""} {
    error "proc get_rootLeafBranchData: check your input, can't find driver pin: $pinName" 
  } else {
    set pin_ptr [dbget top.insts.instTerms.name $pinName -p]
    if {[dbget $pin_ptr.isOutput]} {
      set driverPin_ptr $pin_ptr
    } else {
      set driverPin_ptr [dbget $pin_ptr.net.allTerms {.isOutput}] 
    }
    set driverPin_name [dbget $driverPin_ptr.name]
    set driverPin_loc [lindex [dbget $driverPin_ptr.pt] 0]
    set sinksNum [dbget $driverPin_ptr.net.numInputTerms]
    set sinksPins_ptr [dbget $driverPin_ptr.net.allTerms {.isInput}]
    set sinksPins_loc [dbget $sinksPins_ptr.pt]
    set wiresLines [dbget $driverPin_ptr.net.wires.pts]
    set driverInfo [list $driverPin_name $driverPin_loc]
    set sinksInfo [lmap sink_ptr $sinksPins_ptr {
      set pinname [dbget $sink_ptr.name]
      set pinloc  [lindex [dbget $sink_ptr.pt] 0]
      set keyvalue [list $pinname $pinloc]
    }]
    return [list $driverInfo $sinksInfo] ; # {{drivername {x y}} {{sink1name {x y}} {sink2name {x y}} ...}}
  }
}
