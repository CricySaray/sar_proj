foreach_in_collection timing_path [get_timing_paths -delay_type min -slack_lesser_than 0 -max_paths 200000] {
	set min_slacks [get_attribute $timing_path slack]
	set endpoint [get_object_name [get_attribute $timing_path endpoint]]
	set endpoint_driver [get_object_name [get_pins [all_fanin -to $endpoint -flat -levels 1] -filter "pin_direction == out"]]
	echo "set_annotated_delay -from $endpoint_driver -to $endpoint [expr 0.002-$min_slacks] -net -increment" >> ./hold_check.tcl
}
foreach_in_collection timing_path [get_timing_paths -delay_type max -slack_lesser_than 0 -max_paths 200000] {
        set max_slacks [get_attribute $timing_path slack]
        set endpoint [get_object_name [get_attribute $timing_path endpoint]]
        set endpoint_driver [get_object_name [get_pins [all_fanin -to $endpoint -flat -levels 1] -filter "pin_direction == out"]]
        echo "set_annotated_delay -from $endpoint_driver -to $endpoint [expr 0.002-$max_slacks] -net -increment" >> ./setup_check.tcl
}

