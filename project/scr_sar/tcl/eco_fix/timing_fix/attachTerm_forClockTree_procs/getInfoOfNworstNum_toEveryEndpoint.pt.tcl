source ../../../packages/table_format_with_title.package.tcl; # table_format_with_title
proc getInfoOfNworstNum_toEveryEndpoint {args} {
  set violPathRptFilenameOrEndpointList        "" ; # pt timing report path rpt
  set nworstLimit                              1000
  set pba_mode                                 ex
  set slackLesserThanWhenReportActualNworstNum 0.0000
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {[file exists $violPathRptFilenameOrEndpointList]} {
    set fi [open $violPathRptFilenameOrEndpointList r]
    set endpoints_list [lmap temp_line [lsearch -inline -regexp -all [split [read $fi] "\n"] {^\s*Endpoint:}] { 
      set temp_end [lindex $temp_line 1]
      if {[get_cells -q $temp_end] eq "" && [get_pins -q $temp_end] ne ""} {
        set temp_end [get_cells -of [get_pins $temp_end]]
      } elseif {[get_cells -q $temp_end] ne ""} {
        set temp_end
      } else {
        error "proc getInfoOfNworstNum_toEveryEndpoint: error : check your input file content: endpoint is not pin or inst name ($temp_end)"
      }
    }]
    close $fi
  } else {
    set endpoints_list [lmap temp_input_item $violPathRptFilenameOrEndpointList {
      if {[get_cells -q $temp_input_item] eq "" && [get_pins -q $temp_input_item] ne ""} {
        set temp_input_item [get_cells -of [get_pins $temp_input_item]]
      } elseif {[get_cells -q $temp_input_item] ne ""} {
        set temp_input_item
      } else {
        error "proc getInfoOfNworstNum_toEveryEndpoint: error : check your input endpoint list: endpoint is not pin or inst name ($temp_input_item)"
      }
    }]
  }
  set endpoints_list [lsort -u $endpoints_list]
  set numOfEndpoints [llength $endpoints_list]
  set i 0
  set nworst_worstSlack_endpoint_list [list]
  foreach temp_endpoint $endpoints_list {
    incr i
    puts -nonewline "$i "
    flush stdout
    set endpoint_worst_slack [get_attribute [get_timing_paths -slack_lesser_than 9999 -to [get_cells $temp_endpoint] -pba_mode $pba_mode] slack]
    set actual_to_endpoint_num_with_nworst_more [sizeof_collection [get_timing_paths -nworst $nworstLimit -slack_lesser_than $slackLesserThanWhenReportActualNworstNum -to [get_cells $temp_endpoint] -pba_mode $pba_mode]]
    lappend nworst_endpoint_list [list $actual_to_endpoint_num_with_nworst_more $endpoint_worst_slack $temp_endpoint]
  }
  set nworst_endpoint_list_inOrderByNworstNum [lsort -index 0 -increasing -real $nworst_endpoint_list]
  set nworst_endpoint_list_inOrderByWorstSlack [lsort -index 1 -increasing -real $nworst_endpoint_list]
  set worst_slack [lindex $nworst_endpoint_list_inOrderByWorstSlack 0 0]
  set mostNworstNum [lindex $nworst_endpoint_list_inOrderByNworstNum 0 1]
  puts ""
  puts " ------ "
  puts "total process $numOfEndpoints endpoints."
  puts "worst slack: $worst_slack ns"
  puts "most nworst num: $mostNworstNum path."
}

define_proc_attributes getInfoOfNworstNum_toEveryEndpoint \
  -info "get info of nworst num to every endpoint"\
  -define_args {
    {-violPathRptFilenameOrEndpointList "specify the viol path rpt file name or endpoint list" AList list optional}
    {-pba_mode "specify the pba mode" oneOfString one_of_string {optional value_help {values {ex none path}}}}
    {-nworstLimit "specify the nworst num limit" AInt int optional}
    {-slackLesserThanWhenReportActualNworstNum "specify the slack that is lesser than, when report actual nworst num" AFloat float optional}
  }
