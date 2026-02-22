source ../../../packages/get_block_info_fromTimingRptFile.package.tcl; # get_block_info_fromTimingRptFile
proc getInfoOfRelationshipBetweenViolPathFromInputViolFile {args} {
  set violPathFile ""
  set pba_mode ex
  set nworstOfTracePrevLevel 10000
  set levelToSearch 1 ; # trace foreward or backword
  set typeOfViewingSlackOrCounterMargin "slack" ; # slack|margin

  set memMatchExp {.*(sr_hp|sr_ull|sr_base|sr_ll)$}

  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {[file exists $violPathFile]} {
    set timing_block_info_LIST [get_block_info_fromTimingRptFile $violPathFile start_end {Startpoint:} "" {slack \(VIO}]
  }

  set mem2reg_paths_list [list]
  set reg2mem_paths_list [list]

  set timing_startpoint_endpoint_pair_list [lmap temp_timing_block $timing_block_info_LIST {
    set temp_startpoint_inst [lindex [lsearch -inline -regexp $temp_timing_block {^\s*Startpoint:}] 1]
    set temp_endpoint_inst   [lindex [lsearch -inline -regexp $temp_timing_block {^\s*Endpoint:}] 1]
    set temp_start_end_list [list $temp_startpoint_inst $temp_endpoint_inst]
    set typeOfStartpoint ""
    set typeOfEndpoint ""
    if {[regexp $memMatchExp $temp_startpoint_inst]} {
      set typeOfStartpoint "mem"
    } else {
      set typeOfStartpoint "reg"
    }
    if {[regexp $memMatchExp $temp_endpoint_inst]} {
      set typeOfEndpoint "mem"
    } else {
      set typeOfEndpoint "reg"
    }
    if {$typeOfStartpoint eq "mem" && $typeOfEndpoint eq "reg"} {
      lappend mem2reg_paths_list $temp_start_end_list
    } elseif {$typeOfStartpoint eq "reg" && $typeOfEndpoint eq "mem"} {
      lappend reg2mem_paths_list $temp_start_end_list
    }
    set temp_start_end_list
  }]
  set mem2reg_paths_list [lsort -u $mem2reg_paths_list]
  set reg2mem_paths_list [lsort -u $reg2mem_paths_list]

  set mem2reg2mem_list [list]
  set all_endpoints_of_mem2reg [lsort -u [lmap temp_start_end_reg2mem $mem2reg_paths_list { lindex $temp_start_end_reg2mem 1 }]]
  foreach temp_reg2mem $reg2mem_paths_list {
    lassign $temp_reg2mem temp_reg_start temp_mem_end
    if {$temp_reg_start in $all_endpoints_of_mem2reg} {
      set temp_memstart_of_mem2reg [lindex [lsearch -inline -exact -index 1 $mem2reg_paths_list $temp_reg_start] 0]
      lappend mem2reg2mem_list [list $temp_memstart_of_mem2reg {*}$temp_reg2mem]
    }
  }
  if {![llength $mem2reg2mem_list]} {
    puts "have no mem2reg2mem path."
  } else {
    puts "have [llength $mem2reg2mem_list]  mem2reg2mem paths."
  }
  return $mem2reg2mem_list

  ####   foreach temp_start_end $timing_startpoint_endpoint_pair_list {
  ####     lassign $temp_start_end temp_start_inst temp_end_inst
  ####     set temp_start_input_pins [get_pins -of [get_cells $temp_start_inst] -filter "direction==in"]
  ####     set temp_end_output_pins [get_pins -of [get_cells $temp_end_inst] -filter "direction==out"]
  ####     set temp_start_output_pins [get_pins -of [get_cells $temp_start_inst] -filter "direction==out"]
  ####     set temp_end_input_pins [get_pins -of [get_cells $temp_end_inst] -filter "direction==in"]

  ####     set temp_start_end_slack [get_attribute [get_timing_paths -pba_mode $pba_mode -from $temp_start_output_pins -to $temp_end_input_pins] slack]
  ####     if {$typeOfViewingSlackOrCounterMargin eq "slack"} {
  ####       set slackLessValue 0.00000
  ####     } elseif {$typeOfViewingSlackOrCounterMargin eq "margin"} {
  ####       set slackLessValue [expr {abs($temp_start_end_slack)}]
  ####     }

  ####     #    set endpointIsOtherStartpoint_list [list]
  ####     #    set all_startpoints_without_self [lsort -u [lmap temp_start_end_reg2mem [lsearch -not -all -inline -exact $timing_startpoint_endpoint_pair_list $temp_start_end] { lindex $temp_start_end_reg2mem 0 }]]
  ####     #    set all_endpoints_without_self [lsort -u [lmap temp_start_end_reg2mem [lsearch -not -all -inline -exact $timing_startpoint_endpoint_pair_list $temp_start_end] { lindex $temp_start_end_reg2mem 1 }]]
  ####     #    foreach temp_startpoint_1 $all_startpoints_without_self {
  ####     #      if {$temp_startpoint_1 in $all_endpoints_without_self} {
  ####     #        set temp_startpoint_of_this_endpoint [lindex [lsearch -inline -exact -index 1 $timing_startpoint_endpoint_pair_list $temp_startpoint_1] 0]
  ####     #        lappend endpointIsOtherStartpoint_list [list $temp_startpoint_of_this_endpoint {*}$temp_start_end]
  ####     #      }
  ####     #    }
  ####     return $endpointIsOtherStartpoint_list

  ####     # set temp_paths_prevLevelStartpoins_1 [lsort -u [get_object_name [get_attribute [get_attribute [get_timing_paths -to $temp_start_input_pins -nworst $nworstOfTracePrevLevel -max_paths 100000 -slack_lesser_than $slackLessValue] startpoint] cell]]]
  ####     # set prevLevelHaveRelatedPin_list [list]
  ####     # foreach temp_startinst [lmap temp_start_end_2 [lsearch -not -all -inline -exact $timing_startpoint_endpoint_pair_list $temp_start_end] { lindex $temp_start_end_2 0 }] {
  ####     #   if {$temp_startinst in $temp_paths_prevLevelStartpoins_1} {
  ####     #     lappend prevLevelHaveRelatedPin_list [list $temp_start_end]
  ####     #   }
  ####     # }
  ####   }
}

define_proc_attributes getInfoOfRelationshipBetweenViolPathFromInputViolFile \
  -info "get info of relationship between viol paths from input viol file"\
  -define_args {
    {-violPathFile "specify the viol path filename" AString string optional}
    {-pba_mode "specify the pba mode" oneOfString one_of_string {optional value_help {values {ex none path}}}}
    {-nworstOfTracePrevLevel "specify the num of nworst of trace prev level" AInt int optional}
    {-levelToSearch "specify the level to search foreword or backword" AInt int optional}
    {-typeOfViewingSlackOrCounterMargin "specify the type of viewing slack or counter margin" oneOfString one_of_string {optional value_help {values {slack margin}}}}
  }
