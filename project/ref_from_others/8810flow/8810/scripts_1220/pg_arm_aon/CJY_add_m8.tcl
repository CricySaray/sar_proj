proc add_m8 {} {
	global vars
			
	setAddStripeMode \
		-allow_jog none \
		-ignore_DRC true \
		-skip_via_on_pin {pad block cover standardcell physicalpin} \
		-skip_via_on_wire_shape {blockring stripe followpin corewire blockwire iowire padring ring fillwire noshape} \
		-ignore_nondefault_domains true

	set cmd "addStripe \
							-nets {$vars(power_nets) $vars(gnd_nets)} \
							-create_pins 1 \
							-layer ME8 \
							-direction horizontal \
							-start_from top \
							-start_offset $vars(m8_offset_top) \
							-width $vars(m8_width) \
							-spacing $vars(m8_spacing) \
							-set_to_set_distance $vars(m8_set_set_distance) \
							-break_stripes_at_block_rings 0 \
							-merge_stripes_value 1 \
							-max_same_layer_jog_length 0 \
							-uda global_m8 \
							-block_ring_bottom_layer_limit ME8 \
							-block_ring_top_layer_limit ME8 \
							-padcore_ring_bottom_layer_limit ME8 \
							-padcore_ring_top_layer_limit ME8"
	eval $cmd
}
