proc getInfoOfFluencyOfAttachedTerm_forNewViolPath {args} {
  set attachedTerms [list]
  set attachTermFiles ""
  set newViolFilePath ""
  set pba_mode "ex"
  set tmp_dir_name ".tmp_dir_for_gen_new_viol_path_simple_rpt"
  set outputFileBodyname "affectedPath"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {![file exists $newViolFilePath]} {
    error "proc getInfoOfFluencyOfAttachedTerm_forNewViolPath: input error, not found viol file: $newViolFilePath" 
  }
  mkdir -p ./$tmp_dir_name
  exec grep -E 'Startpoint:|Endpoint:' $newViolFilePath > $tmp_dir_name/simple_newViolFile.rpt
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
  set affectedPath_fromLaunch [list]
  set affectedPath_fromCapture [list]
  set noticeAttachedTermExistsAtBothLaunchAndCapture [list]
  set sideOfLaunchOrCaptureClock ""
  foreach temp_attachedterm $attachedTerms {
    foreach temp_path $pathOfStartToEndList {
      lassign $temp_path temp_start temp_end 
      set temp_col_full_clock_path [get_timing_paths -pba_mode $pba_mode -path_type full_clock_expanded -from $temp_start -to $temp_end ]
      set temp_path_slack [get_attribute $temp_col_full_clock_path slack]
      set temp_col_launch_clock_points [get_attribute [get_attribute $temp_col_full_clock_path launch_clock_paths] points]
      set temp_col_capture_clock_points [get_attribute [get_attribute $temp_col_full_clock_path capture_clock_paths] points]
      set temp_affected_paths_at_launch_clock_path [filter_collection $temp_col_launch_clock_points {$temp_attachedterm =~ "@name"}]
      set temp_affected_paths_at_capture_clock_path [filter_collection $temp_col_capture_clock_points {$temp_attachedterm =~ "@name"}]
      if {[sizeof_collection $temp_affected_paths_at_launch_clock_path]} {
        set sideOfLaunchOrCaptureClock "launch"
        lappend affectedPath_fromLaunch [list $temp_path_slack $temp_path]
      }
      if {[sizeof_collection $temp_affected_paths_at_capture_clock_path]} {
        if {$sideOfLaunchOrCaptureClock eq "launch"} {
          lappend noticeAttachedTermExistsAtBothLaunchAndCapture [list $temp_attachedterm $temp_path_slack $temp_path]
        }
        set sideOfLaunchOrCaptureClock "capture" 
        lappend affectedPath_fromCapture [list $temp_path_slack $temp_path]
      }
      set sideOfLaunchOrCaptureClock ""
    }
  }
  set fo [open ]
}

define_proc_attribute getInfoOfFluencyOfAttachedTerm_forNewViolPath \
  -info "get info of fluency of attached terms for new viol path"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {optional value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string optional}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
