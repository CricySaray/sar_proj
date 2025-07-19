proc userAddBlockDumy_Blk {layer_num} {
	set base_path [pwd]
	set design_name [dbgDesignName]
	set files [open $base_path/../../pv_clb/scr/${design_name}_block_dumy_blockage.tcl w]
	
        set fp_shapes [dbShape [dbGet top.fplan.boxes] SIZE 5 SIZE -5 -output polygon]
	set inner_fp_shapes [dbShape $fp_shapes SIZE -0.6  -output polygon]
	set inner_block_boxes [dbShape $fp_shapes ANDNOT $inner_fp_shapes -output rect]
	foreach box $inner_block_boxes {
		set x1 [lindex $box 0]
		set y1 [lindex $box 1]
		set x2 [lindex $box 2]
		set y2 [lindex $box 3]
		for { set i  1 } { $i <= $layer_num } { incr i 1} {
			puts $files "LAYOUT POLYGON 2 $x1 $y1 $x2 $y2 M${i}DUB"
		}
		puts $files "LAYOUT POLYGON 2 $x1 $y1 $x2 $y2 TM2DUB"
		puts $files "LAYOUT POLYGON 2 $x1 $y1 $x2 $y2 TM1DUB"
	}
close $files
}
