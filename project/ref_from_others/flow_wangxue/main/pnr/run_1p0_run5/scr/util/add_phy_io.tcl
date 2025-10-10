set pad {PVSS2DGZ_H PVDD2DGZ_H PVSS1DGZ_H PVDD1DGZ_H }
deselectAll ;selectInstByCellName $pad
set num 1
exec rm -rf phy_io.tcl
foreach inst [dbGet selected.name ] {
	set pt [dbGet [dbGet top.insts.name $inst -p].pt]
	set pt_x [expr [dbGet [dbGet top.insts.name $inst -p].pt_x] * 2000]
	set pt_y [expr [dbGet [dbGet top.insts.name $inst -p].pt_y] * 2000]
	set n [expr $num%4]
	set cell [lindex $pad $n]
	set inst ${cell}_${num}
	echo "- $inst $cell + SOURCE DIST + FIXED ( $pt_x $pt_y ) W" >> phy_io.tcl
	echo " ;"  >> phy_io.tcl
	#echo "addInst -inst $inst -cell $cell -physical -loc $pt " >> phy_io.tcl
	incr num
	}
set pad {PVSS2DGZ_V PVDD2DGZ_V PVSS1DGZ_V PVDD1DGZ_V}
set num 1


