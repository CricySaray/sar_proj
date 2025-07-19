 setDesignMode -process						                    28
 setLimitedAccessFeature flow_effort_xtreme                     1
 setDesignMode -flowEffort					                    extreme
 setDesignMode -powerEffort				                        none
 #-------------------------------------------------------------------------------------------------
 setAnalysisMode -cppr						                    both
 setAnalysisMode -analysisType					                onChipVariation
 #-------------------------------------------------------------------------------------------------
 setDelayCalMode -engine 					                    aae
 setDelayCalMode -SIAware					                    false
 setDelayCalMode -equivalent_waveform_model			            propagation
 setDelayCalMode -allow_preroute_waveform_propagation           true
 setDelayCalMode -advanced_node_pin_cap_settings                true
 setDelayCalMode -advanced_pincap_mode                          true
 #-------------------------------------------------------------------------------------------------
 setPlaceMode -place_global_place_io_pins 			            false
 setPlaceMode -place_global_max_density 			            0.85
 setPlaceMode -place_global_reorder_scan 			            false
 setPlaceMode -place_detail_honor_inst_pad               	    true
 setPlaceMode -place_detail_io_pin_blockage              	    true
 setPlaceMode -place_detail_swap_eeq_cells               	    true
 setPlaceMode -place_detail_use_check_drc                	    true
 setPlaceMode -place_max_pin_density			            	0.4
 setPlaceMode -place_opt_save_db				                true
 setPlaceMode -place_exp_enhanced_mh_flow		            	true
 setPlaceMode -place_global_clock_gate_aware			        true
 setPlaceMode -place_global_clock_power_driven			        true
 #-------------------------------------------------------------------------------------------------
 setOptMode -verbose						                    true
 setOptMode -reclaimArea					                    true
 setOptMode -powerEffort					                    none
 setOptMode -setupTargetSlack					                0.0
 setOptMode -setupTargetSlackForReclaim				            0.05
 setOptMode -holdTargetSlack					                0.0
 setOptMode -maxDensity						                    0.85
 setOptMode -maxLocalDensity				                    0.8
 setOptMode -allEndPoints					                    true
 setOptMode -fixFanoutLoad					                    true
 setOptMode -maxLength						                    400
 setOptMode -timeDesignNumPaths					                9999
 setOptMode -timeDesignCompressReports			                true
 setOptMode -timeDesignExpandedView				                true
 setOptMode -timeDesignReportNet				                true
 setOptMode -leakageToDynamicRatio				                0
 setOptMode -fixHoldAllowOverlap				                false
 setOptMode -fixHoldAllowSetupTnsDegrade			            false
 setOptMode -fixDrc						                        true
 setOptMode -fixClockDrv					                    true
 setOptMode -fixGlitch						                    true
 setOptMode -usefulSkew						                    false
 setOptMode -usefulSkewPreCTS					                false
 setOptMode -usefulSkewCCOpt					                standard
 setOptMode -usefulSkewPostRoute				                false
 setOptMode -usefulSkewPostRouteMaintainHold	        		false
 setOptMode -skewClockBufferCells				                $vars(ccopt_buf_cells)
 setOptMode -skewClockInverterCells				                $vars(ccopt_inv_cells)
 setOptMode -skewClockUseInverters				                auto
 setOptMode -expUltraHighEffOpt					                true
 setOptMode -honorFence						                    true
 setOptMode -detailDrvFailureReason				                true
 setOptMode -detailDrvFailureReasonMaxNumNets			        9999
 setOptMode -expSkipDptLayerForLAOptimization 			        true
# ---------------------------------------------------------------------------------------
 setSIMode -attacker_alignment					                path
 setSIMode -enable_double_clocking_check		            	true
 setSIMode -individual_attacker_clock_threshold	            	0.010 ;# (TPC Default: 0.01)
 setSIMode -individual_attacker_threshold		            	0.011 ;# (TPC Default: 0.011)
 setSIMode -accumulated_small_attacker_mode		            	current
 setSIMode -si_reselection					                    delta_delay
 setSIMode -si_reselection_delay_threshold		            	5e-12
 setSIMode -separate_delta_delay_on_data		            	true
 setSIMode -switch_prob						                    0.3
# ---------------------------------------------------------------------------------------
 setRouteMode -earlyGlobalMaxRouteLayer				            $vars(max_route_layer)
 setRouteMode -earlyGlobalMinRouteLayer				            $vars(min_route_layer)
 setRouteMode -earlyGlobalEffortLevel				            standard		;# standard/medium/low
 setRouteMode -earlyGlobalNumTracksPerClockWire			        3
 setRouteMode -earlyGlobalRouteSecondPG				            true
 setRouteMode -earlyGlobalRouteStripeLayerRange			        [dbGet [dbGet head.layers.name ME$vars(min_route_layer) -p].num]:[expr [dbGet [dbGet head.layers.name ME$vars(max_route_layer) -p].num]-1]
 setRouteMode -earlyGlobalSecondPGMaxFanout			            5

# ---------------------------------------------------------------------------------------
 setNanoRouteMode -routeBottomRoutingLayer			            [dbGet [dbGet head.layers.name ME$vars(min_route_layer) -p].num]
 setNanoRouteMode -routeTopRoutingLayer				            [dbGet [dbGet head.layers.name ME$vars(max_route_layer) -p].num]
 setNanoRouteMode -routeConcurrentMinimizeViaCountEffort	    high
 setNanoRouteMode -drouteUseMultiCutViaEffort 			        high
 setNanoRouteMode -routeSiEffort				                high
 setNanoRouteMode -routeWithSiDriven				            true
 setNanoRouteMode -routeWithTimingDriven			            true
 setNanoRouteMode -drouteEndIteration				            default
 setNanoRouteMode -droutePostRouteSwapVia			            none
 setNanoRouteMode -droutePostRouteSpreadWire		            true
 setNanoRouteMode -routeWithViaInPin				            {1:1}
 setNanoRouteMode -routeWithViaOnlyForMacroCellPin	            false
 setNanoRouteMode -routeWithViaOnlyForStandardCellPin		    {1:1}
 setNanoRouteMode -routeDesignRouteClockNetsFirst		        true
 setNanoRouteMode -drouteCheckMarOnCellPin		            	true
 setNanoRouteMode -drouteMinimizeLithoEffectOnLayer		        {f t t}
 setNanoRouteMode -dbViaWeight 					                {*_P* -1  } ; # turn off DFM via usage during routing.
 setNanoRouteMode -routeStrictlyHonorNonDefaultRule		        true
# need confrim ---------------------------------------------------------------------------------------
 setNanoRouteMode -drouteUseLefPinTaperRule			            true; #default is true
 setNanoRouteMode -drouteAutoStop				                false
 setNanoRouteMode -drouteNoTaperOnOutputPin			            true
 setNanoRouteMode -drouteVerboseViolationSummary	            1
 setNanoRouteMode -dbIgnoreFollowPinShape			            false
 setNanoRouteMode -routeReserveSpaceForMultiCut			        false   ;# add, default is true
 setNanoRouteMode -grouteExpMinimizeS2sEffort			        high
 setNanoRouteMode -grouteExpTimingDrivenEffort			        medium   ;# add, default is auto
 setNanoRouteMode -drouteExpConcurrentMinimizeViaCountCost	    64
 setNanoRouteMode -drouteExpOptimizeTrimPatch 			        true
 setNanoRouteMode -drouteExpAdvancedMarFix    			        true         ;# add, default is true, private
 setNanoRouteMode -drouteExpDynamicPinAccess  			        true
 setNanoRouteMode -drouteExpAdvancedSearchFix 			        true
 setNanoRouteMode -routeExpAdaptivePinAccess  			        true
 setNanoRouteMode -routeExpAdvancedPinAccess  			        true
 setNanoRouteMode -routeExpAdvancedTechnology 			        true ;  # mainly for metal patching; it may be default later

 setStreamOutMode -virtualConnection				            false	;# resolve VDD: & VSS: in GDS
 setStreamOutMode -SEvianames 					                true


 setUsefulSkewMode -maxAllowedDelay			                	0.2
 setUsefulSkewMode -noBoundary				                	true
 setUsefulSkewMode -maxSkew					                    true

switch -regexp $vars(step) {
 "route*|postroute" {
 setDelayCalMode -engine                                        aae
 setDelayCalMode -SIAware                                       true
 setDelayCalMode -equivalent_waveform_model                     propagation
 setExtractRCMode -engine postRoute -effortLevel medium
 }

}
