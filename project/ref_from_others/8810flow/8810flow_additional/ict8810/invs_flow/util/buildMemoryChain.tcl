##############################################################
#### findMemoryChain : used to find which mem's SD/DS net
#			need to be build delay chain
#	-pinList : memory chain pin list from xts file
#	-pDomain : which power domain do you want to run
#note : when get the memory_chain.list file,need to modify
#	it and add the first memory term for each chain, and
#	add SD/DS for which chain it is : 
#	eg lte_sd_0 SD lte_lb/memory0/SD SD
##############################################################
#
proc findMemoryChain {pinList pDomain} {
	set chain_file [open ./memory_chain.list w]
	set buffertree_file [open ./buffer_tree.list w]
	set netlist ""
	foreach inst [get_object_name [get_cells -hier * -filter "is_memory_cell==true"]] {
		set pd [getInstPowerDomain $inst]
		if {$pd == $pDomain} {
			set instPtr [dbGetInstByName $inst]
			dbForAllInstTerm $instPtr termPtr {
				set term [lindex [dbTermName $termPtr] 0]
				if { $term == "SD" || $term == "DS"} {
					set netPtr [dbTermNet $termPtr]
					set netName [dbget ${netPtr}.name]
					if {[lsearch $netlist $netName] == -1} {
						lappend netlist $netName
						dbForEachNetOutputTerm $netPtr outputTermPtr {
							if {[dbget ${outputTermPtr}.objType] == "Term"} {
								set termName [dbget [${outputTermPtr}.name]
								if {[lsearch $pinList $termName] != -1} {
									puts $chain_file "$netName $term"
								} else {
									puts $buffertree_file "$netName"
								}
							} else {
								puts "Error : SD/DS isn't driven by IO pin, net = [dbget ${netPtr}.name]"
							}
						}
					}
				}
			}
		}
	}
	close $chain_file
	close $buffertree_file
}
proc abs {x} {
	if { $x >= 0 } { return $x } 
	return [expr -$x]
}
proc fixCell {} {
	foreach x [dbGet top.insts] {
		if {[regexp {^PT} [dbGet $x.cell.name]] || [regexp {AON$} [dbGet $x.cell.name]]} {
			dbSet $x.pStatus fixed
		}
	}
}
##############################################################
####buildMemoryChain : sed to build delay chain
####	-chainListfile: define 3 varies in each line: {signal_control_netname first_memory_term SD/DS}
####	-pDomain : which power domain do you want to run
####	-ptDelCel: cell type of always on delay cell
##############################################################
proc buildMemoryChain {chainListfile pDomain ptBufCell ptDelCel} {
	set fileID [open $chainListfile r]
	while {[gets $fileID line] >= 0} {
		if {[regexp {^#} $line]} {
			continue
		}
		set net [lindex $line 0]
		set termChain [lindex $line 1]
		set firstCellTerm [lindex $line 2]
		set pinlist ""
		dbForEachNetInputTerm [dbGetNetByName $net] inputTermPtr {
			set term [lindex [dbTermName $inputTermPtr] 0]
			if {$term == $termChain} {
				lappend pinlist [dbget ${inputTermPtr}.name]
			} else {
				puts "Error: [dbTermInstName $inputTermPtr]/$term pin in $termChain chain !!"
			}
		}

		set connected_term_list $firstCellTerm
		set current_term $firstCellTerm
		while {[llength $connected_term_list] < [llength $pinlist]} {
			set MinDistance 100000000
			foreach new_term $pinlist {
				set loc_a [dbTermLoc [dbGetTermByInstTermName $current_term]]
				set loc_b [dbTermLoc [dbGetTermByInstTermName $new_term]]
				set dist_x [expr [lindex $loc_a 0] - [lindex $loc_b 0]]
				set dist_y [expr [lindex $loc_a 1] - [lindex $loc_b 1]]
				set distance [expr [abs $dist_x] + [abs $dist_y]]
				if {[$distance] !=0 & $distance < $MinDistance & [lsearch $connected_term_list $new_term] == -1} {
					set MinDistance $distance
					set next_term $new_term
				}
			}
			lappend connected_term_list $next_term
			set current_term $next_term
		}

		## add delay buffer
		set L [llength $connected_term_list]
		set j [expr $L-1]
		set terminals [lindex $connected_term_list $j]
		set locInst [dbInstLoc [dbTermInst [dbGetTermByInstTermName $terminals]]]
		set loc_x [expr [lindex $locInst 0]/2000]
		set loc_y [expr [lindex $locInst 1]/2000 - 4.5 ]

		while {$j >= 0 } {
			addBufferForFeedthrough -net $net -powerDomain $pDomain -cell $ptBufCell -termList $terminals -perfix AOBUFF_Cell -noFixedBuf -noRefinePlace -loc $loc_x $loc_y
			set netPtr [dbGetNetByName $net]
			dbForEachNetTerm $netPtr termPtr {
				if {[dbget ${termPtr}.objType] == "instTerm"} {
					if { [dbIsObjTerm $termPtr] == 1 & [dbIsTermInput $$termPtr] == 1 & [dbTermName $$termPtr] == "I" } {
						set termName [dbTermName $termPtr]
						set instPtr [dbTermInst $termPtr]
						set instName [dbInstName $instPtr]
						set AOBUF_I $instName/$termName
						puts "AOBUF_I is $AOBUF_I"
					}
				}
			}
			set loc_x [expr $loc_x + 6]
			addBufferForFeedthrough -net $net -powerDomain $pDomain -cell $ptDelCell -termList $AOBUF_I -perfix DelayCell -noFixedBuf -noRefinePlace -loc $loc_x $loc_y
			incr j -1
			if { $j >= 0 } {
				set terminals [lindex $connected_term_list $j]
				dbForEachNetTerm [dbGetNetByName $net] termPtr {
					if {[dbget ${termPtr}.objType] == "instTerm"} {
						if { [dbIsObjTerm $termPtr] == 1 & [dbIsTermInput $$termPtr] == 1 & [dbTermName $$termPtr] == "I" } {
							set termName [dbTermName $termPtr]
							set instPtr [dbTermInst $termPtr]
							set instName [dbInstName $instPtr]
							set DEL_I $instName/$termName
							puts "DEL_I is $DEL_I"
						}
					}
				}
				lappend terminals $Del_I
				set locInst [dbInstLoc [dbTermInst [dbGetTermByInstTermName [lindex $connected_term_list $j]]]]
				set loc_x [expr [lindex $locInst 0]/2000]
				set loc_y [expr [lindex $locInst 1]/2000 - 4.5 ]
			}	
		}
	}
}
