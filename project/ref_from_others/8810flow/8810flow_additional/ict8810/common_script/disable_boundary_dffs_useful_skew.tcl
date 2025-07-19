set boundary_in_ffs [get_db [get_db [get_db [get_db [get_db [all_fanout -from [get_db [get_db ports -if {.direction == "in" && .name != "ijtag_reset" && .name != "ijtag_se"  && .name != "ict_scan_se"}] .name] -endpoints_only ] -if {.obj_type == pin && .is_data == true && .is_clear == false && .is_async == false && .is_clock == false && .base_pin.base_cell.class == core}] -if {.inst.base_cell.is_latch == false && .inst.base_cell.is_sequential == true && .inst.base_cell.is_integrated_clock_gating == false}] .inst] -unique .pins -if {.is_clock == true}] .name]
set boundary_out_ffs [get_db [get_db [all_fanin -to [get_db [get_db ports -if {.direction == "out"}] .name] -startpoints_only ] -if {.obj_type == pin && .inst.is_sequential == true && .base_pin.base_cell.class == core}] .name]
set boundary_ffs  [concat $boundary_in_ffs $boundary_out_ffs]

foreach pins $boundary_ffs {
    set_ccopt_property schedule off -pin $pins
}
