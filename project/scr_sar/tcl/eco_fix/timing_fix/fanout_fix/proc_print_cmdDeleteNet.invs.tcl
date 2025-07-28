#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/27 21:17:08 Sunday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : print cmd of deleting whole net before adding new repeater when fixing fanout adapting to K-means Algorithm
# return    : cmd of "editDelete -net $net"
# ref       : link url
# --------------------------
proc print_cmdDeleteNet {{pinOrNet ""}} {
  if {$pinOrNet == "" || [dbget top.insts.instTerms.name $pinOrNet -e] == "" && [dbget top.nets.name $pinOrNet -e] == ""}  {
    error "proc print_cmdDeleteNet: check your input!!!"
  } else {
    set pin_ptr [dbget top.insts.instTerms.name $pinOrNet -e -p]
    set net_ptr [dbget top.nets.name $pinOrNet -e] 
    if {$pin_ptr != ""} {
      set netName [dbget $pin_ptr.net.name]
      return "editDelete -net $netName"
    } elseif {$net_ptr != ""} {
      set netName [dbget $net_ptr.name]
      return "editDelete -net $netName"
    }
  }
}
