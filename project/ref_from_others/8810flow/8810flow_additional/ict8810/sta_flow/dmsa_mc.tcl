puts "RM-Info: Running script [info script]\n"

#################################################################################
# PrimeTime Reference Methodology Script
# Script: dmsa_mc.tcl
# Version: Q-2019.12-SP4 (July 20, 2020)
# Copyright (C) 2009-2020 Synopsys All rights reserved.
#################################################################################

set sh_source_uses_search_path true
set report_default_significant_digits 3
set auto_wire_load_selection false

###
#set pt_tmp_dir . 
#set sh_high_capacity_effort high
#set_program_options -enable_high_capacity

# make REPORTS_DIR
#file mkdir $REPORTS_DIR

# make RESULTS_DIR
#file mkdir $RESULTS_DIR 

set REPORTS_DIR "${current_dir}/rpt/${mode}_${corner}_${check}"
set LOG_DIR "${current_dir}/log/${mode}_${corner}_${check}"
set DATA_DIR "${current_dir}/db/${mode}_${corner}_${check}"
sh mkdir -p $REPORTS_DIR
sh mkdir -p $LOG_DIR
sh mkdir -p $DATA_DIR

#set parasitics_log_file  "${current_dir}/rpt/${mode}_${corner}_${check}/parasitics_file.${VIEW}.log"


#############
set timing_aocvm_enable_analysis true
set_app_var timing_remove_clock_reconvergence_pessimism true
set timing_aocvm_analysis_mode combined_launch_capture_depth
set timing_ocvm_enable_distance_analysis true


set si_enable_analysis true 
set si_xtalk_double_switching_mode clock_network 
set delay_calc_waveform_analysis_mode  full_design
set delay_calc_enhanced_ccsn_waveform_analysis true

#Enabling auto clock mux
set timing_enable_auto_mux_clock_exclusivity  false
set timing_report_unconstrained_paths  true
set link_create_black_boxes false
set timing_enable_cross_voltage_domain_analysis true
set timing_enable_cumulative_incremental_derate true 

# Enabling POCV analysis
  ##set_app_var pba_derate_only_mode true 
#  If distance-based derating tables are applied, enabling parasitics location for POCV distance-based derating 

 set read_parasitics_load_locations true

#
set pba_exhaustive_endpoint_path_limit infinity
set timing_save_pin_arrival_and_slack true


echo "Checking $dmsa_corner_library_files($corner)"

set select_dmsa_corner_libs "";

foreach dml $dmsa_corner_library_files($corner)  {
    lappend select_dmsa_corner_libs $dml
}

echo "select_dmsa_corner_libs $select_dmsa_corner_libs"
if { $mode=="func2" || $mode=="func3" } {
 	set link_path "* $1pv_dmsa_corner_library_files($corner) "
 } else { 
	set link_path "* $select_dmsa_corner_libs" }
echo "link_path  $link_path"
#set link_path_per_instance [list
#            [list {ucore} {* lib2.db}]
#            [list {ucore/usubblk} {* lib3.db}]]
#
#set select_io3p3v0p8v_dmsa_corner_libs "";
#foreach dml_io3p3v0p8v $io_3p3v0p8v_dmsa_corner_library_files($corner)  {
#    lappend select_io3p3v0p8v_dmsa_corner_libs $dml_io3p3v0p8v
#}
#set io_lists_1p8v0p9v "sby_top_inst/sby_pad_inst/pad_ext_reset_n/lp_pad"
##set io_lists_3p3v0p8v "	\
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_9/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_8/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_7/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_6/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_5/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_4/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_3/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_2/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_1/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_0/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_15/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_14/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_13/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_12/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_11/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_pd_gpio_10/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_rf_control_7/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_rf_control_6/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_rf_control_5/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_rf_control_4/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_rf_control_3/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_rf_control_2/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_rf_control_1/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_rf_control_0/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_swd0_swclk/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_swd0_swdio/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_clk_au_mclk/pad_v \
# sby_aon_top_inst/sby_aon_top_wrapper_inst/aon_top_wrapper_inst/aon_pad_inst/pad_lpuart0_tx/gp_pad \
# sby_aon_top_inst/sby_aon_top_wrapper_inst/aon_top_wrapper_inst/aon_pad_inst/pad_clk_ext_out/gp_pad \
# sby_aon_top_inst/sby_aon_top_wrapper_inst/aon_top_wrapper_inst/aon_pad_inst/pad_lpuart0_cts/gp_pad \
# sby_aon_top_inst/sby_aon_top_wrapper_inst/aon_top_wrapper_inst/aon_pad_inst/pad_lpuart0_rx/gp_pad \
# sby_aon_top_inst/sby_aon_top_wrapper_inst/aon_top_wrapper_inst/aon_pad_inst/pad_lpuart0_rts/gp_pad \
# sby_aon_top_inst/sby_aon_top_wrapper_inst/aon_top_wrapper_inst/aon_pad_inst/pad_aon_gpio_1/gp_pad \
# sby_aon_top_inst/sby_aon_top_wrapper_inst/aon_top_wrapper_inst/aon_pad_inst/pad_aon_gpio_0/gp_pad  \
# pd_core_top_inst/pd_pinmux_inst/pad_sim0_clk/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_sim0_rst/pad_h \
# pd_core_top_inst/pd_pinmux_inst/pad_sim0_data/pad_h \
#"

## subblock netlist

#foreach design $all_blocks {
#	read_verilog $design.pr.${VIEW}.vg.gz
#}

##read_verilog /eda_files/proj/ict2100/backend/zhangwenjie/chip_top_fdp/sub_proj/chip_top/dsn/gate/chip_top.pr.0407_v2.vg.gz
#read_verilog /eda_files/proj/ict2100/backend/zhangwenjie/chip_top_fdp/sub_proj/chip_top/dsn/gate/lb_dsp.pr.0407_v2.vg.gz
#read_verilog /eda_files/proj/ict2100/backend/zhangwenjie/chip_top_fdp/sub_proj/chip_top/dsn/gate/lb_lte_modem_top.pr.0407_v2.vg.gz
#read_verilog /eda_files/proj/ict2100/backend/zhangwenjie/chip_top_fdp/sub_proj/chip_top/dsn/gate/lb_cpu.pr.0407_v2.vg.gz
#read_verilog /eda_files/proj/ict2100/backend/zhangwenjie/chip_top_fdp/sub_proj/chip_top/dsn/gate/aon_top.pr.0407_v2.vg.gz
#read_verilog /eda_files/proj/ict2100/backend/zhangwenjie/chip_top_fdp/sub_proj/chip_top/dsn/gate/sby_top.pr.0407_v2.vg.gz
set all_blocks ""
echo "debug    $DESIGN_NAME.pr.${VIEW}.vg.gz"
echo "debug  $all_blocks"
read_verilog $DESIGN_NAME.pr.${VIEW}.vg.gz
current_design $DESIGN_NAME
# if { $mode=="func1" || $mode=="func3" } {
#	set link_path_per_instance [list \
#	[list "[get_object_name [get_cells * -hierarchical]]" "* $1pv_dmsa_corner_library_files($corner) "]]
#}
#echo "link_path_per_instance $link_path_per_instance"

echo "Link $DESIGN_NAME .." > ${LOG_DIR}/link.log
echo "read_verilog $DESIGN_NAME.pr.${VIEW}.vg.gz"  >> ${LOG_DIR}/link.log
link  >> ${LOG_DIR}/link.log


set_noise_parameters -include_beyond_rails -enable_propagation -analysis_mode report_at_endpoint

##################################################################
#    Back Annotation Section                                     #
##################################################################

if { [info exists PARASITIC_PATHS] && [info exists PARASITIC_FILES] } {
    foreach para_path $PARASITIC_PATHS($corner) para_file $PARASITIC_FILES($corner) {
       if {[string compare $para_path $DESIGN_NAME] == 0} {
           redirect ${LOG_DIR}/read_parasitics.log {read_parasitics -keep_capacitive_coupling $para_file}
       } else {
           redirect ${LOG_DIR}/read_parasitics.log {read_parasitics -path $para_path -keep_capacitive_coupling $para_file}
       }
    }
}

# subblock spef file



foreach design $all_blocks {
read_parasitics -keep_capacitive_coupling -path [all_instances -hier  $design] $design.${VIEW}.$SPF_CORNER($corner).gz
}


######## read spef not use location
#set design modem_icb_adb_wrapper 
#read_parasitics   -keep_capacitive_coupling -path [all_instances -hier  $design] $design.${VIEW}.$SPF_CORNER($corner).gz
#set design n300_ps_cpu_top
#read_parasitics   -keep_capacitive_coupling -path [all_instances -hier  $design] $design.${VIEW}.$SPF_CORNER($corner).gz
#set design sby_aon_top
#read_parasitics  -keep_capacitive_coupling -path [all_instances -hier  $design] $design.${VIEW}.$SPF_CORNER($corner).gz
#
#
#set design ict_psram_phy_dll_master_delay_line_1_ict_psram_phy_ict_psram_phy
#read_parasitics -keep_capacitive_coupling  -path [get_cells pd_core_top_inst/psram_adb400_wrapper_inst/ict_psram_phy_top_inst/ict_psram_phy/ict_psram_phy_core/dll_phy_slice_core/data_slice_0/dll/dll_delay_line_master] $design.${VIEW}.$SPF_CORNER($corner).gz
#read_parasitics -keep_capacitive_coupling  -path [get_cells pd_core_top_inst/psram_adb400_wrapper_inst/ict_psram_phy_top_inst/ict_psram_phy/ict_psram_phy_core/dll_phy_slice_core/data_slice_0/dll/dll_delay_line_clk_wr] $design.${VIEW}.$SPF_CORNER($corner).gz
#read_parasitics -keep_capacitive_coupling  -path [get_cells pd_core_top_inst/psram_adb400_wrapper_inst/ict_psram_phy_top_inst/ict_psram_phy/ict_psram_phy_core/dll_phy_slice_core/data_slice_0/dll/dll_delay_line_rd_dqs] $design.${VIEW}.$SPF_CORNER($corner).gz
#
#set design ict_psram_phy_dll_delay_element_2097_ict_psram_phy_ict_psram_phy
#append_to_collection n1 [get_cells pd_core_top_inst/psram_adb400_wrapper_inst/ict_psram_phy_top_inst/ict_psram_phy/ict_psram_phy_core/dll_phy_slice_core/data_slice_0/dll/dll_phase_detect/dll_delay_element*]
#append_to_collection n1 [get_cells pd_core_top_inst/psram_adb400_wrapper_inst/ict_psram_phy_top_inst/ict_psram_phy/ict_psram_phy_core/dll_phy_slice_core/data_slice_0/dfi_read_datablk/clkdqs_*_adder_slv/dll_adder_delay_line/delay_*]
#read_parasitics -keep_capacitive_coupling  -path [remove_from_collection [all_instances -hier  $design] $n1] $design.${VIEW}.$SPF_CORNER($corner).gz
#read_parasitics -keep_capacitive_coupling  -path [get_cells pd_core_top_inst/psram_adb400_wrapper_inst/ict_psram_phy_top_inst/ict_psram_phy/ict_psram_phy_core/dll_phy_slice_core/data_slice_0/dll/dll_phase_detect/dll_delay_element*] $design.${VIEW}.$SPF_CORNER($corner).gz
#read_parasitics -keep_capacitive_coupling  -path [get_cells pd_core_top_inst/psram_adb400_wrapper_inst/ict_psram_phy_top_inst/ict_psram_phy/ict_psram_phy_core/dll_phy_slice_core/data_slice_0/dfi_read_datablk/clkdqs_*_adder_slv/dll_adder_delay_line/delay_*] $design.${VIEW}.$SPF_CORNER($corner).gz
#
#set design ict_psram_phy_top_ict_pad
#read_parasitics  -keep_capacitive_coupling -path [all_instances -hier  $design] $design.${VIEW}.$SPF_CORNER($corner).gz



read_parasitics -keep_capacitive_coupling $PARASITIC_FILES($corner)



complete_net_parasitics -complete_with  zero


##################################################################
#    Define Scaling Group Section                                #
##################################################################
#define_scaling_lib_group [list $dmsa_mv_scaling_library1($corner) $dmsa_mv_scaling_library2($corner)]

#create_operating_conditions -name $dmsa_mv_voltage($corner)_oc -library [index_collection [get_libs *] 0] -process $dmsa_mv_process($corner) -temperature $dmsa_mv_temperature($corner) -volt $dmsa_mv_voltage($corner)

#set_operating_conditions $dmsa_mv_voltage($corner)_oc
set_operating_conditions $OPRATING_COND($corner)



##################################################################
#    UPF Section                                                 #
##################################################################
  if {[info exists $dmsa_UPF_FILE]} { 
load_upf $dmsa_UPF_FILE
  } 

######################################
# reading design constraints
######################################
set pre_sta 0
if {[info exists dmsa_mode_constraint_files($mode)]} {
    foreach dmcf $dmsa_mode_constraint_files($mode) {
        file delete -force ${LOG_DIR}/read_sdc.${mode}.log
        redirect -append ${LOG_DIR}/read_sdc.${mode}.log {source -echo -verbose $dmcf}
    }
}

set_propagated_clock  [all_clocks]






#foreach pocvm_file $dmsa_corner_pocvm_file($corner) {
#    echo "reading $vars(WIRE_OCV)"
#    read_ocvm $vars(WIRE_OCV)
#}

set_app_var timing_aocvm_enable_analysis true
set_app_var timing_aocvm_analysis_mode combined_launch_capture_depth
file delete $REPORTS_DIR/${DESIGN_NAME}.aocv_not_annotated.rpt
foreach aocvm_file $dmsa_corner_aocvm_file($corner) {
    echo "Read aocvm $aocvm_file" > $REPORTS_DIR/${DESIGN_NAME}.aocv_not_annotated.rpt
    read_aocvm $aocvm_file   >> $REPORTS_DIR/${DESIGN_NAME}.aocv_not_annotated.rpt
}
echo "aocvmfile $aocvm_file"

#Reading via-variation side file 
#read_ivm via.table
#Enable via variation analysis 
#set timing_enable_via_variation true




#pmcell same as svt/hvt ;not distinguished in channel length,select worstcase data ;
if {$check == "setup"} {
    puts "setting  ocv in setup scenario"
    if {[string match wcl_* $corner ]} {
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.050  [ get_lib_cells *0p81v_m40c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.084  [ get_lib_cells *0p81v_m40c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.043  [ get_lib_cells *0p81v_m40c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.038  [ get_lib_cells *0p81v_m40c*/*ZTUL*]
        # MEM
        set_timing_derate  -cell_delay  -clock  -data -increment  -late    0.030  [get_lib_cells  *0p81v_m40c/AU28HPCP*]
        # IP
        set_timing_derate  -cell_delay  -clock  -data -increment  -late    0.030  [get_lib_cells  */PLLUM28*]
        set_timing_derate  -cell_delay  -clock  -data -increment  -late    0.030  [get_lib_cells  */inno_ddr_phy]
        set_timing_derate  -cell_delay  -clock  -data -increment  -late    0.030  [get_lib_cells  */FXEDP44*]
        set_timing_derate  -cell_delay  -clock  -data -increment  -late    0.030  [get_lib_cells  */SFLVTPA28*]
        set_timing_derate  -cell_delay  -clock  -data -increment  -late    0.030  [get_lib_cells  */O12P5PHYU28*]
        set_timing_derate  -cell_delay  -clock  -data -increment  -late    0.030  [get_lib_cells  */GSM3P*]
        set_timing_derate  -cell_delay  -clock  -data -increment  -late    0.030  [get_lib_cells  */U2OPHY*]
        set_timing_derate  -cell_delay  -clock  -data -increment  -late    0.030  [get_lib_cells  */CPOR*]
        set_timing_derate  -cell_delay  -clock  -data -increment  -late    0.030  [get_lib_cells  */UMC028_PVT*]
        set_timing_derate  -cell_delay  -clock  -data -increment  -late    0.030  [get_lib_cells  */u028efucp*]

#        set_timing_derate  -cell_delay  -clock -increment  -early  -0.084  [ get_lib_cells *0p81vm40c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock -increment  -early  -0.084  [ get_lib_cells *0p81vm40c*/SFLVTPA28_512X80BW64b1]
    }
    if {[string match wc_* $corner ]} {
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.038  [ get_lib_cells *0p81v_125c*/*ZTS*]                   			
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.054  [ get_lib_cells *0p81v_125c*/*ZTH*]             			
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.031  [ get_lib_cells *0p81v_125c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.031  [ get_lib_cells *0p81v_125c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock -increment  -early  -0.054  [ get_lib_cells *0p81v125c*/FXEDP447EWHJ0P]  
#        set_timing_derate  -cell_delay  -clock -increment  -early  -0.054  [ get_lib_cells *0p81v125c*/SFLVTPA28_512X80BW64b1]       
    }
    if {[string match wcz_* $corner ]} {
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.046  [ get_lib_cells *0p81v_0c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.075  [ get_lib_cells *0p81v_0c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.041  [ get_lib_celltypical_max_1p00v_85cs *0p81v_0c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.040  [ get_lib_cells *0p81v_0c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock -increment  -early  -0.075  [ get_lib_cells *0p81v0c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock -increment  -early  -0.075  [ get_lib_cells *0p81v0c*/SFLVTPA28_512X80BW64b1]
    }
    if {[string match typ_85 $corner ] && ( [string match func $mode ] || [string match func1 $mode ] ) } {
        ###typic 85 7% 3sigma setup set
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.061 [get_lib_cells *typical_max_0p90v_85c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.044 [get_lib_cells *typical_max_0p90v_85c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.040 [get_lib_cells *typical_max_0p90v_85c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.038 [get_lib_cells *typical_max_0p90v_85c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock -increment  -early  -0.080 [get_lib_cells *0p90v85c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock -increment  -early  -0.080 [get_lib_cells *0p90v85c*/SFLVTPA28_512X80BW64b1]
        
    }
    if {[string match typ_125 $corner ] && ( [string match func $mode ] || [string match func1 $mode ] ) } {
        ###typic 85 7% 3sigma setup set
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.044 [get_lib_cells *typical_max_0p90v_85c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.059 [get_lib_cells *typical_max_0p90v_85c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.036 [get_lib_cells *typical_max_0p90v_85c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.037 [get_lib_cells *typical_max_0p90v_85c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock -increment  -early  -0.080 [get_lib_cells *0p90v85c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock -increment  -early  -0.080 [get_lib_cells *0p90v85c*/SFLVTPA28_512X80BW64b1]
    }
    if {[string match typ_25 $corner ] && ( [string match func $mode ] || [string match func1 $mode ] ) } {
        ###typic 85 7% 3sigma setup set
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.050 [get_lib_cells *typical_max_0p90v_85c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.069 [get_lib_cells *typical_max_0p90v_85c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.043 [get_lib_cells *typical_max_0p90v_85c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.040 [get_lib_cells *typical_max_0p90v_85c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock -increment  -early  -0.080 [get_lib_cells *0p90v85c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock -increment  -early  -0.080 [get_lib_cells *0p90v85c*/SFLVTPA28_512X80BW64b1]
    }
    if {[string match typ_85 $corner ] && ( [string match func2 $mode ] ||[string match func3 $mode ] ) } {
        ###typic 85 8% 3sigma setup set
        # no change
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.052 [get_lib_cells *typical_max_1p00v_85c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.067  [get_lib_cells *typical_max_1p00v_85c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.047 [get_lib_cells *typical_max_1p00v_85c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -increment  -early  -0.046 [get_lib_cells typical_max_1p00v_85c*typical_max_1p00v_85c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock -increment  -early  -0.067  [get_lib_cells *1p00v85c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock -increment  -early  -0.067  [get_lib_cells *1p00v85c*/SFLVTPA28_512X80BW64b1]
        
        set_timing_derate  -cell_delay  -clock -increment -data  -late  0.052 [get_lib_cells *typical_max_1p00v_85c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock -increment -data  -late  0.067 [get_lib_cells *typical_max_1p00v_85c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock -increment -data  -late  0.047 [get_lib_cells *typical_max_1p00v_85c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -increment -data  -late  0.046 [get_lib_cells *typical_max_1p00v_85c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock -increment -data  -late  0.067 [get_lib_cells *1p00v85c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock -increment -data  -late  0.067 [get_lib_cells *1p00v85c*/SFLVTPA28_512X80BW64b1]
    }
    
    ### arm signoff 
    ####### ss dynamic v chose 5%  3sigmal for HVT SVT LVT cell
} elseif {$check == "hold" } {
    puts "setting  ocv in hold scenario"

    ##arm signoff 14% 5simal
    if {[string match wcl_* $corner ]} {
        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.084 [ get_lib_cells *0p81v_m40c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.141 [ get_lib_cells *0p81v_m40c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.073 [ get_lib_cells *0p81v_m40c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.065 [ get_lib_cells *0p81v_m40c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.205 [ get_lib_cells *0p81vm40c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.205 [ get_lib_cells *0p81vm40c*/SFLVTPA28_512X80BW64b1]
    }
    if {[string match wc_* $corner ]} {
        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.063 [ get_lib_cells *0p81v_125c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.090 [ get_lib_cells *0p81v_125c*/*ZTH*]				
        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.053  [ get_lib_cells *0p81v_125c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.052  [ get_lib_cells *0p81v_125c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.128 [ get_lib_cells *0p81v125c*/FXEDP447EWHJ0P]	
#        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.128 [ get_lib_cells *0p81v125c*/SFLVTPA28_512X80BW64b1]	
    }
    if {[string match wcz_* $corner ]} {
        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.075 [ get_lib_cells *0p81v_0c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.123 [ get_lib_cells *0p81v_0c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.068 [ get_lib_cells *0p81v_0c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.066 [ get_lib_cells *0p81v_0c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.175 [ get_lib_cells *0p81v0c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock -data -increment  -early  -0.175 [ get_lib_cells *0p81v0c*/SFLVTPA28_512X80BW64b1]
    }
    ####### ss dynamic v chose 14%  5 sigmal for HVT SVT LVT cell
    if {[string match ml_* $corner ]} {
        set_timing_derate  -cell_delay  -clock  -increment  -late  0.122  [ get_lib_cells *0p99v_125c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock  -increment  -late  0.146  [ get_lib_cells *0p99v_125c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock  -increment  -late  0.120  [ get_lib_cells *0p99v_125c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock  -increment  -late  0.101  [ get_lib_cells *0p99v_125c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock  -increment  -late 0.146	 [ get_lib_cells *0p99v125c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock  -increment  -late 0.146	 [ get_lib_cells *0p99v125c*/SFLVTPA28_512X80BW64b1]
    }
    if {[string match bc_* $corner ]} {
        set_timing_derate  -cell_delay  -clock  -increment  -late  0.136  [ get_lib_cells *0p99v_0c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock  -increment  -late  0.176  [ get_lib_cells *0p99v_0c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock  -increment  -late  0.127  [ get_lib_cells *0p99v_0c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock  -increment  -late  0.120  [ get_lib_cells *0p99v_0c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock  -increment  -late 0.176  [ get_lib_cells *0p99v0c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock  -increment  -late 0.176  [ get_lib_cells *0p99v0c*/SFLVTPA28_512X80BW64b1]
    }
    if {[string match lt_* $corner ]} {
        set_timing_derate  -cell_delay  -clock  -increment  -late  0.144  [ get_lib_cells *0p99v_m40c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock  -increment  -late  0.190  [ get_lib_cells *0p99v_m40c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock  -increment  -late  0.128  [ get_lib_cells *0p99v_m40c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock  -increment  -late  0.120  [ get_lib_cells *0p99v_m40c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock  -increment  -late 0.19 [ get_lib_cells *0p99vm40c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock  -increment  -late 0.19 [ get_lib_cells *0p99vm40c*/SFLVTPA28_512X80BW64b1]
    }
    ### just set for typic for 0.9v 1.0v 
    if {[string match typ_85 $corner ] && ( [string match func $mode ] || [string match func1 $mode ] ) } {
        set_timing_derate  -cell_delay  -clock -increment  -late  0.074 [get_lib_cells *typical_max_0p90v_85c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock -increment  -late  0.103 [get_lib_cells *typical_max_0p90v_85c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock -increment  -late  0.065 [get_lib_cells *typical_max_0p90v_85c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -increment  -late  0.065 [get_lib_cells *typical_max_0p90v_85c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock -increment  -late  0.136 [get_lib_cells *0p90v85c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock -increment  -late  0.136 [get_lib_cells *0p90v85c*/SFLVTPA28_512X80BW64b1]
    }
    if {[string match typ_85 $corner ] && ( [string match func2 $mode ] || [string match func3 $mode ]) } {
        set_timing_derate  -cell_delay  -clock -increment  -late  0.074 [get_lib_cells *typical_max_1p00v_85c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock -increment  -late  0.103 [get_lib_cells *typical_max_1p00v_85c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock -increment  -late  0.065 [get_lib_cells *typical_max_1p00v_85c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -increment  -late  0.065 [get_lib_cells *typical_max_1p00v_85c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock -increment  -late  0.108 [get_lib_cells *1p00v85c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock -increment  -late  0.108 [get_lib_cells *1p00v85c*/SFLVTPA28_512X80BW64b1]
        
        set_timing_derate  -cell_delay  -clock -increment  -data -early  -0.074 [get_lib_cells *typical_max_1p00v_85c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock -increment  -data -early  -0.103 [get_lib_cells *typical_max_1p00v_85c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock -increment  -data -early  -0.065 [get_lib_cells *typical_max_1p00v_85c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -increment  -data -early  -0.065 [get_lib_cells *typical_max_1p00v_85c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock -increment  -data -early  -0.108 [get_lib_cells *1p00v85c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock -increment  -data -early  -0.108 [get_lib_cells *1p00v85c*/SFLVTPA28_512X80BW64b1]
    }
    if {[string match typ_125 $corner ] && ( [string match func $mode ] || [string match func1 $mode ]) } {
        set_timing_derate  -cell_delay  -clock -increment  -late  0.080 [get_lib_cells *typical_max_1p00v_85c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock -increment  -late  0.096 [get_lib_cells *typical_max_1p00v_85c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock -increment  -late  0.063 [get_lib_cells *typical_max_1p00v_85c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -increment  -late  0.070 [get_lib_cells *typical_max_1p00v_85c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock -increment  -late  0.108 [get_lib_cells *1p00v85c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock -increment  -late  0.108 [get_lib_cells *1p00v85c*/SFLVTPA28_512X80BW64b1]
    }
    if {[string match typ_25 $corner ] && ( [string match func $mode ] || [string match func1 $mode ]) } {
        set_timing_derate  -cell_delay  -clock -increment  -late  0.087 [get_lib_cells *typical_max_1p00v_85c*/*ZTS*]
        set_timing_derate  -cell_delay  -clock -increment  -late  0.123 [get_lib_cells *typical_max_1p00v_85c*/*ZTH*]
        set_timing_derate  -cell_delay  -clock -increment  -late  0.075 [get_lib_cells *typical_max_1p00v_85c*/*ZTL*]
        set_timing_derate  -cell_delay  -clock -increment  -late  0.075 [get_lib_cells *typical_max_1p00v_85c*/*ZTUL*]
#        set_timing_derate  -cell_delay  -clock -increment  -late  0.108 [get_lib_cells *1p00v85c*/FXEDP447EWHJ0P]
#        set_timing_derate  -cell_delay  -clock -increment  -late  0.108 [get_lib_cells *1p00v85c*/SFLVTPA28_512X80BW64b1]
    }
    
    ######## arm signoff
    
    ###typic 85 8% 3sigma hold set
    
} else {
    puts "Warning: No derating fator set on design"
}

#### wire dereating 
if { [string match typ_* $corner ] } {
    set_timing_derate 0.915 -early -net_delay
	set_timing_derate 1.085 -late  -net_delay
} elseif {  [string match $check  setup ] } {
    set_timing_derate 0.915 -early -net_delay
} elseif { [string match *cworst $corner ] && [string match $check  hold ] } {
    set_timing_derate  -early -net_delay -increment -0.085
} elseif { [string match *best $corner ] && [string match $check  hold ] } {
    set_timing_derate  -late -net_delay -increment 0.085
}
set_timing_derate 1.000 -early -net_delay -data
set_timing_derate 1.085 -late  -net_delay -data
set_timing_derate 0.915 -early -net_delay -clock
set_timing_derate 1.085 -late  -net_delay -clock

## max transition 
set_max_transition 0.450 [current_design] ;# data : 0.450
set_max_transition 0.250 -clock_path [all_clocks] ;# clk  : 0.250 -> 0.200 (flow MPW)
if {[get_object_name [current_design]] == "chip_top"} {
set_max_transition 0.250 -clock_path [all_clocks] ;# top clk  : 0.250
}
set_max_fanout 40 [current_design]

# for etm cell
set etm_cells [get_cells * -filter {is_memory_cell == false && is_hierarchical == false && number_of_pins > 1000} -hierarchical -q]
if {[sizeof_collection $etm_cells] != 0} {
    foreach_in_collection cell $etm_cells {
        set insts [get_object_name $cell]
        set_max_transition -force 100 [get_pins $insts/*]
        puts "INFO: set_max_transition -force 100 $insts/*"
        set_max_capacitance -force 100 [get_pins $insts/*]
        puts "INFO: set_max_capacitance -force 100 $insts/*"
    }
}
## clock uncertaily set 
set_clock_uncertainty -setup 0.003 [all_clocks]
if { [string match ssg*  $OPRATING_COND($corner) ]  } {
    set_clock_uncertainty -hold 0.013 [all_clocks]
} elseif {[string match ffg*  $OPRATING_COND($corner) ] } { 
    set_clock_uncertainty -hold 0.003 [all_clocks]
}

################################################################## #    DMSA Derate Section - Based on Mode and Corner		 # ################################################################## if {[info exists dmsa_derate_clock_early_value(${mode}_${corner})]} { echo "clock early: Mode $mode : Corner $corner : Derate Value : $dmsa_derate_clock_early_value(${mode}_${corner})" set_timing_derate $dmsa_derate_clock_early_value(${mode}_${corner}) -clock -early } if {[info exists dmsa_derate_clock_late_value(${mode}_${corner})]} { echo "clock late: Mode $mode : Corner $corner : Derate Value : $dmsa_derate_clock_late_value(${mode}_${corner})" set_timing_derate $dmsa_derate_clock_late_value(${mode}_${corner}) -clock -late } if {[info exists dmsa_derate_data_early_value(${mode}_${corner})]} { echo "data early: Mode $mode : Corner $corner : Derate Value : $dmsa_derate_data_early_value(${mode}_${corner})" set_timing_derate $dmsa_derate_data_early_value(${mode}_${corner}) -data -early } if {[info exists dmsa_derate_data_late_value(${mode}_${corner})]} { echo "data late: Mode $mode : Corner $corner : Derate Value : $dmsa_derate_data_late_value(${mode}_${corner})" set_timing_derate $dmsa_derate_data_late_value(${mode}_${corner}) -data -late } 
puts "RM-Info: Completed script [info script]\n"

##Leon
## func2 typic corner need check setup or hold
if {[regexp {_setuphold} [current_scenario]]} {dmsa_mc.tcl
} elseif {[regexp {_hold} [current_scenario]]} {
    set_false_path -setup -to *
} elseif {[regexp {_setup} [current_scenario]]} {
    set_false_path -hold -to *
}


#source -e /eda_files/proj/ict2100/backend/be2101/chip_top_tdp/sta_pt/group_path.tcl
#set dsp [filter_collection [all_registers] full_name=~pdcore_top_inst/lb_cp_top_inst/u_lb_dsp/*]
#set sby [filter_collection [all_registers] full_name=~sby_top_inst/*]
#set modem [filter_collection [all_registers] full_name=~pdcore_top_inst/lte_modem_top_wrapper_inst/lb_lte_modem_top/*]
#
#set_false_path -from [get_cells $dsp] 
#set_false_path  -to [get_cells $dsp]
#
#
#set_false_path -from [get_cells $sby] 
#set_false_path -from [get_cells $modem] 
#set_false_path  -to [get_cells $sby]
#set_false_path  -to [get_cells $modem]

