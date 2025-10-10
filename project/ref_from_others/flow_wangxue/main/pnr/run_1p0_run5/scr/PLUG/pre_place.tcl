####################################################################################
#                          PRE-PLACE PLUG-IN
####################################################################################
#
# This plug-in script is called before placeDesign from the run_place.tcl flow
# script.
#
####################################################################################
# Example tasks include:
#          - Power planning related tasks which includes
#            - Power planning for power domains (ring/strap creations)
#            - Power Shut-off cell power hookup
############################################################################################
setOptMode -addInstancePrefix PlaceOpt_
setOptMode -addNetPrefix PlaceOptNet_

setDelayCalMode -engine aae
setAnalysisMode -analysisType onChipVariation -cppr both
setOptMode -fixDrc true -fixFanoutLoad true
set_global timing_enable_uncertainty_for_pulsewidth_checks true
set_global timing_enable_derating_for_pulsewidth_checks true
setPlaceMode -place_global_module_padding uClockTreeGmac 2

#setOptMode -maxLocalDensity 0.85
#setPlaceMode -place_global_max_density 0.6


#setPlaceMode -maxDensity 0.85 
setPlaceMode -place_detail_legalization_inst_gap 2 
setPlaceMode -place_global_clock_gate_aware true


setPlaceMode -place_detail_preroute_as_obs {1 2}
setPlaceMode -place_detail_use_check_drc true

setPlaceMode -place_global_module_padding u_core_top/u_peripheral_wrapper0 {1.2 1.2 1.2 1.2}
setPlaceMode -place_global_module_padding u_core_top/u_peripheral_wrapper1 {1.2 1.2 1.2 1.2}
setPlaceMode -place_global_module_padding u_dbe_top/u_dbb_top/u_s2p_rx {1.2 1.2 1.2 1.2}
setPlaceMode -place_global_module_padding u_core_top/u_ahb_peri_wrapper2/u_fft256/U_FFT256 {1.2 1.2 1.2 1.2}
setPlaceMode -place_global_module_padding u_core_top/u_qspi_wrapper/u_cdnsqspi_flash_ctrl/i_cdnsqspi_flash_ctrl_blk {1.2 1.2 1.2 1.2}

#source ./lp/create_region.tcl -e -v

#source ./lp/RLK.tcl -e
#
#deleteRouteBlk -name AFE_BLK
#set AFE_box  [dbGet [dbGet top.insts.name u_core_top/u_UWB4Z_SOC_AFE_DBE_TOP/u_afe/u_afe_core -p].boxes]
#foreach i [join $AFE_box] {
#        createRouteBlk -name AFE_BLK -layer all -cutLayer all -box  [dbShape $i SIZE 0] -spacing 0
#        }

