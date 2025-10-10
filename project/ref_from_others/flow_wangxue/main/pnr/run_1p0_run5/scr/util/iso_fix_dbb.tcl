#######ana2dbb_iso
set_dont_touch [dbGet [dbGet [dbGet top.insts.name *ISO_PDANA2PDDBE* -p].instTerms.cellTerm.name I -p2].net.name] true
set afe_ana2dbb_iso [dbGet top.insts.name *ISO_PDANA2PDDBE* -p]
foreach iso $afe_ana2dbb_iso {
	        set pt [join [dbGet [dbGet [dbGet ${iso}.instTerms.cellTerm.name I -p2].net.instTerms.isOutput 1 -p].pt]]
	        lassign $pt llx lly 
	        set new_llx [expr $llx-22]
	        set pt_new [list $new_llx $lly]
	        dbSet $iso.pt $pt_new
	        dbSet $iso.orient MY
	}

#######ana2core iso
set_dont_touch [dbGet [dbGet [dbGet top.insts.name *ISO_PDANA2PD* -p].instTerms.cellTerm.name I -p2].net.name] true
set afe_ana2core_iso [dbGet top.insts.name *ISO_PDANA2PD* -p]
foreach iso $afe_ana2core_iso {
	        set pt [join [dbGet [dbGet [dbGet ${iso}.instTerms.cellTerm.name I -p2].net.instTerms.isOutput 1 -p].pt]]
	        lassign $pt llx lly 
		set new_lly [expr $lly-22]
		set pt_new [list $llx $new_lly]
	        dbSet $iso.pt $pt_new
	}
#########gpio2core iso
set_dont_touch [dbGet [dbGet [dbGet top.insts.name *GPADC2PDCORE* -p].instTerms.cellTerm.name I -p2].net.name] true
set gpio2core [dbGet top.insts.name *GPADC2PDCORE* -p]
#set gpio2core [dbGet top.insts.name *DFT_ECO_iso* -p]
foreach iso $gpio2core {
	set pt [join [dbGet [dbGet [dbGet ${iso}.instTerms.cellTerm.name I -p2].net.instTerms.isOutput 1 -p].pt]]
	lassign $pt llx lly
	set new_lly [expr $lly+22]
	set pt_new [list $llx $new_lly]
	dbSet $iso.pt $pt_new
}
############M7 buffer
#setEcoMode -reset
#setEcoMode -honorDontTouch false -honorDontUse false -honorFixedStatus false -refinePlace false -updateTiming false -batchMode true -prefixName fix_m7_net 
#set num 1
#set terms {u_afe_core/b_dvdd0p9_aon_porb u_afe_core/b_dvdd1p2_porb u_afe_core/b_dvdd0p9_core_porb u_afe_core/b_dvdd0p9_dbb_porb u_afe_core/b_rc32k_clk_out u_afe_core/b_rc38m_clk_out u_afe_core/b_xo32k_clk_out u_afe_core/clk_bb_dfe u_afe_core/clk_xo_out u_afe_core/o_tx_cnt_ckr_out u_afe_core/i_tx_clk_afe_500M u_afe_core/i_tx_retimer_ena u_afe_core/i_tx_dyn_pwr_ctrl_tx_phmux  u_afe_core/i_tx_dyn_pwr_ctrl_rfpll_pg u_afe_core/i_tx_dyn_pwr_ctrl_rfpll_dco_buff u_afe_core/i_tx_dyn_pwr_ctrl_rfpll_dco u_afe_core/i_tx_clk_afe_polarity u_afe_core/o_tx_cnt_val_out[6] u_afe_core/o_tx_cnt_val_out[5] u_afe_core/o_tx_cnt_val_out[4] u_afe_core/o_tx_cnt_val_out[3] u_afe_core/o_tx_cnt_val_out[2] u_afe_core/o_tx_cnt_val_out[1] u_afe_core/o_tx_cnt_val_out[0] u_afe_core/i_tx_prepulse_sync_am0 u_afe_core/i_tx_prepulse_sync_am1 u_afe_core/i_tx_prepulse_sync_ph0 u_afe_core/i_tx_prepulse_sync_ph1 u_afe_core/i_tx_pulse_sync_am0 u_afe_core/i_tx_pulse_sync_am1 u_afe_core/i_tx_pulse_sync_ph0 u_afe_core/i_tx_pulse_sync_ph1 u_afe_core/rx0_adc_data_i_s0[6] u_afe_core/rx0_adc_data_i_s0[5] u_afe_core/rx0_adc_data_i_s0[4] u_afe_core/rx0_adc_data_i_s0[3] u_afe_core/rx0_adc_data_i_s0[2] u_afe_core/rx0_adc_data_i_s0[1] u_afe_core/rx0_adc_data_i_s0[0] u_afe_core/rx0_adc_data_i_s1[6] u_afe_core/rx0_adc_data_i_s1[5] u_afe_core/rx0_adc_data_i_s1[4] u_afe_core/rx0_adc_data_i_s1[3] u_afe_core/rx0_adc_data_i_s1[2] u_afe_core/rx0_adc_data_i_s1[1] u_afe_core/rx0_adc_data_i_s1[0] u_afe_core/rx0_adc_data_i_s2[6] u_afe_core/rx0_adc_data_i_s2[5] u_afe_core/rx0_adc_data_i_s2[4] u_afe_core/rx0_adc_data_i_s2[3] u_afe_core/rx0_adc_data_i_s2[2] u_afe_core/rx0_adc_data_i_s2[1] u_afe_core/rx0_adc_data_i_s2[0] u_afe_core/rx0_adc_data_i_s3[6] u_afe_core/rx0_adc_data_i_s3[5] u_afe_core/rx0_adc_data_i_s3[4] u_afe_core/rx0_adc_data_i_s3[3] u_afe_core/rx0_adc_data_i_s3[2] u_afe_core/rx0_adc_data_i_s3[1] u_afe_core/rx0_adc_data_i_s3[0] u_afe_core/rx0_adc_data_q_s0[6] u_afe_core/rx0_adc_data_q_s0[5] u_afe_core/rx0_adc_data_q_s0[4] u_afe_core/rx0_adc_data_q_s0[3] u_afe_core/rx0_adc_data_q_s0[2] u_afe_core/rx0_adc_data_q_s0[1] u_afe_core/rx0_adc_data_q_s0[0] u_afe_core/rx0_adc_data_q_s1[6] u_afe_core/rx0_adc_data_q_s1[5] u_afe_core/rx0_adc_data_q_s1[4] u_afe_core/rx0_adc_data_q_s1[3] u_afe_core/rx0_adc_data_q_s1[2] u_afe_core/rx0_adc_data_q_s1[1] u_afe_core/rx0_adc_data_q_s1[0] u_afe_core/rx0_adc_data_q_s2[6] u_afe_core/rx0_adc_data_q_s2[5] u_afe_core/rx0_adc_data_q_s2[4] u_afe_core/rx0_adc_data_q_s2[3] u_afe_core/rx0_adc_data_q_s2[2] u_afe_core/rx0_adc_data_q_s2[1] u_afe_core/rx0_adc_data_q_s2[0] u_afe_core/rx0_adc_data_q_s3[6] u_afe_core/rx0_adc_data_q_s3[5] u_afe_core/rx0_adc_data_q_s3[4] u_afe_core/rx0_adc_data_q_s3[3] u_afe_core/rx0_adc_data_q_s3[2] u_afe_core/rx0_adc_data_q_s3[1] u_afe_core/rx0_adc_data_q_s3[0] u_afe_core/rx1_adc_data_i_s0[6] u_afe_core/rx1_adc_data_i_s0[5] u_afe_core/rx1_adc_data_i_s0[4] u_afe_core/rx1_adc_data_i_s0[3] u_afe_core/rx1_adc_data_i_s0[2] u_afe_core/rx1_adc_data_i_s0[1] u_afe_core/rx1_adc_data_i_s0[0] u_afe_core/rx1_adc_data_i_s1[6] u_afe_core/rx1_adc_data_i_s1[5] u_afe_core/rx1_adc_data_i_s1[4] u_afe_core/rx1_adc_data_i_s1[3] u_afe_core/rx1_adc_data_i_s1[2] u_afe_core/rx1_adc_data_i_s1[1] u_afe_core/rx1_adc_data_i_s1[0] u_afe_core/rx1_adc_data_i_s2[6] u_afe_core/rx1_adc_data_i_s2[5] u_afe_core/rx1_adc_data_i_s2[4] u_afe_core/rx1_adc_data_i_s2[3] u_afe_core/rx1_adc_data_i_s2[2] u_afe_core/rx1_adc_data_i_s2[1] u_afe_core/rx1_adc_data_i_s2[0] u_afe_core/rx1_adc_data_i_s3[6] u_afe_core/rx1_adc_data_i_s3[5] u_afe_core/rx1_adc_data_i_s3[4] u_afe_core/rx1_adc_data_i_s3[3] u_afe_core/rx1_adc_data_i_s3[2] u_afe_core/rx1_adc_data_i_s3[1] u_afe_core/rx1_adc_data_i_s3[0] u_afe_core/rx1_adc_data_q_s0[6] u_afe_core/rx1_adc_data_q_s0[5] u_afe_core/rx1_adc_data_q_s0[4] u_afe_core/rx1_adc_data_q_s0[3] u_afe_core/rx1_adc_data_q_s0[2] u_afe_core/rx1_adc_data_q_s0[1] u_afe_core/rx1_adc_data_q_s0[0] u_afe_core/rx1_adc_data_q_s1[6] u_afe_core/rx1_adc_data_q_s1[5] u_afe_core/rx1_adc_data_q_s1[4] u_afe_core/rx1_adc_data_q_s1[3] u_afe_core/rx1_adc_data_q_s1[2] u_afe_core/rx1_adc_data_q_s1[1] u_afe_core/rx1_adc_data_q_s1[0] u_afe_core/rx1_adc_data_q_s2[6] u_afe_core/rx1_adc_data_q_s2[5] u_afe_core/rx1_adc_data_q_s2[4] u_afe_core/rx1_adc_data_q_s2[3] u_afe_core/rx1_adc_data_q_s2[2] u_afe_core/rx1_adc_data_q_s2[1] u_afe_core/rx1_adc_data_q_s2[0] u_afe_core/rx1_adc_data_q_s3[6] u_afe_core/rx1_adc_data_q_s3[5] u_afe_core/rx1_adc_data_q_s3[4] u_afe_core/rx1_adc_data_q_s3[3] u_afe_core/rx1_adc_data_q_s3[2] u_afe_core/rx1_adc_data_q_s3[1] u_afe_core/rx1_adc_data_q_s3[0] u_afe_core/clk_xo_out}
#
#foreach term $terms {
#        set net [get_object_name [get_nets -of_objects $term]]
#        set input_cell [dbGet [dbGet top.insts.instTerms.net.name $net -p3].cell.name -u]
#        if {![regexp "ISO" $input_cell]} {
#                set pt_x [dbGet [dbGet top.insts.instTerms.name $term -p].pt_x]
#                set pt_y [dbGet [dbGet top.insts.instTerms.name $term -p].pt_y]
#                if {$pt_x > 2000} {
#                        set pt_x_new [expr $pt_x - 22] 
#                        set pt [list [list $pt_x_new $pt_y]]
#                        catch {ecoAddRepeater -term $term -cell CKBD4BWP7T35P140 -loc $pt -hinstGuide u_dbe_top -name buffer_ana2dbb_${num} -bufOrient MY}
#			#incr num
#                } else {
#                        set pt_y_new [expr $pt_y -22]
#                        set pt [list [list $pt_x $pt_y_new]]
#                        if { [lsearch [file2list aon_nets.tcl ] $net] != -1} {
#                         catch {       ecoAddRepeater -term $term -cell  PTBUFFHDD4BWP7T35P140 -loc $pt -hinstGuide u_core_top -name buffer_ana2core_${num} }
#                        } else {
#                         catch {       ecoAddRepeater -term $term -cell CKBD4BWP7T35P140 -loc $pt -hinstGuide u_core_top -name buffer_ana2core_${num} }
#                        }
#                }
#		incr num
#        }
#}
#setEcoMode -reset

refinePlace
foreach iso $afe_ana2dbb_iso {
	dbSet $iso.pStatus fixed
	}
foreach iso $afe_ana2core_iso {
	dbSet $iso.pStatus fixed
	}
foreach iso $gpio2core {
	dbSet $iso.pStatus fixed
	}
#foreach inst [dbGet top.insts.name *buffer_ana2* -p] {
#	dbSet $inst.pStatus fixed
#
