proc getInfoOfNeedFocusClkGaterOrNeedChangeClockTree_forViolPathFile {args} {
  set violPathFile ""
  set numNeedContinueCkBufInv 4
  set tmp_dir_name ".tmp_dir_for_get_simple_viol_path_file"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  
  
}

define_proc_attributes getInfoOfNeedFocusClkGaterOrNeedChangeClockTree_forViolPathFile \
  -info "get info of need focus clk gater or need change clock tree for viol path file"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {optional value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string optional}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
