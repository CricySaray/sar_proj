setEcoMode -honorDontTouch false -honorDontUse false -honorFixedStatus false -refinePlace false -updateTiming false -batchMode true -honorPowerIntent false
foreach inst [dbGet selected.name ] { 
	        set cell [dbGet [dbGet top.insts.name -p $inst].cell.name]
		if {[regexp "BUF" $cell] || [regexp "CKBD" $cell]} {
			ecoChangeCell -inst $inst -cell PTBUFFHDD4BWP7T35P140
		} else {
			ecoChangeCell -inst $inst -cell PTINVHDD4BWP7T35P140
		}
	}


