#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
# descrip   : get net length. ONLY one net!!!
# update    : 2025/07/27 22:32:07 Sunday
#             (U001) fix bug: for net: {{xxx/xxx/xxx[12]}}, it can be converted to {xxx/xxx/xxx[12]}
# update    : 2025/08/08 01:30:09 Friday
#             (U002) fix bug when wires segments not exist, have no physical net
# ref       : link url
# --------------------------
alias gl "get_net_length"
proc get_net_length {{net ""}} {
  if {[lindex $net 0] == [lindex $net 0 0]} { ; # U001
    set net [lindex $net 0]
  }
	if {$net == "0x0" || [dbget top.nets.name $net -e] == ""} { 
		error "proc get_net_length: check your input: net($net) is not found!!!"
	} else {
    set wires_split_length [dbget [dbget top.nets.name $net -u -p].wires.length -e]
    if {$wires_split_length == ""} { return 0 } ; # U002
    set net_length 0
    foreach wire_len $wires_split_length {
      set net_length [expr $net_length + $wire_len]
    }
    return $net_length
	}
}
