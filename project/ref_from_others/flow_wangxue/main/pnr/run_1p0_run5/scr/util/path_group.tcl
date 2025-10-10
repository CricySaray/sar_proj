reset_path_group -all
group_path -from [all_inputs ] -to [all_registers  ] -name in2reg
group_path -from [all_registers ] -to [all_outputs ] -name reg2out
group_path -from [all_inputs ] -to [all_outputs ] -name in2out
group_path -from [get_cells -hierarchical * -filter "@is_memory_cell == true "] -to [all_registers ] -name mem2reg
group_path -from [get_cells -hierarchical * -filter "@is_memory_cell == true "] -to [get_cells -hierarchical * -filter "@is_memory_cell == true "] -name mem2mem
group_path -to [get_cells -hierarchical * -filter "@is_memory_cell == true "] -from [all_registers ] -name reg2mem
group_path -from [remove_from_collection [all_registers ] [get_cells -hierarchical * -filter "@is_memory_cell == true "]] -to [remove_from_collection [all_registers ] [get_cells -hierarchical * -filter "@is_memory_cell == true "]] -name reg2reg
group_path -from [all_registers ] -to [get_cells -filter "is_integrated_clock_gating_cell && !is_hierarchical" -hierarchical ] -name reg2ICG
group_path -from u_afe_core  -to [all_registers ] -name afe2reg
group_path -to  u_afe_core  -from  [all_registers ] -name reg2afe

setPathGroupOptions -effortLevel high -weight 2 reg2reg
setPathGroupOptions -effortLevel high -weight 2 in2reg
setPathGroupOptions -effortLevel high -weight 2 mem2reg
setPathGroupOptions -effortLevel high -weight 2 mem2mem
setPathGroupOptions -effortLevel high -weight 2 reg2mem
setPathGroupOptions -effortLevel high -weight 2 reg2ICG
setPathGroupOptions -effortLevel high -weight 2 afe2reg
setPathGroupOptions -effortLevel high -weight 2 reg2afe
setPathGroupOptions -effortLevel low in2reg
setPathGroupOptions -effortLevel low reg2out
setPathGroupOptions -effortLevel low in2out
reportPathGroupOptions

