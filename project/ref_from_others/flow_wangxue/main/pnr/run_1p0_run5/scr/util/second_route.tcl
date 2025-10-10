set nets {DVDD0P9_AON DVDD0P9_AON_SLP DVDD0P9_AON_IO}
foreach net $nets {
	setAttribute -skip_routing false -net $net
}
if {[dbGet top.insts.cell.name PT*] != 0x0} {
	set all_PT_cell [dbGet top.insts.cell.name PT* -u]
	foreach e_pt $all_PT_cell {
		setPGPinUseSignalRoute $e_pt:TVDD
	}
	routePGPinUseSignalRoute -nets $nets -maxFanout 10 -pattern trunk
}
if {[dbGet top.insts.cell.name HDR*] != 0x0} {
	set all_PT_cell [dbGet top.insts.cell.name HDR* -u]
	foreach e_pt $all_PT_cell {
		setPGPinUseSignalRoute $e_pt:TVDD
	}
	routePGPinUseSignalRoute -nets $nets -maxFanout 10 -pattern trunk
}
foreach net $nets {
	setAttribute -skip_routing true -net $net
}

