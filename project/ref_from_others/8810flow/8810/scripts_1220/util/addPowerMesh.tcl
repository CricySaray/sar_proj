##
setAddStripeMode -skip_via_on_pin {pad block cover standardcell physicalpin}
setAddStripeMode -stripe_min_length 0
setAddStripeMode -ignore_nondefault_domains 1
setAddStripeMode -use_exact_spacing true
setAddStripeMode -use_point2point_router false

set vars(PWR) VDD
set vars(GND) VSS
set vars(core_x1) 0
set vars(core_x2) 0
set vars(core_y1) 0
set vars(core_y2) 0
set vars(m5_width) 
set vars(m5_pitch) 
set vars(m5_step)
set vars(m5_direction) 

		addStripe \
			-nets "$vars(PWR) $vars(GND)" \
			-over_power_domain 0 \
			-layer 5 \
			-direction $vars(m5_direction) \
			-start_x $vars(core_x1) \
			-stop_x $vars(core_x2) \
			-start_y $vars(core_y1) \
			-stop_y $vars(core_y2) \
			-width $vars(m5_width) \
			-spacing [expr $vars(m5_pitch) - $vars(m5_width)] \
			-set_to_set_distance $vars(m5_step) \
			-break_stripes_at_block_rings 0 \
			-merge_stripes_value 1 \
			-max_same_layer_jog_length 0 \
			-padcore_ring_top_layer_limit 6 \
			-padcore_ring_bottom_layer_limit 1 \
			-block_ring_top_layer_limit 6 \
			-block_ring_bottom_layer_limit 1 \
			-stacked_via_top_layer 6 \
			-stacked_via_bottom_layer 1 \
			-uda GlobalM5
	deselectAll
