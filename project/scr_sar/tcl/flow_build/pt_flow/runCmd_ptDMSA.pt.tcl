#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/02 10:42:29 Thursday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : Execute the PT DMSA command to fix DRV, setup, and hold violations in STA. Various options can be customized.
# return    : /
# ref       : link url
# --------------------------
# TO_WRITE
proc runCmd_ptDMSA {args} {
    # $actionsString : The order of commands you need to execute. Use a semicolon to separate each complete action, and use spaces to separate each 
    #                   option within an action. The action commands will be executed in the order of the actions.
  set actionsString                    "setup size_cell ; hold size_cell ; hold insert_buffer" ; # first: fix setup using mothod of size_cell, then fix hold using method of size_cell, finally, fix hold using method of insert_buffer
  set scenariosToRun                   {}
  set sessionPaths                      [glob -nocomplain run/version/*/*.session] ; # All the sessions of the scenarios that need to be read are available in this directory.
  set resultDir                        "./"
  set workingDir                       [file join $resultDir "work"]
  set dmsaRunningLogFile               "$resultDir/dmsa_running[clock format [clock seconds]]"
  set icc2ToInvsEcoScriptFile          "/path/to/icc2ToInvs.eco_script.tcl"
  set dontUseCellsList                 "*/TIE* */DEL* */ANATENNA* */*AOI222* */MUX4* */D0BWP */*D0BWPLVT */G*"
  set defFileWhenPhysicalAware         ""
  set techLefFileWhenPhysicalAware     ""
  set lefFilesWhenPhysicalAware        ""
  set fillerCellsListWhenPhysicalAware {}
  set ifAllowInsertBuffer              1
  set ifAllowFillerCellsAsOpenSites    1
  set ecoReportUnfixedReasonMaxEndpoint 10000
  set multiScenarioMergedErrorLimit    10000
  set multiScenarioMergedErrorLogFile  error_multi_scenario.log
  set reportDefaultSignificantDigits   4
  set hostProcessesNum                 [llength $scenariosToRun] ; # The value of this option must be greater than the number of scenarios, and it is recommended that the two quantities be equal.
  set maxCores                         4 
  set clockInverterList                {}
  set fixHoldBufferList                {}
  set fixSetupBuffList                 {}
  set fixDrvBufferList                 {}
  set fixDrvHoldMargin                 0.001
  set fixDrvSetupMargin                0.010
  set fixTimingHoldMargin              0.003
  set fixTrmingSetupMargin             0.020
  set pbaMode                          path
  set ecoPhysicalMode                  open_site
  set fixTimingSetupToList             {}
  set fixTimingHoldToList              {}

  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }

  if {![file isdirectory [file dirname $workingDir]]} {
    error "proc runCmd_ptDMSA: check your input: directory path([file dirname $workingDir]) workingDir($workingDir) is not exists!!!"
  }

  set multi_scenario_merged_error_limit $multiScenarioMergedErrorLimit
  set multi_scenario_merged_error_log $multiScenarioMergedErrorLogFile
  set multi_scenario_working_directory $workingDir
  set report_default_significant_digits $reportDefaultSignificantDigits
  foreach scenario_session $sessionPaths {
    create_scenario -name $scenario -image $scenario_session 
  }
  set_app_var eco_enable_mim true
  set_host_options -max_cores $maxCores -num_processes $hostProcessesNum
  report_host_usage
  start_hosts
  current_session -all
  current_scenario -all

  set eco_allow_filler_cells_as_open_sites true
  set eco_report_unfixed_reason_max_endpoints 1000000
  set_app_var read_parasitics_load_locations true

  remote_execute -verbose {
    foreach temp_dontUse $dontUseCellsList {
      set_dont_use $temp_dontUse 
    }
    set eco_strict_pin_name_equivalence true
    set timing_save_pin_arrival_and_slack true
    set_app_var eco_alternative_area_ratio_threshold 1.2
    set_eco_options -physical_tech_lib_path $techLefFileWhenPhysicalAware -physical_lib_path $lefFilesWhenPhysicalAware -filler_cell_names $fillerCellsListWhenPhysicalAware -physical_enable_clock_data -log_file  $dmsaRunningLogFile
    check_eco
    update_timing
  }
  

}

define_proc_arguments runCmd_ptDMSA \
  -info "run cmd for PT DMSA"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
