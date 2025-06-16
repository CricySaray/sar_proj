######################################################
#add power stripes on synopsis memory
######################################################
# user guide : userAddMemPower M7 5 0.4
proc userAddMemPower {layer_name pitch net_width} {
	set lcpu [getMultiCpuUsage -localCpu]
	setMultiCpuUsage -localCpu 1
	set pitch $pitch
	set net_width $net_width
	set layer_name $layer_name
	foreach_in_collection instCol [get_cell -hier * -filter "is_memory_cell == true"] {
		set inst [get_object_name $instCol]
		set halo_box [dbget [dbget -p top.insts.name $inst].pHaloBox]
	#	set PD [getInstPowerDomain $inst]
		set pg_net [dbget [dbGetInstByName $inst].pgTermNets.name]
		set pg_net [dbget [dbGetInstByName $inst].pgTermNets.name]
		set pg_net "[lindex  $pg_net 0] [lindex  $pg_net 1]" 
		set x1 [lindex [lindex $halo_box 0] 0]
		set y1 [lindex [lindex $halo_box 0] 1]
		set x2 [lindex [lindex $halo_box 0] 2]
		set y2 [lindex [lindex $halo_box 0] 3]
		set x_halo [dbget [dbGetInstByName $inst].pHaloLeft]
		set xmax [expr $x2-$x_halo]
		set xmin [expr $x1-$x_halo]
		set spacing [expr {($pitch -2*$net_width)/2}]
		set width [expr $xmax - $xmin]
		set intger [expr int($width/$pitch)]
		if {[expr $width - $intger * $pitch ] < [expr $pitch/2] } {
			set num [expr $intger *2 -1 ]
		} else {
			set num [expr $intger *2 ]
		}
		set offset [expr ($width -$num*$pitch/2)/2]
		set cmd "addStripe -area \{$xmin $y1 $xmax $y2\} -nets \{$pg_net\} -block_ring_top_layer_limit $layer_name -max_same_layer_jog_length 4 -padcore_ring_bottom_layer_limit $layer_name -set_to_set_distance $pitch -stacked_via_top_layer $layer_name -padcore_ring_top_layer_limit $layer_name -spacing $spacing -xleft_offset $offset -merge_stripes_value 0.065 -layer $layer_name -block_ring_bottom_layer_limit $layer_name -width $net_width -stacked_via_bottom_layer $layer_name"
		eval $cmd
	}
	setMultiCpuUsage -localCpu $lcpu
}
