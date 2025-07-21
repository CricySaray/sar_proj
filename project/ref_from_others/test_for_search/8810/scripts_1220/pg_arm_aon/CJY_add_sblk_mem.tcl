proc add_sblk_mem {args} {
	set width 10
	set help false
	
	foreach arg $args {
		incr index
		switch $arg {
			"-width" {set width [lindex $args $index]}
			"-help" {set help true}
		}
	}

	if { $help == true } {
		puts "Usage: you can use this command to add soft blockage around memory!"
		puts "eg: add_sblk_mem -width 20"
		puts "\n-help: 				get the help info!"
		puts "-width: 			add the specify width around the memory!"
	} else {
		set mem_box_list ""
		set mems [dbGet [dbGet top.insts.cell.baseClass block -p2].name]
		foreach mem $mems {
			set mem_box_list [dbShape [dbGet [dbGet -p top.insts.name $mem].box] OR $mem_box_list]
		}
		createPlaceBlockage -boxList [dbShape [dbShape [dbShape [dbShape [dbShape $mem_box_list SIZEX 20] SIZEX -20] SIZEY 20] SIZEY -20] SIZE ${width}] -type soft -name mem_sblk
	}
}
