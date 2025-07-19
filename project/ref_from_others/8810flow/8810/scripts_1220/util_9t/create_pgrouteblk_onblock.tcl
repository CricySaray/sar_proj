proc create_blockPGPin_routeblk { } {
	deselectAll
	foreach_in_collection instCol [get_cell -hier * -filter "is_memory_cell== true"] {
                set inst [get_object_name $instCol]
		selectInst $inst 
		set inst_boxes [dbGet selected.boxes]
		set instPtr [dbGet selected] 
		set ShapePtr [dbGet selected.cell.pgTerms.pins.allShapes]
		set m4_blk_boxes {0 0 0 0 }
		foreach shape $ShapePtr {
			set layer_name [dbGet  $shape.layer.name]
			set rect [dbGet $shape.shapes.rect]
			if { $rect == "0x0" } {
				set rect { 0 0 0 0}
			} else {
				set rect [dbTransform -inst [dbGet  $instPtr.name] -localPt $rect]
			}
			if { $layer_name == "M4" } {
				set m4_blk_boxes [dbShape $m4_blk_boxes OR $rect -output rect]
			}
		}
		set m4_blk [dbShape [dbShape $inst_boxes size 0.6 ] AND [dbShape [dbShape $m4_blk_boxes size -0.95 ] size 1.45 ]  -output rect]
		foreach m_list $m4_blk {
			createRouteBlk -boxList "$m_list" -layer M4 -name blockpgpin_blkm4
		}
		deselectAll
	}
}
