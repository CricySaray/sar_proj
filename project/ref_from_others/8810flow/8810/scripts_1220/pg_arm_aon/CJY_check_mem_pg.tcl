proc check_mem_pg {args} {
    set layer M5
	set help false
	
	foreach arg $args {
		incr index
		switch $arg {
			"-layer" {set layer [lindex $args $index]}
			"-help" {set help true}
		}
	}
	set p_box [dbGet [dbGet -p2 [dbGet -p top.pgNets.isPwr 1].sWires.layer.name ${layer}].box]
	set g_box [dbGet [dbGet -p2 [dbGet -p top.pgNets.isGnd 1].sWires.layer.name ${layer}].box]
	deselectAll
	foreach mem [dbGet [dbGet top.insts.cell.name -regexp AU28HPC -p2].name]  {
		#set mem [get_object_name $mem_addr]
		set mem_box [dbGet [dbGet -p top.insts.name $mem].box]
		if { [llength [dbShape ${p_box} AND ${mem_box}]] < 2 } {
			selectInst ${mem}
			puts "=======>Error: ${mem} has less than 2 power net, please correct by yourself!"
		} else {
			continue
		}
		if { [llength [dbShape ${g_box} AND ${mem_box}]] < 2 } {
			selectInst ${mem}
			puts "=======>Error: ${mem} has less than 2 gnd net, please correct by yourself!"
		} else {
			continue
		}
	}
	highlight
	deselectAll
}
#foreach_in_collection mem_addr [get_cells -hierarchical -filter "is_memory_cell == true"] {
