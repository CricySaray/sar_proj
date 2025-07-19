proc invsAddM8 {} {
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
	setAddStripeMode -skip_via_on_pin {pad block cover standardcell physicalpin}
	addStripe \
		-nets "$vars(AON_PWR) $vars(GND)" \
		-over_power_domain 0 \
		-layer 8 \
		-direction $vars(m8_direction) \
		-start_x $vars(core_x1) \
		-stop_x $vars(core_x2) \
		-start_y $vars(m8_start) \
		-stop_y $vars(m8_stop) \
		-width $vars(m8_width) \
		-spacing [expr $vars(m8_pitch) - $vars(m8_width)] \
		-set_to_set_distance $vars(m8_step) \
		-break_stripes_at_block_rings 0 \
		-merge_stripes_value 1 \
		-max_same_layer_jog_length 0 \
		-padcore_ring_top_layer_limit 8 \
		-padcore_ring_bottom_layer_limit 8 \
		-block_ring_top_layer_limit 8 \
		-block_ring_bottom_layer_limit 8 \
		-stacked_via_top_layer 8 \
		-stacked_via_bottom_layer 8 \
		-uda GlobalM8
}
