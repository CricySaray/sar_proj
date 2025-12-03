# 1. write pg tcl (in place invs db)
create_pg_model_for_macro_place -pg_resource_model -pg_model_over_macros -file 1.tcl

# 2. auto mix place (in invs db that need place mems ip, these are unplaced pstatus)
source 1.tcl
set_macro_place_constraint -all_macros -orientation {R0 MY}
set_macro_place_constraint -min_space_to_core 10 -forbidden_space_to_core 5 -min_space_to_macro 10 -forbidden_space_to_macro 5 -max_io_pin_group_keep_out 20
place_design -concurrent_macros
dbDeleteTrialRoute
unplaceAllInsts
