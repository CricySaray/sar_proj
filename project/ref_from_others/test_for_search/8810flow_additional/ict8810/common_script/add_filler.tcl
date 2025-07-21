proc userGetPowerDomains { } {
    set power_domains [list]
    dbForEachPowerDomain [dbgHead] pd {
        lappend power_domains [dbPowerDomainName $pd]
    }
    return $power_domains
}  
#--------------------------------------------------------
#insert filler cell
#--------------------------------------------------------
set prefix DCAP_FILL
if {$vars(lp_mode) == "true"} {
	set vars(power_domains) [userGetPowerDomains]
	foreach domain $vars(power_domains) {
		if {[dbPowerDomainNrInst [dbGetPowerDomainByName $domain]]>0 } {
			if {[info exists vars(decap_cell)]} {
				if { $vars(process) < 28 } {
					clearDrc
					set_verify_drc_mode -limit 1000000 -check_implant false
					setFillerMode -reset
					setFillerMode -corePrefix $prefix -core $vars(decap_cell) -add_fillers_with_drc false
					setFillerMode -verticalStackMaxLength 200 -verticalStackExceptionCell "$vars(filler1_cells) [dbget head.libCells.name TAPCELLBWP*] [dbget head.libCells.name BOUNDARY*]"
					addFiller -powerDomain $domain -doDRC true -fixVerticalStackMaxLengthViolation
				} else {
					setFillerMode -corePrefix $prefix -core $vars(decap_cell) -fitGap true -add_fillers_with_drc false
					addFiller -powerDomain $domain -doDRC true
				}
			}
		}
	}
} else {
	if { $vars(process) < 28 } {
		clearDrc
		set_verify_drc_mode -limit 1000000 -check_implant false
		setFillerMode -reset
		setFillerMode -corePrefix $prefix -core $vars(decap_cell) -add_fillers_with_drc false
		setFillerMode -verticalStackMaxLength 200 -verticalStackExceptionCell "$vars(filler1_cells) [dbget head.libCells.name TAPCELLBWP*] [dbget head.libCells.name BOUNDARY*]"
		addFiller -doDRC true -fixVerticalStackMaxLengthViolation
	} else {
		setFillerMode -corePrefix $prefix -core $vars(decap_cell) -fitGap false -add_fillers_with_drc false
		addFiller -doDRC true
	}
}

set prefix FILL
if {[info exists vars(lp_mode)] && $vars(lp_mode) =="true"} {
	set vars(power_domains) [userGetPowerDomains]
	foreach domain $vars(power_domains) {
		if {[dbPowerDomainNrInst [dbGetPowerDomainByName $domain]]>0 } {
			if {[info exists vars(filler_cells)]} {
				if { $vars(process) < 28 } {
					clearDrc
					set_verify_drc_mode -limit 1000000 -check_implant false
					setFillerMode -reset
					setFillerMode -corePrefix $prefix -core $vars(filler_cells)
					setFillerMode -verticalStackMaxLength 200 -verticalStackExceptionCell "$vars(filler1_cells) [dbget head.libCells.name TAPCELLBWP*] [dbget head.libCells.name BOUNDARY*]"
					addFiller -powerDomain $domain -doDRC false -fixVerticalStackMaxLengthViolation
				} else {
					setFillerMode -corePrefix $prefix -core $vars(filler_cells) -fitGap true
					addFiller -powerDomain $domain -doDRC false
				}
			}
		}
	}
} elseif {[info exists vars(filler_cells)]} {
	if { $vars(process) < 28 } {
		clearDrc
		set_verify_drc_mode -limit 1000000 -check_implant false
		setFillerMode -reset
		setFillerMode -corePrefix $prefix -core $vars(filler_cells)
		setFillerMode -verticalStackMaxLength 200 -verticalStackExceptionCell "$vars(filler1_cells) [dbget head.libCells.name TAPCELLBWP*] [dbget head.libCells.name BOUNDARY*]"
		addFiller -powerDomain $domain -doDRC true -fixVerticalStackMaxLengthViolation
		addFiller -doDRC false -fixVerticalStackMaxLengthViolation
	} else {
		setFillerMode -corePrefix $prefix -core $vars(filler_cells) -fitGap true
		addFiller -powerDomain $domain -doDRC true
		addFiller -doDRC false
	}
}

## globalconnect for vstack_postfix _inst,abug of edi
if {$vars(process) < 28 } {
	if { [userGetPowerDomains] == " " } {
		foreach instName [dbget top.insts.name *VSTACK_POST_*] {
			set instPtr [dbGetInstByName $instName]
			set pwrPin [dbget [dbget -p1 ${instPtr}.cell.pgTerms.type powerTerm].name]
			set gndPin [dbget [dbget -p1 ${instPtr}.cell.pgTerms.type groundTerm].name]
			globalNetConnect $vars(pwr_nets) -override -pin $pwrPin -singleInstance $instName -type pgpin
			globalNetConnect $vars(gnd_nets) -override -pin $gndPin -singleInstance $instName -type pgpin
		}
	} else {
		dbForEachPowerDomain [dbgHead] pd {
			set pdName [dbget ${pd}.name]
			if {[dbPowerDomainNrInst $pd] > 0 } {
				set n($pdName) "$CPF::pd_intnets($pdName,power) $CPF::pd_intnets($pdName,ground)"
			}
		}
		foreach instName [dbget top.insts.name *VSTACK_POST_*] {
			set instDom [getInstPowerDomain $instName]
			set instPtr [dbGetInstByName $instName]
			set pwrPin [dbget [dbget -p1 ${instPtr}.cell.pgTerms.type powerTerm].name]
			set gndPin [dbget [dbget -p1 ${instPtr}.cell.pgTerms.type groundTerm].name]
			globalNetConnect [lindex $n($instDom) 0] -override -pin $pwrPin -singleInstance $instName -type pgpin
			globalNetConnect [lindex $n($instDom) 1] -override -pin $gndPin -singleInstance $instName -type pgpin
	
		}
	}
}

checkPlace
if {$vars(process) < 28 } {
	checkFiller -verticalStackMaxLength
} else {
	checkFiller -reportGap [expr $vars(min_gap)/2]
}

saveDesign $vars(dbs_dir)/[dbgDesignName].filler.enc -compress
