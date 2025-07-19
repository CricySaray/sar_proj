proc invsAddM1 {} {
	global vars
	deselectAll
	if {$vars(cpf_file) != ""} {
		set vars(GND) [dbPowerDomainGNet [lindex $vars(power_domains) 0]]
		###add global ground net
		setSrouteMode -corePinJoinLimit 3
		sroute \
			-nets $vars(GND) \
			-connect {corePin} \
			-layerChangeRange {1 1} \
			-allowJogging 0 \
			-allowLayerChange 0 \
			-blockPinTarget {nearestTarget} \
			-crossoverViaLayerRange {1 1} \
			-targetViaLayerRange {1 1}
		setSrouteMode -corePinJoinLimit 0
		###add power net for all VA
		foreach domain $vars(power_domains) {
			if {[dbget [dbget top.pds.groups.name $domain -p2].isDefault] == 1} {
				set vars(AON_PWR) [dbPowerDomainPNet [dbGetPowerDomainByName $domain]] ""]
			}
		
		}
		foreach domain $vars(power_domains) {
			if {[dbget [dbget top.pds.groups.name $domain -p2].isDefault] == 1} {
				set vars(PWR) $vars(AON_PWR)
			} else {
				set vars(PWR) [regsub $vars(AON_PWR) [dbPowerDomainPNet $domain] ""]
			}
			sroute \
				-nets $vars(PWR) \
				-connect {corePin} \
				-layerChangeRange {1 1} \
				-allowJogging 0 \
				-allowLayerChange 0 \
				-blockPinTarget {nearestTarget} \
				-crossoverViaLayerRange {1 1} \
				-targetViaLayerRange {1 1} \
				-powerDomains $domain
		}
	} else {
		setSrouteMode -corePinJoinLimit 3
		sroute \
			-nets " $vars(pwer_nets)  $vars(gnd_nets)" \
			-connect {corePin} \
			-layerChangeRange {1 1} \
			-allowJogging 0 \
			-allowLayerChange 0 \
			-blockPinTarget {nearestTarget} \
			-crossoverViaLayerRange {1 1} \
			-targetViaLayerRange {1 1}
		setSrouteMode -corePinJoinLimit 0
	}
}
