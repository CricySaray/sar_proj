proc invsAddMemM6 {} {
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
	foreach domain $vars(power_domains) {
		if {[dbget [dbget top.pds.group.name $domain -p2].isDefault] ==1} {
			set vars(PWR) $vars(AON_PWR)
		} else {
			set vars(PWR) [regsub $vars(AON_PWR) [dbPowerDomainPNet $domain] ""]
		}
#		if { $vars(PWR) != "$vars(AON_PWR)"} {
			deselectAll
			selectObject Group $domain
			addStripe \
				-nets "$vars(PWR)" \
				-over_power_domain 1 \
				-layer 6 \
				-direction $vars(m6_direction) \
				-start_x $vars(core_x1) \
				-stop_x $vars(core_x2) \
				-start_y $vars(m6mem_start) \
				-stop_y $vars(core_y2) \
				-width $vars(addm6_width) \
				-spacing [expr $vars(addm6_pitch) - $vars(addm6_width)] \
				-set_to_set_distance $vars(addm6_step) \
				-break_stripes_at_block_rings 0 \
				-merge_stripes_value 1 \
				-max_same_layer_jog_length 0 \
				-padcore_ring_top_layer_limit 7 \
				-padcore_ring_bottom_layer_limit 5 \
				-block_ring_top_layer_limit 7 \
				-block_ring_bottom_layer_limit 5 \
				-stacked_via_top_layer 7 \
				-stacked_via_bottom_layer 5 \
				-uda MemAddM6
#		}
	}
	deselectAll
}
