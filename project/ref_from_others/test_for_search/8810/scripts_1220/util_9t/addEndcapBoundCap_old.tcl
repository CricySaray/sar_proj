proc invsAddEnd {} {
	global vars
	deselectAll
	set vars(cap_prefix) ENDCAP
	deleteFiller -prefix $vars(cap_prefix)

	#add endcap cells surrounding va and block boundary
	setEndCapMode -reset
	setEndCapMode -boundary_tap false
	setEndCapMode -fitGap true ; #1x endcap fix
	if {[regexp {^SMIC} $vars(library)] || [regexp {ARM} $vars(library)]} { 
		setEndCapMode -prefix $vars(cap_prefix) \
			-topEdge "$vars(welltap_cell) FILL2_A9PP140ZTS_C35 FILL3_A9PP140ZTS_C35 FILL4_A9PP140ZTS_C35" \
			-bottomEdge "$vars(welltap_cell) FILL2_A9PP140ZTS_C35 FILL3_A9PP140ZTS_C35 FILL4_A9PP140ZTS_C35" \
			-leftedge $vars(endcap_cell)  \
			-rightedge $vars(endcap_cell) \
			-leftbottomcorner $vars(endcap_cell) \
			-leftbottomedge $vars(endcap_cell) \
			-lefttopcorner $vars(endcap_cell) \
			-lefttopedge $vars(endcap_cell) \
			-rightbottomcorner $vars(endcap_cell) \
			-rightbottomedge $vars(endcap_cell) \
			-righttopcorner $vars(endcap_cell) \
			-righttopedge $vars(endcap_cell) \
	} else {
		setEndCapMode -prefix $vars(cap_prefix) \
			-topEdge "$vars(welltap_cell) FILL3BWP7T35P140 FILL2BWP7T35P140" \
			-bottomEdge "$vars(welltap_cell) FILL3BWP7T35P140 FILL2BWP7T35P140" \
			-leftedge $vars(postcap_cell) \
			-rightedge $vars(precap_cell)  \
			-leftbottomcorner $vars(postcap_cell) \
			-leftbottomedge $vars(postcap_cell) \
			-lefttopcorner $vars(postcap_cell) \
			-lefttopedge $vars(postcap_cell) \
			-rightbottomcorner $vars(precap_cell) \
			-rightbottomedge $vars(precap_cell) \
			-righttopcorner $vars(precap_cell)  \
	}
	set_well_tap_mode -bottom_tap_cell $vars(welltap_cell)  -top_tap_cell $vars(welltap_cell) -rule 58
	if {$vars(lp_mode) == "true"} {
		set vars(power_domains) [userGetPowerDomains]
		foreach domain $vars(power_domains) {
			if {[dbPowerDomainNrInst [dbGetPowerDomainByName $domain]] > 0} {

				addEndCap -powerDomain $domain -prefix ${domain}_$vars(cap_prefix)	

			}
		}
	} else  {
		addEndCap
	}
}
