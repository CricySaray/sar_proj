########################################
# author: Leon Sun
# Date: 2022/01/13 18:14:15
# Version: 1.0
# path group setting
########################################

reset_path_group -all
#createBasicPathGroups -expanded
group_path -from [all_inputs] -to [all_registers] -name in2reg
group_path -from [all_registers] -to [all_outputs] -name reg2out
group_path -from [all_inputs] -to [all_outputs] -name in2out
group_path -from [get_cells -hier * -filter "@is_memory_cell == true"] -to [all_registers] -name mem2reg
group_path -to [get_cells -hier * -filter "@is_memory_cell == true"] -from [all_registers] -name reg2mem
group_path -from [remove_from_collection [all_registers] [get_cells -hier * -filter "@is_memory_cell == true"]] -to [remove_from_collection [all_registers] [get_cells -hier * -filter "@is_memory_cell == true"]] -name reg2reg
group_path -from [all_registers] -to [get_cells -filter "is_integrated_clock_gating_cell && !is_hierarchical" -hier] -name reg2ICG
setPathGroupOptions mem2reg -effortLevel high -weight 5
setPathGroupOptions reg2mem -effortLevel high -weight 5
setPathGroupOptions reg2reg -effortLevel high -weight 5
setPathGroupOptions reg2ICG -effortLevel high -weight 5
setPathGroupOptions in2reg  -effortLevel low
setPathGroupOptions reg2out -effortLevel low
setPathGroupOptions in2out  -effortLevel low

if { [regexp {route} $vars(step)] } {
    set handshake_ports [get_ports "*valid* *vld* *ready* *rdy*" -filter "direction==out" -quiet]
    if { $handshake_ports != "" } { 
        set sinks [get_object_name [filter_collection [all_fanin -to $handshake_ports -startpoint -view func_wcl_cworst_t] name=~CK*]]
        if { $sinks != "" } { 
            echo "INFO: for handshake signals"
            group_path -name  to_handshake -from [all_registers] -to [get_cells -of [get_pins $sinks]]
            setPathGroupOptions to_handshake -effortLevel high -weight 2
        }   
    }
}

reportPathGroupOptions
