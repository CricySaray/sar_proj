proc add_m7 {} {
	global vars
	
	setAddStripeMode \
		-allow_jog none \
		-ignore_DRC true \
		-skip_via_on_pin {pad block cover standardcell physicalpin} \
		-skip_via_on_wire_shape {blockring stripe followpin corewire blockwire iowire padring ring fillwire noshape} \
		-ignore_nondefault_domains true

	set cmd "addStripe \
							-nets {$vars(power_nets) $vars(gnd_nets)} \
							-create_pins 0 \
							-layer ME7 \
							-direction vertical \
							-start_from left \
							-start_offset $vars(m7_offset_left) \
							-width $vars(m7_width) \
							-spacing $vars(m7_spacing) \
							-set_to_set_distance $vars(m7_set_set_distance) \
							-break_stripes_at_block_rings 0 \
							-merge_stripes_value 1 \
							-max_same_layer_jog_length 0 \
							-uda global_m7 \
							-block_ring_bottom_layer_limit ME7 \
							-block_ring_top_layer_limit ME7 \
							-padcore_ring_bottom_layer_limit ME7 \
							-padcore_ring_top_layer_limit ME7"
	eval $cmd
}
