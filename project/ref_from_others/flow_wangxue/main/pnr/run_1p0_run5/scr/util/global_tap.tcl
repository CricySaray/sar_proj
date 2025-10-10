foreach domain {PD_AON_SLP PD_AON} {
	set power_net [dbGet [dbGet top.pds.name $domain -p].primaryPowerNet.name]
	set ground_net [dbGet [dbGet top.pds.name $domain -p].primaryGroundNet.name]
	set insts [dbGet [dbGet [dbGet [dbQuery -objType inst -areas [join [dbGet [dbGet top.pds.name $domain -p].group.boxes]]].cell.name TAP* -p2].pgInstTerms.net.name $power_net -v -p3].name]
 		foreach inst $insts {                                                                                                                                                                     
			globalNetConnect $power_net -pin VDD -type pgpin -singleInstance $inst -override 
			globalNetConnect $ground_net -pin VSS -type pgpin -singleInstance $inst -override 
		}
}

