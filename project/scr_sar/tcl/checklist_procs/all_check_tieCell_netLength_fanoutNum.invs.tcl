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
  linsert $tieInst_pin_netName_netLength_numFanout [list tieName tiePinName netName netLength numFanout]
  puts [print_formatedTable $tieInst_pin_netName_netLength_numFanout]
}
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
proc print_formatedTable {{dataList {}}} {
  set text ""
  foreach row $dataList {
      append text [join $row "\t"]
      append text "\n"
  }
  set pipe [open "| column -t" w+]
  puts -nonewline $pipe $text
  close $pipe w
  set formattedLines [list ]
  while {[gets $pipe line] > -1} {
    lappend formattedLines $line
  }
  close $pipe
  return [join $formattedLines \n]
}
