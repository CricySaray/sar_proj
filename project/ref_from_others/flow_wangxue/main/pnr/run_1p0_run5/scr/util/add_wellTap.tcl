setDesignMode -addPhysicalCell flat
foreach i [dbGet [dbGet top.pds.isPowerDomainMacroOnly 0 -p].name] {
	addWellTap -cell $vars(tap_cell) -cellInterval 116 -fixedGap -prefix WELLTAP_ -checkerBoard -check_channel -powerDomain $i
}

