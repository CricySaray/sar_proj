set scripts_dir                                            "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/sta_check"
set proj_name                                              "ict8810"

#--------------------------------------------------------------------------------------------------------------------------------------------------------------
set sta_vars(sta_hier_file)                                "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/sta_check/8810_hier.rpt"
set sta_vars(dont_use_cell)                                "INV*SGCAP* BUF*SGCAP* FRICG* DFF*QL_* DFF*QNL_* SDFF*QL_* SDFF*QNL_* SDFFQH* SDFFQNH* SDFFRPQH* SDFFRPQNH* SDFFSQH* SDFFSQNH* SDFFSRPQH* SDFFY* *DRFF* HEAD* FOOT* *X0* *DLY* SDFFX* XOR3* XNOR3* *ECO* *ZTL* *ZTEH* *ZTUH* *ZTUL* *ISO* *LVL* *G33* ANTENNA* *AND*_X11* *AND*_X8* *AO21A1AI2_X8* *AOI21B_X8* *AOI21_X11* *AOI21_X8* *AOI22BB_X8* *AOI22_X11* *AOI22_X8* *AOI2XB1_X8* *AOI31_X8* *ENDCAP FILL* GP* MXGL* OA*_X8* OR*_X11* NOR*_X11* OR*_X8* NOR*_X8* *_X20* *QN* ICT_CDMSTD"
set sta_vars(check_clock_filter_clock_cell)                "ref_name =~ *PP140Z* && ref_name !~ PLLUM28HPCP* && ref_name !~ inno_ddr_* && ref_name !~ FXEDP447EWHJ* && ref_name !~ SFLVTPA28_256* && ref_name !~ O12P5PHYU28HPCP* && ref_name !~ GSM3PHYU28* && ref_name !~ U2OPHYU28* && is_hierarchical == false"
set sta_vars(re_ulvt)                                      "ref_name !~ .*P140ZTL_.*"
set sta_vars(check_clock_filter_ip)                        "(ref_name !~ PLLUM28HPCP*) && (ref_name !~ inno_ddr_*) && (ref_name !~ FXEDP447EWHJ*) && (ref_name !~ SFLVTPA28_256*) && (ref_name !~ O12P5PHYU28HPCP*) && (ref_name !~ GSM3PHYU28*) && (ref_name !~ U2OPHYU28*)"
set sta_vars(check_clock_filter_non_symmetricdcap)         "(ref_name !~ *_X*B_*) && (ref_name =~ PREICGN* || ref_name =~ FRICG* || ref_name =~ POSTICG* || ref_name =~ MXIT2_* || ref_name =~ MX2_* || ref_name =~ *ECO*)"
set sta_vars(check_clock_weak_cells)                       "ref_name =~ *_X0B* || ref_name =~ *_X1B**|| ref_name =~ *BUF*_X2B_* || ref_name =~ *INV*_X2B_* || ref_name =~ *BUF*_X3B** || ref_name =~ *INV*_X3B_* || ref_name =~ PREICG*_X3P* || ref_name =~ PREICG*_X3B* || ref_name =~ PREICG*_X2P* || ref_name =~ PREICG*_X2B* || ref_name =~ PREICG*_X1P* || ref_name =~ PREICG*_X1B* || ref_name =~ DLY*"
set sta_vars(check_clock_for_mux)                          $sta_vars(check_clock_filter_clock_cell)
set sta_vars(check_clock_mux_type)                         "ref_name !~ MXGL2.* && ref_name !~ MXT2.* && ref_name =~ .*MX.*"
set sta_vars(delay_cell_type)                              "DLY*"
if {[get_object_name [get_design]] == "lb_ddr4_top"} {
set sta_vars(fix_delay_chain_cell)                         "BUF_X1P7B_A9PP140ZTH_C40"
} else {
set sta_vars(fix_delay_chain_cell)                         "BUF_X1P7B_A7PP140ZTH_C40"
}
set sta_vars(stdcell)                                       "*PP140Z*"
set sta_vars(buffer_cell)                                   "BUF*PP140Z*"
set sta_vars(inverter_cell)                                 "INV*PP140Z*"
set sta_vars(vt_groups)                                     "HVT *ZTH_* SVT *ZTS_* LVT *ZTL_* uLVT *TUL_*"
#set sta_vars(dont_touch_and_size_only_files)                ""

#--------------------------------------------------------------------------------------------------------------------------------------------------------------
# STA Check Item
set sta_vars(check_clock_cell_type)                         1
set sta_vars(check_clock_cell_type_mux)                     1
set sta_vars(check_timing_crossing_clock)                   1
set sta_vars(check_dont_use_cell)                           1
set sta_vars(check_module_name_length)                      1
set sta_vars(check_delay_cell_chain)                        1
set sta_vars(check_sdc_quality)                             1
set sta_vars(check_netlist)                                 1
set sta_vars(report_analysis_coverage)                      1
set sta_vars(generate_timing_summary_internal)              1
set sta_vars(generate_timing_internal)                      1
set sta_vars(generate_propagated_mode_timing_lib)           0
set sta_vars(get_timing_path_noise_delay_in_clk)            1
set sta_vars(get_timing_path_noise_delay_in_data)           1
set sta_vars(report_cell_status)                            1
set sta_vars(check_all_constraints)                         1
set sta_vars(report_clock_status)                           1
set sta_vars(generate_timing_budget_blk_file)               1
set sta_vars(check_netlist_waive_list)                      0
set sta_vars(check_waive_list_of_drv)                       1
#--------------------------------------------------------------------------------------------------------------------------------------------------------------
set TOP                        $DESIGN_NAME
set RPT_DIR                    $REPORTS_DIR
set CHECK_TYPE                 $check
set PBA_MODE                   $pba_mode ;# path / exhaustive
set DATA_DIR                   $DATA_DIR
set LOG_DIR                    $LOG_DIR
set MODE                       $mode
set SDC_LIST                   $dmsa_mode_constraint_files($mode)
set SESSION                    ${mode}_${corner}_${check}
set timing_continue_on_scaling_error  true
source ${scripts_dir}/design_ptsi.tcl


#---------------------------------------------------------------------------------------------------
# Check noise
#---------------------------------------------------------------------------------------------------
set_noise_parameters -enable_propagation -analysis_mode report_at_endpoint
check_noise > ${RPT_DIR}/check_noise.rpt
update_noise
report_noise -nosplit -all_violators -above -low  > ${RPT_DIR}/report_noise_all_vio_abv_low.rpt
report_noise -nosplit -all_violators -above -high > ${RPT_DIR}/report_noise_all_vio_abv_high.rpt
report_noise -all_violators -verbose > ${RPT_DIR}/report_noise.rpt

report_si_double_switching -nosplit -rise -fall > ${RPT_DIR}/report_si_double_switching.rpt
#---------------------------------------------------------------------------------------------------
# Check no assign in netlist , check no back-slash is allowen on netlist instance or port names
#---------------------------------------------------------------------------------------------------
echo "Summary:: please check netlist use below perl."
echo "Summary:: perl /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/release/sta_check/check_netlist.pl block.v"

#---------------------------------------------------------------------------------------------------
# Check hier file of Sub block
#---------------------------------------------------------------------------------------------------
#if {[file exist $RPT_DIR/report_clock_timing.latency.rpt]} {
#    sh gzip $RPT_DIR/report_clock_timing.latency.rpt
#}
if {0} {
if {$sta_vars(sta_hier_file) != ""} {
    design::check_hier_file_of_sub_block -hier_file $sta_vars(sta_hier_file) -file $RRT_DIR/${TOP}.check_hier_file_of_sub_block.rpt
}
}
#---------------------------------------------------------------------------------------------------
# Check DRV
#---------------------------------------------------------------------------------------------------
# drv summary
if {![file exist ${RPT_DIR}/${TOP}.drv.rpt]} {
    report_constraint -nosplit -significant_digits 3 -all_violators -max_transition -max_fanout -max_capacitance -min_period > ${RPT_DIR}/${TOP}.drv.rpt
}
if {$sta_vars(check_waive_list_of_drv) == 1}  {
    if {[file exist ${scripts_dir}/${TOP}.waive.drv.list]} {
        design::check_drv         -report ${RPT_DIR}/${TOP}.drv.rpt  -waive ${scripts_dir}/${TOP}.waive.drv.list
    } else {
        design::check_drv         -report ${RPT_DIR}/${TOP}.drv.rpt
    }
}
# min_period and min_pulse_width
report_min_pulse_width -crosstalk_delta -all_violators -significant_digits 3 -nosplit -path_type full_clock_expanded -input_pins > ${RPT_DIR}/${TOP}.min_pulse_full_clk.rpt
report_min_period      -crosstalk_delta -all_violators -significant_digits 3 -nosplit -path_type full_clock_expanded -input_pins > ${RPT_DIR}/${TOP}.min_period_full_clk.rpt

report_constraint -nosplit -significant_digits 3 -all_violators -verbose -min_period           > ${RPT_DIR}/${TOP}.min_period.rpt
report_constraint -nosplit -significant_digits 3 -all_violators -verbose -min_pulse_width      > ${RPT_DIR}/${TOP}.min_pulse.rpt

report_constraint -all_violators -nosplit -min_period       > ${RPT_DIR}/${TOP}.min_period.rpt.sum
report_constraint -all_violators -nosplit -min_pulse_width  > ${RPT_DIR}/${TOP}.min_pulse_width.rpt.sum
design::check_min_period_summary                              ${RPT_DIR}/${TOP}.min_period.rpt.sum
design::check_min_pulse_width_summary                         ${RPT_DIR}/${TOP}.min_pulse_width.rpt.sum
#---------------------------------------------------------------------------------------------------
# Check Clock cell type
#---------------------------------------------------------------------------------------------------
if {$sta_vars(check_clock_cell_type) == 1} {
    design::check_clock_cell_type -file ${RPT_DIR}/${TOP}.check_clock_cell_type.rpt
}
if {$sta_vars(check_clock_cell_type_mux) == 1} {
    design::check_clock_mux_type -file ${RPT_DIR}/${TOP}.check_clock_mux_cell_type.rpt
}

#---------------------------------------------------------------------------------------------------
# Check crosstalk delay
#---------------------------------------------------------------------------------------------------
design::check_crosstalk -file ${RPT_DIR}/${TOP}.check_crosstalk.rpt 

#---------------------------------------------------------------------------------------------------
# Check clock crossing
#---------------------------------------------------------------------------------------------------
if {$sta_vars(check_timing_crossing_clock) == 1} {
    check_timing -include {clock_crossing} -exclude {no_clock no_input_delay partial_input_delay generic no_driving_cell unconstrained_endpoints unexpandable_clocks latch_fanout loops generated_clocks pulse_clock_non_pulse_clock_merge pll_configuration} -verbose > ${RPT_DIR}/check_timing_cross_clock.rpt
    design::check_timing_cross_clock -save_dir $RPT_DIR
}
#---------------------------------------------------------------------------------------------------
# Check design dont use cell
#---------------------------------------------------------------------------------------------------
if {$sta_vars(check_dont_use_cell) == 1} {
    design::check_dont_use_cell -file ${RPT_DIR}/${TOP}.check_dont_use_cell.rpt
}
#---------------------------------------------------------------------------------------------------
# Check module ref name and full_name length
#---------------------------------------------------------------------------------------------------
if {$sta_vars(check_module_name_length) == 1} {
    design::check_module_name_length   -file ${RPT_DIR}/${TOP}.check_module_name_length.rpt -ref_name_vio_value 256 -full_name_vio_value 512
}
#---------------------------------------------------------------------------------------------------
# Check delay chain
#---------------------------------------------------------------------------------------------------
if {$sta_vars(check_delay_cell_chain) == 1} {
    design::check_delay_cell_chain -file ${RPT_DIR}/${TOP}.check_delay_cell_chain.rpt -fixed_buffer $sta_vars(fix_delay_chain_cell)
}
#---------------------------------------------------------------------------------------------------
# Check SDC and netlist 
#---------------------------------------------------------------------------------------------------
if {$sta_vars(check_sdc_quality) == 1} {
    design::check_sdc_quality -sdc $SDC_LIST  -file ${RPT_DIR}/${TOP}.check_sdc_quality.rpt
}

if {$sta_vars(check_netlist) == 1 } {
        design::check_netlist -file ${RPT_DIR}/${TOP}.check_netlist.rpt
#    if {$sta_vars(check_netlist_waive_list) == 0} {
#        design::check_netlist -file ${RPT_DIR}/${TOP}.check_netlist.rpt
#    } else {
#        design::check_netlist -file ${RPT_DIR}/${TOP}.check_netlist.rpt  -waive $sta_vars(check_netlist_waive_list)
    
#    }
}
#---------------------------------------------------------------------------------------------------
# Check cell vt ratio
#---------------------------------------------------------------------------------------------------
if {[info exists sta_vars(check_vt_ratio)] && $sta_vars(check_vt_ratio) == 1} {
    design::check_vt_ratio -file ${RPT_DIR}/${TOP}.check_vt_ratio.rpt
}
#---------------------------------------------------------------------------------------------------
# report_analysis_coverage
#---------------------------------------------------------------------------------------------------
if {$sta_vars(report_analysis_coverage) == 1} {
    redirect -tee -file ${RPT_DIR}/${TOP}.report_analysis_coverage.rpt {report_analysis_coverage}
}

#---------------------------------------------------------------------------------------------------
# report timing only internal path summary
#---------------------------------------------------------------------------------------------------
if {$sta_vars(generate_timing_summary_internal) == 1} {
    if {$CHECK_TYPE != "setuphold"} {
    set commands "report_timing -slack_lesser_than 0 -significant_digits 3 -nosplit"
    if {[info exists PBA_MODE]} {append commands " -pba_mode $PBA_MODE"}
    if {[info exists CHECK_TYPE]} {
        if {[regexp {hold} $CHECK_TYPE]} {append commands " -delay_type min"} else {append commands " -delay_type max"}
    }

    set summary_commands "$commands -path_type summary -max_paths 9999999 -exclude {get_ports *}"
    eval $summary_commands > ${RPT_DIR}/${TOP}.timing.summary.internal.rpt
    if {[file exist ${RPT_DIR}/${TOP}.timing.summary.internal.rpt.gz]} {
        sh delete ${RPT_DIR}/${TOP}.timing.summary.internal.rpt.gz
    }
    sh gzip ${RPT_DIR}/${TOP}.timing.summary.internal.rpt

    }
}
#---------------------------------------------------------------------------------------------------
# report timing only internal path
#---------------------------------------------------------------------------------------------------
if {$sta_vars(generate_timing_internal) == 1} {
    if {$CHECK_TYPE != "setuphold"} {
    set commands "report_timing -slack_lesser_than 0 -significant_digits 3 -nosplit"
    if {[info exists PBA_MODE]} {append commands " -pba_mode $PBA_MODE"}
    if {[info exists CHECK_TYPE]} {
        if {[regexp {hold} $CHECK_TYPE]} {append commands " -delay_type min"} else {append commands " -delay_type max"}
    }
    set details_commands "$commands -derate -nets -input_pins -crosstalk_delta"
    if {[info exists TRANSITION_TIME]} {append details_commands " -transition"}
    if {[info exists INCLUDE_HIERARCHICAL_PINS]} {append details_commands " -include_hierarchical_pins"}
    if {[info exists MAX_PATH_NUM]} {append details_commands " -max_paths 9999999"} else {append details_commands " -max_paths 9999999"}
#    if {[info exists OCV_MODE] && $OCV_MODE == "pocv" && [info exists VARIATION]} {append details_commands " -variation"}  
    set summary_commands "$details_commands -exclude {get_ports *}"

    eval $summary_commands > ${RPT_DIR}/${TOP}.timing.internal.rpt
    if {[file exist ${RPT_DIR}/${TOP}.timing.internal.rpt.gz]} {
        sh delete ${RPT_DIR}/${TOP}.timing.internal.rpt.gz
    }
    sh gzip ${RPT_DIR}/${TOP}.timing.internal.rpt
    }
}   

#---------------------------------------------------------------------------------------------------
# generate the etm model
#---------------------------------------------------------------------------------------------------
if {$sta_vars(generate_propagated_mode_timing_lib) == 1} {
    extract_mode -output ${DATA_DIR}/${TOP}.${SESSION} -format {db lib} -library_cell
}
#---------------------------------------------------------------------------------------------------
# check clock and data path noise delay base on the violated timing path
#---------------------------------------------------------------------------------------------------
if {$sta_vars(get_timing_path_noise_delay_in_clk) == 1} {
    design::get_timing_path_noise_delay  -clock 1 -data 0 -max_path 9999 -delay_type max -pba_mode path -file ${RPT_DIR}/clk_net_noise_base_timing_path.rpt
}
if {$sta_vars(get_timing_path_noise_delay_in_data) == 1} {
    design::get_timing_path_noise_delay  -clock 0 -data 1 -max_path 9999 -delay_type max -pba_mode path -file ${RPT_DIR}/data_net_noise_base_timing_path.rpt
}
#---------------------------------------------------------------------------------------------------
# report cell status
#---------------------------------------------------------------------------------------------------
if {$sta_vars(report_cell_status) == 1} {
    design::report_cell_status -file ${RPT_DIR}/${TOP}.report_cell_status.rpt
}
#---------------------------------------------------------------------------------------------------
# all drv violations
#---------------------------------------------------------------------------------------------------
if {$sta_vars(check_all_constraints) == 1} {
    report_constraint -all_violators -nosplit -pba_mode path > ${RPT_DIR}/${TOP}.all_constraints.rpt
}
#---------------------------------------------------------------------------------------------------
# report uncertainty and source period of each clock
#---------------------------------------------------------------------------------------------------
if {$sta_vars(report_clock_status) == 1} {
    design::report_clock_status > ${RPT_DIR}/${TOP}.report_clock_status.rpt
    design::summary_design -type pt_constraint -file ${TOP}.pt_constraint.rpt
}
#---------------------------------------------------------------------------------------------------
# timing budget
#---------------------------------------------------------------------------------------------------
if {$sta_vars(generate_timing_budget_blk_file) == 1 } {
   design::timing_budget_blkGen -file ${RPT_DIR}/${TOP}.timing_budget_blkGen.rpt 
}
