if {[dbGet head.rules.name NDR_1W2S] == "0x0"} {
    add_ndr -name NDR_1W2S -width {ME1 0.05 ME2 0.05 ME3 0.05 ME4 0.05 ME5 0.05 ME6 0.05 ME7 0.4 ME8 2.0} -spacing {ME1 0.09 ME2 0.05 ME3 0.1 ME4 0.1 ME5 0.1 ME6 0.1 ME7 0.8 ME8 2.0}
}
if {[dbGet head.rules.name NDR_2W2S] == "0x0"} {
    add_ndr -name NDR_2W2S -width {ME1 0.05 ME2 0.05 ME3 0.10 ME4 0.10 ME5 0.10 ME6 0.10 ME7 0.80 ME8 4.0} -spacing {ME1 0.09 ME2 0.05 ME3 0.1 ME4 0.1 ME5 0.1 ME6 0.1 ME7 0.8 ME8 4.0}
}

if {[dbGet head.routeTypes.name specialRoute_leaf] == "0x0"} {
    create_route_type -name specialRoute_leaf  -top_preferred_layer $vars(leaf_top_pref_layer) -bottom_preferred_layer $vars(leaf_btm_pref_layer) -non_default_rule NDR_1W2S -preferred_routing_layer_effort high
}
if {[dbGet head.routeTypes.name specialRoute_trunk] == "0x0"} {
    create_route_type -name specialRoute_trunk -top_preferred_layer $vars(top_pref_layer)      -bottom_preferred_layer $vars(btm_pref_layer)      -non_default_rule NDR_2W2S -preferred_routing_layer_effort high
}
if {[dbGet head.routeTypes.name specialRoute_top] == "0x0"} {
    create_route_type -name specialRoute_top   -top_preferred_layer $vars(top_pref_layer)      -bottom_preferred_layer $vars(btm_pref_layer)      -non_default_rule NDR_2W2S -preferred_routing_layer_effort high -shield_side both_side  -shield_net $vars(gnd_nets)
}


#if { $vars(ccopt_shiled_mode) == "false" } { 
#    create_route_type -name specialRoute_leaf  -top_preferred_layer $vars(leaf_top_pref_layer) -bottom_preferred_layer $vars(leaf_btm_pref_layer)  -non_default_rule NDR_1W2S      -preferred_routing_layer_effort  high
#    create_route_type -name specialRoute_trunk -top_preferred_layer $vars(top_pref_layer)      -bottom_preferred_layer $vars(btm_pref_layer)       -non_default_rule $vars(cts_ndr) -preferred_routing_layer_effort high
#    create_route_type -name specialRoute_top   -top_preferred_layer $vars(top_pref_layer)      -bottom_preferred_layer $vars(btm_pref_layer)       -non_default_rule $vars(cts_ndr) -preferred_routing_layer_effort high 
#} else {
#    create_route_type -name specialRoute_leaf  -top_preferred_layer $vars(leaf_top_pref_layer) -bottom_preferred_layer $vars(leaf_btm_pref_layer) -non_default_rule NDR_1W2S        -preferred_routing_layer_effort high
#    create_route_type -name specialRoute_trunk -top_preferred_layer $vars(top_pref_layer)      -bottom_preferred_layer $vars(btm_pref_layer)      -non_default_rule $vars(cts_ndr) -shield_side both_side  -shield_net $vars(gnd_nets) -preferred_routing_layer_effort high
#    create_route_type -name specialRoute_top   -top_preferred_layer $vars(top_pref_layer)      -bottom_preferred_layer $vars(btm_pref_layer)      -non_default_rule $vars(cts_ndr) -shield_side both_side  -shield_net $vars(gnd_nets) -preferred_routing_layer_effort high
#}

set_ccopt_property -net_type top   -route_type specialRoute_top
set_ccopt_property -net_type trunk -route_type specialRoute_trunk
set_ccopt_property -net_type leaf  -route_type specialRoute_leaf

## target slew : leaf:0.080 trunk 0.100 top 0.120
#set_ccopt_property target_max_trans -net_type leaf
#set_ccopt_property target_max_trans -net_type trunk
#set_ccopt_property target_max_trans -net_type top

set_ccopt_property route_type_autotrim false
