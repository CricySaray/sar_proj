set i 0
foreach bsc_inst "chip_top_gate_tessent_bscan_logical_group_left_inst chip_top_gate_tessent_bscan_logical_group_bottom_inst chip_top_gate_tessent_bscan_logical_group_right_inst chip_top_gate_tessent_bscan_logical_group_top_inst " {
	foreach mn [dbget [dbGetObjByName $bsc_inst].hInsts.name] {
		foreach_in_collection portCol [get_ports] {
			set pn [get_object_name $portCol]
			set pn_l [string tolower $pn]
			set comp_n "${bsc_inst}/${pn}_BCELL"
			if {$comp_n == $mn} {
				set group_list "$mn"
				puts "$comp_n"
				foreach mn_1 [dbget [dbGetObjByName $bsc_inst].hInsts.name] {
					if {[regexp EN $mn_1]} {
						set p_out ${mn_1}/bscanReg_reg/Q
						if {[dbGetTermByInstTermName $p_out] == "0"} {
							continue
						} else {
							dbForEachNetInputTerm [dbTermNet [dbGetTermByInstTermName $p_out]] inputTermPtr {
								if {[regexp $mn [dbTermInstName $inputTermPtr]]} {
									set group_list "$mn $mn_1"
								}
							}
						}
					}
				}
				puts $group_list
				dbForEachNetTerm [dbGetNetByName $pn] termPtr {
					if {[dbGet ${termPtr}.objType] == "term"} {
						continue
					} else {
						set instPtr [dbTermInst $termPtr]
						set cellType [dbget [dbInstCell $instPtr].baseClass]
						if {$cellType == "pad"} {
							set instName [dbInstName $instPtr]
							set side [dbGet [dbGetIoByName $instName].side]
							if { $side == "West"} {
								set x [expr [lindex [lindex [dbget [dbGetIoByName $instName].box] 0] 2] + 21]
								set y [lindex [lindex [dbget [dbGetIoByName $instName].box] 0] 1]
								set ux [expr $x + 15]
								set uy [expr $y + 25]
								createInstGroup ${pn}_region -fence $x $y $ux $uy
								addInstToInstGroup ${pn}_region $group_list
								addInstToInstGroup ${pn}_region chip_core_inst/chip_pinmux_inst/pd_${pn_l}_pinmux*/*
								incr i
							} elseif { $side == "East"} {
								set x [expr [lindex [lindex [dbget [dbGetIoByName $instName].box] 0] 0] - 35]
								set y [lindex [lindex [dbget [dbGetIoByName $instName].box] 0] 1]
								set ux [expr $x - 15]
								set uy [expr $y + 25]
								createInstGroup ${pn}_region -fence $x $y $ux $uy
								addInstToInstGroup ${pn}_region $group_list
								addInstToInstGroup ${pn}_region chip_core_inst/chip_pinmux_inst/pd_${pn_l}_pinmux*/*
								incr i
							} elseif { $side == "South"} {
								set x [lindex [lindex [dbget [dbGetIoByName $instName].box] 0] 0]
								set y [expr [lindex [lindex [dbget [dbGetIoByName $instName].box] 0] 3] + 21]
								set ux [expr $x + 25]
								set uy [expr $y + 30]
								createInstGroup ${pn}_region -fence $x $y $ux $uy
								addInstToInstGroup ${pn}_region $group_list
								addInstToInstGroup ${pn}_region chip_core_inst/chip_pinmux_inst/pd_${pn_l}_pinmux*/*
								incr i
							} elseif { $side == "North"} {
								set x [lindex [lindex [dbget [dbGetIoByName $instName].box] 0] 0]
								set y [expr [lindex [lindex [dbget [dbGetIoByName $instName].box] 0] 1] - 22]
								set ux [expr $x + 25]
								set uy [expr $y - 30]
								createInstGroup ${pn}_region -fence $x $y $ux $uy
								addInstToInstGroup ${pn}_region $group_list
								addInstToInstGroup ${pn}_region chip_core_inst/chip_pinmux_inst/pd_${pn_l}_pinmux*/*
								incr i
							}
						}
					}
				}
			}
		}
	}
}
puts $i
selectGroup *region
set instPtr [dbGet selected.members.insts]
foreach Ptr $instPtr {
	if { $Ptr != "0x0" } {
		set inst [dbGet $Ptr.name]
		specifySelectiveBlkgGate -inst $inst
	}
} 
deselectAll

#createInstGroup JTAG_region -region x1 y1 x2 y2
#addInstToInstGroup JTAG_region core_top/dft_pin_mux_inst/pinmux_*_jtag_tms
#
