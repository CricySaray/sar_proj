set pds "PD_AON_SLP PD_AON PD_AON_IO PD_DBB PD_CORE"

set f1 [open vt_sum.rpt w]

foreach pd $pds {
     set obj_type [get_db group:$pd .members.obj_type -u ]
     if {$obj_type eq "hinst"} {
     set total_inst [get_db [get_db group:$pd .members.insts -if {.is_physical==0}] .name ]
     set lvt_inst [get_db [get_db group:$pd .members.insts -if {.base_cell.name == *LVT}] .name ]
     set hvt_inst [get_db [get_db group:$pd .members.insts -if {.base_cell.name == *7T40*HVT}] .name]
     set svt_inst [get_db [get_db group:$pd .members.insts -if {.base_cell.name == *35P140}] .name]
     } else {
     set total_hinst [get_db group:$pd .members -if {.obj_type==hinst}] 
     set lvt_hinst [get_db [get_db $total_hinst .insts -if {.base_cell.name == *LVT} ]  .name]
     set hvt_hinst [get_db [get_db $total_hinst .insts -if {.base_cell.name == *7T40*HVT}]  .name ]
     set svt_hinst [get_db [get_db $total_hinst .insts -if {.base_cell.name == *35P140}]  .name ]
     set total_insts [get_db group:$pd .members -if {.obj_type==inst}] 
     set lvt_insts [get_db [get_db $total_insts -if {.base_cell.name == *LVT} ] .name]
     set hvt_insts [get_db [get_db $total_insts -if {.base_cell.name == *7T40*HVT} ] .name]
     set svt_insts [get_db [get_db $total_insts -if {.base_cell.name == *35P140} ] .name]
     
     set total_inst [concat $total_hinst $total_insts]
     set lvt_inst [concat $lvt_hinst $lvt_insts]
     set svt_inst [concat $svt_hinst $svt_insts]
     set hvt_inst [concat $hvt_hinst $hvt_insts]
     }

     set total_num [llength $total_inst]
     set lvt_inst_num [llength $lvt_inst]
     set hvt_inst_num [llength $hvt_inst]
     set svt_inst_num [llength $svt_inst]

     set total_num [expr $lvt_inst_num + $hvt_inst_num + $svt_inst_num]
     
     set lvt_inst_ratio [format "%.2f" [expr double($lvt_inst_num) * 100 / $total_num]]
     set hvt_inst_ratio [format "%.2f" [expr double($hvt_inst_num) * 100 / $total_num]]
     set svt_inst_ratio [format "%.2f" [expr double($svt_inst_num) * 100 / $total_num]]

     set lvt_inst_area 0
     set hvt_inst_area 0
     set svt_inst_area 0
     foreach lvt  $lvt_inst {set lvt_inst_area [expr $lvt_inst_area + [get_db inst:$lvt .area]]}
     foreach hvt  $hvt_inst {set hvt_inst_area [expr $hvt_inst_area + [get_db inst:$hvt .area]]}
     foreach svt  $svt_inst {set svt_inst_area [expr $svt_inst_area + [get_db inst:$svt .area]]}
     
     set total_area [expr $lvt_inst_area + $hvt_inst_area + $svt_inst_area]
     
     set lvt_inst_area_ratio [format "%.2f" [expr double($lvt_inst_area) * 100 / $total_area ]]
     set hvt_inst_area_ratio [format "%.2f" [expr double($hvt_inst_area) * 100 / $total_area ]]
     set svt_inst_area_ratio [format "%.2f" [expr double($svt_inst_area) * 100 / $total_area ]]

     
     set info "
     POWER_DOMAIN: $pd
     Type     count    count_ratio|       area        area_ratio
     -----------------------------------------------------------------------------------------
     [format {%-6s%8d%12s%% | %15s%8s%%} LVT: $lvt_inst_num $lvt_inst_ratio $lvt_inst_area $lvt_inst_area_ratio]
     [format {%-6s%8d%12s%% | %15s%8s%%} HVT: $hvt_inst_num $hvt_inst_ratio $hvt_inst_area $hvt_inst_area_ratio]
     [format {%-6s%8d%12s%% | %15s%8s%%} SVT: $svt_inst_num $svt_inst_ratio $svt_inst_area $svt_inst_area_ratio]
     "
     puts $info
     puts $f1 $info
     
}

#puts $f1 "     TOTAL"
#redirect -append $f1 {invs_Count_Vt -out ./vt_sum}
close $f1


set aon_pds "PD_AON_SLP PD_AON PD_AON_IO"

set f2 [open ecofile w]

foreach pd $aon_pds {
     set obj_type [get_db group:$pd .members.obj_type -u ]
     set total_inst [get_db [get_db group:$pd .members.insts -if {.is_physical==0}] .name ]
     set lvt_inst [get_db [get_db group:$pd .members.insts -if {.base_cell.name == *LVT}] .name ]
     set hvt_inst [get_db [get_db group:$pd .members.insts -if {.base_cell.name == *7T40*HVT}] .name]
     set svt_inst [get_db [get_db group:$pd .members.insts -if {.base_cell.name == *35P140}] .name]

     foreach lvt $lvt_inst {
     set cell [get_db inst:$lvt .base_cell.name]
     set ncell [string map {35P140LVT 40P140HVT} $cell]
     puts $f2 "ecoChangeCell -inst $lvt -cell $ncell"
     }
     foreach svt $svt_inst {
     set cell [get_db inst:$svt .base_cell.name]
     set ncell [string map {35P140 40P140HVT} $cell]
     puts $f2 "ecoChangeCell -inst $svt -cell $ncell"
     }

     }
close $f2

