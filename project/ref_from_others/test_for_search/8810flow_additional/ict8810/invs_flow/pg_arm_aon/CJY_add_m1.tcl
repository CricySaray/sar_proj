proc copy_net {args} {
	global vars
	set help "false"
	foreach arg $args {
		incr index
		switch $arg {
			"-ori_layer" {set ori_layer [lindex $args $index]}
			"-new_layer" {set new_layer [lindex $args $index]}
			"-new_layer_width" {set new_layer_width [lindex $args $index]}
			"-net" {set net [lindex $args $index]}
			"-help" {set help "true" }
		}
	}

	if { $help == "true" } {
		puts "Usage : copy net to the specify layer!"
		puts "Example:"
		puts "	copy_net -ori_layer M1 -new_layer M2 -new_layer_width 0.1 -net VDD" 
	} else {
		setEditMode -drc_on 0 -create_crossover_vias false -create_via_on_pin false -layer_maximum M2
		deselectAll	
		editSelect -layer $ori_layer -shape FOLLOWPIN -net $net -subclass ${ori_layer}_follow_pin
		editDuplicate -layer_horizontal $new_layer -layer_vertical $new_layer
		deselectAll
		editSelect -layer $new_layer -shape FOLLOWPIN -net $net -subclass ${ori_layer}_follow_pin
    dbSet selected.userClass ${new_layer}_follow_pin
		editChangeWidth -width_horizontal $new_layer_width -width_vertical $new_layer_width
		deselectAll
		setEditMode -reset
	}
}
