proc invsAddChannelM5 {} {
 	global vars
	set block_shapes [dbShape [dbget [dbGet top.insts.cell.subClass block -p2].box]]
	set shapes [dbShape [dbShape [dbget [dbGet top.insts.cell.subClass block -p2].box] SIZEX 20 SIZEY 5 ] SIZEX -20 -output rect ]
	set all_mem_shapes [dbShape [dbShape [dbget [dbGet top.insts.cell.subClass block -p2].box] SIZE 2] SIZEX -2 -output rect]
 	set all_mem_shapes_add  [dbShape $all_mem_shapes SIZEY 0.5 -output rect]	
	set core_shapes [dbShape [dbGet top.fplan.coreBox]]
#	set channel_shapes [dbShape $shapes ANDNOT $all_mem_shapes_add  -output rect]
	set mem_region_shape [dbShape [dbShape [dbShape [dbget [dbGet top.insts.cell.subClass block -p2].box] -output polygon] SIZEX 20 -output polygon] SIZEY 15 -output polygon]
	set mem_region_shape [dbShape [dbShape $mem_region_shape SIZEY -9.5 -output polygon]  AND $core_shapes -output polygon]
	
#
	set channel_shapes [dbShape [dbShape [dbShape $mem_region_shape ANDNOT $all_mem_shapes_add -output polygon ] SIZEY -10  -output polygon] SIZEY 10 -output rect]

foreach box $channel_shapes {
               addStripe \
                         -nets "VDD " \
                         -layer M5 \
                         -area $box \
                         -start_offset 4 \
                         -direction $vars(m5_direction) \
                         -width $vars(m5_width) \
                         -spacing 100 \
                         -set_to_set_distance $vars(m5_step) \
                         -merge_stripes_value 1 \
                         -max_same_layer_jog_length 0 \
                         -padcore_ring_top_layer_limit 6 \
                         -padcore_ring_bottom_layer_limit 4 \
                         -block_ring_top_layer_limit 6 \
                         -block_ring_bottom_layer_limit 2 \
                         -stacked_via_top_layer 6 \
                         -stacked_via_bottom_layer 2 \
                         -uda GlobalM7

   addStripe \
                         -nets "VSS " \
                         -layer M5 \
                         -area $box \
                         -start_offset 5 \
                         -direction $vars(m7_direction) \
                         -width $vars(m5_width) \
                         -spacing 100 \
                         -set_to_set_distance $vars(m5_step) \
                         -merge_stripes_value 1 \
                         -max_same_layer_jog_length 0 \
                         -padcore_ring_top_layer_limit 7 \
                         -padcore_ring_bottom_layer_limit 7 \
                         -block_ring_top_layer_limit 7 \
                         -block_ring_bottom_layer_limit 7 \
                         -stacked_via_top_layer 7 \
                         -stacked_via_bottom_layer 7 \
                         -uda GlobalM7
               addStripe \
                         -nets "VDD " \
                         -layer M5 \
                         -area $box \
                         -start_offset 15 \
                         -direction $vars(m5_direction) \
                         -width $vars(m5_width) \
                         -spacing 100 \
                         -set_to_set_distance $vars(m5_step) \
                         -merge_stripes_value 1 \
                         -max_same_layer_jog_length 0 \
                         -padcore_ring_top_layer_limit 7 \
                         -padcore_ring_bottom_layer_limit 7 \
                         -block_ring_top_layer_limit 7 \
                         -block_ring_bottom_layer_limit 7 \
                         -stacked_via_top_layer 7 \
                         -stacked_via_bottom_layer 7 \
                         -uda GlobalM7

   addStripe \
                         -nets "VSS " \
                         -layer M5 \
                         -area $box \
                         -start_offset 16 \
                         -direction $vars(m5_direction) \
                         -width $vars(m5_width) \
                         -spacing 100 \
                         -set_to_set_distance $vars(m5_step) \
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


foreach box $channel_shapes {

		createRouteBlk -layer M5 -box  $box  -name MEM_M5	
}

foreach box $all_mem_shapes {

#		createRouteBlk -layer M5 -box  $box  -name MEM_M5	
}

}
#
#deletePlaceBlockage *
#deleteRouteBlk -all
