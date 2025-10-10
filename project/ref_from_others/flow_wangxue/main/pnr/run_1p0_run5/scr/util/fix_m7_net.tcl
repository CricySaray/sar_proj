setEcoMode -reset
setEcoMode -honorDontTouch false -honorDontUse false -honorFixedStatus false -refinePlace false -updateTiming false -batchMode true -prefixName fix_m7_net
foreach term [dbGet [dbGet top.insts.instTerms.layer.name M7 -p2].name] {
	set net [get_object_name [get_nets -of_objects $term]]
	set input_cell [dbGet [dbGet top.insts.instTerms.net.name $net -p3].cell.name -u]
	if {![regexp "ISO" $input_cell]} {
		set pt_x [dbGet [dbGet top.insts.instTerms.name $term -p].pt_x]
		set pt_y [dbGet [dbGet top.insts.instTerms.name $term -p].pt_y]	
		if {$pt_x > 2000} {
			set pt_x_new [expr $pt_x - 23]
			set pt [list [list $pt_x_new $pt_y]]
			ecoAddRepeater -term $term -cell CKBD8BWP7T35P140 -loc $pt
		} else {
			set pt_y_new [expr $pt_y -23]
			set pt [list [list $pt_x $pt_y_new]]
			if { [lsearch [file2list aon_nets.tcl ] $net] != -1} {
				ecoAddRepeater -term $term -cell  PTBUFFHDD4BWP7T35P140 -loc $pt
			} else {
				ecoAddRepeater -term $term -cell CKBD8BWP7T35P140 -loc $pt
			}
		}
	}
}
setEcoMode -reset

