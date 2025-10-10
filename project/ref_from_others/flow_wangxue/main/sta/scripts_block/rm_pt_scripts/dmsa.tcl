
# Please do not modify the sdir variable.
# Doing so may cause script to fail.
set sdir "../../scripts_block" 

##################################################################
#    Source common and pt_setup.tcl File                         #
##################################################################

source $sdir/rm_setup/pt_setup.tcl

# make REPORTS_DIR
file mkdir $REPORTS_DIR

# make RESULTS_DItruee mkdir $RESULTS_DIR

# set the working directory and error files (delete the old work directory first)
if { $ECO_FIX == "false" } {
#  file delete -force ./work
}
set multi_scenario_working_directory ./$env(DATAOUT_VERSION)
set multi_scenario_merged_error_log ./$env(DATAOUT_VERSION)/error_log.txt

# add search path for design scripts (scenarios will
# inherit the master's search_path)
set search_path "$search_path $sh_launch_dir $sh_launch_dir/$sdir/rm_pt_scripts"

# add slave workstation information
#
# NOTE: change this to your desired machine/add more machines!

# run processes on the local machine
set_host_options -num_processes $dmsa_num_of_hosts -max_cores 8
#set_host_options -num_processes 12  -max_cores 8
#set_host_options -num_processes 15 -max_cores 4

# run processes on machine lm121
#set_host_options -num_processes $dmsa_num_of_hosts -max_cores 4 lm121
#set_host_options -num_processes $dmsa_num_of_hosts -max_cores 4 lm121
#set_host_options -name ds -num_processes 5 -protocol rsh -max_cores 5  { IBM001 IBM002}

 
# run SSH processes on machine lm121 (per SolvNet article 023519)
#set_host_options -num_processes $dmsa_num_of_hosts -max_cores 4 \
#   -submit_command "/usr/bin/ssh" lm121

# run processes using lsf (LSF compute farm)
#set_host_options -num_processes $dmsa_num_of_hosts -max_cores 4 \
  -submit_command "bsub -n 2" \
  -terminate_command "/lsf/bin/bkill"

# run processes using grd (Sun Grid compute farm)
#set_host_options -num_processes $dmsa_num_of_hosts -max_cores 4 \
  -submit_command "qsub -b y -P bnormal" \
  -terminate_command "/grd/bin/qdel"

# set license resource usage
#
# if this is less than the processor count, licenses will be
# dynamically moved around to maximize their usage
#
# this license count is only the ceiling;  licenses will only
# be pulled from the license server as they are needed
#set_multi_scenario_license_limit -feature PrimeTime $dmsa_num_of_licenses
#set_multi_scenario_license_limit -feature PrimeTime-SI $dmsa_num_of_licenses



# create scenario at every corner, for every mode
#
# note that link command must be executed after library definitions
# in the common_data scripts before any constraints are applied!
#
# the search_path is used below to resolve the script location

if { $ECO_FIX == "false" } {
  foreach corner $dmsa_corners {
   foreach mode $dmsa_modes {
    create_scenario \
     -name ${mode}_${corner} \
     -specific_variables {mode corner} \
     -specific_data "$sdir/rm_setup/pt_setup.tcl $sdir/rm_pt_scripts/dmsa_mc.tcl"
   }
  }
} else {
  foreach corner $dmsa_corners {
   foreach mode $dmsa_modes {
    create_scenario \
     -name ${mode}_${corner} \
     -specific_variables {mode corner} \
     -image $sh_launch_dir/$env(DATAOUT_VERSION)/${mode}_${corner}/${DESIGN_NAME}_ss
   }
  }
}



# start processes on all remote machines
#
# if this hangs, check to make sure that you can run this version
# of PrimeTime on the specified machines/farm
start_hosts

# set session focus to all scenarios
current_session -all
#current_session { hp_mode_hp_ssgm40c_cworst_D_dc} 
#current_session {hp_func_mode_hp_ffgm40c_cbest_dc} 
#current_session {scan_func_mode_tt_tt25c_ctyp_dc  hp_func_mode_hp_ssgm40c_cworst_D_dc} 

# Produce report for all scenarios
if { $ECO_FIX == "false" } {
  source $sdir/rm_pt_scripts/dmsa_analysis.tcl
} else {
  source $sdir/rm_pt_scripts/dmsa_fix.tcl
}


## -------------------------------------
## Place the merged error log into the normal logfile.
## -------------------------------------

set fid [open $multi_scenario_merged_error_log r]
puts [read $fid]
close $fid

exit

