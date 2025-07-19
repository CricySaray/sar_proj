





# Please do not modify the sdir variable.
# Doing so may cause script to fail.
set sdir [pwd]
set dsn_path  "[join [lrange [split $sdir "/"] 0 end-1] "/"]/dsn"
#set current_dir [pwd]
#set mode ""
## run one corner 
##set RUN_ONECORNE 0 
#set VIEW "SDP_240414_Pindef0419_042401_cts2602_uk"
puts $VIEW
##################################################################
#    Source common and pt_setup_v1.tcl File                         #
##################################################################
source $sdir/scr/common_setup.tcl
source $sdir/scr/pt_setup_v1.tcl

set current_dir [pwd]/$VIEW
file mkdir $current_dir/db
#Leon
echo "VIEW: $VIEW" >> ${current_dir}/runtime
echo [date] >> ${current_dir}/runtime

# make REPORTS_DIR
#file mkdir $REPORTS_DIR

# make RESULTS_DIR
#file mkdir $RESULTS_DIR

# enable compute resource efficient ECO
set eco_enable_more_scenarios_than_hosts true

set eco_report_unfixed_reason_max_endpoints 10

set number [lindex  [date] 3]


# set the working directory and error files (delete the old work directory first)
#file delete -force ./work_${VIEW}
#set multi_scenario_working_directory ./work_${VIEW}_${number}
#set multi_scenario_merged_error_log ./work_${VIEW}_${number}/error_log.txt
set multi_scenario_working_directory ./work_${VIEW}
set multi_scenario_merged_error_log ./work_${VIEW}/error_log.txt

# add search path for design scripts (scenarios will
# inherit the master's search_path)
set search_path "$search_path $sh_launch_dir $sh_launch_dir/scr"

# add slave workstation information
#
# NOTE: change this to your desired machine/add more machines!

# run processes on the local machine
#set_host_options -max_cores  18

# run processes on machine lm121
#set_host_options -num_processes $dmsa_num_of_hosts -max_cores 4 lm121

# run SSH processes on machine lm121 (per SolvNet article 023519)
#set_host_options -num_processes $dmsa_num_of_hosts -max_cores 4 \
   -submit_command "/usr/bin/ssh" lm121

# run processes using lsf (LSF compute farm)
set cpu 2
set_host_options -load_factor 2 -num_processes $dmsa_num_of_hosts -max_cores $cpu 
#  -submit_command "bsub -Ip -q  $Quen  -n $cpu -o lsf.log " \
#  -terminate_command "/opt/openlava-4.0/bin/bkill"

# run processes using grd (Sun Grid compute farm)
#set_host_options -num_processes $dmsa_num_of_hosts -max_cores 4 \
  -submit_command "qsub -P bnormal" \
  -terminate_command "/grd/bin/qdel"



##################################################################
#    Get ECO Data from ICC and STAR_RC                           #
##################################################################
# Launch ICC and STAR_RC to get def and parasitic files for PT.
#get_eco_data -wait

#####################################################################
#                   Scenario Affinity                               #
#   Optionally one can assign scenarios an "affinity" for           # 
#   execution on a specified hosts, allowing more efficient         #
#   allocation of limited computing resources. For example,         #
#   For smaller jobs you can specify lower number of cores and      #
#   smaller memory size:                                            #
#                                                                   #
#   set_host_options -name SmallHosts -max_cores 8 num_processes 2 \#
#   submit_command {bsub -n 8 -R "rusage[mem=40000] span[ptile=1]"} #
#                                                                   #   For larger jobs you can specify higher number of cores and      #
#   bigger memory size:                                             #
#                                                                   #
#   set_host_options -name BigHosts -max_cores 16 num_processes 2 \ #
#   submit_command {bsub -n 16 -R "rusage[mem=80000] span[ptile=1]"}#
#                                                                   #
#   You can assign smaller jobs to smaller hosts                    #
#   and larger jobs to larger hosts:                                #
#                                                                   #
#   create_scenario -name S1 -affinity SmallHosts ...               #
#   create_scenario -name S2 -affinity SmallHosts ...               #
#   create_scenario -name S3 -affinity BigHosts ...                 #
#   create_scenario -name S4 -affinity BigHosts ...                 #
#####################################################################
# create scenario at every corner, for every mode
#       
# note that link command must be executed after library definitions
# in the common_data scripts before any constraints are applied!
#       
# the search_path is used below to resolve the script location
#if {[file exists /eda_files/proj/ict8810/archive/common_script/sta_common_script/corner_sta/${corner}_${check}]} {
if {!$RUN_ONECORNE}  {     
foreach corner $dmsa_corners {
 foreach mode $dmsa_modes {
   foreach check $dmsa_check {	 
	if {[file exists /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/corner_list/${corner}_${check}]} {
	  create_scenario \
	   -name ${mode}_${corner}_${check} \
	   -specific_variables {mode corner check VIEW current_dir RUN_ONECORNE  cdc_run Quen dsn_path} \
	   -specific_data "$sdir/scr/common_setup.tcl $sdir/scr/pt_setup_v1.tcl $sdir/scr/dmsa_mc.tcl"
	}
   }
 }
}
} else {


	  create_scenario \
	   -name ${mode}_${corner}_${check} \
	   -specific_variables {mode corner check VIEW current_dir RUN_ONECORNE  cdc_run Quen dsn_path} \
	   -specific_data "$sdir/scr/common_setup.tcl $sdir/scr/pt_setup_v1.tcl $sdir/scr/dmsa_mc.tcl"


}

# start processes on all remote machines
#
# if this hangs, check to make sure that you can run this version
#of PrimeTime on the specified machines/farm
start_hosts

# set session focus to all scenarios
current_session -all

source $sdir/scr/dmsa_analysis.tcl






