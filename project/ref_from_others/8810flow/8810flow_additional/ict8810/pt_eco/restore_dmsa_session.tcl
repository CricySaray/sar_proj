#exec mkdir -p ./tmp
#set pt_tmp_dir ./tmp

set view 0727
set all_sessions {
func_ml_cbest_hold
func_wcl_cworst_t_setup
func_wc_cworst_hold
scan_ml_cbest_hold
scan_wcl_cworst_t_setup
scan_wc_cworst_hold
scan_typ_85_setuphold
func_typ_85_setuphold
}


foreach scenario $all_sessions {
	create_scenario -name $scenario -image ../../db/${view}/chip_top.${view}.${scenario} -specific_variables {view}
}
set num_session [llength $all_sessions]
##Warning: set_multi_scenario_license_limit will be made obsolete and removed from future releases of PrimeTime starting with the 2016.06 release. (PT-007) 
#set_multi_scenario_license_limit -feature PrimeTime $num_session
#set_multi_scenario_license_limit -feature PrimeTime-SI $num_session
set_license_limit -quantity $num_session "PrimeTime PrimeTime-SI"
get_license -quantity $num_session "PrimeTime PrimeTime-SI"
#set_host_options -name on_shacs6311 -num_processes 5 -max_cores 4 -submit_command "/usr/bin/ssh" shacs6311
#set_host_options -name on_shacs5334 -num_processes 5 -max_cores 4 -submit_command "/usr/bin/ssh" shacs5334
#set_host_options -name on_shacs5307 -num_processes 3 -max_cores 4 -submit_command "/usr/bin/ssh" shacs5307
#set_host_options -name on_shacs5312 -num_processes 2 -max_cores 4 -submit_command "/usr/bin/ssh" shacs5312
#set_host_options -num_processes 4 -max_core 4
set cpu 4
# set_host_options -load_factor 2 -num_processes $num_session -max_cores $cpu \
#   -submit_command "bsub -Ip  -q I8810_STA -n $cpu -o lsf.log " \
#   -terminate_command "/opt/openlava-4.0/bin/bkill"
#set_host_options -load_factor 2 -num_processes 6 -max_cores $cpu \
#  -submit_command "bsub -Ip  -q I8810_PR -n $cpu -o lsf.log " \
#  -terminate_command "/opt/openlava-4.0/bin/bkill"
# set_host_options -load_factor 2 -num_processes 6 -max_cores $cpu \
#   -submit_command "bsub -Ip  -q I8810_PR1 -n $cpu -o lsf.log " \
#   -terminate_command "/opt/openlava-4.0/bin/bkill"
# set_host_options -load_factor 2 -num_processes 11 -max_cores $cpu \
#   -submit_command "bsub -Ip  -q I8810_STA -n $cpu -o lsf.log " \
#   -terminate_command "/opt/openlava-4.0/bin/bkill"
# set_host_options -load_factor 2 -num_processes [expr $num_session-6-11] -max_cores $cpu \
#   -submit_command "bsub -Ip  -q I8810_PR -n $cpu -o lsf.log " \
#   -terminate_command "/opt/openlava-4.0/bin/bkill"
set_host_options -load_factor 2 -num_processes $num_session -max_cores $cpu \
  -submit_command "bsub -Ip  -q I8810_STA -n $cpu -o lsf.log " \
  -terminate_command "/opt/openlava-4.0/bin/bkill"

start_hosts
report_host_usage -verbose
current_session $all_sessions

remote_execute { echo "Server: [info host]" }
# source -e fix_eco_timing.tcl
#remote_execute {update_timing}

