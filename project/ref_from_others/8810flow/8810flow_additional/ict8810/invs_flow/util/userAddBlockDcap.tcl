proc userAddBlockDcap {} {
	global vars
	deselectAll
	set endcap_width [dbGet [dbGetCellByName $vars(endcap_cell)].size_x]
	set cap_cell [lindex $vars(decap_cell) 0]
	set decap_width [dbGet [dbGetCellByName $cap_cell].size_x]
	set row_height [dbGet head.sites.size_y]
	updateStatus -force designIsPlaced
	foreach mem [dbGet top.insts.cell.subClass block -p2] {
                if [dbGet $mem.pd.isDefault] {
                } else {
			selectInst [dbGet $mem.name]
			set llx [dbGet selected.pHaloBox_llx]
			set lly [dbGet selected.pHaloBox_lly]
			set urx [dbGet selected.pHaloBox_urx]
			set ury [dbGet selected.pHaloBox_ury]
#			set decap_llx [expr $llx -  $decap_width - $endcap_width]
			set decap_llx [expr $llx - $endcap_width]
			set decap_lly [expr $lly - 2 * $row_height]
			set decap_urx [expr $urx + $endcap_width]
			set decap_ury [expr $ury + 2 * $row_height]
			addFiller -cell $cap_cell -area "$decap_llx $decap_lly $decap_urx  $decap_ury" -prefix ADD_DCAP -markFixed
			deselectAll
                }
        }
}
