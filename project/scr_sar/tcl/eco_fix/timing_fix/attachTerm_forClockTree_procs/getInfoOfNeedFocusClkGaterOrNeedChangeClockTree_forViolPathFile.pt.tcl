proc getInfoOfNeedFocusClkGaterOrNeedChangeClockTree_forViolPathFile {args} {
  # NOTICE: need find points after common point
  set violPathFile            ""
  set numNeedContinueCkBufInv 4
  set typeOfPathClockTree     "launch" ; # launch|capture
  set tmp_dir_name            ".tmp_dir_for_get_simple_viol_path_file"
  set output_dir              "./"
  set outputFileBodyName      "findSameClockTreePart"
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
  
}

define_proc_attributes getInfoOfNeedFocusClkGaterOrNeedChangeClockTree_forViolPathFile \
  -info "get info of need focus clk gater or need change clock tree for viol path file"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {optional value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string optional}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
