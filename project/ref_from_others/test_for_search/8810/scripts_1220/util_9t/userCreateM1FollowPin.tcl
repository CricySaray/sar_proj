proc userCreateM1FollowPin {width_pwr width_gnd layer_num shrink_width} {
	global vars
	setLayerPreference pwrdm -isVisible 0
	#create M2 FollowpIN
	setEdit -force_special 1
	setEdit -layer_horizontal M1
	setEdit -layer_vertical M1
	setEdit -shape FOLLOWPIN
	setEdit -layer_minimum M1
	setEdit -layer_maximum M1
	setEdit -drc_on 0
	deselectAll
#	foreach pgNetPtr [dbget -p1 top.nets.isPwr 1] {
#		editSelect -layer M2 -shape FOLLOWPIN -net [dbget $pgNetPtr.name]
		editSelect -layer M2 -shape FOLLOWPIN -net VDD
#	}
	editDuplicate
	editChangeLayer -layer_horizontal M1
	editChangeWidth -width_horizontal $width_pwr -width_vertical $width_pwr
	deselectAll
#	foreach pgNetPtr [dbget -p1 top.nets.isGnd 1] {
#		editSelect -layer M2 -shape FOLLOWPIN -net [dbget $pgNetPtr.name]
		editSelect -layer M2 -shape FOLLOWPIN -net VSS
#	}
	editDuplicate
	editChangeLayer -layer_horizontal M1
	editChangeWidth -width_horizontal $width_gnd -width_vertical $width_gnd
	deselectAll
	##cut pso m2 followPin for drc 16nm
#	for { set i 1 } {$i < [expr $layer_num +1 ]} {incr 1} {
#		setLayerPreference allM${i} -isVisible 0
#		setLayerPreference allM${i}Cont -isVisible 0
#	}
#	setLayerPreference allM2 -isVisible 1
#	setLayerPreference stdCell -isVisible 0
#	setLayerPreference block -isVisible 0
#	set psoPtr [dbGetCellByName $vars(pso_cell)]
#	set p_x [dbget [dbget -p1 $psoPtr.pgTerms.name TVDD].pins.layersShapeShapes.shapes.rect_llx]
#	set p_x "${p_x} [dbget [dbget -p1 $psoPtr.pgTerms.name TVDD].pins.layersShapeShapes.shapes.rect_urx]"
#	set p_x [lsort -real $p_x]
#	set cut_l [expr [lindex $p_x 0] + $shrink_width]
#	set cut_y [expr [lindex $p_x [expr [llength $p_x] - 1]] - $shrink_width]
#	deselectAll
#	foreach c [dbget -p2 top.insts.cell.name $vars(pso_cell)] {
#		set llx [dbget ${c}.pt_x]
#		set lly [dbget ${c}.pt_y]
#		set c_h [dbget ${c}.box_sizey]
#		editCutWire -x1 [expr $llx + $cut_l] -y1 [expr $lly + $c_h/4] -x2 [expr $llx + $cut_l] -y2 [expr $lly + $c_h - $c_h/4]
#		editCutWire -x1 [expr $llx + $cut_r] -y1 [expr $lly + $c_h/4] -x2 [expr $llx + $cut_r] -y2 [expr $lly  + $c_h - $c_h/4]
#
#		lineSelect append [expr $llx + $cut_l + 0.1] [expr $lly + $c_h/2] [expr $llx + $cut_l + 0.15 [$lly + $c_h/2]
#	}
#	deleteSectedFromFPlan
#	deselectAll
#	setLayerPreference stdCell -isVisible 1
#	setLayerPreference block -isVisible 1
	setEdit -reset
}
