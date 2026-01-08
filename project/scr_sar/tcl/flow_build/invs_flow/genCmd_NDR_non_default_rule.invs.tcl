#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/01/07 19:27:41 Wednesday
# label     : 
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
# TO_WRITE
proc genCmd_NDR_non_default_rule {args} {
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set_ccopt_property routing_top_min_fanout 1000
  set_ccopt_property target_max_trans 0.12
  set_ccopt_property target_insertion_delay 0.0
  set_ccopt_property max_fanout 32
  set_ccopt_mode -cts_target_skew 0.04
  set_ccopt_property -route_override_settings "setRouteMode -earlyGlobalSpecialModelingForN12 1"
  
  set occRegClkPins [get_pins -quiet -hier -leaf -of [get_cells -q -hier -filter "is_sequential && full_name ~= *occ* && full_name !~ *u_scan_icg* && ref_name !~ *LN* && full_name =~ *CRG*"] -filter "name =~ CP*"]
  if {$occRegClkPins != ""} {
    foreach pin [get_object_name $occRegClkPins] {
      set_ccopt_property sink_type ignore -pin $pin 
    }
  }
  create_ccopt_clock_tree_spec -file ./rpts/cts.spec
  source ./rpts/cts.spec

  create_route_type -name ndr2w2s_clock_hard -top_preferred_layer 6 -bottom_preferred_layer 4 -mask 0 -non_default_rule ndr_2w2s
  create_route_type -name ndr2w2s_clock_leaf -top_preferred_layer 6 -bottom_preferred_layer 3 -mask 0 -non_default_rule ndr_2w2s

  create_route_type -name ndr2w3s_clock_leaf -top_preferred_layer 6 -bottom_preferred_layer 3 -mask 0 -non_default_rule ndr_2w3s
  create_route_type -name ndr2w3s_clock_leaf -top_preferred_layer 6 -bottom_preferred_layer 3 -mask 0 -non_default_rule ndr_2w3s
  
  create_route_type -name ndr2w2s_clock_hard_shield -top_preferred_layer 6 -bottom_preferred_layer 4 -mask 0 -non_default_rule ndr_2w2s -shield_net VSS -shield_side both_side 
  create_route_type -name ndr2w2s_clock_leaf_shield -top_preferred_layer 6 -bottom_preferred_layer 3 -mask 0 -non_default_rule ndr_2w2s -shield_net VSS -shield_side both_side

  create_route_type -name ndr2w3s_clock_leaf_shield -top_preferred_layer 6 -bottom_preferred_layer 3 -mask 0 -non_default_rule ndr_2w3 -shield_net VSS -shield_side both_sides
  create_route_type -name ndr2w3s_clock_leaf_shield -top_preferred_layer 6 -bottom_preferred_layer 3 -mask 0 -non_default_rule ndr_2w3 -shield_net VSS -shield_side both_sides
  
  set_ccopt_property route_type ndr2w2s_clock_hard_shield -net_type top
  set_ccopt_property route_type ndr2w2s_clock_hard        -net_type trunk
  set_ccopt_property route_type ndr2w2s_clock_leaf_shield -net_type leaf
  if {0} {
    set_ccopt_property cts_add_wire_delay_in_detailed_balancer false 
    set_ccopt_property cts_balance_wire_delay false 
  }
}

define_proc_arguments genCmd_NDR_non_default_rule \
  -info "whatFunction"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
