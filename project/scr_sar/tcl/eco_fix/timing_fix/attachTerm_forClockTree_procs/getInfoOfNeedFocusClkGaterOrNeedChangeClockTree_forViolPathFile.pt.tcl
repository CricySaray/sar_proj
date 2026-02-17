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
proc getInfoOfNeedFocusClkGaterOrNeedChangeClockTree_forViolPathFile {args} {
  # NOTICE: need find points after common point
  set violPathFile                  ""
  set numNeedContinueCkBufInv       4
  set pba_mode                      "ex"
  set buffOrInvRegExp               {DCCKN|DCCKB|CKB|CKN}
  set clkgaterCelltypeRegExp        {^CKLNQD}
  set keepContinueClockTreeInstName {U_MAIN_SUB}
  set needFindInstNameExp           {_cdb_}
  set typeOfPathClockTree           "launch" ; # launch|capture
  set tmp_dir_name                  ".tmp_dir_for_get_simple_viol_path_file"
  set output_dir                    "./"
  set outputFileBodyName            "findSameClockTreePart"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {![file exists $violPathFile]} {
    error "proc getInfoOfFluencyOfAttachedTerm_forNewViolPath: input error, not found viol file: $violPathFile" 
  }
  exec mkdir -p ./$tmp_dir_name
  exec grep -E "Startpoint:|Endpoint:" $violPathFile > $tmp_dir_name/simple_newViolFile.rpt
  set fi [open $tmp_dir_name/simple_newViolFile.rpt r]
  set flagSearchStartOrEndpoint "start"
  set pathOfStartToEndList [list]
  set temp_start_end_pair [list]
  while {[gets $fi line] != -1} {
    if {$flagSearchStartOrEndpoint eq "start"} {
      if {[regexp "Startpoint:" $line]} { lappend temp_start_end_pair [lindex $line end] ; set flagSearchStartOrEndpoint "end" } else {
        error "proc getInfoOfNeedFocusClkGaterOrNeedChangeClockTree_forViolPathFile: error viol path content, can find startpoint-endpoint pair when find startpoint at line:\n\t$line" 
      }
    } elseif {$flagSearchStartOrEndpoint eq "end"} {
      if {[regexp "Endpoint:" $line]} { lappend temp_start_end_pair [lindex $line end] ; set flagSearchStartOrEndpoint "start" } else {
        error "proc getInfoOfNeedFocusClkGaterOrNeedChangeClockTree_forViolPathFile: error viol path content, can find startpoint-endpoint pair when find endpoint at line:\n\t$line" 
      }
      if {[llength $temp_start_end_pair] == 2} {
        lappend pathOfStartToEndList $temp_start_end_pair
        set temp_start_end_pair [list] 
      }
    }
  }
  close $fi
  set pathNum [llength $pathOfStartToEndList]
  puts "total find $pathNum path."

  suppress_message UITE-416
  suppress_message UITE-479
  
  set clockTreeMeetConditionPathBlock [list]
  set notFindMeetContinueBufInvPathList [list]
  foreach temp_path $pathOfStartToEndList {
    lassign $temp_path temp_start temp_end 
    # puts "Now processing: \n\tstartpoint: $temp_start\n\tendpoint: $temp_end"
    set temp_col_full_clock_path [get_timing_paths -pba_mode $pba_mode -path_type full_clock_expanded -from $temp_start -to $temp_end ]
    set temp_path_slack [get_attribute $temp_col_full_clock_path slack]
    if {$typeOfPathClockTree eq "launch"} {
      set temp_col_launch_clock_points [get_attribute [get_attribute [get_attribute $temp_col_full_clock_path launch_clock_paths] points] object]
      set temp_list_launch_clock_points [get_object_name $temp_col_launch_clock_points]
      set temp_list_launch_clock_insts [lreverse [lsort -u [get_object_name [get_attribute $temp_col_launch_clock_points cell]]]]
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
      set temp_save_buffer_or_inverter_name [list] ; # order: from prev inst to after inst
      foreach temp_inst $temp_list_launch_clock_insts_after_process_continue_keep_condition {
        if {[regexp -expanded $buffOrInvRegExp [get_attribute [get_cells $temp_inst] ref_name]]} {
          incr temp_num_of_buf_or_inv 
          if {$needFindInstNameExp eq ""} { set temp_num_of_need_find_inst_name 99999 } else {
            if {[regexp -expanded $needFindInstNameExp $temp_inst]} { incr temp_num_of_need_find_inst_name }
          }
          set temp_save_buffer_or_inverter_name [linsert $temp_save_buffer_or_inverter_name 0 $temp_inst]
          if {$temp_num_of_buf_or_inv >= $numNeedContinueCkBufInv && $temp_num_of_need_find_inst_name >= $numNeedContinueCkBufInv} {
            lappend clockTreeMeetConditionPathBlock [list $temp_path_slack $temp_path $temp_save_buffer_or_inverter_name ] 
            set temp_save_buffer_or_inverter_name [list]
            set temp_num_of_buf_or_inv 0
            break
          }
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
      set temp_list_capture_clock_insts [lreverse [lsort -u [get_object_name [get_attribute $temp_col_capture_clock_points cell]]]]
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
      set temp_save_buffer_or_inverter_name [list] ; # order: from prev inst to after inst
      foreach temp_inst $temp_list_capture_clock_insts_after_process_continue_keep_condition {
        if {[regexp -expanded $buffOrInvRegExp [get_attribute [get_cells $temp_inst] ref_name]]} {
          incr temp_num_of_buf_or_inv 
          if {$needFindInstNameExp eq ""} { set temp_num_of_need_find_inst_name 99999 } else {
            if {[regexp -expanded $needFindInstNameExp $temp_inst]} { incr temp_num_of_need_find_inst_name }
          }
          set temp_save_buffer_or_inverter_name [linsert $temp_save_buffer_or_inverter_name 0 $temp_inst]
          if {$temp_num_of_buf_or_inv >= $numNeedContinueCkBufInv && $temp_num_of_need_find_inst_name >= $numNeedContinueCkBufInv} {
            lappend clockTreeMeetConditionPathBlock [list $temp_path_slack $temp_path $temp_save_buffer_or_inverter_name ] 
            set temp_save_buffer_or_inverter_name [list]
            set temp_num_of_buf_or_inv 0
            break
          }
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
  set outputfilename "$output_dir/$outputFileBodyName.rpt"
  set fo [open $outputfilename w]
  set i 0
  foreach temp_block_info $finalClockClockPath_to_violPath {
    incr i
    lassign $temp_block_info temp_save_buffer_or_inverter_name temp_paths 
    puts $fo "No $i:"
    puts $fo "continue buffer or inverter inst:"
    puts $fo [join $temp_save_buffer_or_inverter_name \n]
    puts $fo "RELATED PATHS: (slack startpoint endpoint)"
    foreach temp_path $temp_paths {
      lassign $temp_path temp_slack temp_start_end
      lassign $temp_start_end temp_start temp_end
      puts $fo "$temp_slack $temp_start\n\t\t$temp_end"
    }
    puts $fo ""
  }
  close $fo
  
}

define_proc_attributes getInfoOfNeedFocusClkGaterOrNeedChangeClockTree_forViolPathFile \
  -info "get info of need focus clk gater or need change clock tree for viol path file"\
  -define_args {
    {-violPathFile "specify the viol path file name" AString string optional}
    {-numNeedContinueCkBufInv "specify the num of need continue clock buffer or inverter" AString string optional}
    {-pba_mode "specify the pba mode for get_timing_paths" AString string optional}
    {-buffOrInvRegExp "specify expression of buffer or inverter" AString string optional}
    {-clkgaterCelltypeRegExp "specify the clkgater celltype regexpression" AString string optional}
    {-keepContinueClockTreeInstName "specify the keep continue clock tree inst name" AString string optional}
    {-needFindInstNameExp "specify the expression of need find inst name e.g. cdb inst, you can demand meet your condition of num of cdb inst" AString string optional}
    {-typeOfPathClockTree "specify the type of path clock tree to find" AString string optional}
    {-tmp_dir_name "specify the tmp dir name" AString string optional}
    {-output_dir "specify the output dir" AString string optional}
    {-outputFileBodyName "specify the output file body name" AString string optional}
  }
