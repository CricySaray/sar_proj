# NOTICE: When fixing the endpoint hold now, we do not deduplicate the startpoint. This is a very dangerous situation.  
#         In order to complete the script quickly, the deduplication operation was not considered. You must add this deduplication protection later.


source ../../../flow_build/common/convert_file_to_list.common.tcl; # convert_file_to_list
source ../../../packages/table_format_with_title.package.tcl; # table_format_with_title
source ../../../packages/get_block_info_fromTimingRptFile.package.tcl; # get_block_info_fromTimingRptFile


proc getInfoOfStartpointEndpointListAtHoldSession_forGetSetupMarginAtSetupSession {args} {
  set violPinsOrInstsOrViolPathFilename                  [list]
  set pba_mode                                           ex
  set outputFileBodyName_ofStartpointEndpointList        "startpointEndpointListAtHoldSession_forGetSetupMarginAtSetupSession"
  set output_dir                                         "./"
  set suffixOfOutputFile                                 "fix_sync_cell"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  
  suppress_message SEL-003
  suppress_message UITE-479
  suppress_message UITE-416

  if {[file exists $violPinsOrInstsOrViolPathFilename]} {
    set timing_block_info_list [get_block_info_fromTimingRptFile $violPinsOrInstsOrViolPathFilename start_end {Startpoint:} "" {slack \(VIO}]
    set violPinsOrInstsOrViolPathFilename [lsort -u [lmap temp_block $timing_block_info_list {
      set temp_endpoint [lindex [lsearch -regexp -inline $temp_block {^\s*Endpoint:}] 1]
      set temp_endpoint
    }]]
  } 

  set needProcessedInsts [list]
  foreach temp_pin_or_inst $violPinsOrInstsOrViolPathFilename {
    if {[get_pins $temp_pin_or_inst -q] ne ""} {
      lappend needProcessedInsts [get_object_name [get_cells -of [get_pins $temp_pin_or_inst]]]
    } elseif {[get_cells $temp_pin_or_inst -q] ne ""} {
      lappend needProcessedInsts [get_object_name [get_cells $temp_pin_or_inst]]
    }
  }
  set needProcessedInsts [lsort -u $needProcessedInsts]
  set totalInstNum [llength $needProcessedInsts]
  puts "total $totalInstNum inst to processing..."
  puts " ------ "
  set i 0
  set needProcessedInsts [lmap temp_inst $needProcessedInsts {
    incr i
    puts -nonewline "$i "
    flush stdout
    set temp_worstest_startpoint_name [get_object_name [get_cells -q -of [get_attribute [get_timing_paths -delay_type min -slack_lesser_than 9999 -pba_mode $pba_mode -to [get_pins -of [get_cells $temp_inst] -filter "direction==in"]] startpoint]]]
    if {$temp_worstest_startpoint_name eq ""} {
      set temp_worstest_startpoint_name noSetupConstraintStartpoint 
    }
    list $temp_inst $temp_worstest_startpoint_name
  }]
  puts ""
  puts " ------ "
  set needProcessedInsts [linsert $needProcessedInsts 0 [list holdViolEndpoint worstestStartpoint]]
  set output_filename "$output_dir/$outputFileBodyName_ofStartpointEndpointList.$suffixOfOutputFile.tcl"
  set fo [open $output_filename w]
  puts $fo [join [table_format_with_title $needProcessedInsts 0 left "" 0] \n]
  close $fo
  puts "have generated setup margin output file."
}

define_proc_attributes getInfoOfStartpointEndpointListAtHoldSession_forGetSetupMarginAtSetupSession \
  -info "gen script make longer for launch clock tree to fix hold, it run at setup session."\
  -define_args {
    {-violPinsOrInstsOrViolPathFilename "specify the viol pins or insts or input filename" AString string optional}
    {-suffixOfOutputFile "specify the suffix name of new cell name, new net name and output file" AString string optional}
    {-pba_mode "specify the pba mode" oneOfString one_of_string {optional value_help {values {exhaustive none path}}}}
    {-outputFileBodyName_ofStartpointEndpointList "specify the output file body name" AString string optional}
    {-output_dir "specify the output dir" AString string optional}
  }


proc genScript_make_longer_for_launchClockTree_toFixHold_runAtSetupSession {args} {
  set violPinsOrInstsOrViolPathFilename                  [list]
  set pba_mode                                           ex
  set outputFileBodyName_ofSetupMarginOfCurrentLevelPath "setupMarginList_to_fix_hold_using_make_longer_for_launchClockTree"
  set output_dir                                         "./"
  set suffixOfOutputFile                                 "fix_sync_cell"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  
  suppress_message SEL-003
  suppress_message UITE-479
  suppress_message UITE-416

  if {[file exists $violPinsOrInstsOrViolPathFilename]} {
    set fi [open $violPinsOrInstsOrViolPathFilename r]
    set violEndpoint_worstStartpoint_List [lsearch -not -all -inline -regexp [split [read $fi] "\n"] holdViolEndpoint]
    close $fi
  } 

  set totalInstNum [llength $violEndpoint_worstStartpoint_List]
  puts "total $totalInstNum inst to processing..."
  puts " ------ "
  set i 0
  set setup_margin_endpoint_list [list]
  foreach temp_endpoint_worstestStartpoint $violEndpoint_worstStartpoint_List {
    lassign $temp_endpoint_worstestStartpoint temp_endpoint temp_worstest_startpoint_name
    incr i
    puts -nonewline "$i "
    flush stdout
    set setup_margin_of_current_level_path [get_attribute [get_timing_paths -delay_type max -pba_mode $pba_mode -slack_lesser_than 9999 -to $temp_endpoint] slack] 
    if {$setup_margin_of_current_level_path eq ""} { set setup_margin_of_current_level_path 9999 }
    lappend setup_margin_endpoint_list [list $setup_margin_of_current_level_path $temp_endpoint $temp_worstest_startpoint_name]
  }
  puts ""
  puts " ------ "
  set setup_margin_endpoint_list [linsert $setup_margin_endpoint_list 0 [list setup_margin_of_currentLevelPath holdViolEndpoint worstestStartpoint]]
  set output_filename "$output_dir/$outputFileBodyName_ofSetupMarginOfCurrentLevelPath.$suffixOfOutputFile.tcl"
  set fo [open $output_filename w]
  puts $fo [join [table_format_with_title $setup_margin_endpoint_list 0 left "" 0] \n]
  close $fo
  puts "have generated setup margin output file."
}

define_proc_attributes genScript_make_longer_for_launchClockTree_toFixHold_runAtSetupSession \
  -info "gen script make longer for launch clock tree to fix hold, it run at setup session."\
  -define_args {
    {-violPinsOrInstsOrViolPathFilename "specify the viol pins or insts or input filename" AString string optional}
    {-suffixOfOutputFile "specify the suffix name of new cell name, new net name and output file" AString string optional}
    {-pba_mode "specify the pba mode" oneOfString one_of_string {optional value_help {values {exhaustive none path}}}}
    {-outputFileBodyName_ofSetupMarginOfCurrentLevelPath "specify the output file body name" AString string optional}
    {-output_dir "specify the output dir" AString string optional}
  }

proc genScript_make_longer_for_launchClockTree_toFixHold_runAtHoldSession {args} {
  set violPinsOrInstsOrViolPathFilename                                    [list]
  set setupMarginFilenameOfCurrentLevelPath                                "./setupMarginList..."
  set ifContinueFixWhenNextLevelPathEndpointIsMem                          0
  set slackLessValueToSearchNextLevelPathEndpointAsMemSlackLesserThanValue 0.1 ; # ns
  set celltypeOfClkBuffer                                                  "DCCKBD4BWP7T35P140LVT"
  set suffixForNewCellAndNetAndOutputFile                                  "fix_sync_cell_hold"
  set topHierNeedRemoveAtScript                                            ""
  set delayOfCelltypeOfClockBuffer                                         0.01 ; # ns
  set minMarginSlackOfNextLevel                                            0.04 ; # when margin > this slack, it will run fixing
  set multiplierOfviolSlackVsMarginSlack                                   1.5
  set ifTurnOnSafeMode                                                     1 ; # safe mode: only process register cp pin, not process mem/ip/... cp/clk pin. not at safe mode: will process all cp/clk pin of provided inst/pins
  set pba_mode                                                             ex
  set insertBufferProcFilename_pt                                          "./insertBuffer_forCaptureClockTree.pt.tcl"
  set insertBufferProcFilename_invs                                        "./insertBuffer_forCaptureClockTree.invs.tcl"
  set outputFileBodyname                                                   "fix_hold_using_make_longer_for_launchClockTree"
  set output_dir                                                           "./"
  set ifDumpUnfixPath                                                      1
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }

  suppress_message SEL-003
  suppress_message UITE-479
  suppress_message UITE-416

  if {[file exists $setupMarginFilenameOfCurrentLevelPath]} {
    set fi [open $setupMarginFilenameOfCurrentLevelPath r]
    set setupMargin_endpoint_List [lsearch -not -all -inline -regexp [split [read $fi] "\n"] {setup_margin}]
    close $fi
  } else {
    error "proc genScript_make_longer_for_launchClockTree_toFixHold_runAtHoldSession: invalid setup margin list filename: ($setupMarginFilenameOfCurrentLevelPath)" 
  }

  if {[file exists $violPinsOrInstsOrViolPathFilename]} {
    set timing_block_info_list [get_block_info_fromTimingRptFile $violPinsOrInstsOrViolPathFilename start_end {Startpoint:} "" {slack \(VIO}]
    set violPinsOrInstsOrViolPathFilename [lsort -u [lmap temp_block $timing_block_info_list {
      set temp_endpoint [lindex [lsearch -regexp -inline $temp_block {^\s*Endpoint:}] 1]
      set temp_endpoint
    }]]
  } 

  set needProcessedInsts [list]
  foreach temp_pin_or_inst $violPinsOrInstsOrViolPathFilename {
    if {[get_pins $temp_pin_or_inst -q] ne ""} {
      lappend needProcessedInsts [get_object_name [get_cells -of [get_pins $temp_pin_or_inst]]]
    } elseif {[get_cells $temp_pin_or_inst -q] ne ""} {
      lappend needProcessedInsts [get_object_name [get_cells $temp_pin_or_inst]]
    }
  }
  set needProcessedInsts [lsort -u $needProcessedInsts]
  if {$ifTurnOnSafeMode} {
    set needProcessedInsts [lmap temp_inst $needProcessedInsts {
      if {[get_attribute [get_cells $temp_inst] is_sequential]} {
        set temp_inst
      } else {
        continue
      }
    }]
  } 
  set totalInstNum [llength $needProcessedInsts]
  if {$ifTurnOnSafeMode} { puts "at safe mode: only process register inst/pin" }
  puts "total $totalInstNum inst to processing..."
  puts " ------ "
  set finalCmdsList_invs [list]
  set numOfFixedInst 0
  set numOfUnfixedInst 0
  set numOfMeetInst 0
  set finalCmdsList_pt [list]
  set unfixInst [list]
  set notFoundSetupMarginInst [list]
  set i 0
  foreach temp_setupMargin_violEndpoint_worstStartpoint $needProcessedInsts {
    incr i
    puts -nonewline "$i "
    flush stdout
    set hitSetupMargin_violEndpoint_worstestStartpoint [lsearch -index 1 -inline -exact $setupMargin_endpoint_List $temp_setupMargin_violEndpoint_worstStartpoint]
    if {$hitSetupMargin_violEndpoint_worstestStartpoint eq ""} {
      set setup_margin_ofCurrentLevelPath notFound
    } else {
      lassign $hitSetupMargin_violEndpoint_worstestStartpoint setup_margin_ofCurrentLevelPath temp_violEndpoint temp_worstest_startpoint_name
    }
    set viol_slack [get_attribute [get_timing_paths -delay_type min -pba_mode $pba_mode -to [get_pins -of [get_cells $temp_violEndpoint] -filter "direction==in"]] slack]
    if {$setup_margin_ofCurrentLevelPath eq "notFound"} {
      set ifCanFix "notFoundSetupMargin"
    } elseif {$viol_slack >= 0.00000} {
      set ifCanFix " meet"
    } elseif {$viol_slack < 0.00000 && $setup_margin_ofCurrentLevelPath >= $minMarginSlackOfNextLevel && $setup_margin_ofCurrentLevelPath > [expr {abs($viol_slack * $multiplierOfviolSlackVsMarginSlack)}]} {
      set ifCanFix "  ok "
    } else {
      set ifCanFix "unfix"
    }
    set current_level_startpoint [get_object_name [filter_collection [get_cells $temp_worstest_startpoint_name] {is_black_box || is_pad_cell || is_memory_cell}]]
    if {$current_level_startpoint ne ""} {
      set ifCanFix [string cat $ifCanFix ": NOTICE_WHEN_RUN_CMD: current level startpoint have mem!!!"]
    }
    set clockPinOfInst [get_object_name [get_pins -of [get_cells $temp_worstest_startpoint_name] -filter "is_clock_pin"]]
    if {[lsearch -exact -index 0 $finalCmdsList_invs $clockPinOfInst] != -1} {
      continue
    } else {
      lappend finalCmdsList_invs "# to fix to endpoint: $temp_violEndpoint\n# $ifCanFix , marginSlack:$setup_margin_ofCurrentLevelPath , violSlack:$viol_slack , clockPin:$clockPinOfInst"
      lappend finalCmdsList_pt   "# to fix to endpoint: $temp_violEndpoint\n# $ifCanFix , marginSlack:$setup_margin_ofCurrentLevelPath , violSlack:$viol_slack , clockPin:$clockPinOfInst"


      set multiViolVsDelayOfCelltypeOfClockBuffer [expr {int(floor(abs($viol_slack) / abs($delayOfCelltypeOfClockBuffer)))}]
      set num_buffer [expr {$multiViolVsDelayOfCelltypeOfClockBuffer + 1}]

      if {[regexp notFoundSetupMargin $ifCanFix]} {
        lappend notFoundSetupMarginInst [list $viol_slack $temp_violEndpoint]
        lappend finalCmdsList_invs [list $clockPinOfInst "### notFoundSetupMargin ###"]
        lappend finalCmdsList_pt [list $clockPinOfInst "### notFoundSetupMargin ###"]
      } elseif {![regexp unfix $ifCanFix]} {
        if {[regexp ok $ifCanFix]} {
          incr numOfFixedInst
          if {[regexp NOTICE_WHEN_RUN_CMD $ifCanFix]} {
            lappend finalCmdsList_invs [list $clockPinOfInst "insertBuffer_forCaptureClockTree_invs -ifDryRun 0 -suffixForEco $suffixForNewCellAndNetAndOutputFile -celltypeOfBufferToInsert $celltypeOfClkBuffer -numOfInsert $num_buffer -terms $clockPinOfInst" $current_level_startpoint]
            lappend finalCmdsList_pt [list $clockPinOfInst "insertBuffer_forCaptureClockTree_pt -ifDryRun 0 -suffixForEco $suffixForNewCellAndNetAndOutputFile -celltypeOfBufferToInsert $celltypeOfClkBuffer -numOfInsert $num_buffer -terms $clockPinOfInst" $current_level_startpoint]
          } else {
            lappend finalCmdsList_invs [list $clockPinOfInst "insertBuffer_forCaptureClockTree_invs -ifDryRun 0 -suffixForEco $suffixForNewCellAndNetAndOutputFile -celltypeOfBufferToInsert $celltypeOfClkBuffer -numOfInsert $num_buffer -terms $clockPinOfInst"]
            lappend finalCmdsList_pt [list $clockPinOfInst "insertBuffer_forCaptureClockTree_pt -ifDryRun 0 -suffixForEco $suffixForNewCellAndNetAndOutputFile -celltypeOfBufferToInsert $celltypeOfClkBuffer -numOfInsert $num_buffer -terms $clockPinOfInst"]
          }
        } elseif {[regexp meet $ifCanFix]} {
          incr numOfMeetInst
          lappend finalCmdsList_invs [list $clockPinOfInst "### MEET ###"]
          lappend finalCmdsList_pt [list $clockPinOfInst "### MEET ###"]
        }
      } else {
        incr numOfUnfixedInst
        lappend unfixInst $temp_violEndpoint
        if {[regexp NOTICE_WHEN_RUN_CMD $ifCanFix]} {
          lappend finalCmdsList_invs [list $clockPinOfInst "### UNFIX ###" $current_level_startpoint]
          lappend finalCmdsList_pt [list $clockPinOfInst "### UNFIX ###" $current_level_startpoint]
        } else {
          lappend finalCmdsList_invs [list $clockPinOfInst "### UNFIX ###"]
          lappend finalCmdsList_pt [list $clockPinOfInst "### UNFIX ###"]
        }
      }
    }
  }
  set outputfilename_invs "$output_dir/$outputFileBodyname.$suffixForNewCellAndNetAndOutputFile.invs.tcl"
  set outputfilename_pt "$output_dir/$outputFileBodyname.$suffixForNewCellAndNetAndOutputFile.pt.tcl"
  set fo_invs [open $outputfilename_invs w] ; set fo_pt [open $outputfilename_pt w]
  puts $fo_invs "source $insertBufferProcFilename_invs"
  puts $fo_invs "setEcoMode -reset"
  puts $fo_invs "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"

  puts $fo_pt "source $insertBufferProcFilename_pt"
  set final_list_i 0
  foreach temp_invs $finalCmdsList_invs temp_pt $finalCmdsList_pt {
    if {[regexp {^#} $temp_invs]} {
      puts $fo_invs $temp_invs
    } elseif {![regexp {^#} $temp_invs]} {
      if {$final_list_i != 0} {
        if {[regexp NOTICE_WHEN_RUN_CMD [lindex $finalCmdsList_invs [expr {$final_list_i - 1}]]]} {
          puts $fo_invs "### mem_startpoint_ofCurrentLevelPath(slack lesser than $slackLessValueToSearchNextLevelPathEndpointAsMemSlackLesserThanValue ns): - > [join [lindex $temp_invs 2] "\n### mem_startpoint_ofCurrentLevelPath: - > "]"
        }
      }
      puts $fo_invs [regsub [subst {$topHierNeedRemoveAtScript/}] [lindex $temp_invs 1] ""]
    }
    if {[regexp {^#} $temp_pt]} {
      puts $fo_pt $temp_pt
    } elseif {![regexp {^#} $temp_pt]} {
      if {$final_list_i != 0} {
        if {[regexp NOTICE_WHEN_RUN_CMD [lindex $finalCmdsList_pt [expr {$final_list_i - 1}]]]} {
          puts $fo_pt "### mem_startpoint_ofCurrentLevelPath: - > [join [lindex $temp_pt 2] "\n### mem_startpoint_ofCurrentLevelPath: - > "]"
        }
      }
      puts $fo_pt [lindex $temp_pt 1]
    }
    incr final_list_i
  }
  puts $fo_invs "setEcoMode -reset"
  close $fo_invs ; close $fo_pt

  puts ""
  puts " ------ "
  puts "total processed $totalInstNum inst."
  puts "fixed $numOfFixedInst inst."
  puts "have $numOfUnfixedInst inst that is unfixed."
  puts "have $numOfMeetInst inst that is meet originally."
  puts "output file invs: $outputfilename_invs"
  puts "output file pt  : $outputfilename_pt"

  if {$ifDumpUnfixPath} {
    puts " ------ "
    puts "have turn on switch of dumping unfixed path."
    puts "now dumping unfixed path ..."
    set outputfile_unfixpath "$output_dir/$outputFileBodyname.$suffixForNewCellAndNetAndOutputFile.unfix_path.rpt"
    if {[file exists $outputfile_unfixpath]} {
      file delete $outputfile_unfixpath
    }
    set j 0
    foreach temp_unfixinst $unfixInst {
      incr j
      puts -nonewline "$j "
      flush stdout
      redirect -append $outputfile_unfixpath {report_timing -significant_digits 4 -delay_type min -pba_mode $pba_mode -to [get_pins -of [get_cells $temp_unfixinst] -filter "direction==in"] -nos -input_pins -trans -derate -cap -sort_by slack -crosstalk_delta -slack_lesser_than 9999 -nets -max_paths 1 -nworst 1}
      flush stdout
    }
    puts ""
    puts "have dump all unfixed path to $outputfile_unfixpath"
  }
  
}

define_proc_attributes genScript_make_longer_for_launchClockTree_toFixHold_runAtHoldSession \
  -info "whatFunction"\
  -define_args {
    {-violPinsOrInstsOrViolPathFilename "specify the viol pins or insts or input filename" AString string optional}
    {-setupMarginFilenameOfCurrentLevelPath "specify the setup margin filename of current level path" AString string optional}
    {-ifContinueFixWhenNextLevelPathEndpointIsMem "if continue fix path when next level path endpoint is mem" oneOfString one_of_string {optional value_help {values {0 1}}}}
    {-slackLessValueToSearchNextLevelPathEndpointAsMemSlackLesserThanValue "specify the slack that is less when search next level endpoint, such as mem" AFloat float optional}
    {-celltypeOfClkBuffer "specify the celltype of clock buffer, such as DCCKBD4BWP30P140LVT" AString string optional}
    {-suffixForNewCellAndNetAndOutputFile "specify the suffix name of new cell name, new net name and output file" AString string optional}
    {-topHierNeedRemoveAtScript "specify the top hier name that need remove at script. you can keep empty if no need" AString string optional}
    {-delayOfCelltypeOfClockBuffer "specify the delay value of celltype of clock buffer" AFloat float optional}
    {-minMarginSlackOfNextLevel "specify the min margin slack of next level" AFloat float optional}
    {-multiplierOfviolSlackVsMarginSlack "specify the multiplier of viol slack Vs margin slack" AFloat float optional}
    {-ifTurnOnSafeMode "if turn on safe mode" oneOfString one_of_string {optional value_help {values {0 1}}}}
    {-pba_mode "specify the pba mode" oneOfString one_of_string {optional value_help {values {exhaustive none path}}}}
    {-insertBufferProcFilename_pt "specify the file name of insertBuffer for pt" AString string optional}
    {-insertBufferProcFilename_invs "specify the file name of insertBuffer for invs" AString string optional}
    {-outputFileBodyname "specify the output file body name" AString string optional}
    {-output_dir "specify the output dir" AString string optional}
    {-ifDumpUnfixPath "if dump unfixed path to output file" oneOfString one_of_string {optional value_help {values {0 1}}}}
  }
