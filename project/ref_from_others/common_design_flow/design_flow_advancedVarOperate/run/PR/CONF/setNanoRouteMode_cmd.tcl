# default value
setNanoRouteMode -reset                                                
setNanoRouteMode -extract_keep_fill_wires                               false  ; # {true|false}
setNanoRouteMode -route_adjust_auto_via_weight                          true   ; # {true|false}
setNanoRouteMode -route_allow_inst_overlaps                             true   ; # {true|false}
setNanoRouteMode -route_ignore_follow_pin_shapes                        false  ; # {true|false}
setNanoRouteMode -route_process_node                                    ""     ; # value
setNanoRouteMode -route_rc_extraction_corner                            ""     ; # value
setNanoRouteMode -route_skip_analog                                     false  ; # {true|false}
setNanoRouteMode -route_via_weight                                      auto   ; # {via_name via_weight ...}
setNanoRouteMode -route_detail_add_passive_fill_only_on_layers          ""     ; # layers
setNanoRouteMode -route_detail_allow_passive_fill_only_in_layers        false  ; # layers
setNanoRouteMode -route_detail_antenna_eco_list_file                    ""     ; # file_name
setNanoRouteMode -route_detail_auto_stop                                true   ; # {true|false}
setNanoRouteMode -route_detail_end_iteration                            0      ; # pass_number
setNanoRouteMode -route_detail_check_mar_on_cell_pin                    false  ; # {true|false}
setNanoRouteMode -route_detail_fix_antenna                              true   ; # {true|false}
setNanoRouteMode -route_detail_fix_antenna_on_secondary_pg_nets         false  ; # {true|false}
setNanoRouteMode -route_detail_fix_antenna_with_gate_array_filler_mode  false  ; # {true|false}
setNanoRouteMode -route_detail_merge_abutting_cut                       true   ; # {true|false}
setNanoRouteMode -route_detail_min_length_for_spread_wire               0      ; # {layer_1 length_1 ... layer_n length_n}
setNanoRouteMode -route_detail_min_length_for_widen_wire                1      ; # value
setNanoRouteMode -route_detail_min_slack_for_opt_wire                   1      ; # value
setNanoRouteMode -route_detail_no_taper_in_layers                       ""     ; # "bottom_layer_number:top_layer_number"
setNanoRouteMode -route_detail_no_taper_on_output_pin                   false  ; # {true|false|auto}
setNanoRouteMode -route_detail_on_grid_only                             none   ; # none | false | true | all | {[wire [ml:mh]] | [via [ml:mh]]}
setNanoRouteMode -route_detail_post_route_litho_repair                  false  ; # {true|false}
setNanoRouteMode -route_detail_post_route_spread_wire                   auto   ; # {auto| true | false | 0 | 0.25 | 0.5 | 1 }
setNanoRouteMode -route_detail_post_route_swap_via                      false  ; # {true | multiCut | false | none}
setNanoRouteMode -route_detail_post_route_via_pillar_effort             low    ; # {none | low | medium | high}
setNanoRouteMode -route_detail_postroute_via_priority                   auto   ; # {auto | allNets | criticalNetsfirst | nonCriticalNetOnly}
setNanoRouteMode -route_detail_post_route_wire_widen                    none   ; # {widen | shrink | none}
setNanoRouteMode -route_detail_post_route_wire_widen_rule               ""     ; # rule_name
setNanoRouteMode -route_detail_search_and_repair                        true   ; # {true|false}
setNanoRouteMode -route_detail_signoff_effort                           high   ; # {high | medium | low | auto | n}
setNanoRouteMode -route_detail_stub_routing_in_first_layer              false  ; # {true|false}
setNanoRouteMode -route_detail_use_multi_cut_via_effort                 low    ; # {low | medium | high}
setNanoRouteMode -route_number_fail_limit                               1      ; # integer
setNanoRouteMode -route_number_thread                                   1      ; # number_processors
setNanoRouteMode -route_number_warning_limit                            20     ; # integer
setNanoRouteMode -route_third_party_data                                false  ; # {true|false}
setNanoRouteMode -route_high_freq_constraint_groups                     ""     ; # {order net match bus pair shield}
setNanoRouteMode -route_high_freq_match_report_file                     ""     ; # file_name
setNanoRouteMode -route_high_freq_num_reserved_layers                   1      ; # value
setNanoRouteMode -route_high_freq_remove_floating_shield                false  ; # {true|false}
setNanoRouteMode -route_high_freq_search_repair                         auto   ; # {auto | false | true | only}
setNanoRouteMode -route_high_freq_shield_trim_length                    0      ; # value
setNanoRouteMode -route_interposer_allow_diagonal_trunk                 ""     ; # {auto | true | false}
setNanoRouteMode -route_interposer_interlayer_shielding_layers          ""     ; # value
setNanoRouteMode -route_interposer_interlayer_shielding_nets            ""     ; # value
setNanoRouteMode -route_interposer_interlayer_shielding_widths          ""     ; # value
setNanoRouteMode -route_interposer_interlayer_shielding_offsets         ""     ; # value
setNanoRouteMode -route_interposer_same_layer_shielding_net             ""     ; # net_name
setNanoRouteMode -route_interposer_same_layer_shielding_width_spacing   ""     ; # {width width}
setNanoRouteMode -route_interposer_trunk_routing_layers                 ""     ; # value
setNanoRouteMode -route_interposer_trunk_routing_width_spacing          ""     ; # {width width}
setNanoRouteMode -route_add_antenna_inst_prefix                         ""     ; # value
setNanoRouteMode -route_concurrent_minimize_via_count_effort            medium ; # value
setNanoRouteMode -route_allow_pin_as_feedthru                           true   ; # {true|TRUE|false|FALSE|none|NONE|output|input|inout, bottomLayerNum:topLayerNum}
setNanoRouteMode -route_antenna_cell_name                               ""     ; # {cell_name | list_of_cell_names}
setNanoRouteMode -route_connect_to_bumps                                false  ; # {true | false}
setNanoRouteMode -route_fix_clock_nets                                  false  ; # {true|false}
setNanoRouteMode -route_route_clock_nets_first                          true   ; # {true|false}
setNanoRouteMode -route_eco_ignore_existing_route                       ""     ; # value
setNanoRouteMode -route_enable_route_rule_si_limit_length               false  ; # value
setNanoRouteMode -route_enforce_route_rule_on_special_net_wire          false  ; # {false | true | special_net_name_list}
setNanoRouteMode -route_extra_via_enclosure                             0      ; # distance
setNanoRouteMode -route_honor_exclusive_region                          true   ; # {true|false}
setNanoRouteMode -route_honor_power_domain                              false  ; # {true|false}
setNanoRouteMode -route_ignore_antenna_top_cell_pin                     true   ; # {true|false}
setNanoRouteMode -route_antenna_diode_insertion                         false  ; # {true|false}
setNanoRouteMode -route_diode_insertion_for_clock_nets                  false  ; # {true|false}
setNanoRouteMode -route_shield_tap_cell_insertion                       ""     ; # {true|false}
setNanoRouteMode -route_relaxed_route_rule_spacing_to_power_ground_nets none   ; # {layer:spacing layer:spacing}
setNanoRouteMode -route_reserve_space_for_multi_cut                     false  ; # {true|false}
setNanoRouteMode -route_reverse_direction                               ""     ; # {(lx ly ux uy bottom_layer:top_layer)}
setNanoRouteMode -route_selected_net_only                               false  ; # {true|false}
setNanoRouteMode -route_shield_crosstie_offset                          ""     ; # {layerName:numTrack1 layerName2:numTrack2...}
setNanoRouteMode -route_shield_length_threshold                         -1     ; # value
setNanoRouteMode -route_shield_report_skip_status                       false  ; # {true|false}
setNanoRouteMode -route_shield_tap_cell_name                            ""     ; # string
setNanoRouteMode -route_strictly_honor_1d_routing                       false  ; # value
setNanoRouteMode -route_strictly_honor_route_rule                       false  ; # {true  | false | bottomLayerNum:topLayerNum | wire bottomLayerNum:topLayerNum}
setNanoRouteMode -route_stripe_layer_range                              ""     ; # "bottomLayerNum:topLayerNum"
setNanoRouteMode -route_tieoff_to_shapes                                auto   ; # "auto | stripe | ring | followpin | powergroundpin"
setNanoRouteMode -route_trim_pull_back_distance_from_boundary           ""     ; # {layer:value ...}
setNanoRouteMode -route_use_auto_via                                    auto   ; # value
setNanoRouteMode -route_trunk_with_cluster_target_size                  1      ; # integer
setNanoRouteMode -route_with_eco                                        false  ; # {true|false}
setNanoRouteMode -route_with_litho_driven                               false  ; # {true|false}
setNanoRouteMode -route_with_si_driven                                  false  ; # {true|false}
setNanoRouteMode -route_with_timing_driven                              false  ; # {true|false}
setNanoRouteMode -route_with_trim_metal                                 ""     ; # value
setNanoRouteMode -route_with_via_in_pin                                 false  ; # {true| false | bottomLayerNum:topLayerNum}
setNanoRouteMode -route_with_via_only_for_block_cell_pin                false  ; # value
setNanoRouteMode -route_with_via_only_for_stdcell_pin                   false  ; # {true| false | bottomLayerNum:topLayerNum}
