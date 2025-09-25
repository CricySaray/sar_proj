#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/22 17:06:08 Monday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : run cmd for init check in pt
# return    : cmds list
# ref       : link url
# --------------------------
source ../../packages/timer.tcl; # start_timer end_timer
source ../common/convert_file_to_list.common.tcl; # convert_file_to_list
source ../../packages/every_any.package.tcl; # any
source ../batchRunCmd_forProc_genCmd.common.tcl; # batchRunCmd_forProc_genCmd
source ../genCmd_setMaxTransition_forDataClock_byClockPeriod.pt.tcl; # genCmd_setMaxTransition_forDataClock_byClockPeriod
source ./procs_of_init_check.pt.tcl; # init check procs
proc runCmd_init_check {args} {
  set stepIndexOfRunCmd                       0 ; # Specify an integer starting from 0. If it is 0, the commands will run from the beginning. If 10 is specified, 
                                                  # the commands will start executing from the command with sequence number 10, and the commands with sequence 
                                                  # numbers 0-9 will not be executed. This parameter is suitable for scenarios where the proc has been executed 
                                                  # once but failed. After you modify the code and parameters, you can perform subsequent operations without re-executing 
                                                  # the commands that have been executed before.
  set netlistFiles                            "" ; # can provide more than one file
  set sdcFiles                                "" ; # only provide one netlist file
  set uncertaintyFile                         "" ; # you can provide file of uncertainty setting
  set dontUseCellsRegExpList                  "TIE* DEL* ANTENNA* AOI222 MUX4 *BWPLVT *D0BWP* G*" ; # for example : 
  set dbListFile                              "" ; # specified corner db list file
  set scenario                                "func_setup_0p99v_cworst_m40c" ; # for example: func_setup_0p99v_cworst_m40c
  set designName                              "SC5019_TOP"
  set suffixOfResultRptFile                   "song"
  set formatExpOfResultFile                   "<design>_<scenario>_<body>_<suffix>.rpt" ; # like: "initCheck_<design>_<suffix>.rpt"; optional <design>|<suffix>
  set bufferInverterCelltypeExpList           {{BUFFD*BWP*} {INVD*BWP*}}
  set resultDir                               "./"

  set maxCores                                16
  set maxMessageLimit                         20
  set ifSouchUsesSearchPath                   true

  set ratioOfClockWhenSetMaxTranForClock      0.167 ; # cycle ratio of the clock when setting the clock max transition. 1 / 6
  set ratioOfClockWhenSetMaxTranForData       0.33 ; # cycle ratio of the clock when setting the clock max transition. 1 / 3
  set userSetClockMaxTransition               150  ; # ps
  set userSetDataMaxTransition                400 ; # ps
  set dataDefaultMaxTransitionInLibSet        378 ; # ps, default max transition in lib of std cell
  set ratioOfLibSetDefaultMaxTransitionOfData 0.67 ; # 2 / 3
  set extraDerateForClock                     10 ; # ps, Set stricter parameters for calculating subsequent values, and apply an additional margin if necessary.
  set extraDerateForData                      10 ; # ps
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set tempStepIndexOfCmd $stepIndexOfRunCmd
  try {
    if {$tempStepIndexOfCmd == 0} {
      if {![file isdirectory $resultDir]} {
        error "proc runCmd_init_check: check your result dir($resultDir), is not exist!!!"
      }
      set resultScenarioDir "$resultDir/$scenario"
      set optionsOfFormatExp [list "<design>" "<suffix>" "<scenario>" "<body>"]
      # check input correction
      if {![file isfile $dbListFile]} {
        error "proc genCmd_init_check: check your input: dbListFile($dbListFile) is not found!!!" 
      }
      set stringname_of_formatExp [regexp -all -inline {<\w+>} $formatExpOfResultFile]
      if {$formatExpOfResultFile == "" || ![every x $stringname_of_formatExp { expr {$x in $optionsOfFormatExp}}]} {
        error "proc genCmd_init_check: check your input: formatExpOfResultFile($formatExpOfResultFile) is not any option of list($optionsOfFormatExp) !!!"
      }
      set varname_of_formatExp [lmap temp $stringname_of_formatExp { regsub {>|<} $temp ""  }]
      set rawRptFileName $formatExpOfResultFile
      set mapString [list design $designName suffix $suffixOfResultRptFile scenario $scenario]
      foreach temp_varname [lsearch -not -all -inline -exact $varname_of_formatExp "body"] {
        set rawRptFileName [string map $mapString $rawRptFileName]
      }
      # NOTICE: Because the `uplevel` command is used along with the `subst` command for variable substitution in strings, issues arise during program execution 
      # due to the impact of subcommands such as `list` in expressions like `set temp [list "test" "is" "now"]`. To address this, a unified approach is 
      # adopted: define specific variables outside of `uplevel`, then redefine variables with the same name inside `uplevel` using the format `set testVar 
      # $testVar`. This method avoids executing subcommands within `uplevel` and prevents unexpected errors, as the scopes of these variables differ.
      uplevel #0 [subst {
        set resultScenarioDir "$resultDir/$scenario"
        exec mkdir -p $resultScenarioDir
        set optionsOfFormatExp $optionsOfFormatExp
        set stringname_of_formatExp $stringname_of_formatExp
        set_host_options -max_cores $maxCores
        set sh_message_limit $maxMessageLimit
        if {$ifSouchUsesSearchPath} { set sh_source_uses_search_path true } else { set sh_source_uses_search_path false }
        set varname_of_formatExp $varname_of_formatExp
        set mapString $mapString
        set rawRptFileName $rawRptFileName
      }]
      incr tempStepIndexOfCmd 1  ; # == 1
    }
    if {$tempStepIndexOfCmd == 1} {
      # logic part 
      start_timer
      uplevel #0 [list start_timer]
      set link_library [convert_file_to_list $dbListFile]
      uplevel #0 [list set link_library $link_library]
      incr tempStepIndexOfCmd 1 ; # == 2
    }
    if {$tempStepIndexOfCmd == 2} {
      uplevel #0 [subst {
        foreach tempNetlist $netlistFiles {
          puts " - > Reading Netlist: $tempNetlist ..."
          read_verilog $tempNetlist 
        }
        current_design $designName
      }]
      incr tempStepIndexOfCmd 1 ; # == 3
    }
    if {$tempStepIndexOfCmd == 3} {
      uplevel #0 [subst {
        puts " - > link design ..."
        link_design > $resultScenarioDir/link_design.log
      }]
      incr tempStepIndexOfCmd 1 ; # == 4
    }
    if {$tempStepIndexOfCmd == 4} {
      uplevel #0 [subst {
        foreach tempSdc $sdcFiles {
          puts " - > Reading sdc file: $tempSdc"
          read_sdc $tempSdc
        }
      }]
      incr tempStepIndexOfCmd 1 ; # == 5
    }
    if {$tempStepIndexOfCmd == 5} {
      # set max transition
      set cmdsList_ofMaxTransition [genCmd_setMaxTransition_forDataClock_byClockPeriod -ratioOfClockWhenSetMaxTranForClock $ratioOfClockWhenSetMaxTranForClock -ratioOfClockWhenSetMaxTranForData $ratioOfClockWhenSetMaxTranForData \
        -ratioOfLibSetDefaultMaxTransitionOfData $ratioOfLibSetDefaultMaxTransitionOfData -userSetClockMaxTransition $userSetClockMaxTransition -userSetDataMaxTransition $userSetDataMaxTransition \
        -dataDefaultMaxTransitionInLibSet $dataDefaultMaxTransitionInLibSet -extraDerateForClock $extraDerateForClock -extraDerateForData $extraDerateForData]
      uplevel #0 [subst {
        set cmdsList_ofMaxTransition $cmdsList_ofMaxTransition
        if {$cmdsList_ofMaxTransition != ""} {
          batchRunCmd_forProc_genCmd $cmdsList_ofMaxTransition
        } else {
          puts " - > NOTICE: ERROR: have no any cmd of set_max_transition!!! check it!!!"
        }
      }]
      incr tempStepIndexOfCmd 1 ; # == 6
    }
    if {$tempStepIndexOfCmd == 6} {
      # set uncertainty
      # ...
      incr tempStepIndexOfCmd 1 ; # == 7
    } 
    if {$tempStepIndexOfCmd == 7} {
      uplevel #0 [subst {
        set timing_input_port_default_clock true
        update_timing -full > $resultScenarioDir/update_timing.log
      }]
      incr tempStepIndexOfCmd 1 ; # == 8
    }
    if {$tempStepIndexOfCmd == 8} {
      uplevel #0 [subst {
        foreach_in_collection itr [get_nets -quiet -hier -filter "number_of_leaf_loads > 50" -top_net_of_hierarchical_group] {
          if {[sizeof [get_pins -q -of [get_nets $itr]  -leaf]] > 0} {
            set_annotated_delay -net 0.05 -load_delay net -from [get_pins -of [get_nets $itr] -leaf]
            set_annotated_delay -net 0.05 -load_delay cell -from [get_pins -of [get_nets $itr] -leaf]
          }
          if {[sizeof [get_pins -q -of [get_nets $itr] -filter "direction == out" -leaf]] > 0} {
            set_annotated_delay -net 0.01 -load_delay net -from [get_pins -of [get_nets $itr] -filter "direction == out" -leaf]
            set_annotated_delay -net 0.01 -load_delay cell -from [get_pins -of [get_nets $itr] -filter "direction == out" -leaf]
          }
        }
        set filterBufInvExp [subst -nobackslashes {ref_name =~ [join $bufferInverterCelltypeExpList " || ref_name =~ " ]}]
        foreach_in_collection itr [get_cells -quiet -hier -filter "$filterBufInvExp" -top_net_of_hierarchical_group] {
          if {[sizeof [get_pins -q -of [get_nets $itr] -filter "direction == out"  -leaf]] > 0} {
            set_annotated_delay -net 0.01 -load_delay cell -from [get_pins -of [get_nets $itr] -filter "direction == out" -leaf]
          }
        }
      }]
      incr tempStepIndexOfCmd 1 ; # == 9
    }
    if {$tempStepIndexOfCmd == 9} {
      uplevel #0 [list save_session $resultScenarioDir/[string map $mapString [join [lsearch -not -all -inline -exact $stringname_of_formatExp "<body>"] "_"]].session]
      incr tempStepIndexOfCmd 1 ; # == 10
    }
    if {$tempStepIndexOfCmd == 10} {
      uplevel #0 [subst {
        set timing_check_defaults {generated_clocks no_input_delay unconstrained_endpoints no_clock loops}
        redirect {check_timing -verbose} > $resultScenarioDir/[string map [list body "check_timing"] $rawRptFileName]
        redirect {report_global_timing} > $resultScenarioDir/[string map [list body "global_timing"] $rawRptFileName]
        redirect {report_timing -transition_time -nets -derate -delay_type max -slack_lesser_than 0 -nosplit -significant_digits 3 -max_path 100000} > $resultScenarioDir/[string map [list body "setup_timing"] $rawRptFileName]
        redirect {report_min_pulse_width -crosstalk_delta -all_violators -significant_digits 3 -nosplit -path_type full_clock_expanded -input_pins} > $resultScenarioDir/[string map [list body "min_pulse"] $rawRptFileName]
        
        redirect {report_design_status} > $resultScenarioDir/[string map [list body "design_states"] $rawRptFileName]
        redirect {report_cell_status} > $resultScenarioDir/[string map [list body "cell_status"] $rawRptFileName]
        redirect {report_floating_pins} > $resultScenarioDir/[string map [list body "floating_pins"] $rawRptFileName]
        redirect {report_net_status} > $resultScenarioDir/[string map [list body "net_status"] $rawRptFileName]
        redirect {report_port_status} > $resultScenarioDir/[string map [list body "port_status"] $rawRptFileName]
        redirect {report_clock_status} > $resultScenarioDir/[string map [list body "clock_status"] $rawRptFileName]
        redirect {report_dont_use_status $dontUseCellsRegExpList} > $resultScenarioDir/[string map [list body "dont_use_status"] $rawRptFileName]
        redirect {report_vt_usage} > $resultScenarioDir/[string map [list body "vt_usage"] $rawRptFileName]
        redirect {check_memory_info} > $resultScenarioDir/[string map [list body "memory_info"] $rawRptFileName]
        redirect {report_asyn_status} > $resultScenarioDir/[string map [list body "async"] $rawRptFileName]
        redirect {report_dont_touch_status} > $resultScenarioDir/[string map [list body "dont_touch"] $rawRptFileName]
        redirect {report_dft_status} > $resultScenarioDir/[string map [list body "DFT_status"] $rawRptFileName]
      }]
      incr tempStepIndexOfCmd 1 ; # == 11
    }

    if {$stepIndexOfRunCmd <= 1} {
      set timeSpend [end_timer "string"]
      uplevel #0 [subst {
        set timeSpend $timeSpend
        redirect {puts "spend time : $timeSpend"} > $resultScenarioDir/runtime.rpt
      }]
    }
  } on error {err_info} {
    puts " - >>> step index of cmd : $tempStepIndexOfCmd"
    puts "error info : \n$err_info"
  }
}

define_proc_attributes runCmd_init_check \
  -info "gen cmd for initial checking on PT(PrimeTime of Synopsys)"\
  -define_args {
    {-stepIndexOfRunCmd "specify the step index of running cmd, default: 0" AInt int optional}
    {-netlistFiles "specify the netlist files" AList list optional}
    {-sdcFiles "specify the sdc files" AList list optional}
    {-uncertaintyFile "specify the uncertain file" AString string optional}
    {-dontUseCellsRegExpList "specify the list of dontUseCells regExp" AList list optional}
    {-dbListFile "specify the file of db list" AString string optional}
    {-scenario "specify the name of scenario" AString string optional}
    {-designName "specify the name of design" AString string optional}
    {-suffixOfResultRptFile "specify the suffix of result rpt files" AString string optional}
    {-formatExpOfResultFile "specify the format Expression of result files" AString string optional}
    {-bufferInverterCelltypeExpList "specify the list of regExp of celltype of buffer and inverter" AList list optional}
    {-resultDir "specify the directory of result rpt files" AString string optional}
    {-maxCores "specify the max cores of PT" AInt int optional}
    {-maxMessageLimit "specify the max message limit" AInt int optional}
    {-ifSouchUsesSearchPath "if source uses search path" "" boolean optional}
    {-ratioOfClockWhenSetMaxTranForClock "(for maxTransition setting)specify the ratio of clock period when set max transition for clock path" AFloat float optional}
    {-ratioOfClockWhenSetMaxTranForData "(for maxTransition setting)specify the ratio of clock period when set max transition for data path" AFloat float optional}
    {-ratioOfLibSetDefaultMaxTransitionOfData "(for maxTransition setting)specify the ratio of default set_max_transition in std cell lib when set max transition for data path" AFloat float optional}
    {-userSetClockMaxTransition "(for maxTransition setting)specify the min clock max_transition" AFloat float optional}
    {-userSetDataMaxTransition "(for maxTransition setting)specify the min data max_transition" AFloat float optional}
    {-dataDefaultMaxTransitionInLibSet "(for maxTransition setting)input the default set_max_transition in std cell lib file, please look up" AFloat float optional}
    {-extraDerateForClock "(for maxTransition setting)specify the extra derate value for clock final max_transition" AFloat float optional}
    {-extraDerateForData  "(for maxTransition setting)specify the extra derate value for data final max_transition" AFloat float optional}
  }
