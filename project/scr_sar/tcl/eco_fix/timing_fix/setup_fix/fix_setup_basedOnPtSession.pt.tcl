proc fix_setup_basedOnPtSession {args} {
  set pba_mode ex
  set nworst 1
  set max_paths 10000
  set group [list] ; # if is empty, it will not specify this option when using report_timing/get_timing_paths
  set slack_greater_than "none" ; # if is none or empty, it will not specify this option
  set slack_lesser_than "none"
  
  set path_type "full" ; # full|full_clock_expanded
  defaultoptions -input_pins -nets -transition_time -capacitance -significant_digits 4 -crosstalk_delta -derate 
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  
}

define_proc_attributes fix_setup_basedOnPtSession \
  -info "whatFunction"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
