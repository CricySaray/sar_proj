proc add_m2 {} {
	global vars
	deselectAll
	setSrouteMode -corePinJoinLimit 3
	sroute \
		-nets " $vars(power_nets)  $vars(gnd_nets)" \
		-connect {corePin} \
		-layerChangeRange {2 2} \
		-allowJogging 0 \
		-allowLayerChange 0 \
		-blockPinTarget {nearestTarget} \
		-crossoverViaLayerRange {2 2} \
        -uda ME2_follow_pin \
		-targetViaLayerRange {2 2}
		setSrouteMode -corePinJoinLimit 0
    deselectAll
}
#    if {[regexp {ddr|pcie|dp_ocb|mge} [dbGet top.name]]} {
#	} else {
#    		editSelect -type Special -layer ME2 -shape FOLLOWPIN -subclass ME2_follow_pin
#		editDuplicate -layer_horizontal ME1 -layer_vertical ME1
#		deselectAll
#		editSelect -type Special -layer ME1 -shape FOLLOWPIN -subclass ME2_follow_pin
#    editStretch y -0.04 high -no_conn
#    editStretch y 0.04 low -no_conn
#		dbSet selected.userClass ME1_follow_pin
#		deselectAll
#	}
