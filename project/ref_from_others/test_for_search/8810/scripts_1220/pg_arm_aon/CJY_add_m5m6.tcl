#add mem m5 m6 pg	
proc add_m5m6 {args} {
	global vars

	set help "false"

	foreach arg $args {
		incr index
		switch $arg {
			"-size" {set size [lindex $args $index]}
			"-help" {set help "true" }
		}
	}

	if { $help == "true" } {
		puts "Usage : add m5 m6 pg on all block or only on memory!"
		puts " 		-size	: specify memory channel width!"
		puts " 		-help	: get the help infomation"
		puts "Example:"
		puts "	add_m5m6 -size 15" 
	} else {
		set mem_box ""
		set mem_halo_box ""
		set mem_mem_channel_box_list ""

		foreach mem [dbGet [dbGet top.insts.cell.name -regexp AU28HPC -p2].name] {
			set mem_box [dbShape $mem_box OR [dbGet [dbGet -p top.insts.name $mem].box]]
			set mem_halo_box [dbShape $mem_halo_box OR [dbGet [dbGet -p top.insts.name $mem].pHaloBox]]
		}

		foreach channel_box [dbShape [dbShape [dbShape [dbShape [dbShape [dbShape [dbShape [dbShape [dbShape ${mem_halo_box} SIZEY 10] SIZEY -10] SIZEX 10] SIZEX -10] ANDNOT [dbShape [dbShape [dbShape [dbShape ${mem_halo_box} SIZEY 10] SIZEY -10] SIZEX [expr 3*$vars(site_width)]] SIZEX [expr -3*$vars(site_width)]]] SIZEY [expr 3*$vars(site_height)]] ANDNOT ${mem_box}] SIZEY [expr -0.5*$vars(site_height)]] AND [dbGet top.fplan.box] -output hrect] {
			if { [expr [lindex $channel_box 2] - [lindex $channel_box 0]] < 5 } {
				puts "warn1:This channel is to narrow,please check this channel!"
			} else {
				createRouteBlk -box $channel_box -name memory_channel_rbk -layer ME5
				set mem_mem_channel_box_list [dbShape $mem_mem_channel_box_list OR $channel_box]
			}
		}

		setAddStripeMode \
		-allow_jog none \
		-ignore_DRC true \
		-ignore_block_check true \
		-merge_with_all_layers false \
		-skip_via_on_pin {pad block cover standardcell physicalpin} \
		-skip_via_on_wire_shape {blockring stripe followpin corewire blockwire iowire padring ring fillwire noshape}

		set cmd "addStripe \
							-nets { $vars(power_nets) $vars(gnd_nets) } \
							-create_pins 0 \
							-layer ME5 \
							-extend_to design_boundary \
							-direction vertical \
							-start_from left \
							-start_offset $vars(m5_offset_left) \
							-width $vars(m5_width) \
							-spacing $vars(m5_spacing) \
							-set_to_set_distance $vars(m5_set_set_distance) \
							-uda M5_PG \
							"
		eval $cmd

		set cmd "addStripe \
							-nets { $vars(power_nets) $vars(gnd_nets) } \
							-create_pins 0 \
							-layer ME6 \
							-extend_to design_boundary \
							-direction horizontal \
							-start_from top \
							-start_offset $vars(m6_offset_top) \
							-width $vars(m6_width) \
							-spacing $vars(m6_spacing) \
							-set_to_set_distance $vars(m6_set_set_distance) \
							-uda M6_PG \
							"
		eval $cmd
		deleteRouteBlk -name memory_channel_rbk
		foreach channel_box $mem_mem_channel_box_list {
			set cmd	"addStripe -area {${channel_box}} -layer ME5 -nets {$vars(power_nets) $vars(gnd_nets)} -number_of_sets 1 -spacing 2 -direction vertical -width $vars(m5_width) -start_from left -start_offset 1 -uda mem_channel_m5"
			puts $cmd
			eval $cmd
		}
	}
}
#[get_object_name [get_cells -hierarchical -filter "is_memory_cell == true"]]
