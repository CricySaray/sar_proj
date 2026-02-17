#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/02/16 21:23:14 Monday
# label     : clock_tree_relative_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : * Input a list of attachTerms (these terms must be locations on the clock tree), along with a violation path report file. 
#             It can determine which violations are affected by these terms, or identify which new violation paths are caused by jumper 
#             changes to terms on the clock tree.
#             * Alternatively, you can run this script once every time you make a jumper change during the routing process to see how many 
#             paths are affected by that single jumper adjustment.  
#             This prevents unpredictable impacts caused by repeated jumper changes on different violations that share the same clock tree path.
# return    : output affected path summary file and summary list
# ref       : link url
# --------------------------
alias sus "subst -nocommands -nobackslashes"
proc getInfoOfFluencyOfAttachedTerm_forNewViolPath {args} {
  set attachedTerms [list]
  set violPathFile ""
  set pba_mode "ex"
  set tmp_dir_name ".tmp_dir_for_gen_new_viol_path_simple_rpt"
  set outputFileBodyName "affectedPathByAttachedTerm"
  set output_dir "./"
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
        error "proc getInfoOfFluencyOfAttachedTerm_forNewViolPath: error viol path content, can find startpoint-endpoint pair when find startpoint at line:\n\t$line" 
      }
    } elseif {$flagSearchStartOrEndpoint eq "end"} {
      if {[regexp "Endpoint:" $line]} { lappend temp_start_end_pair [lindex $line end] ; set flagSearchStartOrEndpoint "start" } else {
        error "proc getInfoOfFluencyOfAttachedTerm_forNewViolPath: error viol path content, can find startpoint-endpoint pair when find endpoint at line:\n\t$line" 
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
  set temp_create_i 0
  foreach temp_attachedterm $attachedTerms {
    incr temp_create_i
    set affectedPath_fromLaunch_$temp_create_i [list]
    set affectedPath_fromCapture_$temp_create_i [list]
    set noticeAttachedTermExistsAtBothLaunchAndCapture_$temp_create_i [list]
    set noAffectPath_$temp_create_i [list]
  }
  foreach temp_path $pathOfStartToEndList {
    lassign $temp_path temp_start temp_end 
    set temp_col_full_clock_path [get_timing_paths -pba_mode $pba_mode -path_type full_clock_expanded -from $temp_start -to $temp_end ]
    set temp_path_slack [get_attribute $temp_col_full_clock_path slack]
    set temp_col_launch_clock_points [get_attribute [get_attribute [get_attribute $temp_col_full_clock_path launch_clock_paths] points] object]
    set temp_col_capture_clock_points [get_attribute [get_attribute [get_attribute $temp_col_full_clock_path capture_clock_paths] points] object]
    set temp_list_launch_clock_points [get_object_name $temp_col_launch_clock_points]
    set temp_list_capture_clock_points [get_object_name $temp_col_capture_clock_points]
    set i 0
    foreach temp_attachedterm $attachedTerms {
      incr i
      if {[lsearch -regexp $temp_list_launch_clock_points $temp_attachedterm] != -1 && [lsearch -regexp $temp_list_capture_clock_points $temp_attachedterm] == -1} {
        lappend affectedPath_fromLaunch_$i [list $temp_path_slack $temp_path]
      } elseif {[lsearch -regexp $temp_list_launch_clock_points $temp_attachedterm] == -1 && [lsearch -regexp $temp_list_capture_clock_points $temp_attachedterm] != -1} {
        lappend affectedPath_fromCapture_$i [list $temp_path_slack $temp_path]
      } elseif {[lsearch -regexp $temp_list_launch_clock_points $temp_attachedterm] != -1 && [lsearch -regexp $temp_list_capture_clock_points $temp_attachedterm] != -1} {
        lappend noticeAttachedTermExistsAtBothLaunchAndCapture_$i [list $temp_attachedterm $temp_path_slack $temp_path]
      } else {
        lappend noAffectPath_$i [list $temp_path_slack $temp_path]
      }
    }
  }
  set j 0
  foreach temp_attachedterm $attachedTerms {
    incr j
    set outputfilename "$output_dir/$outputFileBodyName.No$j.rpt"
    set fo [open $outputfilename w]
    puts $fo "# affected by term: $temp_attachedterm"
    if {[sus \${noticeAttachedTermExistsAtBothLaunchAndCapture_$j}] ne ""} {
      puts $fo "NOTICE: affected path by both launch and capture clock path: (slack startpoint endpoint)"
      foreach temp_affected_path [sus \${noticeAttachedTermExistsAtBothLaunchAndCapture_$j}] {
        lassign $temp_affected_path temp_attachedterm temp_slack temp_start_end
        lassign $temp_start_end temp_start_2 temp_end_2
        puts $fo "$temp_slack $temp_start_2\n\t$temp_end_2" 
      }
      puts $fo ""
    }
    if {[sus \${affectedPath_fromLaunch_$j}] ne ""} {
      puts $fo "AFFECTED PATHS BY LAUNCH: (slack startpoint endpoint)"
      foreach temp_affected_path [sus \${affectedPath_fromLaunch_$j}] {
        lassign $temp_affected_path temp_slack temp_start_end
        lassign $temp_start_end temp_start_2 temp_end_2
        puts $fo "$temp_slack $temp_start_2\n\t$temp_end_2" 
      }
      puts $fo ""
    }
    if {[sus \${affectedPath_fromCapture_$j}] ne ""} {
      puts $fo "AFFECTED PATHS BY CAPTURE: (slack startpoint endpoint)"
      foreach temp_affected_path [sus \${affectedPath_fromCapture_$j}] {
        lassign $temp_affected_path temp_slack temp_start_end
        lassign $temp_start_end temp_start_2 temp_end_2
        puts $fo "$temp_slack $temp_start_2\n\t$temp_end_2" 
      }
      puts $fo ""
    }
    if {[sus \${noAffectPath_$j}] ne ""} {
      puts $fo "NO AFFECTED PATHS: (slack startpoint endpoint)"
      foreach temp_no_affected_path [sus \${noAffectPath_$j}] {
        lassign $temp_no_affected_path temp_slack temp_start_end
        lassign $temp_start_end temp_start_2 temp_end_2
        puts $fo "$temp_slack $temp_start_2\n\t$temp_end_2" 
      }
    }
    close $fo
    set noticePathNum [llength [sus \${noticeAttachedTermExistsAtBothLaunchAndCapture_$j}]]
    set launchRelatedPathNum [llength [sus \${affectedPath_fromLaunch_$j}]]
    set captureRelatedPathNum [llength [sus \${affectedPath_fromCapture_$j}]]
    set noAffectedPathNum [llength [sus \${noAffectPath_$j}]]
    puts "For attached term: $temp_attachedterm"
    puts "  need notice path         : $noticePathNum"
    puts "  launch related path num  : $launchRelatedPathNum"
    puts "  capture related path num : $captureRelatedPathNum"
    puts "  no affected path num     : $noAffectedPathNum"
    puts "  output file name         : $outputfilename"
    puts " ------ "
  }
}
define_proc_attributes getInfoOfFluencyOfAttachedTerm_forNewViolPath \
  -info "get info of fluency of attached terms for new viol path file"\
  -define_args {
    {-attachedTerms "specify attached terms" AList list optional}
    {-violPathFile "specify the new viol path file" AString string optional}
    {-pba_mode "specify the pba mode for get_timing path" AString string optional}
    {-tmp_dir_name "specify the tmp dir name" AString string optional}
    {-outputFileBodyName "specify the output file body name" AString string optional}
    {-output_dir "specify the output directory" AString string optional}
  }
