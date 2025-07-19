## setPlaceMode 
## setOptMode 
## setDelayCalMode 
#setDesignMode  -flowEffort extreme
#setLimitedAccessFeature flow_effort_xtreme 1
setPlaceMode -place_detail_swap_eeq_cells true ;##for eeq cell
setPlaceMode -expAdvPinAccess true
setPlaceMode -expCDPUseEaglMode 1
setOptMode  -fixFanoutLoad true \
            -reclaimArea true \
            -allEndPoints true \
            -congEffForRouteTypeOpt high \
            -expLayerAwareTNSOptEffortLevel 2 \
            -expReclaimEffort high \
            -fixHoldAllowSetupTnsDegrade false \
            -fixSIAttacker true
setOptMode  -powerEffort none
setOptMode  -maxLocalDensity  0.80
setOptMode  -postRouteAreaReclaim setupAware  \
            -usefulSkewCTS true \
            -fixSISlew true
setOptMode -expNewAutoLayerEffortLevel true
setOptMode -expRTReclaimOptLA true
setOptMode -expExtremeHighEffOpt true
setOptMode -expUltraHighEffOpt true
setOptMode -expSkipDptLayerForLAOptimization true
setOptMode -skewClockExtremeEffort true
setOptMode -timeDesignNumPaths 9999

if {[dbGet head.rules.name non_default_rule_data] == "0x0"} {
    add_ndr -name non_default_rule_data -width {ME3 0.10 ME4 0.10 ME5 0.05 ME6 0.05 ME7 0.8 ME8 4.0} -spacing {ME3 0.1 ME4 0.1 ME5 0.05 ME6 0.05 ME7 0.8 ME8 4.0}
}

setOptMode -ndrAwareOpt non_default_rule_data
setPlaceMode -place_global_timing_effort high

setDelayCalMode -equivalent_waveform_model propagation
setDelayCalMode -SIAware true
setDelayCalMode -engine aae
setDelayCalMode -advanced_node_pin_cap_settings true
setDelayCalMode -advanced_pincap_mode true

#set_ccopt_property ccopt_auto_limit_insertion_delay_factor 1.5
#set_ccopt_mode -ccopt_auto_limit_insertion_delay_factor 1.5
#set_ccopt_property auto_limit_insertion_delay_max_increment auto
#setUsefulSkewMode -reset -maxAllowedDelay 
if {[string match cts  $vars(step)] } {
    set_ccopt_property inst_name_prefix                                     CCOPT_INST_
    set_ccopt_property net_name_prefix                                      CCOPT_NET_
    set_ccopt_property enable_locked_node_check_failure                     false
    set_ccopt_property cts_def_lock_clock_sinks_after_routing               true
    set_ccopt_property adjacent_rows_legal                                  false
    set_ccopt_property cell_density                                         0.5
    set_ccopt_property ccopt_merge_clock_gates                              true
	set_ccopt_property merge_clock_gates 									true
    set_ccopt_property call_cong_repair_during_final_implementation         true
    set_ccopt_property route_type_override_preferred_routing_layer_effort   none
	set_ccopt_property routing_top_min_fanout 								2000
	set_ccopt_property target_skew 											0.085
    set_ccopt_property allow_resize_of_dont_touch_cells                     true
    set_ccopt_property clustering_mix_inverters_and_buffers                 false
    #set_ccopt_property max_fanout                                           16 ;#

    unset_ccopt_property cluster_when_starting_skewing
    unset_ccopt_property cts_manage_local_overskew
    unset_ccopt_property approximate_balance_buffer_output_of_leaf_drivers_that_meet_skew_target

    set_ccopt_property auto_limit_insertion_delay_factor 1.1
    set_ccopt_property -ccopt_auto_limit_insertion_delay_factor 1.1
    set_ccopt_mode -ccopt_auto_limit_insertion_delay_factor 1.1
    set_ccopt_property auto_limit_insertion_delay_max_increment 0.1

} elseif {[string match route  $vars(step)] } {
    setDelayCalMode  -equivalent_waveform_model_type ecsm
    setNanoRouteMode -drouteUseMultiCutViaEffort high
    setNanoRouteMode -drouteExpMinimizeClockTopologyChange true 
    setExtractRCMode -engine postRoute -effortLevel medium
} elseif {[string match postroute  $vars(step)] } {
        setOptMode -powerEffort low
        setDelayCalMode -equivalent_waveform_model_type ecsm
        setNanoRouteMode -drouteUseMultiCutViaEffort high
        setNanoRouteMode -drouteExpMinimizeClockTopologyChange true
        setExtractRCMode -engine postRoute -effortLevel high
} else {
    #set_ccopt_property ccopt_auto_limit_insertion_delay_factor 1.05
    #set_ccopt_mode -ccopt_auto_limit_insertion_delay_factor 1.05
    #set_ccopt_property auto_limit_insertion_delay_max_increment auto
    #setUsefulSkewMode -reset -maxAllowedDelay 

}
# usefulSkew
if {$vars(userfulSkew_mode) == true} {
    setOptMode -usefulSkew true
    setOptMode -usefulSkewCCOPt extreme
    setOptMode -usefulSkewPostRouteMaintainHold true
    setOptMode -usefulSkewCTS true

    set_ccopt_property ccopt_auto_limit_insertion_delay_factor 1.1
    set_ccopt_mode -ccopt_auto_limit_insertion_delay_factor 1.1
    set_ccopt_property auto_limit_insertion_delay_max_increment auto
    setUsefulSkewMode -reset -maxAllowedDelay 
    set_ccopt_property useful_skew_max_delta 0.1
    setUsefulSkewMode -maxAllowedDelay 0.1
}
setNanoRouteMode  -reset -routeStrictlyHonorNonDefaultRule

setUsefulSkewMode -noBoundary false
