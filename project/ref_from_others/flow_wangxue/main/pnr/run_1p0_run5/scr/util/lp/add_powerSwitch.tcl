proc add_power_switch_cell {} {
		global vars
		global power_domain
		if {$vars($vars(powerDomain,off_domain),user_pso_channel_list) != ""} {                                                  
 			createPlaceBlockage -type hard -boxList $vars(PD_CORE_TOP,user_pso_channel_list) -name PSO_BLK
		} else {
		}
		if {$vars($vars(powerDomain,off_domain),module) != ""} {
			addPowerSwitch \
				-switchModuleInstance $vars($vars(powerDomain,off_domain),module) \
			        -incremental 1 \
			        -skipRows $power_domain(skipRows) \
			        -powerDomain $vars(powerDomain,off_domain) \
			        -globalSwitchCellName $power_domain(switch_cell) \
			        -column \
			        -noEnableChain \
			        -orientation R0 \
			        -leftOffset $power_domain(switch_x_offset) \
			        -bottomOffset 0 \
			        -topOffset 0 \
			        -horizontalPitch $power_domain(switch_x_pitch) \
			        -noFixedStdCellOverlap true \
			        -noRowVerify \
			        -ignoreSoftBlockage \
			        -instancePrefix $vars(powerDomain,off_domain)_
		} else {
			addPowerSwitch \
			        -incremental 1 \
			        -skipRows $power_domain(skipRows) \
			        -powerDomain $vars(powerDomain,off_domain) \
			        -globalSwitchCellName $power_domain(switch_cell) \
			        -column \
			        -noEnableChain \
			        -orientation R0 \
			        -leftOffset $power_domain(switch_x_offset) \
			        -bottomOffset 0 \
			        -topOffset 0 \
			        -horizontalPitch $power_domain(switch_x_pitch) \
			        -noFixedStdCellOverlap true \
			        -noRowVerify \
			        -ignoreSoftBlockage \
			        -instancePrefix $vars(powerDomain,off_domain)_
		}
		
	}
proc add_power_switch_cell_channel {} {
	global vars
	global power_domain
	foreach area $vars($vars(powerDomain,off_domain),user_pso_channel_list) {
		lassign $area llx lly urx ury
		set new_llx [lindex [lsort -real -incr [dbGet [dbGet [dbQuery -objType row -areas $area ] {.area<100}].box_llx ]] 0]
		set new_urx [lindex [lsort -real -incr [dbGet [dbGet [dbQuery -objType row -areas $area ] {.area<100}].box_urx ]] 0]
		set new_rect [list $new_llx $lly $new_urx $ury]
		set channel_lef_offset [expr ($new_urx-$new_llx-[get_db base_cell:$power_domain(switch_cell) .bbox.dx ])/2]
		if {$vars($vars(powerDomain,off_domain),module) != ""} {
			addPowerSwitch \
				-switchModuleInstance $vars($vars(powerDomain,off_domain),module) \
			        -incremental 1 \
			        -skipRows $power_domain(skipRows) \
			        -powerDomain $vars(powerDomain,off_domain) \
			        -globalSwitchCellName $power_domain(switch_cell) \
			        -column \
			        -noEnableChain \
			        -orientation R0 \
			        -leftOffset $channel_lef_offset \
			        -bottomOffset 0 \
			        -topOffset 0 \
			        -horizontalPitch $power_domain(switch_x_pitch) \
			        -noFixedStdCellOverlap true \
			        -noRowVerify \
			        -ignoreSoftBlockage \
			        -instancePrefix CHANNEL_$vars(powerDomain,off_domain) \
				-area $new_rect
		} else {
			addPowerSwitch \
			        -incremental 1 \
			        -skipRows $power_domain(skipRows) \
			        -powerDomain $vars(powerDomain,off_domain) \
			        -globalSwitchCellName $power_domain(switch_cell) \
			        -column \
			        -noEnableChain \
			        -orientation R0 \
			        -leftOffset $channel_lef_offset \
			        -bottomOffset 0 \
			        -topOffset 0 \
			        -horizontalPitch $power_domain(switch_x_pitch) \
			        -noFixedStdCellOverlap true \
			        -noRowVerify \
			        -ignoreSoftBlockage \
			        -instancePrefix CHANNEL_$vars(powerDomain,off_domain)_ \
				-area $new_rect
		}
	}
}
proc add_power_switch_cell_area {} {
	global vars
	global power_domain
	foreach area $vars($vars(powerDomain,off_domain),user_pso_area_list) {
		lassign $area llx lly urx ury
		set cell_width [dbGet [dbGet top.insts.cell.name $power_domain(switch_cell) -p].size_x -u]
		set new_llx [expr ($urx-$llx)/2+$llx-($cell_width/2)]
		set new_urx [expr ($urx-$llx)/2+$llx+($cell_width/2)]
		set new_rect [list $new_llx $lly $new_urx $ury]
		if {$vars($vars(powerDomain,off_domain),module) != ""} {
			addPowerSwitch \
				-switchModuleInstance $vars($vars(powerDomain,off_domain),module) \
			        -incremental 1 \
			        -skipRows $power_domain(skipRows) \
			        -powerDomain $vars(powerDomain,off_domain) \
			        -globalSwitchCellName $power_domain(switch_cell) \
			        -column \
			        -noEnableChain \
			        -orientation R0 \
			        -bottomOffset 0 \
			        -topOffset 0 \
			        -horizontalPitch $power_domain(switch_x_pitch) \
			        -noFixedStdCellOverlap true \
			        -noRowVerify \
			        -ignoreSoftBlockage \
			        -instancePrefix CHANNEL_$vars(powerDomain,off_domain) \
				-area $new_rect
		} else {
			addPowerSwitch \
			        -incremental 1 \
			        -skipRows $power_domain(skipRows) \
			        -powerDomain $vars(powerDomain,off_domain) \
			        -globalSwitchCellName $power_domain(switch_cell) \
			        -column \
			        -noEnableChain \
			        -orientation R0 \
			        -bottomOffset 0 \
			        -topOffset 0 \
			        -horizontalPitch $power_domain(switch_x_pitch) \
			        -noFixedStdCellOverlap true \
			        -noRowVerify \
			        -ignoreSoftBlockage \
			        -instancePrefix CHANNEL_$vars(powerDomain,off_domain)_ \
				-area $new_rect
		}
	}
}
proc reorder_power_switch_chain {} {
	global vars
	global power_domain
	set psos [dbGet [dbGet top.insts.cell.name $power_domain(switch_cell) -p2].name *$vars(powerDomain,off_domain)* -p]
		foreach pso $psos {
		        set pso_name [dbGet $pso.name]
		        set pso_llx [dbGet $pso.box_llx]
		        set pso_lly [dbGet $pso.box_lly]
		        lappend pso_long_chain_init_list "$pso_name $pso_llx $pso_lly"
		}
	set pso_chain_llx_sort [lsort -real -index 1 -increasing $pso_long_chain_init_list]
	set pso_chain_lly_sort [lsort -real -index 2 -increasing $pso_long_chain_init_list]
	set pso_chain_box_llx [lindex [lindex $pso_chain_llx_sort 0] 1]
	set pso_chain_box_lly [lindex [lindex $pso_chain_lly_sort 0] 2]
	set pso_chain_box_urx [lindex [lindex $pso_chain_llx_sort end] 1]
	set pso_chain_box_ury [lindex [lindex $pso_chain_lly_sort end] 2]
	set pso_chain_box "$pso_chain_box_llx $pso_chain_box_lly $pso_chain_box_urx $pso_chain_box_ury"
	set pso_chain_box_center_x [expr ([lindex $pso_chain_box 2]-[lindex $pso_chain_box 0])/2+[lindex $pso_chain_box_llx]]
	set pso_chain_box_center_y [expr ([lindex $pso_chain_box 3]-[lindex $pso_chain_box 1])/2+[lindex $pso_chain_box_lly]]
	set pso_chain_ctrl_port_llx [dbGet [dbGet top.insts.instTerms.name $vars($vars(powerDomain,off_domain),switch_long_input) -p].pt_x]
	set pso_chain_ctrl_port_lly [dbGet [dbGet top.insts.instTerms.name $vars($vars(powerDomain,off_domain),switch_long_input) -p].pt_y]
	set NetIn [dbGet [dbGet top.insts.instTerms.name $vars($vars(powerDomain,off_domain),switch_long_input) -p].net.name]
	        if {$pso_chain_ctrl_port_llx < $pso_chain_box_center_x && $pso_chain_ctrl_port_lly < $pso_chain_box_center_y} {
	                set chain_x_dir LtoR
	                set chain_y_dir BtoT
	        } elseif {$pso_chain_ctrl_port_llx < $pso_chain_box_center_x && $pso_chain_ctrl_port_lly >= $pso_chain_box_center_y} {
	                set chain_x_dir LtoR
	                set chain_y_dir TtoB
	        } elseif {$pso_chain_ctrl_port_llx >= $pso_chain_box_center_x && $pso_chain_ctrl_port_lly < $pso_chain_box_center_y} {
	                set chain_x_dir RtoL
	                set chain_y_dir BtoT
	        } elseif {$pso_chain_ctrl_port_llx >= $pso_chain_box_center_x && $pso_chain_ctrl_port_lly >= $pso_chain_box_center_y} {
	                set chain_x_dir RtoL
	                set chain_y_dir TtoB
	        } else {
	                set chain_x_dir LtoR
	                set chain_y_dir BtoT
	        }
	rechainPowerSwitch \
	     -backToBackChain \
	     -chainByInstances \
	     -chainDirectionX $chain_x_dir \
	     -chainDirectionY $chain_y_dir  \
	     -enableNetIn $NetIn  \
	     -enablePinIn $power_domain(switch_pso_in) \
	     -enablePinOut $power_domain(switch_pso_out) \
	     -switchInstances [addPowerSwitch -column -getSwitchInstances -powerDomain $vars(powerDomain,off_domain)]
}
if {$off_domain_name != ""} {
	foreach e_off_domain $off_domain_name {
		set vars(powerDomain,off_domain) $e_off_domain
		deletePowerSwitch -column -powerDomain $vars(powerDomain,off_domain)
		add_power_switch_cell
		if {[dbGet top.fPlan.pBlkgs.name PSO_BLK* -p] != 0x0 } {deletePlaceBlockage PSO_BLK*}
		add_power_switch_cell_channel
		add_power_switch_cell_area
		reorder_power_switch_chain
	}
}



