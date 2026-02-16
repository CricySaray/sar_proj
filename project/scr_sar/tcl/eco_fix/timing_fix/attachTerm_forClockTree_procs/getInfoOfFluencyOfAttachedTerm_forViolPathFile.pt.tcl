proc getInfoOfFluencyOfAttachedTerm_forNewViolPath {args} {
  set attachedTerms [list]
  set violPathFile ""
  set pba_mode "ex"
  set tmp_dir_name ".tmp_dir_for_gen_new_viol_path_simple_rpt"
  set outputFileBodyName "affectedPathByAttachedTerm"
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
  set affectedPath_fromLaunch [list]
  set affectedPath_fromCapture [list]
  set noAffectPath [list]
  set noticeAttachedTermExistsAtBothLaunchAndCapture [list]
  set sideOfLaunchOrCaptureClock ""
  set i 0
  suppress_message UITE-416
  suppress_message UITE-479
  foreach temp_attachedterm $attachedTerms {
    foreach temp_path $pathOfStartToEndList {
      lassign $temp_path temp_start temp_end 
      set temp_col_full_clock_path [get_timing_paths -pba_mode $pba_mode -path_type full_clock_expanded -from $temp_start -to $temp_end ]
      set temp_path_slack [get_attribute $temp_col_full_clock_path slack]
      set temp_col_launch_clock_points [get_attribute [get_attribute [get_attribute $temp_col_full_clock_path launch_clock_paths] points] object]
      set temp_col_capture_clock_points [get_attribute [get_attribute [get_attribute $temp_col_full_clock_path capture_clock_paths] points] object]
      set temp_list_launch_clock_points [get_object_name $temp_col_launch_clock_points]
      set temp_list_capture_clock_points [get_object_name $temp_col_capture_clock_points]
      if {[lsearch -regexp $temp_list_launch_clock_points $temp_attachedterm] != -1} {
        set sideOfLaunchOrCaptureClock "launch"
        lappend affectedPath_fromLaunch [list $temp_path_slack $temp_path]
      }
      if {[lsearch -regexp $temp_list_capture_clock_points $temp_attachedterm] != -1} {
        if {$sideOfLaunchOrCaptureClock eq "launch"} {
          lappend noticeAttachedTermExistsAtBothLaunchAndCapture [list $temp_attachedterm $temp_path_slack $temp_path]
          set affectedPath_fromLaunch [lsearch -all -inline -not -exact $affectedPath_fromLaunch [list $temp_path_slack $temp_path]]
        } else {
          set sideOfLaunchOrCaptureClock "capture" 
          lappend affectedPath_fromCapture [list $temp_path_slack $temp_path]
        }
      }
      if {$sideOfLaunchOrCaptureClock eq ""} {
        lappend noAffectPath [list $temp_path_slack $temp_path]
      } else {
        set sideOfLaunchOrCaptureClock ""
      }
    }
    incr i
    set outputfilename "$outputFileBodyName.No$i.rpt"
    set fo [open $outputfilename w]
    puts $fo "# affected by term: $temp_attachedterm"
    if {$noticeAttachedTermExistsAtBothLaunchAndCapture ne ""} {
      puts $fo "NOTICE: affected path by both launch and capture clock path: (slack startpoint endpoint)"
      foreach temp_affected_path $noticeAttachedTermExistsAtBothLaunchAndCapture {
        lassign $temp_affected_path temp_attachedterm temp_slack temp_start_end
        lassign $temp_start_end temp_start_2 temp_end_2
        puts $fo "$temp_slack $temp_start_2\n\t$temp_end_2" 
      }
      puts $fo ""
    }
    if {$affectedPath_fromLaunch ne ""} {
      puts $fo "AFFECTED PATHS BY LAUNCH: (slack startpoint endpoint)"
      foreach temp_affected_path $affectedPath_fromLaunch {
        lassign $temp_affected_path temp_slack temp_start_end
        lassign $temp_start_end temp_start_2 temp_end_2
        puts $fo "$temp_slack $temp_start_2\n\t$temp_end_2" 
      }
      puts $fo ""
    }
    if {$affectedPath_fromCapture ne ""} {
      puts $fo "AFFECTED PATHS BY CAPTURE: (slack startpoint endpoint)"
      foreach temp_affected_path $affectedPath_fromCapture {
        lassign $temp_affected_path temp_slack temp_start_end
        lassign $temp_start_end temp_start_2 temp_end_2
        puts $fo "$temp_slack $temp_start_2\n\t$temp_end_2" 
      }
      puts $fo ""
    }
    if {$noAffectPath ne ""} {
      puts $fo "NO AFFECTED PATHS: (slack startpoint endpoint)"
      foreach temp_no_affected_path $noAffectPath {
        lassign $temp_no_affected_path temp_slack temp_start_end
        lassign $temp_start_end temp_start_2 temp_end_2
        puts $fo "$temp_slack $temp_start_2\n\t$temp_end_2" 
      }
    }
    close $fo
    set noticePathNum [llength $noticeAttachedTermExistsAtBothLaunchAndCapture]
    set launchRelatedPathNum [llength $affectedPath_fromLaunch]
    puts "For attached term: $temp_attachedterm"
    puts "have"
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
  }
