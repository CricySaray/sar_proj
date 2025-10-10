proc restore_dmsa_session {args} {
 parse_proc_arguments -args $args results

 if {[set dirs [glob -nocomplain -type f $results(dir_name)/*/lib_map]] eq {}} {
  echo "Error: no save_session directories found."
  return 0
 }

 foreach dir $dirs {
  set dir [file dirname $dir]
  echo "Defining scenario '[set name [file tail $dir]]'."
  create_scenario -name $name -image $dir
 }
}

define_proc_attributes restore_dmsa_session \
 -info "Restores PrimeTime sessions in DMSA" \
 -define_args \
 {
  {dir_name "Directory name to restore from" "dir_name" string required}
}

set sh_source_uses_search_path true
set report_default_significant_digits 4

set eco_enable_more_scenarios_than_hosts true
set eco_alternative_area_ratio_threshold 0
set eco_strict_pin_name_equivalence true
set read_parasitics_load_locations true
set eco_allow_filler_cells_as_open_sites true

file delete -force ./pt_dmsa
file mkdir ./pt_dmsa
file mkdir ./rpt
set multi_scenario_working_directory "./pt_dmsa"
set multi_scenario_merged_error_log "./rpt/data.fix_eco_error.default.txt"
#set_multi_scenario_license_limit -feature PrimeTime 100
#set_multi_scenario_license_limit -feature PrimeTime-SI 100
#set_multi_scenario_license_limit -feature PrimeTime-PX 100
set_host_options -max_cores 4 -num_process 16 [exec hostname]
start_hosts

restore_dmsa_session ./session

current_session -all
remote_execute {
	define_user_attribute pt_dont_use \
	-quiet -type boolean -class lib_cell
	proc set_pt_dont_use {lib_cell} {
            set_user_attribute \
            -class lib_cell \
            [get_lib_cell -quiet $lib_cell] \
             pt_dont_use true
              }
}

remote_execute {
	set_pt_dont_use [list \
              *D0BWP* \
              *D1BWP* \
              *D20BWP* \
              ISOSR* \
              PT* \
              .*35P140$ \
              ]
}

return
#########eco by handle###########


remote_execute {write_changes -format icctcl -output ./icc.tcl}
remote_execute {write_changes -format ptsh -output ./icc.pt.tcl}
remote_execute {save_session dmsa.session}

#exit


