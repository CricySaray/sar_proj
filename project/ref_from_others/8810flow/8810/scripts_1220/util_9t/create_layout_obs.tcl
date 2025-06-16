set files [open ./block_layoutobs.tcl w]
deselectAll
selectInst chip_core_inst/lb_modem_top_inst/lb_modem_top1_inst
selectInst chip_core_inst/lb_modem_top_inst/lb_modem_top0_inst
selectInst chip_core_inst/lb_modem_top_inst/lb_modem_top2_inst
selectInst chip_core_inst/cpu1_inst
selectInst chip_core_inst/cpu2_inst
selectInst chip_core_inst/lb_lpddr2_top_inst
set block_ptr [dbGet selected]
foreach inst_ptr $block_ptr {
	set boxes [dbShape [dbGet $inst_ptr.boxes] size 0.2 -output rect]
	foreach box $boxes {
	puts $files "LAYOUT POLYGON 2 $box DUMBA"
	puts $files "LAYOUT POLYGON 2 $box DUMBP"
	puts $files "LAYOUT POLYGON 2 $box M1DUB"
	puts $files "LAYOUT POLYGON 2 $box M2DUB"
	puts $files "LAYOUT POLYGON 2 $box M3DUB"
	puts $files "LAYOUT POLYGON 2 $box M4DUB"
	puts $files "LAYOUT POLYGON 2 $box M5DUB"
	puts $files "LAYOUT POLYGON 2 $box M6DUB"
	puts $files "LAYOUT POLYGON 2 $box M7DUB"
	puts $files "LAYOUT POLYGON 2 $box TM1DUB"
	puts $files "LAYOUT POLYGON 2 $box TM2DUB"
	}
}
deselectAll
close $files
	
