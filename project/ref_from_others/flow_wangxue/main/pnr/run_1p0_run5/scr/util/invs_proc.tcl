proc invs_Count_Vt {args} {
	parse_proc_arguments -args $args rst
	set ft [open $rst(-out) w]
	set lvt_inst 0
	set hvt_inst 0
	set svt_inst 0
	
	set  lvt_inst [dbGet -e -p [dbGet top.insts.cell.name *LVT -p2].isPhysOnly 0]
	set  hvt_inst [dbGet -e -p [dbGet top.insts.cell.name *HVT -p2].isPhysOnly 0]
	set  svt_inst [dbGet -e -p [dbGet -regexp top.insts.cell.name ".*35P140$" -p2].isPhysOnly 0]
	
	set lvt_inst_num 0
	set hvt_inst_num 0
	set svt_inst_num 0
	
	set lvt_inst_num [llength $lvt_inst]
	set hvt_inst_num [llength $hvt_inst]
	set svt_inst_num [llength $svt_inst]
	######################################ratio
	set total_num [expr $lvt_inst_num + $hvt_inst_num + $svt_inst_num]
	
	set lvt_inst_ratio [format "%.2f" [expr double($lvt_inst_num) * 100 / $total_num]]
	set hvt_inst_ratio [format "%.2f" [expr double($hvt_inst_num) * 100 / $total_num]]
	set svt_inst_ratio [format "%.2f" [expr double($svt_inst_num) * 100 / $total_num]]
	##########################################area
	set lvt_inst_area 0
	set hvt_inst_area 0
	set svt_inst_area 0
	foreach lvt  $lvt_inst {set lvt_inst_area [expr $lvt_inst_area + [dbGet $lvt.area]]}
	foreach hvt  $hvt_inst {set hvt_inst_area [expr $hvt_inst_area + [dbGet $hvt.area]]}
	foreach svt  $svt_inst {set svt_inst_area [expr $svt_inst_area + [dbGet $svt.area]]}
	
	set total_area [expr $lvt_inst_area + $hvt_inst_area + $svt_inst_area]
	
	set lvt_inst_area_ratio [format "%.2f" [expr double($lvt_inst_area) * 100 / $total_area ]]
	set hvt_inst_area_ratio [format "%.2f" [expr double($hvt_inst_area) * 100 / $total_area ]]
	set svt_inst_area_ratio [format "%.2f" [expr double($svt_inst_area) * 100 / $total_area ]]
	####################################output
	set info "
	Type     count    count_ratio|       area        area_ratio
	-----------------------------------------------------------------------------------------
	[format {%-6s%8d%12s%% | %15s%8s%%} LVT: $lvt_inst_num $lvt_inst_ratio $lvt_inst_area $lvt_inst_area_ratio]
	[format {%-6s%8d%12s%% | %15s%8s%%} HVT: $hvt_inst_num $hvt_inst_ratio $hvt_inst_area $hvt_inst_area_ratio]
	[format {%-6s%8d%12s%% | %15s%8s%%} SVT: $svt_inst_num $svt_inst_ratio $svt_inst_area $svt_inst_area_ratio]
	"
	puts $info
	puts $ft $info
	close $ft
}

define_proc_arguments invs_Count_Vt -info "count vt number" \
	-define_args {
	-out "out dir" string required
	}

proc gen_set_user_match {args} {
	parse_proc_arguments -args $args rst 
        set mapfile $rst(-file_name)
	set outFile $rst(-out)/set_user_match.tcl
	if {![file exists $mapfile]} {
		puts "bk error : map file <$mapfile> not found."
		return
	}
	set topname "[dbGet top.name ]"
	set fi [open $mapfile r]
	set fo [open $outFile w]
	while {[gets $fi line] >= 0} {
		if {[regexp {(\S+)/D(\d+)\s+(\S+)/D?(\d+)?} $line match orgname orgbit newname newbit]} {
			set orgbitval [string trim $orgbit]
			set newbitval [string trim $newbit]
			if {$orgbitval ne "" && $orgbitval ne "0"} {
				if {$newbitval ne "" && $newbitval ne "0"} {
					puts $fo "set_user_match -type cell r:/WORK/$topname/$orgname/\\*dff.00.[expr {$orgbitval -1 }]\\* i:/WORK/$topname/$newname/\\*dff.00.[expr {$newbitval -1 }]\\*"
				} else {
					puts $fo "set_user_match -type cell r:/WORK/$topname/$orgname/\\*dff.00.[expr {$orgbitval -1 }]\\* i:/WORK/$topname/$newname/\\*dff.00\\*"
				}
			} elseif {$orgbitval == "0"} {
				puts $fo "set_user_match -type cell r:/WORK/$topname/$orgname/\\*dff.00\\* i:/WORK/$topname/$newname/\\*dff.00\\*"
			}
		}
	}
	close $fi
	close $fo
}

define_proc_arguments gen_set_user_match -info "set_user_match for fm" \
	-define_args { \
	{-file_name "mulibit map file" "" string required} {-out "out dir" "" string required }
	}

proc highlight_timing_path {args} {
	parse_proc_arguments -args $args rst 
	set timing_path $rst(timing_path) 
	if {[array name rst -index] !=""} {
		set index $rst(-index)
	} else {
	 	set index 1
	}
	set pin [get_property [get_property [get_property $timing_path timing_points] pin] full_name]
	if {[dbGet [dbGetTermByInstTermName [lindex $pin 0]].isInput]} {
		set pin [lrange $pin 1 end]
	}
	set start [lindex $pin 0]
	set end [lindex $pin end]
	if {![regexp {/} $start]} {
		highlight [dbGet top.terms.name $start ] -index $index
		highlight [get_nets -of [get_ports $start]] -index $index
		set pin [lrange $pin 2 end]
	}
	if {![regexp {/} $end]} {
		highlight [dbGet top.terms.name $end ] -index $index
		highlight [get_nets -of [get_ports $end]] -index $index
		set pin [lrange $pin 0 end-2]
	}
	foreach {start end} $pin {
		highlight_pin_connection -from_pin $start -to_pin $end -with_arrow -net_color_index $index -inst_color_index 6
	}
}

define_proc_arguments highlight_timing_path -info "highlight timing path" \
	-define_args \
	{{timing_path "timing path collection" "" string required} {-index "index color" "" int optional}
	}

proc echo_group_box {} {
foreach pd [dbGet top.pds.name ] {
	set box [join [dbGet [dbGet top.pds.name $pd -p].group.boxes]]
	echo "setObjFPlanBoxList Group $pd $box"
	}
}
proc select_memory_pad {} {
	deselectAll ;selectInst [dbGet top.insts.cell.baseClass block -p2]
	selectInst [dbGet top.insts.cell.baseClass pad -p2]
}
proc max_num {list} {
	set list $list
	set sort_list [lsort -real -decreasing $list]
	set max [lindex $sort_list 0]
	return $max
	}
proc min_num {list} {
	set list $list
	set sort_list [lsort -real -decreasing $list]
	set min [lindex $sort_list end]
	return $min
	}

proc hightimingpath {args } {
	parse_proc_arguments -args $args optional
	set cmd "report_timing -machine_readable $args"
	eval $cmd >> timing_path.rpt
	load_timing_debug_report ./timing_path.rpt
	highlight_timing_report -file ./timing_path.rpt -all -color_index 1
}



proc add_partial_lhy {dens lenth llx lly urx ury} {
	set X $urx
	set Y $ury
	set x $llx
	while {$x < $X} {
		set x_bk $x
		set x [expr $x+$lenth]
		set y $lly
		while {$y < $Y} {
			set y_bk $y
			set y [expr $y + $lenth]
			createPlaceBlockage -type partial -density $dens -box "$x_bk $y_bk $x $y" -name area_partial
		}
	}
}

proc centre_ponit {llx lly urx ury} {
	set centre_ponit_x [expr ($urx-$llx)/2+$llx]
	set centre_ponit_y [expr ($ury-$lly)/2+$lly]
	return "$centre_ponit_x $centre_ponit_y"
}

#proc centre_ponit_expan {pt_x pt_y} {
#	set new_llx [expr $pt_x -1] 
#	set new_lly [expr $pt_y -1] 
#	set new_urx [expr $pt_x +1] 
#	set new_ury [expr $pt_y +1] 
#	return "$new_llx $new_lly $new_urx $new_ury"
#}

proc text_pin {llx lly urx ury num} {
	lassign [centre_ponit $llx $lly $urx $ury] pt_x pt_y
	set new_llx [expr $pt_x - $num]
	set new_lly [expr $pt_y - $num]
	set new_urx [expr $pt_x + $num]
	set new_ury [expr $pt_y + $num]
	return "$new_llx $new_lly $new_urx $new_ury"
}

#proc select_all {} {
#	deselectAll ;selectInst [dbGet top.insts.cell.baseClass block -p2]
#	selectInst [dbGet top.insts.cell.baseClass pad -p2]
#	selectInstByCellName PCORNER
#	editSelect -layer {M2 M3 M4 M5 M6 M7 M8}
#	editSelect -area [list [join [dbShape [dbGet [dbGet top.insts.name -regexp {u_core_top/u_efuse_ctrl_sys/u_64x32_efuse|u_core_top/u_cc312_wrapper/u_efuse_ctrl_cc312/u_64x32_efuse} -p].boxes] SIZE 30]]] -layer M1
#	}

proc select_all {} {
	deselectAll ;selectInst [dbGet top.insts.cell.baseClass block -p2]
	selectInst [dbGet top.insts.cell.baseClass pad -p2]
	selectInst TCD*
	selectInstByCellName PCORNER
	editSelect -layer {M7 M8 M5 AP} -type Special
	editSelect -area [list [join [dbShape [dbGet [dbGet top.insts.name -regexp {esd_a|esd_b} -p].boxes] SIZE 30]]] -layer {M1 M2 M3 M4 M5 M6} -type Special
	editSelect -area [list [join [dbShape [dbGet [dbGet top.insts.name -regexp {u_core_top/u_efuse_ctrl_sys/u_64x32_efuse|u_core_top/u_cc312_wrapper/u_efuse_ctrl_cc312/u_64x32_efuse} -p].boxes] SIZE 30]]] -layer {M1 M2 M3 M4 M5 M6} -type Special
	editSelect -layer M6 -net {DVDD0P9_AON_SLP DVDD0P9_AON DVDD0P9_AON_IO}
}


proc file2list {file_name} {
	set list_tmp ""
	set fc [open $file_name]
	while {[gets $fc content] >=0 } {
		if {[regexp {^ *#} $content] || [regexp {^ *$} $content]} {continue}
		lappend list_tmp $content
	}
	close $fc
	return $list_tmp
}

proc pt2innovus {pt_tcl edi_tcl} {
        set input_file [open $pt_tcl r]
        set output_file [open $edi_tcl w]
        puts $output_file "setEcoMode -reset"
        puts $output_file "set gpsPrivate::dpgEcoMemoryFix 4"
        puts $output_file "setEcoMode -batchMode true -updateTiming false -refinePlace false -LEQCheck true -honorDontUse false  -honorFixedStatus false -honorFixedNetWire false"
        while {[gets $input_file line] >= 0} {
                puts [lindex $line 0]
                set action [lindex $line 1]
                if {[regexp insert_buffer $action]} {
                        set hier [regsub ":" [lindex $line 3] ""]
                        set cell [regsub -all "'" [lindex $line 6] ""]
                        set pin [regsub -all "'" [lindex $line 12] ""]
                        set new_net_name [regsub -all "'" [lindex $line 14] ""]
                        set new_inst_name [regsub -all "'" [lindex $line 15] ""]
                        if {[regexp $hier "<top>"]} {
                                puts $output_file "ecoAddRepeater -term $pin -cell $cell -newNetName $new_net_name -name $new_inst_name -loc \[dbGet \[dbGet top.insts.instTerms.name $pin -p\].pt\]"
                        } else {
                                puts $output_file "ecoAddRepeater -term $hier/$pin -cell $cell -hinstGuide $hier -newNetName $new_net_name -name $new_inst_name -loc \[dbGet \[dbGet top.insts.instTerms.name $hier/$pin -p\].pt\]"
                        }
                } elseif {[regexp size_cell $action]} {
                        set hier [regsub ":" [lindex $line 3] ""]
                        set cell [regsub -all "'" [lindex $line 7] ""]
                        set inst [regsub -all "'" [lindex $line 4] ""]
                        if {[regexp $hier "<top>"]} {
                                puts $output_file "ecoChangeCell -inst $inst -cell $cell"
                        } else {
                                puts $output_file "ecoChangeCell -inst $hier/$inst -cell $cell"
                        }
                } elseif {[regexp remove_buffer $action]} {
                        set hier [regsub ":" [lindex $line 3] ""]
                        set inst [regsub -all "'" [lindex $line 5] ""]
                        if {[regexp $hier "<top>"]} {
                                puts $output_file "ecoDeleteRepeater -inst $inst"
                        } else {
                                puts $output_file "ecoDeleteRepeater -inst $hier/$inst"
                        }
                } else {
                }
        }
        puts $output_file "setEcoMode -batchMode false -LEQCheck true "
        close $input_file
        close $output_file
        puts "Output Edi Cmd File : $edi_tcl"
}
proc fix_tran {tran_list buffer_cell_name tran_file} {
	echo "setEcoMode -reset" > $tran_file
	set fix_tran_time [clock format [clock seconds] -format "%Y%m%d"]
	echo "setEcoMode -honorDontTouch false -honorDontUse false -honorFixedStatus false -refinePlace false -updateTiming false -batchMode true -honorPowerIntent false -prefixName fix_tran_${fix_tran_time}" >> $tran_file
	set nets [get_object_name [get_nets -of_objects [file2list $tran_list ]]]
	foreach net $nets {
		set is_donttouch [lindex [dbGet [dbGet top.insts.instTerms.net.name $net -p].dontTouch 0] 0]
		if {$is_donttouch != true} {
			deselectAll 
			selectNet $net
			set wire_length 0
			foreach box [dbGet selected.wires.box] {
				set tmp_length [expr abs([lindex $box 0] - [lindex $box 2]) +abs([lindex $box 1] - [lindex $box 3])]
				echo $tmp_length
				if {$tmp_length > $wire_length} {
					set max_length_wire_box $box
					set wire_length $tmp_length
				}
			}
			echo $max_length_wire_box
			set pt "[expr ([lindex $max_length_wire_box 0] + [lindex $max_length_wire_box 2])/2] [expr ([lindex $max_length_wire_box 1] + [lindex $max_length_wire_box 3])/2]"
			echo "ecoAddRepeater -net $net -cell $buffer_cell_name -offLoadAtLoc \{$pt\}" >> $tran_file
		}
	}
	echo "setEcoMode -reset" >> $tran_file
}

proc check_CK_tree_cell {{reportName not_ck_cell.rpt}} {
	set check_info "check if insts on tree with ck* cell name"
	set out_file [open $reportName w+]
	deselectAll
	foreach cktree [get_ccopt_clock_trees *] {
		if {[get_ccopt_clock_tree_cells * -in_clock_trees $cktree] != ""} {
			selectInst [get_ccopt_clock_tree_cells * -in_clock_trees $cktree]
		}
	}
	set errflag 0
	set i 0
	set summary_content ""
	foreach cell_on_tree [dbGet -e [dbGet selected.cell.baseClass core -p].name -u] {
		if {![string match CK* $cell_on_tree]&&![string match ISO* $cell_on_tree]&&![string match SDF* $cell_on_tree]} {
			incr errflag
			lappend summary_content "[dbGet -e [dbGet selected.cell.name $cell_on_tree -p2].name]"
			foreach inst [dbGet -e [dbGet selected.cell.name $cell_on_tree -p2].name] {
				set cell [dbGet -e [dbGet top.insts.name -p $inst].cell.name]
				puts $out_file "$inst $cell"
				incr i
			}
		}
	}
	deselectAll
}

	

