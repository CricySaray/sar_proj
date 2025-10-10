setEcoMode -reset
setEcoMode -honorDontTouch false -honorDontUse false -honorFixedStatus false -refinePlace false -updateTiming false -batchMode true -honorPowerIntent false
foreach inst [dbGet [dbGet top.insts.isPhysOnly -p 0].name u_aon_top/* -p] {
        set cell_name [dbGet $inst.cell.name]
	set inst_name [dbGet $inst.name]
        if {[regexp {.*35P140$} $cell_name]} {
        	set cell [string replace $cell_name end-5 end "40P140HVT"]
		set yesor [dbGet head.libCells.name $cell]
		if {$yesor != 0x0} {
			ecoChangeCell -inst $inst_name -cell $cell
		} else {
			echo $cell_name
		}
	}
}
foreach inst [dbGet [dbGet top.insts.isPhysOnly -p 0].name u_aon_top/* -p] {
        set cell_name [dbGet $inst.cell.name]
	set inst_name [dbGet $inst.name]
        if {![regexp 40P140HVT $cell_name]} {
        	set cell [string replace $cell_name end-8 end "40P140HVT"]
		set yesor [dbGet head.libCells.name $cell]
		if {$yesor != 0x0} {
			ecoChangeCell -inst $inst_name -cell $cell
		} else {
			echo $cell_name
		}
	}
}
foreach inst [dbGet [dbGet top.insts.isPhysOnly -p 0].name u_aon_top/* -p] {
	set cell_name [dbGet $inst.cell.name]
	if {![regexp 40P140HVT $cell_name]} {
		echo $cell_name
	}
}
setEcoMode -reset

