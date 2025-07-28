#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
# descrip   : get net length. ONLY one net!!!
# update    : 2025/07/27 22:32:07 Sunday
#             fix bug: for net: {{xxx/xxx/xxx[12]}}, it can be converted to {xxx/xxx/xxx[12]}
# ref       : link url
# --------------------------
proc get_net_length {{net ""}} {
  if {[lindex $net 0] == [lindex $net 0 0]} {
    set net [lindex $net 0]
  }
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
