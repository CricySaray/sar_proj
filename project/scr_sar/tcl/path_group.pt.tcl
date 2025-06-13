set allSeqs [all_registers]
set macros [get_object_name [get_cells -quiet -hierarchical -filter "is_black_box"]]

#set mems [get_cells -quiet -hierarchical -filter "is_memory_cell"]
#set ips [get_cells -quiet -hierarchical -filter "is_black_box"]
#set ips [get_cells -quiet -hierarchical -filter "is_black_box && @ref_name !~ TS*"]

set mems ""; set ips ""
foreach m $macros {
	if {[regexp TS $m]} {
		lappend mems $m
	} else {
		lappend ips $m
	}
}

set regs_and_icgs $allSeqs
if {"" != $mems} {set regs_and_icgs [remove_from_collection $regs_and_icgs [get_cells $mems]]}
if {"" != $ips} {set regs_and_icgs [remove_from_collection $regs_and_icgs [get_cells $ips]]}

set icgs [filter_collection $regs_and_icgs "is_integrated_clock_gating_cell"]
#set regs [remove_from_collection [all_registers -edge_triggered] $icgs]
set regs [remove_from_collection $regs_and_icgs $icgs]
set inPorts [all_inputs -exclude_clock_ports]
set outPorts [all_outputs]

remove_path_group -all

group_path -name i2r -from $inPorts -to $allSeqs
group_path -name r2o -from $allSeqs -to $outPorts
group_path -name i2o -from $inPorts -to $outPorts

group_path -name r2r -from $allSeqs -to $allSeqs
group_path -name r2g -from $regs -to $icgs

if {"" != $mems} {
	group_path -name r2m -from $regs_and_icgs -to $mems
	group_path -name m2g -from $mems -to $icgs
	group_path -name m2r -from $mems -to $regs
	group_path -name m2m -from $mems -to $mems
}

if {"" != $ips} {
	group_path -name r2p -from $regs_and_icgs -to $ips
	group_path -name p2r -from $ips           -to $regs_and_icgs
	group_path -name p2p -from $ips           -to $ips 
}
