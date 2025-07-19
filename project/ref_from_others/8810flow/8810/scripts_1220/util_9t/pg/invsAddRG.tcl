proc invsAddExMemRG {args} {
	parse_proc_arguments -args $args results
	if [info exists results(-layer)] {
		set rg_layer $results(-layer)
	}
	if [info exists results(-name)] {
		set name $results(-name)
	}
	set core_shape [dbShape [dbGet top.fplan.boxes] -output polygon]
	if {$rg_layer == 5} {
		set mem_shape [dbShape [dbShape [dbShape [dbget [dbGet top.insts.cell.subClass block -p2].box] -output polygon] SIZEX 20 -output polygon] SIZEY 15 -output polygon]
		set mem_shape [dbShape $mem_shape SIZEY -9.5 -output polygon]
	} elseif {$rg_layer == 6} {
		set mem_shape [dbShape [dbShape [dbget [dbGet top.insts.cell.subClass block -p2].box] -output polygon] SIZEX 50 -output polygon]
	} else {
		set mem_shape [dbShape [dbget [dbGet top.insts.cell.subClass block -p2].box] -output polygon]
	}
	set mem_ex_boxes [dbShape $core_shape ANDNOT $mem_shape -output rect]
	foreach box $mem_ex_boxes {
		set x1 [lindex $box 0]
		set y1 [lindex $box 1]
		set x2 [lindex $box 2]
		set y2 [lindex $box 3]
		createRouteBlk -box "$x1 $y1 $x2 $y2" -layer $rg_layer -name $name
	}
}

define_proc_arguments invsAddExMemRG -info "add rg execpt mem" \
-define_args \
{
	{-layer "rg on layer" "" string optional}
	{-name "rg name" "" string optional}
}

proc invsAddMemRG {args} {
	parse_proc_arguments -args $args results
	if [info exists results(-layer)] {
		set rg_layer $results(-layer)
	}
	if [info exists results(-name)] {
		set name $results(-name)
	}
	set core_shape [dbShape [dbGet top.fplan.boxes] -output polygon]
	set mem_shape [dbShape [dbShape [dbShape [dbget [dbGet top.insts.cell.subClass block -p2].box] -output polygon] SIZEY 16 -output polygon] SIZEY -14 -output polygon]
	set mem_boxes [dbShape $mem_shape -output rect]
	foreach box $mem_boxes {
		set x1 [lindex $box 0]
		set y1 [lindex $box 1]
		set x2 [lindex $box 2]
		set y2 [lindex $box 3]
		createRouteBlk -box "$x1 $y1 $x2 $y2" -layer $rg_layer -name $name
	}
}

define_proc_arguments invsAddMemRG -info "add rg on mem" \
-define_args \
{
	{-layer "rg on layer" "" string optional}
	{-name "rg name" "" string optional}
}

proc invsAddChannelRG {args} {
	parse_proc_arguments -args $args results
	if [info exists results(-layer)] {
		set rg_layer $results(-layer)
	}
	if [info exists results(-sizey)] {
		set sizey $results(-sizey)
	}
	if [info exists results(-name)] {
		set name $results(-name)
	}
	set shapes [dbShape [dbShape [dbget [dbGet top.insts.cell.subClass block -p2].box] SIZE 15] SIZE -15 -output polygon]
	set all_mem_shapes [dbShape [dbShape [dbget [dbGet top.insts.cell.subClass block -p2].box] SIZEY 15] SIZEY -15 -output polygon]
	set channel_boxes [dbShape $shapes ANDNOT $all_mem_shapes SIZEY $sizey -output rect]
	foreach box $channel_boxes {
		set x1 [lindex $box 0]
		set y1 [lindex $box 1]
		set x2 [lindex $box 2]
		set y2 [lindex $box 3]
		createRouteBlk -box "$x1 $y1 $x2 $y2" -layer $rg_layer -name $name
	}
}

define_proc_arguments invsAddChannelRG -info "add rg on channel" \
-define_args \
{
	{-layer "rg on layer" "" string optional}
	{-sizey "rg sizey" "" string optional}
	{-name "rg name" "" string optional}
}
proc invsAddRG {args} {
	parse_proc_arguments -args $args results
	if [info exists results(-layer)] {
		set rg_layer $results(-layer)
	}
	if [info exists results(-name)] {
		set name $results(-name)
	}
	editSelect -layer $rg_layer
	if {$rg_layer == 5 || $rg_layer == 7 } {
		set layer_boxes [dbShape [dbShape [dbShape [dbShape [dbGet selected.box] -output polygon] SIZEX 0.2 -output polygon] SIZEX -0.2 -output rect]]
	}
	if {$rg_layer == 6 } {
		set layer_boxes [dbShape [dbShape [dbShape [dbShape [dbGet selected.box] -output polygon] SIZEX 0.2 -output polygon] SIZEX -0.2 -output rect]]
	}
	foreach box $layer_boxes {
		set x1 [lindex $box 0]
		set y1 [lindex $box 1]
		set x2 [lindex $box 2]
		set y2 [lindex $box 3]
		createRouteBlk -box "$x1 $y1 $x2 $y2" -layer "M2 M3 M4 M5 M6 M7" -name $name
	}
	deselectAll
}

define_proc_arguments invsAddRG -info "add rg on layer area" \
-define_args \
{
	{-layer "rg on layer" "" string optional}
	{-name "rg name" "" string optional}
}
