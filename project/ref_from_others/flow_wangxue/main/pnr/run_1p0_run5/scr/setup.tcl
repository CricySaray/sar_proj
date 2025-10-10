global  vars
set     vars(version)  20.1.3
exec    mkdir    -p    ./tmp
setenv  TMPDIR         ./tmp

set     vars(dbs_dir)  ../db
set     vars(rpt_dir)  ../rpt

#######################################################################
# Define common setting
#-----------------------------------------------------------------
set  vars(process)              28
set  vars(local_cpus)           32
set  vars(distribute)           local
setDistributeHost -local
setMultiCpuUsage -localCpu $vars(local_cpus) -keepLicense true -threadInfo 2


#######################################################################
# Define the design data
#-----------------------------------------------------------------
set   vars(design)                "CX200UR1_SOC_TOP"
set   vars(netlist)               "/process/TSMC28/projects/CX200UR1/backend/user3/backend/input/syn/1.0/20250725/CX200UR1_SOC_TOP_final.v"
set   vars(func_sdc)              "/process/TSMC28/projects/CX200UR1/backend/user3/backend/input/syn/1.0/20250725/CX200UR1_SOC_TOP_func_ptwrite.sdc"
set   vars(func_1p8vio_sdc)       "/process/TSMC28/projects/CX200UR1/backend/user3/backend/input/syn/1.0/20250725/CX200UR1_SOC_TOP_func_1p8_ptwrite.sdc"
set   vars(scan_sdc)              "/process/TSMC28/projects/CX200UR1/backend/user3/backend/input/syn/1.0/20250725/CX200UR1_SOC_TOP_scan_ptwrite.sdc"
set   vars(scan_def)              "/process/TSMC28/projects/CX200UR1/backend/user3/backend/input/syn/1.0/20250725/CX200UR1_SOC_TOP_dft.scandef"
set   vars(size_only_file)        "/process/TSMC28/projects/CX200UR1/backend/user3/backend/input/syn/1.0/20250725/dont.tcl"
set   vars(fp_file)               ""
set   vars(ieee1801_file)         "/process/TSMC28/projects/CX200UR1/backend/user3/backend/input/syn/1.0/20250725/cx200_ur1.upf"
set   vars(def_files)             "IOPlace.def_20250725.gz"
set   vars(power_nets)            "AVDD0P9_TX_RF AVDD1P2_TX_RF DVDD0P9_AON DVDD0P9_CORE DVDD0P9_DBB DVDD0P9_RAM DVDD1P2 VBAT"
set   vars(ground_nets)           "VSS_CORE VSS_ANA"
set   vars(honor_pitch)           FALSE
set   vars(dont_use_list)         "*D0BWP* *D1BWP* *D20BWP* *LVT ISOSR* PT*  HDRSI* DCCK* *CK*"
set   vars(tie_cells)             "TIELBWP7T35P140 TIEHBWP7T35P140"
set   vars(view_definition_file)  "../scr/view_definition.tcl"
set   vars(flow)                  mmmc
set   vars(enable_ocv)            pre_postcts
set   vars(enable_cppr)           both
set   vars(enable_si_aware)       true

###############################################################
set  vars(use_sdc_uncertainty)              "true"
set  vars(clk_uncertainty_setup_prects)     0.4
set  vars(clk_uncertainty_hold_prects)      0.05
set  vars(clk_uncertainty_setup_postcts)    0.35
set  vars(clk_uncertainty_hold_postcts)     0.05
set  vars(clk_uncertainty_setup_postroute)  0.3
set  vars(clk_uncertainty_hold_postroute)   0.05
set  vars(data_slew)                        0.25
set  vars(clk_slew)                         0.15
set  vars(max_fanout)                       16
    
#######################################################################
# Define rc corners ...
#-----------------------------------------------------------------
#source ./corner.tcl

#######################################################################
# Define cts vars
#-----------------------------------------------------------------
set   vars(usefulSkew_cts)           false
set   vars(cts_use_invters)          true
set   vars(cts_shield_mode)          false
set   vars(cts_logic_cells)          "CKXOR*7T35P140      CKND2D*7T35P140     CKMUX*7T35P140      CKLHQD*7T35P140     CKAN2D*7T35P140"
set   vars(cts_icg_cells)            "CKLNQD8BWP7T35P140  CKLNQD6BWP7T35P140  CKLNQD4BWP7T35P140  CKLNQD3BWP7T35P140  CKLNQD2BWP7T35P140  CKLNQD16BWP7T35P140  CKLNQD12BWP7T35P140"
set   vars(cts_driver_cells)         "CKBD8BWP7T35P140"
set   vars(cts_buf_cells)            "CKBD8BWP7T35P140    CKBD6BWP7T35P140    CKBD4BWP7T35P140    CKBD3BWP7T35P140    CKBD2BWP7T35P140    CKBD16BWP7T35P140    CKBD12BWP7T35P140"
set   vars(cts_inv_cells)            "CKND8BWP7T35P140    CKND6BWP7T35P140    CKND4BWP7T35P140    CKND3BWP7T35P140    CKND2BWP7T35P140    CKND16BWP7T35P140    CKND12BWP7T35P140"
set   vars(cts_top_pref_layer)       5
set   vars(cts_btm_pref_layer)       2
set   vars(cts_leaf_top_pref_layer)  ""
set   vars(cts_leaf_btm_pref_layer)  ""
set   vars(cts_fanout)               16
set   vars(cts_leangth)              250
set   vars(cts_skew)                 0.1
set   vars(cts_tran)                 0.15
set   vars(cts_ndr)                  NDR_2W2S
#set  vars(max_buffer_depth)         6
set   vars(cts_engine)               ccopt_cts


#######################################################################
# Define analysis views ...
#-----------------------------------------------------------------
set  vars(place,active_setup_views)  "func_ssm40_cworst_T func_ssm40_cworst_T_2p5io func_ssm40_cworst_T_1p8io func_ss125_cworst_T func_ss125_cworst_T_2p5io func_ss125_cworst_T_1p8io func_ssm40_cworst_T_2p5io func_tt85 scan_ssm40_cworst_T scan_ss125_cworst_T scan_tt85"
set  vars(cts,active_setup_views)    "func_ssm40_cworst_T func_ssm40_cworst_T_2p5io func_ssm40_cworst_T_1p8io func_ss125_cworst_T func_ss125_cworst_T_2p5io func_ss125_cworst_T_1p8io func_ssm40_cworst_T_2p5io func_tt85 scan_ssm40_cworst_T scan_ss125_cworst_T scan_tt85"
set  vars(route,active_setup_views)  "func_ssm40_cworst_T func_ssm40_cworst_T_2p5io func_ssm40_cworst_T_1p8io func_ss125_cworst_T func_ss125_cworst_T_2p5io func_ss125_cworst_T_1p8io func_ssm40_cworst_T_2p5io func_tt85 scan_ssm40_cworst_T scan_ss125_cworst_T scan_tt85"

set  vars(place,active_hold_views)   "func_ff125_rcbest  func_ssm40_cworst func_ssm40_cworst_2p5io func_ssm40_cworst_1p8io func_ss125_cworst func_ss125_cworst_2p5io func_ss125_cworst_1p8io  func_tt85 scan_ff125_rcbest  scan_ssm40_cworst scan_ss125_cworst scan_tt85"
set  vars(cts,active_hold_views)     "func_ff125_rcbest  func_ssm40_cworst func_ssm40_cworst_2p5io func_ssm40_cworst_1p8io func_ss125_cworst func_ss125_cworst_2p5io func_ss125_cworst_1p8io  func_tt85 scan_ff125_rcbest  scan_ssm40_cworst scan_ss125_cworst scan_tt85"
set  vars(route,active_hold_views)   "func_ff125_rcbest  func_ssm40_cworst func_ssm40_cworst_2p5io func_ssm40_cworst_1p8io func_ss125_cworst func_ss125_cworst_2p5io func_ss125_cworst_1p8io  func_tt85 scan_ff125_rcbest  scan_ssm40_cworst scan_ss125_cworst scan_tt85"
#######################################################################
# Define power settings ...
#-----------------------------------------------------------------
set vars(power_analysis_view)                      func_ffm40_rcbest
#set vars(leakage_power_effort)                     none
#set vars(dynamic_power_effort)                     none
#set vars(activity_file)                            ""
#set vars(activity_file_format)                     TCF
#set vars(report_power)                             TRUE
#set vars(cpf_file)                                  $upf
#set vars(cpf_keep_rows)                             TRUE
#set vars(cpf_power_domain)                         FALSE
#set vars(cpf_power_switch)                          FALSE
#set vars(cpf_isolation)                            FALSE
#set vars(cpf_state_retention)                      FALSE
#set vars(cpf_level_shifter)                        FALSE


#######################################################################
# Define tool specific options ...
#-----------------------------------------------------------------

set vars(max_route_layer)                          6
set vars(min_route_layer)                          2
set vars(opt_max_length)                           700
set vars(generate_tracks)                          TRUE
set vars(postroute_extraction_effort)              high
set vars(multi_cut_effort)                         high
set vars(litho_driven_routing)                     FALSE
set vars(postroute_spread_wires)                   FALSE

#set vars(delta_delay_threshold)                    ""
#set vars(celtic_settings)                          ""
#set vars(coupling_c_thresh)                        ""
#set vars(relative_c_thresh)                        ""
#set vars(total_c_thresh)                           ""
set vars(si_analysis_type)                         default
set vars(signoff_extraction_effort)                high
#set vars(antenna_diode)                            ""

set vars(metalfill)                                false
#set vars(metalfill_tcl)                            ""
#set vars(gds_files) ""
#set vars(qrc_layer_map) ""
#set vars(qrc_library) ""
#set vars(qrc_config_file) ""
#set vars(gds_layer_map)                            ""
#set vars(oa_abstract_name)                         ""
#set vars(oa_layout_name)                           ""
#set vars(oa_ref_lib)                               ""
#set vars(oa_design_lib)                            ""
#set vars(oa_design_cell)                           ""
#set vars(oa_design_view)                           ""

#set vars(custom,script) ""
#set vars(lsf,queue) ""
#set vars(lsf,resource) ""
#set vars(lsf,args) ""
#set vars(rsh,host_list) "XIN-NB01"
#set vars(distribute_timeout)                       ""

#######################################################################
# Define innovus configure settings ...
#-----------------------------------------------------------------
#set vars(buffer_tie_assign)                        ""
set vars(delay_cells)                               ""
#set vars(cts_cell_list)                            ""
#set vars(clock_gate_cells)                         ""
#set vars(spare_cells)                              ""
#set vars(verify_litho)                             ""
#set vars(lpa_tech_file)                            ""
#set vars(acceptable_wns)                           ""
#set vars(report_run_time)                          ""
#set vars(final_always_source_tcl)                  ""
#set vars(pre_pin_assign_tcl)                       ""
#set vars(post_pin_assign_tcl)                      ""
#set vars(pre_partition_tcl)                        ""
#set vars(post_partition_tcl)                       ""
#set vars(pre_assemble_tcl)                         ""
#set vars(post_assemble_tcl)                        ""
#set vars(pre_signoff_tcl)                          ""
#set vars(post_signoff_tcl)                         ""
#set vars(abort)                                    ""
#set vars(catch_errors)                             ""
#set vars(save_on_catch)                            ""
#set vars(mail,to)                                  ""
#set vars(mail,steps)                               ""
#set vars(tags,verbose)                             ""
#set vars(tags,verbosity_level)                     ""

set vars(clock_gate_aware)                         FALSE
set vars(clock_gate_clone)                         FALSE
set vars(useful_skew)                              FALSE
#set vars(skew_buffers)                             ""
#set vars(critical_range)                           ""
set vars(preserve_assertions)                      FALSE
set vars(fix_hold)                                 postcts
set vars(fix_hold_ignore_ios)                      TRUE
set vars(fix_hold_allow_tns_degradation)           TRUE
set vars(resize_shifter_and_iso_insts)             FALSE
set vars(assign_buffer)                            FALSE
set vars(high_timing_effort)                       FALSE
#set vars(use_list)                                 ""

set vars(route_clock_nets)                         TRUE
set vars(clock_eco)                                none

set vars(no_pre_place_opt)                         FALSE
set vars(in_place_opt)                             FALSE
set vars(place_io_pins)                            FALSE
#set vars(filler_cells)                             ""
#set vars(welltaps)                                 ""
#set vars(itag_cells)                               ""
#set vars(itag_rows)                                ""
set vars(congestion_effort)                        medium
set vars(welltaps,checkerboard)                    FALSE
#set vars(welltaps,verify_rule)                     ""
#set vars(pre_endcap)                               ""
#set vars(post_endcap)                              ""
#set vars(welltaps,max_gap)                         ""
#set vars(welltaps,cell_interval)                   ""


source ../scr/lib_setup.tcl
source ../scr/util/invs_proc.tcl

