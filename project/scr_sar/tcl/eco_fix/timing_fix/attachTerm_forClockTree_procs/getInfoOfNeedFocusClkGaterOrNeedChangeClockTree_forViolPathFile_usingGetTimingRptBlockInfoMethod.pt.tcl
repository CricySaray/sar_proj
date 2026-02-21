#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/02/17 17:49:13 Tuesday
# label     : clock_tree_relative_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This procedure can extract the common clock tree portion from the input timing paths and classify them. Paths sharing the 
#             same clock tree structure are grouped into the same category, which helps users analyze path types, reduces redundant operations, 
#             and avoids confusion caused by an overwhelming number of paths.
#             You can use this procedure to analyze the viol path file before performing jumper adjustments. It will generate an output file 
#             that groups paths with identical clock tree structures into separate classes for easier analysis.
# return    : analized and classified output summary file
# ref       : link url
# --------------------------
# NOTICE: safe mode: 
#     It searches forward from the CP/CLK segments of startpoints or endpoints, and stops searching immediately once a sufficient number of specified 
#   insts or celltypes are found. This ensures that the consecutively matched insts you find are closest to the startpoint or endpoint, minimizing 
#   the scope of impact from jumper adjustments.
#     However, a drawback of this approach is that the grouping may be too granular, resulting in a relatively large number of groups.
#     Additionally, there is a bold mode (undeveloped) which, after grouping is completed in safe mode, can further identify the common 
#   clock tree paths among them to reduce the number of groups. Nevertheless, this will correspondingly increase the impact caused by jumper adjustments.
source ../../../packages/get_block_info_fromTimingRptFile.package.tcl; # get_block_info_fromTimingRptFile
source ../../../packages/get_unique_list_without_reorder.package.tcl; # get_unique_list_without_reorder
proc getInfoOfNeedFocusClkGaterOrNeedChangeClockTree_forViolPathFile {args} {
  # NOTICE: need find points after common point
  set violPathFile                     ""
  set ifFindLongestClockTreeCommonPath 1
  set numNeedContinueCkBufInv          4
  set pba_mode                         "ex"
  set buffOrInvRegExp                  {DCCKN|DCCKB|CKB|CKN}
  set clkgaterCelltypeRegExp           {^CKLNQD}
  set keepContinueClockTreeInstName    {U_MAIN_SUB}
  set needFindInstNameExp              {_cdb_}
  set typeOfPathClockTree              "launch" ; # launch|capture
  set output_dir                       "./"
  set outputFileBodyName               "findSameClockTreePart"
  set suffixOfOutputFile               "eco17_mem2icg"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {![file exists $violPathFile]} {
    error "proc getInfoOfFluencyOfAttachedTerm_forNewViolPath: input error, not found viol file: $violPathFile" 
  }

  set simplePath_vs_originalTimingRptBlockInfo_LIST [list]
  set timing_rpt_block_info_list [get_block_info_fromTimingRptFile $violPathFile "start_end" {Startpoint:} "" {slack \(VIO}]
  set pathOfStartToEndList [lmap temp_block_info $timing_rpt_block_info_list {
    set idxOfPrevOfStartpoint [lsearch -regexp $temp_block_info "clock network delay"] 
    set idxOfAfterEndpoint [lsearch -regexp $temp_block_info "data arrival time"]
    set temp_startpoint [lindex $temp_block_info [expr {$idxOfPrevOfStartpoint + 2}] 0]
    set temp_endpoint [lindex $temp_block_info [expr {$idxOfAfterEndpoint - 1}] 0]
    lappend simplePath_vs_originalTimingRptBlockInfo_LIST [list [list $temp_startpoint $temp_endpoint] $temp_block_info]
    list $temp_startpoint $temp_endpoint
  }]

  set pathNum [llength $pathOfStartToEndList]
  puts "total find $pathNum path."

  suppress_message UITE-416
  suppress_message UITE-479
  
  set clockTreeMeetConditionPathBlock [list]
  set notFindMeetContinueBufInvPathList [list]
  set i 0
  puts "processing path: ..."
  foreach temp_path $pathOfStartToEndList {
    incr i
    puts -nonewline "$i "
    flush stdout
    lassign $temp_path temp_start temp_end 
    # puts "Now processing: \n\tstartpoint: $temp_start\n\tendpoint: $temp_end"
    set temp_col_full_clock_path [get_timing_paths -pba_mode $pba_mode -path_type full_clock_expanded -from $temp_start -to $temp_end ]
    set temp_path_slack [get_attribute $temp_col_full_clock_path slack]
    if {$typeOfPathClockTree eq "launch"} {
      set temp_col_launch_clock_points [get_attribute [get_attribute [get_attribute $temp_col_full_clock_path launch_clock_paths] points] object]
      set temp_list_launch_clock_points [get_object_name $temp_col_launch_clock_points]
      set temp_list_launch_clock_insts [lreverse [get_unique_list_without_reorder [get_object_name [get_attribute $temp_col_launch_clock_points cell]]]]
      if {$keepContinueClockTreeInstName ne ""} {
        set temp_list_launch_clock_insts_after_process_continue_keep_condition [list] 
        set flagOfBeginMonitor 0
        foreach temp_inst $temp_list_launch_clock_insts {
          if {[regexp -expanded $keepContinueClockTreeInstName $temp_inst]} {
            set flagOfBeginMonitor 1 
            lappend temp_list_launch_clock_insts_after_process_continue_keep_condition $temp_inst
          } elseif {![regexp -expanded $keepContinueClockTreeInstName $temp_inst] && $flagOfBeginMonitor} {
            break 
          }
        }
      } else {
        set temp_list_launch_clock_insts_after_process_continue_keep_condition $temp_list_launch_clock_insts 
      }
      set temp_num_of_buf_or_inv 0
      set temp_num_of_need_find_inst_name 0
      set temp_num_of_clkgater 0
      set ifCanDumpList 0
      set temp_save_buffer_or_inverter_name [list] ; # order: from prev inst to after inst
      foreach temp_inst $temp_list_launch_clock_insts_after_process_continue_keep_condition {
        if {[regexp -expanded $buffOrInvRegExp [get_attribute [get_cells $temp_inst] ref_name]]} {
          incr temp_num_of_buf_or_inv 
          if {$needFindInstNameExp eq ""} { set temp_num_of_need_find_inst_name 99999 } else {
            if {[regexp -expanded $needFindInstNameExp $temp_inst]} { incr temp_num_of_need_find_inst_name }
          }
          set temp_save_buffer_or_inverter_name [linsert $temp_save_buffer_or_inverter_name 0 $temp_inst]
          if {$temp_num_of_buf_or_inv >= $numNeedContinueCkBufInv && $temp_num_of_need_find_inst_name >= $numNeedContinueCkBufInv} {
            set ifCanDumpList 1
            if {!$ifFindLongestClockTreeCommonPath} {
              lappend clockTreeMeetConditionPathBlock [list $temp_path_slack $temp_path $temp_save_buffer_or_inverter_name ] 
              set temp_save_buffer_or_inverter_name [list]
              set temp_num_of_buf_or_inv 0
              break
            }
          }
        } elseif {$ifCanDumpList && ![regexp -expanded $buffOrInvRegExp [get_attribute [get_cells $temp_inst] ref_name]]} {
          lappend clockTreeMeetConditionPathBlock [list $temp_path_slack $temp_path $temp_save_buffer_or_inverter_name ] 
          set temp_save_buffer_or_inverter_name [list]
          set temp_num_of_buf_or_inv 0
          break
        } else {
          set temp_num_of_buf_or_inv 0 
        }
        if {$temp_inst eq [lindex $temp_list_launch_clock_insts_after_process_continue_keep_condition end]} {
          lappend notFindMeetContinueBufInvPathList [list $temp_path_slack $temp_path]
        }
      }
    } elseif {$typeOfPathClockTree eq "capture"} {
      set temp_col_capture_clock_points [get_attribute [get_attribute [get_attribute $temp_col_full_clock_path capture_clock_paths] points] object]
      set temp_list_capture_clock_points [get_object_name $temp_col_capture_clock_points]
      set temp_list_capture_clock_insts [lreverse [get_unique_list_without_reorder [get_object_name [get_attribute $temp_col_capture_clock_points cell]]]]
      if {$keepContinueClockTreeInstName ne ""} {
        set temp_list_capture_clock_insts_after_process_continue_keep_condition [list] 
        set flagOfBeginMonitor 0
        foreach temp_inst $temp_list_capture_clock_insts {
          if {[regexp -expanded $keepContinueClockTreeInstName $temp_inst]} {
            set flagOfBeginMonitor 1 
            lappend temp_list_capture_clock_insts_after_process_continue_keep_condition $temp_inst
          } elseif {![regexp -expanded $keepContinueClockTreeInstName $temp_inst] && $flagOfBeginMonitor} {
            break 
          }
        }
      } else {
        set temp_list_capture_clock_insts_after_process_continue_keep_condition $temp_list_capture_clock_insts 
      }
      set temp_num_of_buf_or_inv 0
      set temp_num_of_need_find_inst_name 0
      set temp_num_of_clkgater 0
      set ifCanDumpList 0
      set temp_save_buffer_or_inverter_name [list] ; # order: from prev inst to after inst
      foreach temp_inst $temp_list_capture_clock_insts_after_process_continue_keep_condition {
        if {[regexp -expanded $buffOrInvRegExp [get_attribute [get_cells $temp_inst] ref_name]]} {
          incr temp_num_of_buf_or_inv 
          if {$needFindInstNameExp eq ""} { set temp_num_of_need_find_inst_name 99999 } else {
            if {[regexp -expanded $needFindInstNameExp $temp_inst]} { incr temp_num_of_need_find_inst_name }
          }
          set temp_save_buffer_or_inverter_name [linsert $temp_save_buffer_or_inverter_name 0 $temp_inst]
          if {$temp_num_of_buf_or_inv >= $numNeedContinueCkBufInv && $temp_num_of_need_find_inst_name >= $numNeedContinueCkBufInv} {
            set ifCanDumpList 1
            if {!$ifFindLongestClockTreeCommonPath} {
              lappend clockTreeMeetConditionPathBlock [list $temp_path_slack $temp_path $temp_save_buffer_or_inverter_name ] 
              set temp_save_buffer_or_inverter_name [list]
              set temp_num_of_buf_or_inv 0
              break
            }
          }
        } elseif {$ifCanDumpList && ![regexp -expanded $buffOrInvRegExp [get_attribute [get_cells $temp_inst] ref_name]]} {
          lappend clockTreeMeetConditionPathBlock [list $temp_path_slack $temp_path $temp_save_buffer_or_inverter_name ] 
          set temp_save_buffer_or_inverter_name [list]
          set temp_num_of_buf_or_inv 0
          break
        } else {
          set temp_num_of_buf_or_inv 0 
        }
        if {$temp_inst eq [lindex $temp_list_capture_clock_insts_after_process_continue_keep_condition end]} {
          lappend notFindMeetContinueBufInvPathList [list $temp_path_slack $temp_path]
        }
      }
    } else {
      error "proc getInfoOfNeedFocusClkGaterOrNeedChangeClockTree_forViolPathFile: error typeOfPathClockTree(need launch or capture): $typeOfPathClockTree" 
    }
  }
  set finalClockClockPath_to_violPath [list]
  foreach temp_clock_tree_info_block $clockTreeMeetConditionPathBlock {
    lassign $temp_clock_tree_info_block temp_path_slack temp_path temp_save_buffer_or_inverter_name 
    if {$finalClockClockPath_to_violPath eq "" || [lsearch -index 0 $finalClockClockPath_to_violPath $temp_save_buffer_or_inverter_name] == -1} {
      lappend finalClockClockPath_to_violPath [list $temp_save_buffer_or_inverter_name [list [list $temp_path_slack $temp_path]]] 
    } elseif {$finalClockClockPath_to_violPath ne "" && [lsearch -index 0 $finalClockClockPath_to_violPath $temp_save_buffer_or_inverter_name] != -1} {
      lset finalClockClockPath_to_violPath [lsearch -index 0 $finalClockClockPath_to_violPath $temp_save_buffer_or_inverter_name] end [list {*}[lindex $finalClockClockPath_to_violPath [lsearch -index 0 $finalClockClockPath_to_violPath $temp_save_buffer_or_inverter_name] end] [list $temp_path_slack $temp_path]]
    }
  }
  set outputfilename "$output_dir/$outputFileBodyName.$typeOfPathClockTree.$suffixOfOutputFile.rpt"
  set fo [open $outputfilename w]
  set i 0
  set maxGroupItems 0
  set groupedPathNum 0
  foreach temp_block_info $finalClockClockPath_to_violPath {
    incr i
    lassign $temp_block_info temp_save_buffer_or_inverter_name temp_paths 
    puts $fo "No $i:"
    puts $fo "continue buffer or inverter inst:"
    puts $fo "have [llength $temp_paths] RELATED PATHS: (slack startpoint endpoint)    NOTICE: check clock tree path type: $typeOfPathClockTree"
    puts $fo [join $temp_save_buffer_or_inverter_name \n]
    puts $fo " ------ "
    if {[llength $temp_paths] > $maxGroupItems} { set maxGroupItems [llength $temp_paths] }
    set groupedPathNum [expr {$groupedPathNum + [llength $temp_paths]}]
    set temp_paths [lsort -index 0 -real -increasing $temp_paths]
    foreach temp_path $temp_paths {
      lassign $temp_path temp_slack temp_start_end
      lassign $temp_start_end temp_start temp_end
      puts $fo "$temp_slack $temp_start\n\t\t$temp_end"
    }
    puts $fo ""
  }
  close $fo
  set outputfilename_notFindMeetCondition "$output_dir/$outputFileBodyName.notMeetContinuousCondition.$typeOfPathClockTree.$suffixOfOutputFile.rpt"
  set outputfilename_notFindMeetCondition_fulltimingrpt "$output_dir/$outputFileBodyName.notMeetContinuousCondition.originalTimingPath.$typeOfPathClockTree.$suffixOfOutputFile.rpt"
  set numOfNotMeetContinuousConditionPath [llength $notFindMeetContinueBufInvPathList]
  set fo_2 [open $outputfilename_notFindMeetCondition w]
  set fo_3 [open $outputfilename_notFindMeetCondition_fulltimingrpt w]
  puts $fo_2 "have $numOfNotMeetContinuousConditionPath path that not meet continuous condition."
  puts $fo_2 ""
  set notMeet_num 0
  foreach temp_slack_path $notFindMeetContinueBufInvPathList {
    lassign $temp_slack_path temp_slack_path temp_path
    lassign $temp_path temp_start temp_end
    puts $fo_2 "$temp_slack $temp_start\n\t\t$temp_end"
    incr notMeet_num 
    puts $fo_3 "songpath $notMeet_num:"
    puts $fo_3 [join [lindex [lsearch -inline -exact -index 0 $simplePath_vs_originalTimingRptBlockInfo_LIST $temp_path] 1] \n]
    puts $fo_3 ""
  }
  close $fo_2 ; close $fo_3
  puts ""
  puts " ------ "
  puts "total $pathNum path."
  puts "have $i groups."
  puts "have $groupedPathNum grouped path that meets continuous condition."
  puts "max group items: $maxGroupItems"
  puts "have $numOfNotMeetContinuousConditionPath paths that does not meet continuous condition."
  puts "output summary file: $outputfilename"
  puts " ------ "
  
}

define_proc_attributes getInfoOfNeedFocusClkGaterOrNeedChangeClockTree_forViolPathFile \
  -info "get info of need focus clk gater or need change clock tree for viol path file"\
  -define_args {
    {-violPathFile "specify the viol path file name" AString string optional}
    {-ifFindLongestClockTreeCommonPath "if find longest clock tree common path that meet continue condition" oneOfString one_of_string {optional value_help {values {0 1}}}}
    {-numNeedContinueCkBufInv "specify the num of need continue clock buffer or inverter" AString string optional}
    {-pba_mode "specify the pba mode for get_timing_paths" AString string optional}
    {-buffOrInvRegExp "specify expression of buffer or inverter" AString string optional}
    {-clkgaterCelltypeRegExp "specify the clkgater celltype regexpression" AString string optional}
    {-keepContinueClockTreeInstName "specify the keep continue clock tree inst name" AString string optional}
    {-needFindInstNameExp "specify the expression of need find inst name e.g. cdb inst, you can demand meet your condition of num of cdb inst" AString string optional}
    {-typeOfPathClockTree "specify the type of path clock tree to find" oneOfString one_of_string {optional value_help {values {launch capture}}}}
    {-output_dir "specify the output dir" AString string optional}
    {-outputFileBodyName "specify the output file body name" AString string optional}
    {-suffixOfOutputFile "specify the suffix of output file in order to facilitate the distinction between output files from different periods and for different purposes." AString string optional}
  }

