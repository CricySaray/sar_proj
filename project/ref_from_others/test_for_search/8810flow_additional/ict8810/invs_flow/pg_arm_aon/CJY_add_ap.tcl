proc add_ap {} {
	global vars
	
	setAddStripeMode \
		-allow_jog none \
		-ignore_DRC true \
		-skip_via_on_pin {pad block cover standardcell physicalpin} \
		-skip_via_on_wire_shape {blockring stripe followpin corewire blockwire iowire padring ring fillwire noshape}

	set cmd "addStripe \
							-nets { $vars(power_nets) $vars(gnd_nets) } \
							-layer AL_RDL \
              -create_pins 0 \
							-direction vertical \
							-start_from left \
							-start_offset $vars(ap_offset_left) \
							-width $vars(ap_width) \
							-spacing $vars(ap_spacing) \
							-set_to_set_distance $vars(ap_set_set_distance) \
							-break_stripes_at_block_rings 0 \
							-merge_stripes_value 1 \
							-max_same_layer_jog_length 0 \
							-uda ap \
							-block_ring_bottom_layer_limit AL_RDL \
							-block_ring_top_layer_limit AL_RDL \
							-padcore_ring_bottom_layer_limit AL_RDL \
							-padcore_ring_top_layer_limit AL_RDL \
              -extend_to design_boundary \
							"
	eval $cmd
}
