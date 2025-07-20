#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/20 15:47:17 Sunday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : get pt(location) of object(pin/inst/...)
# ref       : link url
# --------------------------
alias gpt "getPt_ofObj"
proc getPt_ofObj {{obj ""}} {
  if {$obj == ""} { 
    set obj [dbget selected.name -e] ; # now support case that is only one obj
  }
  if {$obj == "" || [dbget top.insts.name $obj -e] == "" && [dbget top.insts.instTerms.name $obj -e] == ""} {
    return "0x0:1"; # check your input 
  } else {
    set inst_ptr [dbget top.insts.name $obj -e -p]
    set pin_ptr  [dbget top.insts.instTerms.name $obj -e -p]
    if {$inst_ptr != ""} {
      set inst_pt [lindex [dbget $inst_ptr.pt] 0]
      return $inst_pt
    } elseif {$pin_ptr != ""} {
      set pin_pt [lindex [dbget $pin_ptr.pt] 0]
      return $pin_pt
    }
  }
}
