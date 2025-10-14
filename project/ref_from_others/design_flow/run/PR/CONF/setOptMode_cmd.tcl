setOptMode -reset                                                 
setOptMode -opt_activity_refresh_args                              ""          ; # "list_of_arguments"
setOptMode -opt_add_always_on_feed_through_buffers                 false       ; # {true | false}
setOptMode -opt_add_insts                                          true        ; # {true | false}
setOptMode -opt_add_ports                                          true        ; # {true | false}
setOptMode -opt_add_repeater_report_failure_reason                 false       ; # {true | false}
setOptMode -opt_all_end_points                                     false       ; # {true | false}
setOptMode -opt_allow_only_cell_swapping                           false       ; # {true | false}
setOptMode -opt_allow_multi_bit_on_flop_with_sdc                   true        ; # {true | false | mergeOnly | splitOnly}
setOptMode -opt_area_recovery                                      default     ; # {true |false | default}
setOptMode -opt_area_recovery_setup_target_slack                   0ns         ; # slack
setOptMode -opt_consider_routing_congestion                        auto        ; # {auto | false | true}
setOptMode -opt_constant_inputs                                    false       ; # {true | false}
setOptMode -opt_constant_nets                                      true        ; # {true | false}
setOptMode -opt_concatenate_default_and_user_prefixes              true        ; # {true | false}
setOptMode -opt_delete_insts                                       true        ; # {true | false}
setOptMode -opt_detail_drv_failure_reason                          false       ; # {true | false}
setOptMode -opt_detail_drv_failure_reason_max_num_nets             50          ; # value
setOptMode -opt_down_size_insts                                    true        ; # {true | false}
setOptMode -opt_drv                                                true        ; # {true | false}
setOptMode -opt_drv_margin                                         0           ; # margin
setOptMode -opt_drv_with_miller_cap                                false       ; # {true | false}
setOptMode -opt_duplicate_cte_constrained_hport                    false       ; # {true | false}
setOptMode -opt_enable_data_to_data_checks                         false       ; # {true | false}
setOptMode -opt_enable_podv2_clock_opt_flow                        true        ; # {true | false}
setOptMode -opt_enable_restructure                                 true        ; # {true | false}
setOptMode -opt_fix_fanout_load                                    false       ; # {true | false}
setOptMode -opt_flop_pins_report                                   fales       ; # {false | true}
setOptMode -opt_flops_report                                       false       ; # {false | true}
setOptMode -opt_hold_allow_overlap                                 auto        ; # {auto | true | false}
setOptMode -opt_high_effort_cells                                  ""          ; # list_of_cells
setOptMode -opt_hold_allow_resize                                  true        ; # {true | false}
setOptMode -opt_hold_allow_setup_tns_degradation                   true        ; # {true | false}
setOptMode -opt_hold_cells                                         [list]      ; # list_of_buffers
setOptMode -opt_hold_on_excluded_clock_nets                        false       ; # {true | false}
setOptMode -opt_hold_slack_threshold                               -1000ns     ; # slack
setOptMode -opt_hold_target_slack                                  0           ; # holdTargetslack
setOptMode -opt_honor_density_screen                               false       ; # {true | false}
setOptMode -opt_honor_fences                                       false       ; # {true | false}
setOptMode -opt_hold_ignore_path_groups                            ""          ; # {groupA groupB ...}
setOptMode -opt_leakage_to_dynamic_ratio                           1           ; # ratio
setOptMode -opt_max_density                                        0.95        ; # density
setOptMode -opt_max_length                                         -1          ; # length
setOptMode -opt_move_insts                                         true        ; # {true | false}
setOptMode -opt_multi_bit_combinational_mode                       auto        ; # {auto | power | area}
setOptMode -opt_multi_bit_combinational_opt                        splitOnly   ; # {false | true | mergeOnly | splitOnly}
setOptMode -opt_multi_bit_combinational_merge_timing_effort        medium      ; # {none | low | medium | high}
setOptMode -opt_multi_bit_combinational_split_timing_effort        low         ; # {none | low | medium | high}
setOptMode -opt_multi_bit_flop_merge_bank_label_inference          false       ; # {true | false}
setOptMode -opt_multi_bit_flop_merge_timing_effort                 medium      ; # {low | medium | high}
setOptMode -opt_multi_bit_flop_name_prefix                         "CDN_MBIT_" ; # prefix_name
setOptMode -opt_multi_bit_flop_name_separator                      "_MD_"      ; # separator_name
setOptMode -opt_multi_bit_flop_name_suffix                         ""          ; # _user_suffix
setOptMode -opt_multi_bit_flop_opt                                 splitOnly   ; # {true | false | mergeOnly | splitOnly}
setOptMode -opt_multi_bit_flop_reorder_bits                        false       ; # {false | true | timing | power}
setOptMode -opt_multi_bit_flop_split_report_failure_reason         true        ; # {true|false}
setOptMode -opt_multi_bit_flop_split_timing_effort                 low         ; # {low | medium | high}
setOptMode -opt_multi_bit_unused_bit_count                         0           ; # integer
setOptMode -opt_multi_bit_unused_bits                              prePlace    ; # {false | true | prePlace | preCTS}
setOptMode -opt_new_inst_prefix                                    ""          ; # prefix
setOptMode -opt_new_net_prefix                                     ""          ; # prefix
setOptMode -opt_one_pass_lec                                       false       ; # {true | false}
setOptMode -opt_podv2_flow_effort                                  auto        ; # {auto | standard | extreme}
setOptMode -opt_pin_swapping                                       true        ; # {true | false}
setOptMode -opt_post_route_allow_overlap                           true        ; # {true | false}
setOptMode -opt_post_route_area_reclaim                            none        ; # {none | setupAware | holdAndSetupAware}
setOptMode -opt_post_route_art_flow                                false       ; # {true | false}
setOptMode -opt_post_route_check_antenna_rules                     true        ; # {true | false}
setOptMode -opt_post_route_drv_recovery                            auto        ; # {false | auto | true}
setOptMode -opt_post_route_fix_clock_drv                           true        ; # {true | false}
setOptMode -opt_post_route_fix_glitch                              true        ; # {true | false}
setOptMode -opt_post_route_fix_si_transitions                      false       ; # {true | false}
setOptMode -opt_post_route_hold_recovery                           false       ; # {false | auto | true}
setOptMode -opt_post_route_setup_recovery                          auto        ; # {false | auto | true}
setOptMode -opt_power_effort                                       none        ; # {none | low | high}
setOptMode -opt_pre_route_ndr_aware                                ""          ; # list
setOptMode -opt_preserve_all_sequential                            false       ; # {true | false}
setOptMode -opt_preserve_hpin_function                             false       ; # {true | false}
setOptMode -opt_remove_redundant_insts                             true        ; # {true | false}
setOptMode -opt_report_multi_bit_unmerged_reasons                  false       ; # {true | false}
setOptMode -opt_resize_flip_flops                                  true        ; # {true | false}
setOptMode -opt_resize_level_shifter_and_iso_insts                 false       ; # {true | false}
setOptMode -opt_resize_power_switch_insts                          false       ; # {true | false}
setOptMode -opt_sequential_genus_restructure_report_failure_reason false       ; # {true | false}
setOptMode -opt_setup_target_slack                                 0ns         ; # setupTargetSlack
setOptMode -opt_skew                                               true        ; # {true       | false}
setOptMode -opt_skew_ccopt                                         standard    ; # {none | standard | extreme}
setOptMode -opt_skew_post_route                                    true        ; # {true|false}
setOptMode -opt_skew_pre_cts                                       true        ; # {true|false}
setOptMode -opt_target_based_opt_file                              ""          ; # filename
setOptMode -opt_target_based_opt_file_only                         true        ; # {true | false}
setOptMode -opt_target_based_opt_hold_file                         ""          ; # hold_file_name
setOptMode -opt_tied_inputs                                        false       ; # {true | false}
setOptMode -opt_time_design_compress_reports                       true        ; # {true | false}
setOptMode -opt_time_design_expanded_view                          false       ; # {true | false}
setOptMode -opt_time_design_num_paths                              50          ; # number
setOptMode -opt_time_design_report_net                             true        ; # {true | false}
setOptMode -opt_time_design_vertical_timing_summary                false       ; # {true|false}
setOptMode -opt_unfix_clock_insts                                  true        ; # {true | false}
setOptMode -opt_verbose                                            false       ; # {true | false}
