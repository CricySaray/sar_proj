proc invsAddM7 {} {
 	global vars
	deselectAll
	if {$vars(cpf_file) != ""} {
		set vars(power_domains) [userGetPowerDomains]
		set vars(GND) [dbPowerDomainGNet [lindex $vars(power_domains) 0]]
		#add global grouond net
		foreach domain $vars(power_domains) {
			if {[dbget [dbget top.pds.group.name $domain -p2].isDefault] ==1} {
				set vars(AON_PWR) [dbPowerDomainPNet [dbGetPowerDomainByName $domain]]
			}
		}
		setAddStripeMode -skip_via_on_pin {pad block cover standardcell physicalpin}
		addStripe \
			-nets "$vars(AON_PWR) $vars(GND)" \
			-over_power_domain 0 \
			-layer 7 \
			-direction $vars(m7_direction) \
			-start_x $vars(m7_start) \
			-stop_x $vars(m7_stop) \
			-start_y $vars(core_y1) \
			-stop_y $vars(core_y2) \
			-width $vars(m7_width) \
			-spacing [expr $vars(m7_pitch) - $vars(m7_width)] \
			-set_to_set_distance $vars(m7_step) \
			-break_stripes_at_block_rings 0 \
			-merge_stripes_value 1 \
			-max_same_layer_jog_length 0 \
			-padcore_ring_top_layer_limit 7 \
			-padcore_ring_bottom_layer_limit 7 \
			-block_ring_top_layer_limit 7 \
			-block_ring_bottom_layer_limit 7 \
			-stacked_via_top_layer 7 \
			-stacked_via_bottom_layer 7 \
			-uda GlobalM7
        } else {
                addStripe \
                        -nets "$vars(gnd_nets) $vars(pwer_nets) " \
                        -over_power_domain 0 \
                        -layer 7 \
                        -direction $vars(m7_direction) \
                        -start_x $vars(core_x1) \
                        -stop_x $vars(core_x2) \
                        -start_y $vars(m7_start) \
                        -stop_y $vars(m7_stop) \
                        -width $vars(m7_width) \
                        -spacing [expr $vars(m7_pitch) - $vars(m7_width)] \
                        -set_to_set_distance $vars(m7_step) \
                        -break_stripes_at_block_rings 0 \
                        -merge_stripes_value 1 \
                        -max_same_layer_jog_length 0 \
                        -padcore_ring_top_layer_limit 7 \
                        -padcore_ring_bottom_layer_limit 7 \
                        -block_ring_top_layer_limit 7 \
                        -block_ring_bottom_layer_limit 7 \
                        -stacked_via_top_layer 7 \
                        -stacked_via_bottom_layer 7 \
                        -uda GlobalM7
        }
}

