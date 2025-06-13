proc enhence_m6_pg {} {
	global vars
	if { $vars(lp_mode) == "true" } {
        set global_ground_net [dbPowerDomainGNet [dbGet -p top.pds.isDefault 1]]
	    set m6_pg_box [dbGet [dbGet -p2 top.pgNets.sWires.layer.name ME6].box]
	    foreach domain [dbGet top.pds.name] {
	    	set local_vdd [dbPowerDomainPNet [dbGet -p top.pds.name $domain]]
	    	set mem_box_list ""
	    	foreach mem [get_object_name [get_cells -hierarchical -quiet -filter "is_memory_cell == true && power_domain == ${domain}"]] {
	    		set mem_box_list [dbShape ${mem_box_list} OR [dbGet [dbGet -p top.insts.name ${mem}].box]]
	    	}
	    	
            foreach box_a [dbShape [dbShape [dbShape ${mem_box_list} SIZEX 10] SIZEX -10] -output hrect] {
                set i 0
                foreach box [dbShape ${box_a} ANDNOT ${m6_pg_box}] {
	    		    set box_llx [lindex $box 0]
	    		    set box_lly [lindex $box 1]
	    		    set box_urx [lindex $box 2]
	    		    set box_ury [lindex $box 3]
                    set mid_box_y [expr $vars(m6_track_pitch_y)*round(((${box_lly}+${box_ury})/2-$vars(m6_track_offset_y))/$vars(m6_track_pitch_y))+$vars(m6_track_offset_y)]
	    		    set mem_enhence_m6_pg_box {${box_llx} [expr ${mid_box_y}-$vars(aon_global_m6_width)/2.0] ${box_urx} [expr ${mid_box_y}+$vars(aon_global_m6_width)/2.0]}
	    		    if { [db_rect $box -sizey] < [expr 3*$vars(aon_global_m6_width)] } {
	    			    continue
	    		    } else {
	    			    if { [expr ${i}%2] == 0 } {
	    				    set cmd "add_shape -layer ME6 -net ${local_vdd} -rect ${mem_enhence_m6_pg_box} -shape STRIPE -user_class ${domain}_enhence_mem_m6"
	    			    } else {
	    				    set cmd "add_shape -layer ME6 -net ${global_ground_net} -rect ${mem_enhence_m6_pg_box} -shape STRIPE -user_class ${domain}_enhence_mem_m6"
	    			    }
	    			    eval $cmd
	    			    incr i
	    		    }
                }
            }
	    }
    } else {
        set m6_pg_box [dbGet [dbGet -p2 top.pgNets.sWires.layer.name ME6].box]
	    set mem_box_list ""
	    foreach mem [dbGet [dbGet top.insts.cell.name -regexp {AU28HPC|SFLVTPA28_256X80BW32}  -p2].name]  {
	    	set mem_box_list [dbShape ${mem_box_list} OR [dbGet [dbGet -p top.insts.name ${mem}].box]]
        }
	    	
        foreach box_a [dbShape [dbShape [dbShape ${mem_box_list} SIZEX 10] SIZEX -10] -output hrect] {
            set i 0
            foreach box [dbShape ${box_a} ANDNOT ${m6_pg_box}] {
	    	    set box_llx [lindex $box 0]
	    	    set box_lly [lindex $box 1]
	    	    set box_urx [lindex $box 2]
	    	    set box_ury [lindex $box 3]
                set mid_box_y [expr $vars(m6_track_pitch_y)*round(((${box_lly}+${box_ury})/2-$vars(m6_track_offset_y))/$vars(m6_track_pitch_y))+$vars(m6_track_offset_y)]
	    	    set mem_enhence_m6_pg_box {${box_llx} [expr ${mid_box_y}-$vars(m6_width)/2.0] ${box_urx} [expr ${mid_box_y}+$vars(m6_width)/2.0]}
	    	    if { [db_rect $box -sizey] < [expr 3*$vars(m6_width)] } {
	    		    continue
	    	    } else {
	    		    if { [expr ${i}%2] == 0 } {
	    			    set cmd "add_shape -layer ME6 -net $vars(power_nets) -rect ${mem_enhence_m6_pg_box} -shape STRIPE -user_class enhence_mem_m6"
	    		    } else {
	    			    set cmd "add_shape -layer ME6 -net $vars(gnd_nets) -rect ${mem_enhence_m6_pg_box} -shape STRIPE -user_class enhence_mem_m6"
	    		    }
	    		    eval $cmd
	    		    incr i
	    	    }
            }
        }
    }
}
