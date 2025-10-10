#exec rm cell_list
set list "*PD_AON_SLP* *PD_AON* *PD_AON_IO* *PD_DBB* *PD_CORE* "
set cell_name_list "FILL* DCAP* GDCAP* GFILL*"
foreach i $list {
	foreach a $cell_name_list {
		set cell_list [dbGet [dbGet top.insts.name $i -p].cell.name $a -u]
		foreach b   $cell_list {
		set num [llength [dbGet [dbGet top.insts.name $i -p].cell.name $b -p2]]
		echo "$i $b $num" >> cell_list
		}
	}
}
######################################num
exec rm -rf insi_info.tcl
set lvt_inst 0
set hvt_inst 0
set svt_inst 0

set  lvt_inst [dbGet -e -p [dbGet top.insts.cell.name *LVT -p2].isPhysOnly 0]
set  hvt_inst [dbGet -e -p [dbGet top.insts.cell.name *HVT -p2].isPhysOnly 0]
set  svt_inst [dbGet -e -p [dbGet -regexp top.insts.cell.name ".*35P140$" -p2].isPhysOnly 0]

set lvt_inst_num 0
set hvt_inst_num 0
set svt_inst_num 0

set lvt_inst_num [llength $lvt_inst]
set hvt_inst_num [llength $hvt_inst]
set svt_inst_num [llength $svt_inst]
######################################ratio
set total_num [expr $lvt_inst_num + $hvt_inst_num + $svt_inst_num]

set lvt_inst_ratio [format "%.2f" [expr double($lvt_inst_num) * 100 / $total_num]]
set hvt_inst_ratio [format "%.2f" [expr double($hvt_inst_num) * 100 / $total_num]]
set svt_inst_ratio [format "%.2f" [expr double($svt_inst_num) * 100 / $total_num]]
##########################################area
set lvt_inst_area 0
set hvt_inst_area 0
set svt_inst_area 0
foreach lvt  $lvt_inst {set lvt_inst_area [expr $lvt_inst_area + [dbGet $lvt.area]]}
foreach hvt  $hvt_inst {set hvt_inst_area [expr $hvt_inst_area + [dbGet $hvt.area]]}
foreach svt  $svt_inst {set svt_inst_area [expr $svt_inst_area + [dbGet $svt.area]]}

set total_area [expr $lvt_inst_area + $hvt_inst_area + $svt_inst_area]

set lvt_inst_area_ratio [format "%.2f" [expr double($lvt_inst_area) * 100 / $total_area ]]
set hvt_inst_area_ratio [format "%.2f" [expr double($hvt_inst_area) * 100 / $total_area ]]
set svt_inst_area_ratio [format "%.2f" [expr double($svt_inst_area) * 100 / $total_area ]]
####################################output
set info "
Type     count    count_ratio|       area        area_ratio
-----------------------------------------------------------------------------------------
[format {%-6s%8d%12s%% | %15s%8s%%} LVT: $lvt_inst_num $lvt_inst_ratio $lvt_inst_area $lvt_inst_area_ratio]
[format {%-6s%8d%12s%% | %15s%8s%%} HVT: $hvt_inst_num $hvt_inst_ratio $hvt_inst_area $hvt_inst_area_ratio]
[format {%-6s%8d%12s%% | %15s%8s%%} SVT: $svt_inst_num $svt_inst_ratio $svt_inst_area $svt_inst_area_ratio]
"
puts $info
set inst_info  [open insi_info.tcl w]
puts $inst_info $info
close $inst_info




