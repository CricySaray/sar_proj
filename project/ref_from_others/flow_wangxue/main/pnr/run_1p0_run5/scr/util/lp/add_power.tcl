###################################################
#deleteAllPowerPreroutes
#defIn ./efuse_power.def.gz
source ../scr/util/lp/lp_config.tcl -echo -verbose
deleteRouteBlk -name power_blk
#if {$off_domain_name != ""} {
#	foreach e_off_domain_name $off_domain_name {
#	set box [join [dbGet [dbGet top.pds.group.name $e_off_domain_name -p].boxes]]
#	createRouteBlk -box $box -layer all -cutLayer all -name power_blk -spacing 0
#	}
#}
if {$off_domain_name != ""} {
	foreach e_off_domain_name $off_domain_name {
		set boxes [join [dbGet [dbGet top.pds.group.name $e_off_domain_name -p].boxes]]
		foreach box $boxes {
			createRouteBlk -box $box -layer all -cutLayer all -name power_blk -spacing 0
		}
	}
}


########################################################################
if {$on_domain_name != ""} {
	foreach e_on_domain $on_domain_name {
		if {$e_on_domain != ""} {
		set local_power "$vars($e_on_domain,primary_pwr)"
		set ground_power "$vars($e_on_domain,primary_gnd)"
		#set on_domain_name $e_on_domain
		} else {
		puts "ERR: no on_domain "
		}


#######################################
setEditMode -reset
setEditMode -create_crossover_vias false -create_via_on_pin false 

##########################add M6 power##############
#set layer M6
#set direction vertical
#
#####add memory channel power and ground
#setAddStripeMode -reset
##setAddStripeMode -ignore_DRC true -skip_via_on_pin {pad block cover standardcell physicalpin} -skip_via_on_wire_shape {blockring stripe followpin corewire blockwire iowire padring ring fillwire noshape} -stacked_via_top_layer $layer -stacked_via_bottom_layer $layer -ignore_nondefault_domains true -domain_offset_from_core true -max_extension_distance 1 -extend_to_closest_target {area_boundary stripe} -trim_stripe core_boundary
#
#setAddStripeMode -ignore_DRC true -skip_via_on_pin {pad block cover standardcell physicalpin} -skip_via_on_wire_shape {blockring stripe followpin corewire blockwire iowire padring ring fillwire noshape} -stacked_via_top_layer $layer -stacked_via_bottom_layer $layer 
#deleteRouteBlk -name broudary_Blk_M6
#deleteRouteBlk -name AFE_power_rlk
#foreach i {{1080.715 2360.2 1964.955 2379.8} {882.055 130.0 1961.035 146.1}} {
#	createRouteBlk -layer M6 -box $i -name broudary_Blk_M6
#	}
createRouteBlk -boxList  [join [dbShape [dbGet [dbGet top.insts.name u_afe_core -p].boxes] SIZE 20]]  -layer all -cutLayer all -name AFE_power_rlk  -spacing 0
#if {$e_on_domain == "PD_DBB"} {
#set mem_channel_boxs [dbShape [dbShape [dbGet [ dbGet [dbQuery -objType row -areas [join [dbGet [dbGet top.pds.name $e_on_domain -p].group.boxes ]]] {.area < 20}].box -e] SIZEY 10] SIZEY -10]
##set mem_channel_boxs [dbShape [dbGet [ dbGet [dbQuery -objType row -areas [join [dbGet [dbGet top.pds.name $e_on_domain -p].group.boxes ]]] {.area < 20}].box -e] SIZEY 0]
#if {$mem_channel_boxs != ""} {
#        foreach mem_channel_box $mem_channel_boxs {
#                lassign $mem_channel_box llx lly urx ury
#                set width 1
#                set space 2
#                set off_site  [expr ($urx-$llx -4)/2]
#                addStripe -nets "$local_power $ground_power" -width $width -set_to_set_distance 50 -layer $layer -start_offset $off_site -direction $direction -area $mem_channel_box -spacing $space 
#        }
#} 
#} else {
#set mem_channel_boxs [dbShape [dbShape [dbGet [ dbGet [dbQuery -objType row -areas [join [dbGet [dbGet top.pds.name $e_on_domain -p].group.boxes ]]] {.area < 20}].box -e] SIZEY 10] SIZEY -8]
##set mem_channel_boxs [dbShape [dbGet [ dbGet [dbQuery -objType row -areas [join [dbGet [dbGet top.pds.name $e_on_domain -p].group.boxes ]]] {.area < 20}].box -e] SIZEY 5]
#if {$mem_channel_boxs != ""} {
#        foreach mem_channel_box $mem_channel_boxs {
#                lassign $mem_channel_box llx lly urx ury
#                set width 1
#                set space 2
#                set off_site  [expr ($urx-$llx -4)/2]
#                addStripe -nets "$local_power $ground_power" -width $width -set_to_set_distance 50 -layer $layer -start_offset $off_site -direction $direction -area $mem_channel_box -spacing $space 
#        }
#}
#}
#
####add core power and ground 
#deleteRouteBlk -name broudary_Blk_M6
#setAddStripeMode -reset
#setAddStripeMode -ignore_DRC true -skip_via_on_pin {pad block cover standardcell physicalpin} -skip_via_on_wire_shape {blockring stripe followpin corewire blockwire iowire padring ring fillwire noshape} -stacked_via_top_layer $layer -stacked_via_bottom_layer $layer -ignore_nondefault_domains true -domain_offset_from_core true -max_extension_distance 2 -extend_to_closest_target {area_boundary stripe} -trim_stripe core_boundary
####add memory power and ground
#set core_retention_memorys {u_core_top/u_sram_ctrl_wrapper/u_soc_sram0/u_sram_ctrl_ecc/sram_instance_0__u_mem/u_mem u_core_top/u_sram_share_wrapper/u_ram1_32KB_cp_itcm_dedicated/u_mem u_core_top/u_sram_share_wrapper/u_ram6_32KB/u_mem u_core_top/u_sram_share_wrapper/u_ram0_32KB_cp_itcm_dedicated/u_mem u_core_top/u_sram_share_wrapper/u_ram2_32KB_ap_itcm_dedicated/u_mem u_core_top/u_sram_share_wrapper/u_ram3_32KB/u_mem u_core_top/u_sram_share_wrapper/u_ram4_32KB/u_mem u_core_top/u_sram_share_wrapper/u_ram5_32KB/u_mem u_core_top/u_sram_share_wrapper/u_ram8_16KB/u_mem u_core_top/u_sram_share_wrapper/u_ram10_16KB/u_mem u_core_top/u_sram_share_wrapper/u_ram9_16KB/u_mem u_core_top/u_sram_share_wrapper/u_ram7_16KB/u_mem}
#set dbb_retention_memorys {u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_5__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_7__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_6__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_0__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_4__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_2__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_1__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_3__u_2048x32_wrapper/u_mem}
#if {$e_on_domain == "PD_DBB"} {
#	set dbb_retention_memory_boxs [dbShape [dbShape [dbGet [dbGet [dbGet [dbGet top.insts.cell.baseClass block -p2].pd.name $e_on_domain -p2].name -regexp [list [join $dbb_retention_memorys |]]  -p].boxes] SIZEY 10] SIZEY -10]
#	#set dbb_retention_memory_boxs [dbShape [dbGet [dbGet [dbGet [dbGet top.insts.cell.baseClass block -p2].pd.name $e_on_domain -p2].name -regexp [list [join $dbb_retention_memorys |]]  -p].boxes] SIZE 10]
#	foreach mem_box $dbb_retention_memory_boxs {
#		addStripe -nets "$local_power $ground_power DVDD0P9_RAM" -width 1 -set_to_set_distance 20 -layer $layer -start_offset 3 -direction $direction -area $mem_box -spacing 2
#	}
#	set dbb_memory_boxs [dbGet [dbGet [dbGet [dbGet top.insts.cell.baseClass block -p2].pd.name $e_on_domain -p2].name -regexp [list [join $dbb_retention_memorys |]] -v -p].boxes]
#	foreach mem_box $dbb_memory_boxs {
#		addStripe -nets "$local_power $ground_power" -width 1 -set_to_set_distance 20 -layer $layer -start_offset 3 -direction $direction -area $mem_box -spacing 2
#	}
#} elseif {$e_on_domain == "PD_CORE"} {
#	set core_retention_memory_boxs [dbShape [dbShape [dbGet [dbGet [dbGet [dbGet top.insts.cell.baseClass block -p2].pd.name $e_on_domain -p2].name -regexp [list [join $core_retention_memorys |]]  -p].boxes] SIZEY 10] SIZEY -10]
#	foreach mem_box $core_retention_memory_boxs {
#		addStripe -nets "$local_power $ground_power DVDD0P9_RAM" -width 1 -set_to_set_distance 20 -layer $layer -start_offset 3 -direction $direction -area $mem_box -spacing 2
#	}
#	set core_memory_boxs [dbGet [dbGet [dbGet [dbGet top.insts.cell.baseClass block -p2].pd.name $e_on_domain -p2].name -regexp [list [join $core_retention_memorys |]] -v -p].boxes]
#	foreach mem_box $core_memory_boxs {
#		addStripe -nets "$local_power $ground_power" -width 1 -set_to_set_distance 20 -layer $layer -start_offset 3 -direction $direction -area $mem_box -spacing 2
#	}
#} else {
#	set mem_boxs [dbShape [dbGet [dbGet [dbGet top.insts.cell.baseClass block -p2].pd.name $e_on_domain -p2].boxes -e] SIZE 1]
#	#set mem_boxs [dbGet [dbGet [dbGet top.insts.cell.baseClass block -p2].pd.name $e_on_domain -p2].boxes -e]
#	if {$mem_boxs != ""} {
#       		foreach mem_box $mem_boxs {
#                	addStripe -nets "$local_power $ground_power" -width 1 -set_to_set_distance 20 -layer $layer -start_offset 3 -direction $direction -area $mem_box -spacing 2 
#        }
#}
#}
#addStripe -nets "$local_power $ground_power" -width 1 -set_to_set_distance 20 -layer $layer -start_offset 3 -direction $direction -spacing 2  -power_domains $e_on_domain -max_same_layer_jog_length 2
#
#
###########################add M7 power##############
#set layer M7
#set direction horizontal
#setAddStripeMode -reset
#setAddStripeMode -skip_via_on_pin {pad block cover standardcell physicalpin} -skip_via_on_wire_shape {blockring stripe followpin corewire blockwire iowire padring ring fillwire noshape} -stacked_via_top_layer $layer -stacked_via_bottom_layer $layer -ignore_nondefault_domains true -domain_offset_from_core true -max_extension_distance 2 -extend_to_closest_target {area_boundary stripe} -trim_stripe core_boundary
#if {$e_on_domain == "PD_DBB"} {
#	set dbb_retention_memory_boxs [dbShape [dbShape [dbGet [dbGet [dbGet [dbGet top.insts.cell.baseClass block -p2].pd.name $e_on_domain -p2].name -regexp [list [join $dbb_retention_memorys |]]  -p].boxes] SIZE 10] SIZE -10]
#	#set dbb_retention_memory_boxs [dbShape [dbGet [dbGet [dbGet [dbGet top.insts.cell.baseClass block -p2].pd.name $e_on_domain -p2].name -regexp [list [join $dbb_retention_memorys |]]  -p].boxes] SIZE 10]
#	foreach mem_box $dbb_retention_memory_boxs {
#		addStripe -nets "$local_power $ground_power DVDD0P9_RAM" -width 12 -set_to_set_distance 45 -layer $layer -start_offset 10 -direction $direction -area $mem_box -spacing 3
#	}
#
#} 
#if {$e_on_domain == "PD_CORE"} {
#	set core_retention_memory_boxs [dbShape [dbShape [dbGet [dbGet [dbGet [dbGet top.insts.cell.baseClass block -p2].pd.name $e_on_domain -p2].name -regexp [list [join $core_retention_memorys |]]  -p].boxes] SIZE 20] SIZE -20]
#	foreach mem_box $core_retention_memory_boxs {
#		addStripe -nets "$local_power $ground_power DVDD0P9_RAM" -width 12 -set_to_set_distance 45 -layer $layer -start_offset 10 -direction $direction -area $mem_box -spacing 3
#	}
#} 
#addStripe -nets "$local_power $ground_power" -width 12 -set_to_set_distance 30 -layer $layer -start_offset 1 -direction $direction -spacing 3  -power_domains $e_on_domain 
##########################add M8 power##############
#set layer M8
#set direction vertical
#setAddStripeMode -reset
#setAddStripeMode -skip_via_on_pin {pad block cover standardcell physicalpin} -skip_via_on_wire_shape {blockring stripe followpin corewire blockwire iowire padring ring fillwire noshape} -stacked_via_top_layer $layer -stacked_via_bottom_layer $layer -ignore_nondefault_domains true -domain_offset_from_core true -max_extension_distance 2 -extend_to_closest_target {area_boundary stripe} -trim_stripe core_boundary
#addStripe -nets "$local_power $ground_power" -width 10 -set_to_set_distance 40 -layer $layer -start_offset 1 -direction $direction -spacing 10  -power_domains $e_on_domain
##########################add M1 power##############
set layer M1
setAddStripeMode -reset
setAddStripeMode -skip_via_on_pin {pad block cover standardcell physicalpin} -skip_via_on_wire_shape {blockring stripe followpin corewire blockwire iowire padring ring fillwire noshape} -stacked_via_top_layer $layer -stacked_via_bottom_layer $layer
sroute -nets "$local_power $ground_power" -corePinWidth 0.1 -corePinLayer M1 -connect corePin -layerChangeRange {M1 M1} -powerDomains $e_on_domain
	}
}
deleteRouteBlk -name AFE_power_rlk
deleteRouteBlk -name power_blk



########################################################################
if {$off_domain_name != ""} {
	foreach e_off_domain $off_domain_name {
		if {$e_off_domain != ""} {
		set local_power "$vars($e_off_domain,primary_pwr)"
		set aon_power "$vars($e_off_domain,always_on)"
		set ground_power "$vars($e_off_domain,primary_gnd)"
		#set off_domain_name $e_off_domain
		} else {
		puts "ERR: no off_domain "
		}


#######################################
setEditMode -reset
setEditMode -create_crossover_vias false -create_via_on_pin false 

##########################add M6 power##############
##########################add psw power##############
#setEditMode -reset
#setEditMode -create_crossover_vias false -create_via_on_pin false 
#
#set layer M6
#set direction vertical
##set RBlk_pd_sram_box [join [dbGet [dbGet top.pds.name PD_SRAM_RE -p].group.boxes]]
##createRouteBlk -layer {M6 M7 M8} -box $RBlk_pd_sram_box -name RBlk_pd_sram
#setAddStripeMode -reset 
#setAddStripeMode -skip_via_on_pin {pad block cover standardcell physicalpin} -skip_via_on_wire_shape {blockring stripe followpin corewire blockwire iowire padring ring fillwire noshape} -stacked_via_top_layer $layer -stacked_via_bottom_layer $layer
#set skip_y_length [expr $power_domain(psw_row_y)*$power_domain(skipRows)]
#set psw_boxs [dbShape [dbShape [dbShape [dbGet [dbGet top.insts.cell.name $power_domain(switch_cell) -p2].boxes] SIZEY $skip_y_length] SIZEY 1.4] AND [dbGet [dbGet top.pds.name $e_off_domain -p].group.boxes]]
#
##set psw_boxs [dbShape [dbShape [dbShape [dbShape [dbGet [dbGet top.insts.cell.name $power_domain(switch_cell) -p2].boxes] SIZEY $skip_y_length] SIZEY 1.4] AND [dbShape [dbGet [dbGet top.pds.isDefault 1 -p].group.boxes] ANDNOT [dbShape [dbShape [dbGet [dbGet top.pds.isDefault 0 -p].group.boxes] SIZE 1.2]]]] ANDNOT [dbGet [dbGet [dbGet top.insts.cell.baseClass block -p2].pd.name -u $off_domain_name -p2].pHaloBox]]
##set psw_boxs [dbShape [dbShape [dbShape [dbGet [dbGet top.insts.cell.name $power_domain(switch_cell) -p2].boxes] SIZEY $skip_y_length] AND [dbGet [dbGet top.pds.name $off_domain_name -p].group.boxes]] ANDNOT [dbGet [dbGet top.insts.cell.baseClass block -p2].pHaloBox]]
#foreach i $psw_boxs  {
#	lassign $i llx lly urx ury
#	set new_urx [expr $urx+1]
#	addStripe -nets "$local_power $aon_power $ground_power " -width 1 -set_to_set_distance 50 -layer $layer -start_offset 0.3 -direction $direction -area "$llx $lly $new_urx $ury" -spacing 0.5
#}
#
#
###########################add M7 power##############
#set layer M7
#set direction horizontal
#setAddStripeMode -reset
#setAddStripeMode -skip_via_on_pin {pad block cover standardcell physicalpin} -skip_via_on_wire_shape {blockring stripe followpin corewire blockwire iowire padring ring fillwire noshape} -stacked_via_top_layer $layer -stacked_via_bottom_layer $layer -ignore_nondefault_domains true -domain_offset_from_core true -max_extension_distance 2 -extend_to_closest_target {area_boundary stripe} -trim_stripe core_boundary
#addStripe -nets "$local_power $aon_power $ground_power" -width 12 -set_to_set_distance 45 -layer $layer -start_from top -start_offset 1 -direction $direction -spacing 3  -power_domains $e_off_domain 
##########################add M8 power##############
#set layer M8
#set direction vertical
#setAddStripeMode -reset
#setAddStripeMode -skip_via_on_pin {pad block cover standardcell physicalpin} -skip_via_on_wire_shape {blockring stripe followpin corewire blockwire iowire padring ring fillwire noshape} -stacked_via_top_layer $layer -stacked_via_bottom_layer $layer -ignore_nondefault_domains true -domain_offset_from_core true -max_extension_distance 2 -extend_to_closest_target {area_boundary stripe} -trim_stripe core_boundary
#addStripe -nets "$local_power $aon_power $ground_power" -width 10 -set_to_set_distance 60  -layer $layer -start_from top -start_offset 1 -direction $direction -spacing 10  -power_domains $e_off_domain
##########################add M1 power##############
set layer M1
setAddStripeMode -reset
setAddStripeMode -skip_via_on_pin {pad block cover standardcell physicalpin} -skip_via_on_wire_shape {blockring stripe followpin corewire blockwire iowire padring ring fillwire noshape} -stacked_via_top_layer $layer -stacked_via_bottom_layer $layer
sroute -nets "$local_power $ground_power" -corePinWidth 0.1 -corePinLayer M1 -connect corePin -layerChangeRange {M1 M1} -powerDomains $e_off_domain
	}
}

#setEditMode -reset 
#setEditMode -drc_on 0 -create_crossover_vias false -create_via_on_pin false -layer_maximum M2
#deselectAll
#editSelect -layer M1 -shape FOLLOWPIN
#editDuplicate -layer_horizontal M2
#setEditMode -reset

