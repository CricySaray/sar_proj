# ------------------------------
# 00 reset propatated clock
set_interactive_constraint_modes [all_constraint_modes active]
reset_propagated_clock [all_clocks]
reset_propagated_clock [get_ports *]
reset_propagated_clock [git_pins -hier *]
set_interactive_constraint_modes {}

# ------------------------------
# 01 setNanoRouteMode for ccopt ; ## can be covered by set_ccopt_property, do we need it???
#setCTSMode -routeCNet true

# ------------------------------
# 02.1 ccopt_property cell setting
set_ccopt_property use_inverters 



