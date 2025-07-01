proc get_net_length {{net ""}} {
	if {$net == "0x0" || [dbget top.nets.name $net -e] == ""} { 
		return "0x0"
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
