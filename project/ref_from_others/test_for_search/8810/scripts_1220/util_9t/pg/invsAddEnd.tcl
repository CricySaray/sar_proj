proc invsAddEnd {} {
	global vars
	deselectAll
	set vars(cap_prefix) ENDCAP
	deleteFiller -inst *$vars(cap_prefix)*

	#add endcap cells surrounding va and block boundary
	setEndCapMode -reset
	setEndCapMode -boundary_tap true
	setEndCapMode -fitGap true ; #1x endcap fix
	if {[regexp {^SMIC} $vars(library)] || [regexp {^ARM} $vars(library)]} { 
		setEndCapMode -prefix $vars(cap_prefix) \
			-topEdge "[lindex $vars(decap_cell) 0] F_FILLHD2 F_FILLHD1" \
			-bottomEdge "[lindex $vars(decap_cell) 0] F_FILLHD2 F_FILLHD1" \
			-leftedge $vars(precap_cell)  \
			-rightedge $vars(postcap_cell) \
			-leftbottomcorner $vars(precap_cell) \
			-leftbottomedge $vars(precap_cell) \
			-lefttopcorner $vars(precap_cell) \
			-lefttopedge $vars(precap_cell) \
			-rightbottomcorner $vars(postcap_cell) \
			-rightbottomedge $vars(postcap_cell) \
			-righttopcorner $vars(postcap_cell) \
			-righttopedge $vars(postcap_cell) \
	} else {
		setEndCapMode -prefix $vars(cap_prefix) \
			-topEdge $vars(welltap_cell)  \
			-bottomEdge $vars(welltap_cell) \
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
	set_well_tap_mode -bottom_tap_cell $vars(welltap_cell)  -top_tap_cell $vars(welltap_cell) -rule 30
	if {$vars(cpf_file) != ""} {
		foreach domain $vars(power_domains) {
			if {[dbPowerDomainNrInst [dbGetPowerDomainByName $domain]] > 0} {

				addEndCap -powerDomain $domain -prefix ${domain}_$vars(cap_prefix)	

			}
		}
	} else  {
		addEndCap
	}
}
