proc enhence_m5_pg {} {
	global vars
	if { $vars(lp_mode) == "true" } {
        set global_ground_net [dbPowerDomainGNet [dbGet -p top.pds.isDefault 1]]
	    set m5_pg_box [dbGet [dbGet -p2 top.pgNets.sWires.layer.name ME5].box]
	    foreach domain [dbGet top.pds.name] {
	    	set local_vdd [dbPowerDomainPNet [dbGet -p top.pds.name $domain]]
	    	set mem_box_list ""
	    	foreach mem [get_object_name [get_cells -quiet -hierarchical -filter "is_memory_cell == true && power_domain == ${domain}"]] {
	    		set mem_box_list [dbShape ${mem_box_list} OR [dbGet [dbGet -p top.insts.name ${mem}].box]]
	    	}

	    	foreach box_a [dbShape [dbShape ${mem_box_list} SIZE 10] SIZE -10] {
	    		set i 0
                    foreach box [dbShape ${box_a} ANDNOT ${m5_pg_box}] {
                    set box_llx [lindex $box 0]
	    		    set box_lly [lindex $box 1]
	    		    set box_urx [lindex $box 2]
	    		    set box_ury [lindex $box 3]
                    set mid_box_x [expr $vars(m5_track_pitch_x)*round(((${box_llx}+${box_urx})/2-$vars(m5_track_offset_x))/$vars(m5_track_pitch_x))+$vars(m5_track_offset_x)]
	    		    set mem_enhence_m5_pg_box {[expr ${mid_box_x}-$vars(aon_global_m5_width)/2.0] ${box_lly} [expr ${mid_box_x}+$vars(aon_global_m5_width)/2.0] ${box_ury}}
	    		    if { [db_rect $box -sizex] < [expr 3*$vars(aon_global_m5_width)] } {
	    		    	continue
	    		    } else {
	    		    	if { [expr ${i}%2] == 0 } {
	    		    		set cmd "add_shape -layer ME5 -net ${local_vdd} -rect ${mem_enhence_m5_pg_box} -shape STRIPE -user_class ${domain}_enhence_mem_m5"
	    		    	} else {
	    		    		set cmd "add_shape -layer ME5 -net ${global_ground_net} -rect ${mem_enhence_m5_pg_box} -shape STRIPE -user_class ${domain}_enhence_mem_m5"
	    		    	}
	    		    	eval $cmd
	    		    	incr i
	    		    }
                }
	    	}
	    }
    } else {
        set m5_pg_box [dbGet [dbGet -p2 top.pgNets.sWires.layer.name ME5].box]
	    set mem_box_list ""
	    foreach mem [get_object_name [get_cells -quiet -hierarchical -filter "is_memory_cell == true "]] {
	    	set mem_box_list [dbShape ${mem_box_list} OR [dbGet [dbGet -p top.insts.name ${mem}].box]]
	    }

	    foreach box_a [dbShape [dbShape ${mem_box_list} SIZE 10] SIZE -10] {
	   	    set i 0
            foreach box [dbShape ${box_a} ANDNOT ${m5_pg_box}] {
                set box_llx [lindex $box 0]
	    		set box_lly [lindex $box 1]
	    		set box_urx [lindex $box 2]
	    		set box_ury [lindex $box 3]
                set mid_box_x [expr $vars(m5_track_pitch_x)*round(((${box_llx}+${box_urx})/2-$vars(m5_track_offset_x))/$vars(m5_track_pitch_x))+$vars(m5_track_offset_x)]
	    		set mem_enhence_m5_pg_box {[expr ${mid_box_x}-$vars(m5_width)/2.0] ${box_lly} [expr ${mid_box_x}+$vars(m5_width)/2.0] ${box_ury}}
	    		if { [db_rect $box -sizex] < [expr 3*$vars(m5_width)] } {
	    			continue
	    		} else {
	    			if { [expr ${i}%2] == 0 } {
	    				set cmd "add_shape -layer ME5 -net $vars(power_nets) -rect ${mem_enhence_m5_pg_box} -shape STRIPE -user_class enhence_mem_m5"
	    			} else {
	    				set cmd "add_shape -layer ME5 -net $vars(gnd_nets) -rect ${mem_enhence_m5_pg_box} -shape STRIPE -user_class enhence_mem_m5"
	    			}
	    			eval $cmd
	    			incr i
	    		}
            }
        }
    }
}
