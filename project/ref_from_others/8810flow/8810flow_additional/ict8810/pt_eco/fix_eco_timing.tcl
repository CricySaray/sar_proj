proc file2list {file_name} {
    set list_tmp ""
    set fc [open $file_name]
    while {[gets $fc content] >= 0 } { 
        if {[regexp {^ *#} $content] || [regexp {^ *$} $content]} {continue}
        lappend list_tmp $content
    }   
    close $fc 
    return $list_tmp
}

# physical aware data
#remote_execute {
#    #set view  0626_1
#    source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/last/.lib_setup.tcl
#	set tech "$vars(TECH_LEF_7T) $vars(TECH_LEF_9T)"
##    set pad_lefs "\
##        /eda_files/proj/ict8810/backend/be8812/lef/L28_BOAC_op1_55_6um_stagger_133X74D3.lef \
##        /eda_files/proj/ict8810/backend/be8812/lef/L28_BOAC_op1_55_6um_stagger_50D8X74D3.lef \
##        /eda_files/proj/ict8810/backend/be8812/lef/L28_BOAC_op1_55_6um_stagger_65D3X74D3.lef \
##        /eda_files/proj/ict8810/backend/be8812/lef/L28_BOAC_op1_55_6um_stagger_pitch78_50D3X74D3.lef \
##        /eda_files/proj/ict8810/backend/be8812/lef_cut/CUTGD.lef \
##        /eda_files/proj/ict8810/backend/be8812/lef_cut/CUT_OSC.lef \
##    "
#	set lefs " $vars(TECH_NDR_LEF) $vars(LEF_7T_LIBS) $vars(LEF_9T_LIBS) $vars(LEF_RAM_LIBS) $vars(LEF_ROM_LIBS) $vars(LEF_IP_LIBS) $vars(LEF_IO_LIBS)"
#	set def ""
##	set FILL_WITHOUT_CAP "FILLSG*"
##	set FILL_WITH_CAP "DCAP64BWP7T40P140HVT DCAP32BWP7T40P140HVT DCAP16BWP7T40P140HVT DCAP8BWP7T40P140HVT DCAP4BWP7T40P140HVT"
##	set user_filler "$FILL_WITHOUT_CAP $FILL_WITH_CAP"
#	set eco_allow_filler_cells_as_open_sites true
#
#	set_eco_options \
#			-physical_tech_lib_path $tech \
#			-physical_lib_path $lefs \
#			-physical_design_path $def \
#			-log_file   load_lef_def.log
#			#-filler_cell_names $user_filler 
#
#    set eco_strict_pin_name_equivalence true ;# this must be set in slave session
#}
set eco_strict_pin_name_equivalence true
set_app_var eco_enable_mim true
#set eco_enable_more_scenarios_than_hosts true

## dont_touch
remote_execute {
#set_dont_touch [get_cell -hier *U_IP_BUF*]
#set_dont_touch [get_cell -hier *U_PORT_BUF*]
#set_dont_touch [get_cell -of [get_pin -l -of [get_net -of [get_ports *]]]]
#set_dont_touch [get_cell -hier *U_spare*]
    #
set_dont_touch  [get_nets -hierarchical -filter "full_name =~ *_iso_buffer_net_*"] true
set_dont_touch  [get_nets -of_objects [get_ports] -top -segments] true
set_dont_touch  [get_nets -of [get_pins -of [get_cells -hierarchical -filter "full_name =~ *ISO*"]]] true
set_dont_touch  [get_cells -hierarchical -filter "full_name =~ *_post_buf_data_*"] true
set_dont_touch  [get_cells -hierarchical -filter "full_name =~ *_pre_buf_data_*"] true
set_dont_touch  [get_cells -hierarchical -filter "full_name =~ *_pre_buf_clk_*"] true
set_dont_touch  [get_cells -hierarchical -filter "full_name =~ *_post_buf_clk_*"] true
set_dont_touch  [get_cells -hierarchical -filter "full_name =~ *_ISO_PORT_CLK_*"] true
set_dont_touch  [get_cells -hierarchical -filter "full_name =~ *_ISO_PORT_IN_*"] true
set_dont_touch  [get_cells -hierarchical -filter "full_name =~ *_ISO_PORT_OUT_*"] true

set_size_only [get_cells -q -hierarchical -filter "full_name =~ *__dont_touch__*"] true
}
#remote_execute {
#    set_dont_touch [get_cells {
#        chip_core_inst/lb_cpu_top_inst
#        chip_core_inst/np_top_inst/lb_eth_ge
#        chip_core_inst/usb_block_inst
#        chip_core_inst/lb_ddr4_top_inst
#        chip_core_inst/np_top_inst/lb_dp_ocb_top_u0
#        chip_core_inst/np_top_inst/pp_top_u0
#        chip_core_inst/pcie_block_inst
#        chip_core_inst/np_top_inst/lb_mge_pon_top_u0
#        chip_core_inst/np_top_inst/lb_se_tm_top_u0
#    }]
#}

## dont_use
remote_execute {
set timing_save_pin_attival_and_slack true
set eco_alternative_area_ratio_threshold 0
set_dont_use "*/*ZTUL* */*ZTUH* */*_X0* */*_X20* */*ECO* */*AND*_X11* */*AND*_X8* */*AO21A1AI2_X8* */*AOI21B_X8* */*AOI21_X11* */*AOI21_X8* */*AOI22BB_X8* */*AOI22_X11* */*AOI22_X8* */*AOI2XB1_X8* */*AOI31_X8* */*ENDCAP */FILL* */GP* */MXGL* */OA*_X8* */OR*_X11* */NOR*_X11* */OR*_X8* */NOR*_X8* */*SGCAP* "

update_timing
}

redirect -tee pre_global_timing.rpt {report_global_timing}

set S_PREFIX_S "[clock format [clock seconds] -format "%Y%m%d_%H%M%S"]"
set eco_report_unfixed_reason_max_endpoints 10000

#fix_eco_timing -pba_mode exhaustive  -type setup \
#                -slack_lesser_than 0 \
#				-slack_greater_than -2 \
#				-methods size_cell \
#				-cell_type combinational \
#				-hold_margin 0.01 \
#				-verbose \
#				-physical_mode open_site \
#				-to chip_core_inst/np_top_inst/pp_top_u0/proton_ro_top_u0/proton_ro_ofsm_u/para_out_r_reg_83_/D
return
### fix power
#fix_eco_power -setup_margin 0.05 -pattern_priority {40P140HVT 35P140HVT 30P140HVT 40P140 35P140 30P140} -verbose
#remote_execute {write_changes -format icctcl -output ./fix_power.swap.tcl}
#remote_execute {write_changes -reset}
#remote_execute {
#	define_user_attribute vt_group -type string -class lib_cell
#	set_user_attribute [get_lib_cells */*40P140HVT] vt_group 40hvt
#	set_user_attribute [get_lib_cells */*40P140] vt_group 40svt
#	set_user_attribute [get_lib_cells */*35P140HVT] vt_group 35hvt
#	set_user_attribute [get_lib_cells */*35P140] vt_group 35svt
#	set_user_attribute [get_lib_cells */*30P140HVT] vt_group 30hvt
#	set_user_attribute [get_lib_cells */*30P140] vt_group 30svt
#	set eco_alternative_cell_attribute_restrictions "vt_group"
#}
#fix_eco_power -setup_margin 0.05 -verbose
#remote_execute {write_changes -format icctcl -output ./fix_power.sizedown.tcl}
#remote_execute {write_changes -reset}
 
### fix drc
#remote_execute {update_timing}
#set eco_instance_name_prefix "eco_tran_cell_${S_PREFIX_S}"
#set eco_net_name_prefix      "eco_tran_net_${S_PREFIX_S}"
#fix_eco_drc -type max_transition -methods { size_cell } -setup_margin 0.02 -verbose
##fix_eco_drc -type max_transition -methods { size_cell } -setup_margin 0.02 -buffer_list "BUFFD8BWP7T40P140HVT BUFFD12BWP7T40P140HVT" -verbose -physical_mode open_site
#set eco_instance_name_prefix "eco_cap_cell_${S_PREFIX_S}"
#set eco_net_name_prefix      "eco_cap_net_${S_PREFIX_S}"
#fix_eco_drc -type max_capacitance -methods { size_cell} -setup_margin 0.02  -verbose
##fix_eco_drc -type max_capacitance -methods { size_cell insert_buffer } -setup_margin 0.02 -buffer_list "BUFFD8BWP7T40P140HVT BUFFD12BWP7T40P140HVT" -verbose -physical_mode open_site
#
#remote_execute {write_changes -format icctcl -output ./fix_drc.tcl}
#remote_execute {write_changes -reset}
#
#
#### fix setup
#remote {set eco_alternative_cell_attribute_restrictions "area"}
#remote_execute {update_timing}
##set eco_alternative_area_ratio_threshold 1
#set eco_instance_name_prefix "eco_setup_cell_${S_PREFIX_S}"
#set eco_net_name_prefix      "eco_setup_net_${S_PREFIX_S}"
#
#
#fix_eco_timing -pba_mode path  -type setup \
#                -slack_lesser_than 0 \
#				-slack_greater_than -2 \
#				-methods size_cell \
#				-cell_type combinational \
#				-hold_margin 0.01 \
#				-verbose \
#				-physical_mode open_site
#				#-group {ddrpllclk sspllclk bcpuclk bhvcclk bimeclk bjpgclk bmclk bvclk2 bvclk3 bvclk4 *clock_gating*}
#remote_execute {write_changes -format icctcl -output ./fix_setup.tcl}
#remote_execute {write_changes -reset}
#_report_qor_dmsa -name fix_setup

## fix hold
#remote_execute {update_timing}
set eco_instance_name_prefix eco_hold_${S_PREFIX_S}
set eco_net_name_prefix eco_hold_net_${S_PREFIX_S}
#set S_ECOFixBufList_L "DEL150MD1BWP7T40P140HVT DEL100MD1BWP7T40P140HVT DEL075MD1BWP7T40P140HVT DEL050MD1BWP7T40P140HVT DEL025D1BWP7T40P140HVT BUFFD1BWP7T40P140HVT BUFFD2BWP7T40P140HVT BUFFD3BWP7T40P140HVT"
set S_ECOFixBufList_L "DEL025D1BWP7T40P140HVT BUFFD1BWP7T40P140HVT BUFFD2BWP7T40P140HVT"
#set S_ECOFixBufList_L "BUFFD1BWP7T40P140HVT BUFFD2BWP7T40P140HVT BUFFD3BWP7T40P140HVT BUFFD4BWP7T40P140HVT"
set S_ECOFixBufList_L {
DLY4_X1M_A7PP140ZTS_C40  DLY4_X2M_A7PP140ZTS_C40  DLY4_X4M_A7PP140ZTS_C40 \
DLY2_X1M_A7PP140ZTS_C40  DLY2_X2M_A7PP140ZTS_C40  DLY2_X4M_A7PP140ZTS_C40 \
DLY4_X1M_A7PP140ZTS_C35  DLY4_X2M_A7PP140ZTS_C35  DLY4_X4M_A7PP140ZTS_C35 \
DLY2_X1M_A7PP140ZTS_C35  DLY2_X2M_A7PP140ZTS_C35  DLY2_X4M_A7PP140ZTS_C35 \ 
DLY4_X1M_A7PP140ZTS_C30  DLY4_X2M_A7PP140ZTS_C30  DLY4_X4M_A7PP140ZTS_C30 \
DLY2_X1M_A7PP140ZTS_C30  DLY2_X2M_A7PP140ZTS_C30  DLY2_X4M_A7PP140ZTS_C30 \ 
BUF_X1P7M_A7PP140ZTH_C40 BUF_X1P7B_A7PP140ZTH_C40 BUF_X1P4M_A7PP140ZTH_C40 BUF_X1P4B_A7PP140ZTH_C40 BUF_X1M_A7PP140ZTH_C40 BUF_X1B_A7PP140ZTH_C40 BUF_X2M_A7PP140ZTH_C40 BUF_X2B_A7PP140ZTH_C40 \
BUF_X1P7M_A7PP140ZTH_C35 BUF_X1P7B_A7PP140ZTH_C35 BUF_X1P4M_A7PP140ZTH_C35 BUF_X1P4B_A7PP140ZTH_C35 BUF_X1M_A7PP140ZTH_C35 BUF_X1B_A7PP140ZTH_C35 BUF_X2M_A7PP140ZTH_C35 BUF_X2B_A7PP140ZTH_C35 \
BUF_X1P7M_A7PP140ZTH_C30 BUF_X1P7B_A7PP140ZTH_C30 BUF_X1P4M_A7PP140ZTH_C30 BUF_X1P4B_A7PP140ZTH_C30 BUF_X1M_A7PP140ZTH_C30 BUF_X1B_A7PP140ZTH_C30 BUF_X2M_A7PP140ZTH_C30 BUF_X2B_A7PP140ZTH_C30 \
BUF_X1P7M_A7PP140ZTS_C40 BUF_X1P7B_A7PP140ZTS_C40 BUF_X1P4M_A7PP140ZTS_C40 BUF_X1P4B_A7PP140ZTS_C40 BUF_X1M_A7PP140ZTS_C40 BUF_X1B_A7PP140ZTS_C40 BUF_X2M_A7PP140ZTS_C40 BUF_X2B_A7PP140ZTS_C40 \
BUF_X1P7M_A7PP140ZTS_C35 BUF_X1P7B_A7PP140ZTS_C35 BUF_X1P4M_A7PP140ZTS_C35 BUF_X1P4B_A7PP140ZTS_C35 BUF_X1M_A7PP140ZTS_C35 BUF_X1B_A7PP140ZTS_C35 BUF_X2M_A7PP140ZTS_C35 BUF_X2B_A7PP140ZTS_C35 \
BUF_X1P7M_A7PP140ZTS_C30 BUF_X1P7B_A7PP140ZTS_C30 BUF_X1P4M_A7PP140ZTS_C30 BUF_X1P4B_A7PP140ZTS_C30 BUF_X1M_A7PP140ZTS_C30 BUF_X1B_A7PP140ZTS_C30 BUF_X2M_A7PP140ZTS_C30 BUF_X2B_A7PP140ZTS_C30 \
DLY4_X1M_A9PP140ZTS_C40  DLY4_X2M_A9PP140ZTS_C40  DLY4_X4M_A9PP140ZTS_C40 \
DLY2_X1M_A9PP140ZTS_C40  DLY2_X2M_A9PP140ZTS_C40  DLY2_X4M_A9PP140ZTS_C40 \
DLY4_X1M_A9PP140ZTS_C35  DLY4_X2M_A9PP140ZTS_C35  DLY4_X4M_A9PP140ZTS_C35 \
DLY2_X1M_A9PP140ZTS_C35  DLY2_X2M_A9PP140ZTS_C35  DLY2_X4M_A9PP140ZTS_C35 \ 
DLY4_X1M_A9PP140ZTS_C30  DLY4_X2M_A9PP140ZTS_C30  DLY4_X4M_A9PP140ZTS_C30 \
DLY2_X1M_A9PP140ZTS_C30  DLY2_X2M_A9PP140ZTS_C30  DLY2_X4M_A9PP140ZTS_C30 \ 
BUF_X1P7M_A9PP140ZTS_C40 BUF_X1P7B_A9PP140ZTS_C40 BUF_X1P4M_A9PP140ZTS_C40 BUF_X1P4B_A9PP140ZTS_C40 BUF_X1M_A9PP140ZTS_C40 BUF_X1B_A9PP140ZTS_C40 BUF_X2M_A9PP140ZTS_C40 BUF_X2B_A9PP140ZTS_C40 \
BUF_X1P7M_A9PP140ZTS_C35 BUF_X1P7B_A9PP140ZTS_C35 BUF_X1P4M_A9PP140ZTS_C35 BUF_X1P4B_A9PP140ZTS_C35 BUF_X1M_A9PP140ZTS_C35 BUF_X1B_A9PP140ZTS_C35 BUF_X2M_A9PP140ZTS_C35 BUF_X2B_A9PP140ZTS_C35 \
BUF_X1P7M_A9PP140ZTS_C30 BUF_X1P7B_A9PP140ZTS_C30 BUF_X1P4M_A9PP140ZTS_C30 BUF_X1P4B_A9PP140ZTS_C30 BUF_X1M_A9PP140ZTS_C30 BUF_X1B_A9PP140ZTS_C30 BUF_X2M_A9PP140ZTS_C30 BUF_X2B_A9PP140ZTS_C30 \
BUF_X1P7M_A9PP140ZTH_C40 BUF_X1P7B_A9PP140ZTH_C40 BUF_X1P4M_A9PP140ZTH_C40 BUF_X1P4B_A9PP140ZTH_C40 BUF_X1M_A9PP140ZTH_C40 BUF_X1B_A9PP140ZTH_C40 BUF_X2M_A9PP140ZTH_C40 BUF_X2B_A9PP140ZTH_C40 \
BUF_X1P7M_A9PP140ZTH_C35 BUF_X1P7B_A9PP140ZTH_C35 BUF_X1P4M_A9PP140ZTH_C35 BUF_X1P4B_A9PP140ZTH_C35 BUF_X1M_A9PP140ZTH_C35 BUF_X1B_A9PP140ZTH_C35 BUF_X2M_A9PP140ZTH_C35 BUF_X2B_A9PP140ZTH_C35 \
BUF_X1P7M_A9PP140ZTH_C30 BUF_X1P7B_A9PP140ZTH_C30 BUF_X1P4M_A9PP140ZTH_C30 BUF_X1P4B_A9PP140ZTH_C30 BUF_X1M_A9PP140ZTH_C30 BUF_X1B_A9PP140ZTH_C30 BUF_X2M_A9PP140ZTH_C30 BUF_X2B_A9PP140ZTH_C30 \
}
set cts_list {BUF_X4B_A7PP140ZTL_C30 BUF_X6B_A7PP140ZTL_C30 BUF_X7P5B_A7PP140ZTL_C30 BUF_X9B_A7PP140ZTL_C30 BUF_X11B_A7PP140ZTL_C30 BUF_X13B_A7PP140ZTL_C30 BUF_X16B_A7PP140ZTL_C30}

fix_eco_timing -pba_mode exhaustive  -type hold \
                -setup_margin 0.02       \
                -hold_margin 0 \
                -buffer_list $cts_list \
                -cell_type clock_network \
                -clock_max_level_from_reg 20 \
                -methods {size_cell insert_buffer_at_load_pins} \
                -max_iteration 5 \
                -verbose  -physical_mode none

redirect -tee post_global_timing.rpt {report_global_timing}

remote_execute {write_changes -format icctcl -output ./fix_hold.tcl}
remote_execute {write_changes -reset}
#_report_qor_dmsa -name fix_hold


sh touch ../rpt/out.finish
#report_constraint -all -nosplit > ../rpt/dmsa.all_violation_fixtiming.rpt.${S_PREFIX_S}

