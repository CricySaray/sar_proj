if {![regexp cpu [dbget top.name]]} {
	create_ccopt_skew_group -name group1 -balance_skew_groups {scan_clk/scan edt_clk/scan}
}
