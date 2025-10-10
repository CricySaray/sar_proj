##################################################################################
#                              PRE_CTS PLUG-IN 
##################################################################################
#
# This plug-in script is called before clockDesign from the run_cts.tcl flow script.
#
##################################################################################

#setCTSMode -topPreferredLayer 7 \
#           -bottomPreferredLayer 3  \
#           -preferredExtraSpace 2
setOptMode -addInstancePrefix CCOPT_
setOptMode -usefulSkew $vars(usefulSkew_cts)
setOptMode -usefulSkewCTS $vars(usefulSkew_cts)

set_ccopt_property update_io_latency false
set_ccopt_property buffer_cells $vars(cts_buf_cells)
set_ccopt_property inverter_cells $vars(cts_inv_cells)
set_ccopt_property clock_gating_cells $vars(cts_icg_cells)
set_ccopt_property logic_cells $vars(cts_logic_cells)

set_ccopt_property use_inverters $vars(cts_use_invters)
set_ccopt_property cell_density 0.3

set_ccopt_property target_max_trans $vars(cts_tran)
set_ccopt_property target_skew $vars(cts_skew)
#set_ccopt_property max_buffer_depth $vars(max_buffer_depth)
set_ccopt_property max_fanout $vars(cts_fanout)
set_ccopt_property max_source_to_sink_net_length $vars(cts_leangth)

#####icg clone
#set_ccopt_property clone_clock_gates false
set_ccopt_property allow_clustering_with_weak_drivers true
#set_ccopt_property route_type_autotrim false
set_ccopt_property move_clock_gates true
set_ccopt_property move_logic true
set_ccopt_property recluster_to_reduce_power true
set_ccopt_property clone_clock_gates true
set_ccopt_property clone_clock_logic false

specifyCellPad CK* 2
specifyCellPad DCCK* 2
#if {[dbGet head.rules.name ] == ""} {
	add_ndr -name $vars(cts_ndr) -spacing_multiplier {M2:M5 2} -width_multiplier {M2:M5 2}
#}

create_route_type -name cts_rule  -non_default_rule $vars(cts_ndr) -top_preferred_layer $vars(cts_top_pref_layer) -bottom_preferred_layer $vars(cts_btm_pref_layer)
set_ccopt_property route_type -net_type trunk cts_rule
set_ccopt_property route_type -net_type leaf cts_rule

set insertion_delay_pins {
	{0.6 u_core_top/u_sys_crm/u_i_adc_clk_resetsync/src_arst_cdc_reg_1___src_arst_cdc_reg_0_/CP}
	{0.6 u_dbe_top/u_dbb_crm/u_adc_clk_499m_resetsync/src_arst_cdc_reg_1___src_arst_cdc_reg_0_/CP}
	{0.6 u_dbe_top/u_dbb_top/u_s2p_rx/u_rx_s2p_rst_resync/src_arst_cdc_reg_1___src_arst_cdc_reg_0_/CP}
	{0.6 u_dbe_top/u_dbb_top/u_tx_rx_dsr/u_tx_dsr/u_dsr2ahb/seg_currstate_reg_2_/CP}
	{0.6 u_core_top/u_sys_crm/u_async_adc_clk_gate/u0_e_sync_cdc/async_signal_cdc_reg_1_/CP}
	{0.6 u_core_top/u_sys_crm/u_soc_clk_3sel1/u0_clk2_en_sync2_cdc/async_signal_cdc_reg_1_/CP}
	{0.6 u_dbe_top/u_dbb_crm/u_wclk_gate/u0_e_sync_cdc/async_signal_cdc_reg_1_/CP}
	{0.5 u_core_top/u_sys_crm/u_adc_div_param/u_cfg_en_pulse_sync/u0_level_src_sync_cdc/async_signal_cdc_reg_1_/CP}
	{0.4 u_dbe_top/u_dbb_crm/u_wclk_tx_ls/u0_e_sync_cdc/async_signal_cdc_reg_1_/CP}
	{0.4 u_core_top/u_sys_crm/u_gen_sysclk/u_clk_div/clk_en_reg/CP}
	{0.4 u_core_top/u_sys_crm/pmu_sysclk_en_reg/CP}
	{0.5 u_dbe_top/u_dbb_crm/u_h_occ_cal_rx_adc_clk/u_sync_reg_0/CPN}
	{0.5 u_core_top/u_star_sp_cp/u_ll_sync_down_ahbs/u_core_s/hwdata_reg_reg_7___hwdata_reg_reg_6___hwdata_reg_reg_5___hwdata_reg_reg_4___hwdata_reg_reg_3___hwdata_reg_reg_2___hwdata_reg_reg_1___hwdata_reg_reg_0_/CP}
	{0.5 u_core_top/u_sys_crm/u_adc_div_param/u_cfg_en_pulse_sync/level_dest_d3_reg/CP}
	{0.6 u_dbe_top/u_dbb_top/u_top_ctrl_reg/dsr_tx_sel_bank_reg/CP}
	{0.6 u_core_top/u_sys_crm/u_can_adc_clk_en/u0_e_sync_cdc/async_signal_cdc_reg_1_/CP}
	{0.6 u_core_top/u_sys_crm/u_i2s_adc_clk_gate/u0_e_sync_cdc/async_signal_cdc_reg_1_/CP}
	{0.5 u_dbe_top/u_dbb_crm/u_wclk_tmr/u0_e_sync_cdc/async_signal_cdc_reg_1_/CP}
	{0.5 u_aon_top/u_pd_slp_top/u_aon_reg/int_wakeup_cfg_pin_int_polarity_reg/CP}
}
set allPins ""
foreach pin $insertion_delay_pins {
	set target_num [lindex $pin 0]
	set pin_name [lindex $pin 1]
	catch {set_ccopt_property sink_type auto -pin $pin_name}
	catch {set_ccopt_property insertion_delay $target_num -pin $pin_name}
	catch {set_ccopt_property schedule off -pin $pin_name}
	lappend allPins $pin
	}
setOptMode -skewClockPreserveLatencyTermList $allPins

catch {set_ccopt_property sink_type -pin u_core_top/u_sys_crm/u_qspi_adc_clk_gate/u0_cx_clkgate/CKGATE__dont_touch/CP ignore }

foreach_in_collection a [get_pins -of_objects [filter_collection [all_registers ] "full_name=~*_occ_*" ] -filter "direction==in && defined(clocks)"] {
	catch { set_ccopt_property sink_type -pin [get_property $a full_name] ignore }
	}


foreach_in_collection a [get_pins -of_objects [filter_collection [all_registers ] "full_name=~*LOCKUP*" ] -filter "direction==in && defined(clocks)"] {
	catch { set_ccopt_property sink_type -pin [get_property $a full_name] ignore }
	}
foreach_in_collection pin [get_pins -of_objects [all_fanout -from u_core_top/u_sys_crm/u_l_occ_sdioclk/u_bist_clk_mux_inst/Z -endpoints_only -only_cells ] -filter "direction==in && defined(clocks)"] {
	catch { set_ccopt_property sink_type -pin [get_property $pin full_name] ignore }
}


