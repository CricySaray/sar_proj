foreach domain  [dbGet [dbGet top.pds.isPowerDomainMacroOnly 0 -p].name] {
	modifyPowerDomainAttr $domain -minGaps 1.2 1.2 1.2 1.2
}


