proc invsAddCorePSWM5 {} {
 	global vars
	deselectAll
	set vars(power_domains) [userGetPowerDomains]
	set vars(GND) [dbPowerDomainGNet [lindex $vars(power_domains) 0]]
	#add global grouond net
	foreach domain $vars(power_domains) {
		if {[dbget [dbget top.pds.group.name $domain -p2].isDefault] ==1} {
			set vars(AON_PWR) [dbPowerDomainPNet [dbGetPowerDomainByName $domain]]
		}
	}
	foreach domain $vars(power_domains) {
		if {[dbget [dbget top.pds.group.name $domain -p2].isDefault] ==1} {
			set vars(PWR) $vars(AON_PWR)
		} else {
			set vars(PWR) [regsub $vars(AON_PWR) [dbPowerDomainPNet $domain] ""]
		}
		setAddStripeMode -skip_via_on_pin {pad block cover standardcell physicalpin}
		if { $vars(PWR) != "$vars(AON_PWR)"} {
			puts "$vars(PWR) $vars(AON_PWR) $vars(AON_PWR) $vars(PWR)"
			deselectAll
			selectObject Group $domain
			#	-nets "$vars(PWR) $vars(AON_PWR) $vars(AON_PWR) $vars(PWR)" 
			addStripe \
				-nets "$vars(PWR)  $vars(PWR) " \
				-over_power_domain 1 \
				-layer 5 \
				-start_x [expr $vars(core_x1) + $vars(sw_offset)] \
				-stop_x $vars(core_x2) \
				-start_y $vars(core_y1) \
				-stop_y $vars(core_y2) \
				-width $vars(m5psw_width) \
				-spacing [expr $vars(m5psw_pitch) - $vars(m5psw_width) + 3.9] \
				-set_to_set_distance $vars(m5psw_step) \
				-break_stripes_at_block_rings 0 \
				-merge_stripes_value 1 \
				-max_same_layer_jog_length 0 \
				-padcore_ring_top_layer_limit 6 \
				-padcore_ring_bottom_layer_limit 1 \
				-block_ring_top_layer_limit 6 \
				-block_ring_bottom_layer_limit 1 \
				-stacked_via_top_layer 6 \
				-stacked_via_bottom_layer 1 \
				-uda GlobalPSW5
			addStripe \
				-nets "$vars(AON_PWR) $vars(AON_PWR) $vars(GND)" \
				-over_power_domain 1 \
				-layer 7 \
				-start_x [expr $vars(core_x1) + $vars(sw_offset) + 1.6] \
				-stop_x $vars(core_x2) \
				-start_y $vars(core_y1) \
				-stop_y $vars(core_y2) \
				-width $vars(m7psw_width) \
				-spacing [expr $vars(m7psw_pitch) - $vars(m7psw_width)] \
				-set_to_set_distance $vars(m5psw_step) \
				-break_stripes_at_block_rings 0 \
				-merge_stripes_value 1 \
				-max_same_layer_jog_length 0 \
				-padcore_ring_top_layer_limit 8 \
				-padcore_ring_bottom_layer_limit 6 \
				-block_ring_top_layer_limit 8 \
				-block_ring_bottom_layer_limit 6 \
				-stacked_via_top_layer 8 \
				-stacked_via_bottom_layer 6 \
				-uda GlobalPSW5
		}
	}
	deselectAll
}
