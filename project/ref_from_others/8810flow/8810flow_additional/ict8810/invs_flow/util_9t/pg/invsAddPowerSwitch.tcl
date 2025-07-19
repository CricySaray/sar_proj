proc my.pg.delete_all_pwrsh {} {
	foreach pds [dbGet [dbGet top.pds.isAlwaysOn 0 -p].name] {
		deletePowerSwitch -column -powerDomain $pds
	}
}
proc my.fp.block_channel { clx cly {type soft}} {
	deletePlaceBlockage pb4channel_${type}_*
	if [info exist area] { unset area } ;
	foreach mem [dbGet top.insts.cell.subClass block -p2] {
		if [info exist area] {
			set area [dbShape $area OR [dbShape [dbGet $mem.box] SIZEX $clx SIZEY $cly]]
		} else {
			set area [dbShape [dbGet $mem.box] SIZEX $clx SIZEY $cly]
		}
	}
	set i 0
	foreach box [dbShape $area SIZEX -$clx SIZEY -$cly] {
		createPlaceBlockage -box $box -type $type -name pb4channel_${type}_$i ;
		incr i
	}
}
proc my.fp.routeblk_on_block { clx cly layers} {
	deleteRouteBlk routeblk_on_block_*
	if [info exist area] { unset area } ;
	foreach mem [dbGet top.insts.cell.subClass block -p2] {
		if [info exist area] {
			set area [dbShape $area OR [dbShape [dbGet $mem.box] SIZEX $clx SIZEY $cly]]
		} else {
			set area [dbShape [dbGet $mem.box] SIZEX $clx SIZEY $cly]
		}
	}
	set i 0
	foreach box [dbShape $area SIZEX -0.01 SIZEY -0.01 ] {
		createRouteBlk -box $box -layer $layer -name routeblk_on_block_$i
		incr i
	}
}
proc my.fp.routeblk_on_core { clx cly layers} {
	deleteRouteBlk routeblk_on_core_*
	if [info exist area] { unset area } ;
	foreach mem [dbGet top.insts.cell.subClass block -p2] {
		if [info exist area] {
			set area [dbShape $area OR [dbShape [dbGet $mem.box] SIZEX $clx SIZEY $cly]]
		} else {
			set area [dbShape [dbGet $mem.box] SIZEX $clx SIZEY $cly]
		}
	}
	set i 0
	foreach box [dbShape [dbGet top.fplan.boxes] ANDNOT [dbShape $area SIZEX -0.01 SIZEY [expr 1 - $cly ]]] {
		createRouteBlk -box $box -layer $layer -name routeblk_on_core_$i
		incr i
	}
}
proc my.fp.block_core { clx cly {type soft}} {
	deletePlaceBlockage pb4core_*
	if [info exist area] { unset area } ;
	foreach mem [dbGet top.insts.cell.subClass block -p2] {
		if [info exist area] {
			set area [dbShape $area OR [dbShape [dbGet $mem.box] SIZEX $clx SIZEY $cly]]
		} else {
			set area [dbShape [dbGet $mem.box] SIZEX $clx SIZEY $cly]
		}
	}
	set i 0
	foreach box [dbShape [dbGet top.fplan.boxes] ANDNOT [dbShape $area SIZEX -$clx SIZEY -$cly]] {
		createPlaceBlockage -box $box -type $type -name pb4core_${type}_$i ;
		incr i
	}
}
proc my.fp.block_for_channel_psw { clx cly {type soft}} {
	global vars
	set block_shapes [dbShape [dbget [dbGet top.insts.cell.subClass block -p2].box] -output polygon]
	set boundary_left_cells_shapes [dbShape [dbget [dbGet top.insts.cell.name FILL4_A9TR50 -p2].boxes] -output polygon]
	set boundary_left_cells_boxes [dbShape $boundary_left_cells_shapes -output rect]
	## get all domain shapes
	set vars(power_domains) [userGetPowerDomains]
	set vars(GND) [dbPowerDomainGNet [lindex $vars(power_domains) 0]]
	set shut_domain_shapes_all {0 0 0 0}
	foreach domain $vars(power_domains) {
		if {[dbget [dbget top.pds.group.name $domain -p2].isDefault] ==1} {
			set vars(AON_POWER) [dbPowerDomainPNet [dbGetPowerDomainByName $domain]]
		} else {
			deselectAll
			selectObject Group $domain
			set ${domain}_shapes [dbShape [dbget selected.boxes] -output polygon]
			set shut_domain_shapes_all [dbShape [set ${domain}_shapes] OR $shut_domain_shapes_all  -output polygon]
		}
	}
	deselectAll
	set aon_domain_shapes_all [dbShape [dbget top.fplan.boxes] ANDNOT $shut_domain_shapes_all -output polygon]
	foreach domain $vars(power_domains) {
		set ${domain}_boxes ""
		if {[dbget [dbget top.pds.group.name $domain -p2].isDefault] ==1} {
			set shape1 $aon_domain_shapes_all
		} else {
			set shape1 [set ${domain}_shapes]
		}
		foreach box $boundary_left_cells_boxes {
			set or_poly [dbshape [dbshape [dbshape $box -output polygon] SIZEX 15 -output polygon] OR $shape1 -output polygon]
			set and_poly [dbshape [dbshape [dbshape $box -output polygon] -output polygon] AND $shape1 -output polygon]
			set and_mem_poly [dbshape [dbshape $block_shapes SIZEX 10] AND [dbshape $box -output polygon] -output polygon]
			if {$or_poly != $shape1 && $and_poly != "" && $and_mem_poly != ""} {
				lappend ${domain}_boxes $box
			}
		}
	}
	deletePlaceBlockage pb4channelpsw_*
	if [info exist area] { unset area } ;
	foreach mem [dbGet top.insts.cell.subClass block -p2] {
		if [info exist area] {
			set area [dbShape $area OR [dbShape [dbGet $mem.box] SIZEX $clx SIZEY $cly]]
		} else {
			set area [dbShape [dbGet $mem.box] SIZEX $clx SIZEY $cly]
		}
	}
	set i 0
	set block_boxes [dbShape [dbGet top.fplan.boxes] ANDNOT [dbShape $area SIZEX -$clx SIZEY -$cly]]
	foreach domain $vars(power_domains) {
		set block_boxes [dbShape $block_boxes ANDNOT [dbShape [set ${domain}_boxes] SIZEX 10] -output rect]
	}
	foreach box $block_boxes {
		createPlaceBlockage -box $box -type $type -name pb4channelpsw_${type}_$i ;
		incr i
	}
}

proc my.fp.get_channel {clx cly} {
	set mem_list [dbGet top.insts.cell.subClass block -p2]
	foreach mem $mem_list {
		if [info exist area] {
			set area [dbShape $area OR [dbShape [dbGet $mem.box] SIZEX $clx SIZEY $cly]]
		} else {
			set area [dbShape [dbGet $mem.box] SIZEX $clx SIZEY $cly]
		}
	}
	set new_area [dbShape [dbShape $area SIZE -$clx SIZEY -$cly] ANDNOT [dbGet $mem_list.boxes]]
	set new_area1 [dbShape $new_area AND [dbShape [dbGet $mem_list.boxes] SIZEX $clx]]
	set new_area2 [dbShape $new_area AND [dbShape [dbGet $mem_list.boxes] SIZEX $cly]]
	set return_area [dbShape $new_area1 OR $new_area2] ;
	set i 0
	foreach box $return_area {
		incr 1
		set size [my.util.get_width_height $box] ;
		set width [lindex $size 0] ;
		set height [lindex $size 1] ;
		createMarker -bbox $box -type channel_$i
		lappend return_box $box ;
	}
		
	if [info exist return_box] {
		return $return_box ;
	}
}
proc my.util.get_width_height {box} {
	set lx [lindex $box 0] ;
	set ly [lindex $box 1] ;
	set rx [lindex $box 2] ;
	set ry [lindex $box 3] ;
	set width [expr $rx - $lx];
	set height [expr $ry - $ly];
	return [list $width $height];
}
proc my.pg.add_power_switch_in_channel {} {
	global pgvars
	my.fp.block_core 30 30 hard
	set hInst [dbGet [dbGet top.pds.name $pgvars(domain) -p].group.members.name] ;
}
proc my.pg.add_power_switch {domain} {
	global pgvars
	set pgvars(domain) $domain
	my.fp.block_channel 15 2 hard
	#3 set pgvars(leftOffset)
	set pds [dbGet top.pds.name $pgvars(domain) -p]
	set pds_box [dbGet $pds.group.members.box -i 0]  ;; ????
	set hInst [dbGet $pds.group.members.name]
	set num_pitch [expr int(([lindex $pds_box 0] - $pgvars(leftOffset))/$pgvars(horizontalPitch))]
	set num [expr ([lindex $pds_box 0] - $pgvars(leftOffset))/$pgvars(horizontalPitch)]
	
	if { $num_pitch < $num } {
		incr num_pitch
	} ;
	set leftOffset [expr $pgvars(leftOffset) + $pgvars(horizontalPitch)*$num_pitch - [lindex $pds_box 0]] ;
	puts "************************* leftOffset $leftOffset **************************"
	set cmd "addPowerSwitch -column -incremental 0            \
		-powerDomain $pgvars(domain)                      \
		-skipRows $pgvars(skipRows)                       \
		-leftOffset $leftOffset                           \
		-horizontalPitch $pgvars(horizontalPitch)         \
		-instancePrefix PWRSH_$pgvars(domain)_core        \
		-globalSwitchCellName $pgvars(pso_cell)           \
		-switchModuleInstance $hInst                      \
		-noEnableChain                                    \
		$pgvars(add_pwrsh_option)"
	eval $cmd
	deletePlaceBlockage pb4channel_hard_*
	my.fp.block_for_channel_psw 15 2 hard
	#my.fp.block_core 15 2 hard
	set cmd "addPowerSwitch -column -incremental 1            \
		-powerDomain $pgvars(domain)                      \
		-instancePrefix PWRSH_$pgvars(domain)_channel     \
		-globalSwitchCellName $pgvars(channel_pso_cell)   \
		-skipRows $pgvars(channel_skipRows)               \
		-placementAdjustX $pgvars(channel_placementAdjustX) \
		-placeunderverticalnet {$pgvars(AON_POWER) $pgvars(AON_POWER_layer)}  \
		-switchModuleInstance $hInst                      \
		-noEnableChain                                    \
		$pgvars(channel_add_pwrsh_option)"
	eval $cmd
	deletePlaceBlockage *
}
proc my.pg.rechainPowerSwitch {domain} {
	set pgvars(domain) $domain
	set pgvars(enablePortIn) [list PD_EN_IN ] ;
	set pgvars(enablePortOut) [list PD_EN_OUT ] ;
	set hInst [dbGet [dbGet $top.pds.name $pgvars(domain) -p].group.members.name]
	if [info exist enableNetIn] {
		unset enableNetIn
	}
	foreach pin_name $pgvars(enablePortIn) {
		set pin [get_pins $hInst/$pin_name -quiect]
		if {[sizeof_collection $pin] == 0} {
			addModulePort $hInst $pin_name input
		}
		lappend enableNetIn $hInst/$pin_name"
	}
	if [info exist enableNetOut] {
		unset enableNetOut
	}
	foreach pin_name $pgvars(enablePortOut) {
		set pin [get_pins $hInst/$pin_name -quiect]
		if {[sizeof_collection $pin] == 0} {
			addModulePort $hInst $pin_name output
		}
		lappend enableNetOut $hInst/$pin_name"
	}
	set enablePinIn [dbGet [dbGet [dbGet head.libCells.name $pgvars(pso_cell) -p].terms.isInput 1 -p].name]
	set enablePinOut [dbGet [dbGet [dbGet head.libCells.name $pgvars(pso_cell) -p].terms.isOutput 1 -p].name]
	deselectAll
	dbSelectObj [dbGet [dbGet top.insts.cell.name $pgvars(pso_cell) -p2].pd.name $pgvars(domain) -p2 -e]
	rechainPowerSwitch -backToBackChain -selected \
		-enablePinIn $enablePinIn -enablePinOut $enablePinOut -maxDistanceY 100 -maxDistanceX 100 \
		-enableNetIn $enableNetIn -enableNetOut $enableNetOut
	dbSelectObj [dbGet [dbGet [dbGet top.insts.cell.name $pgvars(pso_cell) -p2].pd.name $pgvars(domain) -p2 -e].instTerms]
}
