proc userCreatePgOverClamp_T28HPC {xhalo yhalo pwr_net gnd_net} {
#	deselectAll
	addHaloToBlock -cell PCLAMPEC_V_G $xhalo $yhalo $xhalo $yhalo
	addHaloToBlock -cell PCLAMPEC_H_G $xhalo $yhalo $xhalo $yhalo
	addHaloToBlock -cell PCLAMPE_G $xhalo $yhalo $xhalo $yhalo
#	globalNetConnect VDD -pin VDD11_CP -type pgpin -override
#	globalNetConnect VSS -pin VSS_CP -type pgpin -override
#	selectInstByCellName VDD1CE
#	selectInstByCellName VDD2CEN 
	set clamp_inst [dbGet selected.name]
	deselectAll
	foreach inst $clamp_inst {
		deselectAll
		selectInst $inst 
		set ori [dbGet selected.orient]
		set cell_name [dbGet selected.cell.name]
		set loc_x [dbGet selected.pt_x]
		set loc_y [dbGet selected.pt_y]
		setAddStripeMode -skip_via_on_pin {pad cover standardcell physicalpin block} -skip_via_on_wire_shape {stripe}
		puts "$ori"
		 if { $ori == "R0" || $ori == "MY" || $ori == "MX" || $ori == "R180"  } { 
			set box_list [dbGet [dbGet -p2 [dbGet -p2 selected.pgInstTerms.net.name $pwr_net].term.pins.layerShapeShapes.layer.name M3].shapes.rect]
			puts "$box_list"
			foreach box $box_list {
                		set llx_0 [lindex $box 0]
             			set lly_0 [lindex $box 1]
       				set urx_0 [lindex $box 2]
         		        set ury_0 [lindex $box 3]
				set global_cor [dbTransform -inst $inst -localPt "$llx_0 $lly_0 $urx_0 $ury_0"]
                		set llx [lindex $global_cor 0]
             			set lly [lindex $global_cor 1]
       				set urx [lindex $global_cor 2]
         		        set ury [lindex $global_cor 3]
				puts "$llx $lly $urx $ury"
				
				### note 15 num,please modfiy it if clamp change
				if { [expr $urx -$llx] > 15 } {
					set width [expr  int([expr ($ury-$lly) *100])/100.0]
					addStripe -start_offset 0 -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M4 -block_ring_top_layer_limit M4 -padcore_ring_top_layer_limit M4 -padcore_ring_bottom_layer_limit M4 -direction horizontal -layer M4 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly  [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0 -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M5 -block_ring_top_layer_limit M5 -padcore_ring_top_layer_limit M5 -padcore_ring_bottom_layer_limit M5 -direction horizontal -layer M5 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly  [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0 -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M6 -block_ring_top_layer_limit M6 -padcore_ring_top_layer_limit M6 -padcore_ring_bottom_layer_limit M6 -direction horizontal -layer M6 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly  [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0 -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M7 -block_ring_top_layer_limit M7 -padcore_ring_top_layer_limit M7 -padcore_ring_bottom_layer_limit M7 -direction horizontal -layer M7 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly  [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0 -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M8 -block_ring_top_layer_limit M8 -padcore_ring_top_layer_limit M7 -padcore_ring_bottom_layer_limit M8 -direction horizontal -layer M8 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly  [expr $urx + 18 ] $ury" -start_from left
				} else {
					set width [expr  int([expr ($urx-$llx) *100])/100.0]
					addStripe -start_offset 0 -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M4 -block_ring_top_layer_limit M4 -padcore_ring_top_layer_limit M4 -padcore_ring_bottom_layer_limit M4  -direction vertical -layer M4 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
					addStripe -start_offset 0 -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M5 -block_ring_top_layer_limit M5 -padcore_ring_top_layer_limit M5 -padcore_ring_bottom_layer_limit M5  -direction vertical -layer M5 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
					addStripe -start_offset 0 -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M6 -block_ring_top_layer_limit M6 -padcore_ring_top_layer_limit M6 -padcore_ring_bottom_layer_limit M6  -direction vertical -layer M6 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
					addStripe -start_offset 0 -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M7 -block_ring_top_layer_limit M7 -padcore_ring_top_layer_limit M7 -padcore_ring_bottom_layer_limit M7  -direction vertical -layer M7 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
				}
			}
			set box_list [dbGet [dbGet -p2 [dbGet -p2 selected.pgInstTerms.net.name $gnd_net].term.pins.layerShapeShapes.layer.name M3].shapes.rect]
			foreach box $box_list {
                		set llx_0 [lindex $box 0]
             			set lly_0 [lindex $box 1]
       				set urx_0 [lindex $box 2]
         		        set ury_0 [lindex $box 3]
				set global_cor [dbTransform -inst $inst -localPt "$llx_0 $lly_0 $urx_0 $ury_0"]
                		set llx [lindex $global_cor 0]
             			set lly [lindex $global_cor 1]
       				set urx [lindex $global_cor 2]
         		        set ury [lindex $global_cor 3]
				set width [expr  int([expr ($ury-$lly) *100])/100.0]
				### note 15 num,please modfiy it if clamp change
				if { [expr $urx -$llx] > 15 } {
					set width [expr  int([expr ($ury-$lly) *100])/100.0]
					addStripe -start_offset 0  -width $width -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M4 -block_ring_top_layer_limit M4 -padcore_ring_top_layer_limit M4 -padcore_ring_bottom_layer_limit M4 -direction horizontal -layer M4 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0  -width $width -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M5 -block_ring_top_layer_limit M5 -padcore_ring_top_layer_limit M5 -padcore_ring_bottom_layer_limit M5 -direction horizontal -layer M5 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0  -width $width -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M6 -block_ring_top_layer_limit M6 -padcore_ring_top_layer_limit M6 -padcore_ring_bottom_layer_limit M6 -direction horizontal -layer M6 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0  -width $width -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M7 -block_ring_top_layer_limit M7 -padcore_ring_top_layer_limit M7 -padcore_ring_bottom_layer_limit M7 -direction horizontal -layer M7 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0  -width $width -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M8 -block_ring_top_layer_limit M8 -padcore_ring_top_layer_limit M8 -padcore_ring_bottom_layer_limit M8 -direction horizontal -layer M8 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly [expr $urx + 18 ] $ury" -start_from left
				} else {
					set width [expr  int([expr ($urx-$llx) *100])/100.0]
					addStripe -start_offset 0 -width $width -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M4 -block_ring_top_layer_limit M4 -padcore_ring_top_layer_limit M4 -padcore_ring_bottom_layer_limit M4  -direction vertical -layer M4 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
					addStripe -start_offset 0 -width $width -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M5 -block_ring_top_layer_limit M5 -padcore_ring_top_layer_limit M5 -padcore_ring_bottom_layer_limit M5  -direction vertical -layer M5 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
					addStripe -start_offset 0 -width $width -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M6 -block_ring_top_layer_limit M6 -padcore_ring_top_layer_limit M6 -padcore_ring_bottom_layer_limit M6  -direction vertical -layer M6 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
					addStripe -start_offset 0 -width $width -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M7 -block_ring_top_layer_limit M7 -padcore_ring_top_layer_limit M7 -padcore_ring_bottom_layer_limit M7  -direction vertical -layer M7 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
				}
			}
		} else {
			set box_list [dbGet [dbGet -p2 [dbGet -p2 selected.pgInstTerms.net.name $pwr_net].term.pins.layerShapeShapes.layer.name M3].shapes.rect]
			foreach box $box_list {
                		set llx_0 [lindex $box 0]
             			set lly_0 [lindex $box 1]
       				set urx_0 [lindex $box 2]
         		        set ury_0 [lindex $box 3]
				set global_cor [dbTransform -inst $inst -localPt "$llx_0 $lly_0 $urx_0 $ury_0"]
                		set llx [lindex $global_cor 0]
             			set lly [lindex $global_cor 1]
       				set urx [lindex $global_cor 2]
         		        set ury [lindex $global_cor 3]
				set width [expr  int([expr ($urx-$llx) *100])/100.0]
				### note 15 num,please modfiy it if clamp change
				if { [expr $ury -$lly] > 15 } {
					set width [expr  int([expr ($ury-$lly) *100])/100.0]
					addStripe -start_offset 0 -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M4 -block_ring_top_layer_limit M4 -padcore_ring_top_layer_limit M4 -padcore_ring_bottom_layer_limit M4  -direction vertical -layer M4 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
					addStripe -start_offset 0 -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M5 -block_ring_top_layer_limit M5 -padcore_ring_top_layer_limit M5 -padcore_ring_bottom_layer_limit M5  -direction vertical -layer M5 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
					addStripe -start_offset 0 -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M6 -block_ring_top_layer_limit M6 -padcore_ring_top_layer_limit M6 -padcore_ring_bottom_layer_limit M6  -direction vertical -layer M6 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
					addStripe -start_offset 0 -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M7 -block_ring_top_layer_limit M7 -padcore_ring_top_layer_limit M7 -padcore_ring_bottom_layer_limit M7  -direction vertical -layer M7 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
				} else {
					set width [expr  int([expr ($urx-$llx) *100])/100.0]
					addStripe -start_offset 0  -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M4 -block_ring_top_layer_limit M4 -padcore_ring_top_layer_limit M4 -padcore_ring_bottom_layer_limit M4 -direction horizontal -layer M4 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0  -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M5 -block_ring_top_layer_limit M5 -padcore_ring_top_layer_limit M5 -padcore_ring_bottom_layer_limit M5 -direction horizontal -layer M5 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0  -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M6 -block_ring_top_layer_limit M6 -padcore_ring_top_layer_limit M6 -padcore_ring_bottom_layer_limit M6 -direction horizontal -layer M6 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0  -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M7 -block_ring_top_layer_limit M7 -padcore_ring_top_layer_limit M7 -padcore_ring_bottom_layer_limit M7 -direction horizontal -layer M7 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0  -width $width -nets $pwr_net -uda clamp_power -block_ring_bottom_layer_limit M8 -block_ring_top_layer_limit M8 -padcore_ring_top_layer_limit M8 -padcore_ring_bottom_layer_limit M8 -direction horizontal -layer M8 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly [expr $urx + 18 ] $ury" -start_from left
				}
			}
			set box_list [dbGet [dbGet -p2 [dbGet -p2 selected.pgInstTerms.net.name $gnd_net].term.pins.layerShapeShapes.layer.name M3].shapes.rect]
			foreach box $box_list {
                		set llx_0 [lindex $box 0]
             			set lly_0 [lindex $box 1]
       				set urx_0 [lindex $box 2]
         		        set ury_0 [lindex $box 3]
				set global_cor [dbTransform -inst $inst -localPt "$llx_0 $lly_0 $urx_0 $ury_0"]
                		set llx [lindex $global_cor 0]
             			set lly [lindex $global_cor 1]
       				set urx [lindex $global_cor 2]
         		        set ury [lindex $global_cor 3]
				set width [expr  int([expr ($urx-$llx) *100])/100.0]
				### note 15 num,please modfiy it if clamp change
				if { [expr $ury -$lly] > 15 } {
					set width [expr  int([expr ($ury-$lly) *100])/100.0]
					addStripe -start_offset 0  -width $width  -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M4 -block_ring_top_layer_limit M4 -padcore_ring_top_layer_limit M4 -padcore_ring_bottom_layer_limit M4  -direction vertical -layer M4 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
					addStripe -start_offset 0  -width $width  -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M5 -block_ring_top_layer_limit M5 -padcore_ring_top_layer_limit M5 -padcore_ring_bottom_layer_limit M5  -direction vertical -layer M5 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
					addStripe -start_offset 0  -width $width  -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M6 -block_ring_top_layer_limit M6 -padcore_ring_top_layer_limit M6 -padcore_ring_bottom_layer_limit M6  -direction vertical -layer M6 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
					addStripe -start_offset 0  -width $width  -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M7 -block_ring_top_layer_limit M7 -padcore_ring_top_layer_limit M7 -padcore_ring_bottom_layer_limit M7  -direction vertical -layer M7 -set_to_set_distance 6000 -area "$llx [expr $lly - 18 ] $urx [expr $ury + 18 ]" -start_from bottom
				} else {
					set width [expr  int([expr ($urx-$llx) *100])/100.0]
					addStripe -start_offset 0  -width $width -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M4 -block_ring_top_layer_limit M4 -padcore_ring_top_layer_limit M4 -padcore_ring_bottom_layer_limit M4 -direction horizontal -layer M4 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0  -width $width -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M5 -block_ring_top_layer_limit M5 -padcore_ring_top_layer_limit M5 -padcore_ring_bottom_layer_limit M5 -direction horizontal -layer M5 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0  -width $width -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M6 -block_ring_top_layer_limit M6 -padcore_ring_top_layer_limit M6 -padcore_ring_bottom_layer_limit M6 -direction horizontal -layer M6 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0  -width $width -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M7 -block_ring_top_layer_limit M7 -padcore_ring_top_layer_limit M7 -padcore_ring_bottom_layer_limit M7 -direction horizontal -layer M7 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly [expr $urx + 18 ] $ury" -start_from left
					addStripe -start_offset 0  -width $width -nets $gnd_net -uda clamp_power -block_ring_bottom_layer_limit M8 -block_ring_top_layer_limit M8 -padcore_ring_top_layer_limit M8 -padcore_ring_bottom_layer_limit M8 -direction horizontal -layer M8 -set_to_set_distance 6000 -area "[expr $llx - 18 ] $lly [expr $urx + 18 ] $ury" -start_from left
				}
			}
		}
	}
	deselectAll
	editSelect -subclass clamp_power
	editPowerVia -between_selected_wires 1 -via_scale_height 90 -via_scale_width 90  -split_vias 1 -top_layer M8 -bottom_layer M3 -uda clamp_via -orthogonal_only false -add_vias 1 -via_using_exact_crossover_size 1
	deselectAll
#	selectInstByCellName VDD1CE
#	selectInstByCellName VDD2CEN 
#	editPowerVia -selected_blocks 1 -via_scale_height 80 -via_scale_width 80 -split_vias 1 -top_layer M4 -bottom_layer M3 -uda clamp_via -orthogonal_only false -add_vias 1 -via_using_exact_crossover_size 1
#	set clamp_inst [dbGet selected.name]
#	deselectAll
	foreach inst $clamp_inst {
		deselectAll
		selectInst $inst 
		editPowerVia -selected_blocks 1 -via_scale_height 90 -via_scale_width 90 -split_vias 1 -top_layer M4 -bottom_layer M3 -uda clamp_via -orthogonal_only false -add_vias 1 -via_using_exact_crossover_size 1
		set llx [dbGet selected.phaloBox_llx]
		set lly [dbGet selected.phaloBox_lly]
		set urx [dbGet selected.phaloBox_urx]
		set ury [dbGet selected.phaloBox_ury]
		set cell_name [dbGet selected.cell.name]
		if { ![ regexp _H_G $cell_name ] } {
			addStripe -start_offset 0  -width 4.0 -nets "$pwr_net $gnd_net" -spacing 1 -uda clamp_power -block_ring_bottom_layer_limit M8 -block_ring_top_layer_limit M8 -padcore_ring_top_layer_limit M8 -padcore_ring_bottom_layer_limit M8 -direction horizontal -layer M8 -set_to_set_distance 10  -area "[expr $llx - 0.5 ] [expr $lly + 0.6] [expr $urx - 0.5 ] [expr $ury -0.6 ]" -start_from left
		}
		editPowerVia -via_scale_height 90 -via_scale_width 90  -split_vias 1 -top_layer M9 -bottom_layer M8 -uda clamp_via -orthogonal_only true -add_vias 1 -via_using_exact_crossover_size 1 -area "$llx $lly $urx  $ury "
		editPowerVia -via_scale_height 90 -via_scale_width 90  -split_vias 1 -top_layer M8 -bottom_layer M7 -uda clamp_via -orthogonal_only true -add_vias 1 -via_using_exact_crossover_size 1 -area "$llx $lly $urx  $ury "
		createRouteBlk -box "[expr $llx + 1.5] [expr $lly + 1.5] [expr $urx - 1.5] [expr  $ury - 1.5 ]" -name clamp_routblk -layer "M1 M2 M3 M4 M5 M6 M7 M8"
	}
		
	deselectAll

	
}
