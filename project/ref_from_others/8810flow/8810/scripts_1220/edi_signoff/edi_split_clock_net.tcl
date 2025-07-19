####################################################################
#usage : edi_split_clock_net $clocknets $cell filename
#
#clock cell :BUF_X4B_A7PP140ZTL_C30 BUF_X4B_A9PP140ZTL_C30
#
#data  cell :BUF_X4B_A7PP140ZTS_C30 BUF_X4B_A9PP140ZTS_C30
####################################################################

proc edi_split_clock_net {clock_net_list buffer_cell_name filename} {
	echo "setEcoMode -reset" >> $filename
	echo "setEcoMode  -updateTiming false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false -LEQCheck true -refinePlace false -batchMode  true" >> $filename
	foreach tmp_clock_net_list $clock_net_list {
		deselectAll
		selectNet $tmp_clock_net_list
		set max_wire_length 0
		foreach tmp_box [dbGet selected.wires.box] {
			set tmp_length [expr abs([lindex $tmp_box 0] - [lindex $tmp_box 2]) + abs([lindex $tmp_box 1] - [lindex $tmp_box 3])]
			if {$tmp_length > $max_wire_length} {
				set max_length_wire_box $tmp_box
				set max_wire_length $tmp_length
			}
		}
		echo $max_length_wire_box
		set pt "[expr ([lindex $max_length_wire_box 0] + [lindex $max_length_wire_box 2])/2] [expr ([lindex $max_length_wire_box 1] + [lindex $max_length_wire_box 3])/2]"
		echo "ecoAddRepeater -net $tmp_clock_net_list -cell $buffer_cell_name -offLoadAtLoc \{ $pt \}"  >> $filename
}
	echo "setEcoMode -reset"  >> $filename
}
