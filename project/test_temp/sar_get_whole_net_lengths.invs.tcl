proc sar_get_whole_net_lengths {{nets ""}} {
	if {$nets == ""} { set nets [dbget selected.net.name -u] }
	if {$nets == "0x0"} {
		puts "Error: No provided nets and No selected nets. Please input nets!!!"
	} else {
		set num 0
		set mod 1
		set net_length_blocks [list ]
		foreach net $nets {
			incr i
			if {[dbget top.nets.name $net] == "0x0"} {
				lappend net_length_blocks [list "NaN" $net]
			} else {
				set wires_split_length [dbget [dbget top.nets.name $net -u -p].wires.length]
				set net_length 0
				foreach wire_len $wires_split_length {
					set net_length [expr $net_length + $wire_len]
				}
				lappend net_length_blocks [list $net_length $net]
			}
		}
		foreach keyvalue $net_length_blocks {
			set len_wide [string length [lindex $keyvalue 0]]
			#puts $len_wide
			if {$mod < $len_wide} {set mod $len_wide}
		}
		set num_mod [expr [expr int(log10($i))] + 1]
		set net_length_blocks [lsort -decreasing -real -index 0 $net_length_blocks]
		#puts $net_length_blocks
		set j 0
		foreach block $net_length_blocks {
			incr j
			printf "%-${num_mod}s : %-${mod}s um : [lindex $block 1]\n" "$j" [lindex $block 0]
		}
	}
}
alias len "sar_get_whole_net_lengths"
