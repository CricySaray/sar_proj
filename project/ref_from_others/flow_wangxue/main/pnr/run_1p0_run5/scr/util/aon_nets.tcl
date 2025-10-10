##########retention memory
set core_retention_memorys {u_core_top/u_sram_ctrl_wrapper/u_soc_sram0/u_sram_ctrl_ecc/sram_instance_0__u_mem/u_mem u_core_top/u_sram_share_wrapper/u_ram1_32KB_cp_itcm_dedicated/u_mem u_core_top/u_sram_share_wrapper/u_ram6_32KB/u_mem u_core_top/u_sram_share_wrapper/u_ram0_32KB_cp_itcm_dedicated/u_mem u_core_top/u_sram_share_wrapper/u_ram2_32KB_ap_itcm_dedicated/u_mem u_core_top/u_sram_share_wrapper/u_ram3_32KB/u_mem u_core_top/u_sram_share_wrapper/u_ram4_32KB/u_mem u_core_top/u_sram_share_wrapper/u_ram5_32KB/u_mem u_core_top/u_sram_share_wrapper/u_ram8_16KB/u_mem u_core_top/u_sram_share_wrapper/u_ram10_16KB/u_mem u_core_top/u_sram_share_wrapper/u_ram9_16KB/u_mem u_core_top/u_sram_share_wrapper/u_ram7_16KB/u_mem}
set dbb_retention_memorys {u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_5__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_7__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_6__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_0__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_4__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_2__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_1__u_2048x32_wrapper/u_mem u_dbe_top/u_dbb_top/u_data_capture_top/u_data_capture_ctrl/mem_num_3__u_2048x32_wrapper/u_mem}
foreach memory $dbb_retention_memorys {
	set term [dbGet [dbGet [dbGet top.insts.name $memory -p].instTerms.cellTerm.name RET1N -p2].name]
	echo [get_object_name [get_nets -of_objects $term]] >> aon_nets.tcl
	}
foreach memory $core_retention_memorys {
	set term [dbGet [dbGet [dbGet top.insts.name $memory -p].instTerms.cellTerm.name RET1N -p2].name]
	echo [get_object_name [get_nets -of_objects $term]] >> aon_nets.tcl
	}
################afe pins
set aon_pin_list [list \
    u_afe_core/b_dvdd0p9_aon_porb      \
    u_afe_core/b_rc32k_clk_out        \
    u_afe_core/b_xo32k_clk_out        \
    u_afe_core/b_dvdd1p2_porb     \
    u_afe_core/b_wakeup_ds_wk      \
    u_afe_core/b_spi_cs_wk      \
    u_afe_core/b_rstn_wk      \
    u_afe_core/b_over_temp_warning    \
    u_afe_core/b_over_voltage_warning \
    u_afe_core/i_buck_en           \
    u_afe_core/i_buck_vsel         \
    u_afe_core/i_ldo_efuse_en      \
    u_afe_core/i_ldo_efuse_vsel    \
    u_afe_core/i_rc32k_pd          \
    u_afe_core/i_rc32k_coarse_trim \
    u_afe_core/i_rc32k_fine_trim   \
    u_afe_core/i_aon_ldo_vsel      \
    u_afe_core/i_bgp_aon_trim      \
    u_afe_core/i_aon_hd            \
    u_afe_core/i_wakeup_ds_wk_en   \
    u_afe_core/i_spi_cs_wk_en      \
    u_afe_core/i_rstn_wk_en        \
    u_afe_core/i_current_lmt_s     \
    u_afe_core/i_current_lmt_en    \
    u_afe_core/i_rc32k_s           \
    ]

#    u_afe_core/i_ldo_core_load_en  
set slp_pin_list [list \
    u_afe_core/i_s_iopsw_en        \
    u_afe_core/i_s_efuse_en        \
    u_afe_core/i_bgp_en            \
    u_afe_core/i_bgp_trim          \
    u_afe_core/i_aon_otp_pd        \
    u_afe_core/i_aon_ovp_pd        \
    u_afe_core/i_aon_otp_temp_ctrl \
    u_afe_core/i_rc38m_freq_tune   \
    u_afe_core/i_rc38m_freq_tune_fine \
    u_afe_core/i_rc38m_en          \
    u_afe_core/i_ldo_38m_rc_en     \
    u_afe_core/i_ldo_38m_rc_ft_en  \
    u_afe_core/i_ldo_38m_xo_en     \
    u_afe_core/i_ldo_38m_xo_ft_en  \
    u_afe_core/i_ldo_38m_xo_vsel   \
    u_afe_core/i_ldo_38m_rc_vsel   \
    u_afe_core/i_ldo_core_en       \
    u_afe_core/i_ldo_core_vsel     \
    u_afe_core/i_ldo_dbb_en        \
    u_afe_core/i_ldo_dbb_vsel      \
    u_afe_core/i_xo32k_en          \
    u_afe_core/i_xo_32k_io_poc     \
    u_afe_core/i_xo32k_driving_sel \
    u_afe_core/dig_aon_reserved1   \
    u_afe_core/dig_aon_reserved2   \
    u_afe_core/dig_aon_reserved3   \
    u_afe_core/dig_aon_reserved4   \
    u_afe_core/i_ldo_ram_en        \
    u_afe_core/i_ldo_ram_vsel      \
    u_afe_core/xo_ena_fsm            \
    u_afe_core/xo_ena_inj            \
    u_afe_core/xo_ena_test           \
    u_afe_core/xo_ena                \
    u_afe_core/xo_ena_amp            \
    u_afe_core/xo_ena_cmp            \
    u_afe_core/xo_ena_div            \
    u_afe_core/xo_ena_ed             \
    u_afe_core/xo_ena_ibias          \
    u_afe_core/xo_ena_ibias_1u       \
    u_afe_core/xo_ena_ibias_10u      \
    u_afe_core/xo_set_ctune_e        \
    u_afe_core/xo_set_c_ref          \
    u_afe_core/xo_set_ib_tune        \
    u_afe_core/xo_set_pbuff_bit      \
    u_afe_core/xo_set_sel_ctune      \
    u_afe_core/xo_set_sel_div        \
    u_afe_core/xo_set_sel_en_inj     \
    u_afe_core/xo_set_sel_stop       \
    u_afe_core/xo_set_ed_ct          \
    u_afe_core/xo_set_ext_clk        \
    u_afe_core/xo_set_vref_cw        \
    u_afe_core/xo_set_nrst_dal       \
    u_afe_core/xo_set_nset_dal       \
    u_afe_core/xo_set_ibias          \
    ]
foreach pin $aon_pin_list {
	set nets [get_object_name [get_nets -of_objects $pin]]
	foreach net $nets {
		echo $net >> aon_nets.tcl
	}
}
foreach pin $slp_pin_list {
	set nets [get_object_name [get_nets -of_objects $pin]]
	foreach net $nets {
		echo $net >> aon_nets.tcl
	}
}

