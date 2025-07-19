set scripts_dir  "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/release/invs_check/design_invs.tcl"

set proj_name                                   "ict8810"
set design_name                                 [dbgDesignName]
set dont_use_lib_cells                          $vars(dont_use_cells)
set size_only_list                              $vars(func_dontch_list)
set dont_touch_list                             ""
set vt_groups                                   "HVT *ZTH_* SVT *ZTS_* LVT *ZTL_* uLVT *TUL_*"

set pclamp_core_h                               "VESDC09GH"
set pclamp_core_v                               "VESDC09GV"
set dtcd_cell_name                              "NA"

set check_run_dir_rule_name                     "1"
set flow_check_missing_lef_exit                 "1"
set flow_check_missing_timing_exit              "1"
set flow_check_group_path                       "1"
set flow_check_ports_status                     "1"
set flow_check_init_ilm                         "0"
set check_sdc_quality                           "1"
set check_empty_softblk_area_in_channel         "1"
set flow_fix_empty_softblk_area_in_channel      "0"
set insert_decap_around_iso_buffer         	    "0"

set check_data_net_max_length                 	"400"
set check_clock_net_max_length                	"350"
set check_tie_net_max_length                  	"30"
set check_tie_net_max_fanout                  	"10"
set check_macro_iso_max_length                  "50"
set check_iso_max_length                      	"50"
set check_blkage_in_boundary_length             "0.28"
set report_shielding                            "1"
set check_pg_missing_via                        "1"

#set generate_timing_summary                   "1"
#set generate_timing_budget_file               "0"
#set check_clock_cell_type                     "0"
#


#---------------------------------------------------------------------------------------------------------------------------
set enc_source_continue_on_error             1
source $scripts_dir/design_invs.tcl
# gen timing summary
source -e -v /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/script/invs_parse_timing_rpt/parse_timing_rpts_invs.tcl

#---------------------------------------------------------------------------------------------------------------------------
set post_plugins_start_runtime  [clock seconds]
#um::pop_snapshot_stack
#create_snapshot -name $vars(step) -categories design
#######################################################################################################################
##  Common check
# 1. report utilication
design::reportUtilization                                  -file $vars(rpt_dir)/$design_name.report_utilication.rpt
# 2. report vt usage
design::report_vt_usage                                    -file $vars(rpt_dir)/$design_name.report_vt_usage.rpt
# 3. report multi-Bit
redirect  -file $vars(rpt_dir)/$design_name.report_mbdff.status.rpt   {reportMultiBitFFs -statistics}

###### init
if {$vars(step) == "init"} {
    #######################################################################################################################

    # 1. check run name 
    if {![info exists check_run_dir_rule_name] || $check_run_dir_rule_name == 1} {
        set netlist     [lindex [split $vars(view_rpt) _] 0]
        set sdc         [lindex [split $vars(view_rpt) _] 1]
        set floorplan   [lindex [split $vars(view_rpt) _] 2]
        if {![regexp V $netlist] || ![regexp S $sdc] || ![regexp FP $floorplan]} {
            puts "DESIGN::INFO: view_rpt:$env(view_rpt)"
            puts "\nDESIGN::INFO: ERROR, Your run name not flow the name rule , eg : V1008_S1008_FP1008_xxx\n"
            exit
        }
    }

    # 2. if design have the cell that missing lef , invs will exit
    design::check_missing_lef                              -file $vars(rpt_dir)/$design_name.check_missing_lef.rpt
    if {![info exists flow_check_missing_lef_exit] || $flow_check_missing_lef_exit == 1} {
        design::check_error_exit                           -file $vars(rpt_dir)/$design_name.check_missing_lef.rpt
    }

    # 3. if design have the cell that missing timing information , invs will exit
    design::check_missing_timing_library                   -file $vars(rpt_dir)/$design_name.check_missing_timing_library.rpt
    if {![info exists flow_check_missing_timing_exit] || $flow_check_missing_timing_exit == 1} {
        design::check_error_exit                           -file $vars(rpt_dir)/$design_name.check_missing_timing_library.rpt
    }

    # 4. check macro status , if have unplaced or placed status macro , invs will exit
    design::summary_macro_pstatus                          -file $vars(rpt_dir)/$design_name.check_macro_pstatus.rpt
    design::check_error_exit                               -file $vars(rpt_dir)/$design_name.check_macro_pstatus.rpt

    # 5. check in2reg / reg2out group paths if any "NA"
    if {![info exists flow_check_group_path] || $flow_check_group_path == 1} {
        if {[get_metric timing.setup.feps.path_group:in2reg] == "" || [get_metric timing.setup.feps.path_group:reg2out] == ""} {
            puts "\nDM::INFO: ERROR, your design no define in2reg and reg2out group or No constrained timing paths found, please check your init.summary.gz\n"
        }
    }

    # 6. check ILM mode in init stage , if yes exit
    if {![info exists flow_check_init_ilm] || $flow_check_init_ilm == 1} {
        if {[get_db is_ilm_flattened] == "true"} {
            puts "DM::INFO: ERROR, Please dont't read ilm at init stage , and you can read ilm at place stage"
        }
    }

    # 7. check ports status , if design ports have unplaced , invs will exit
    if {![info exists flow_check_ports_status] || $flow_check_ports_status == 1} {
        design::check_ports_status                         -file $vars(rpt_dir)/$design_name.check_ports_status.rpt
    }

    # 8. check netlist input floating and net multi-driver
    design::check_input_floating                           -file $vars(rpt_dir)/$design_name.check_input_floating.rpt

    # 9. check invs log error
    design::check_log_error -check_log_error               -file $vars(rpt_dir)/check_log_error.rpt

    # 10. check sdc quality
    if {![info exists check_sdc_quality] || $check_sdc_quality == 1} {
        design::check_sdc_quality                          -file $vars(rpt_dir)/$design_name.check_sdc_quality.rpt
    }

    # 11. check and add sofo blockage in memory channel
    if {[info exists check_empty_softblk_area_in_channel] &&  $check_empty_softblk_area_in_channel == 1} {
        design::check_empty_softblk_area_in_channel        -file $vars(rpt_dir)/$design_name.check_empty_softblk_area_in_channel.rpt
    }
    #if {[info exists flow_fix_empty_softblk_area_in_channel] &&  $flow_fix_empty_softblk_area_in_channel == 1} {
    #    design::fix_empty_softblk_area_in_channel          -file $vars(rpt_dir)/$design_name.fix_empty_softblk_area_in_channel.rpt
    #}

    # 12. check place
    redirect -file $vars(rpt_dir)/$design_name.check_place.rpt  {checkPlace}

    # 13. check unique
    redirect -file $vars(rpt_dir)/$design_name.check_unique.rpt  {checkUnique}

    # 14. check library
    check_library -place -file $vars(rpt_dir)/$design_name.check_librarys.rpt

    # 15. check dont use
    design::check_dont_use_cell -dont_use_list $dont_use_lib_cells -file $vars(rpt_dir)/$design_name.check_dont_use_cell.rpt

    # 16. report multi-bit 
    design::report_multi_bit_dff                           -file $vars(rpt_dir)/$design_name.report_multi_bit_dff.rpt

    # 17. check memort
    design::check_memory_orient                            -file $vars(rpt_dir)/$design_name.check_memory_orient.rpt

    # 18. check pclamp and dtcd
    design::check_floorplan_insert_pclamp_dtcd -dtcd_cell $dtcd_cell_name -pclamp_cell "$pclamp_core_h $pclamp_core_v" -file $vars(rpt_dir)/$design_name.check_pclamp_dtcd_in_floorplan.rpt

    # 19. check dont touch and sizeOnly
    if {$size_only_list != ""} {
        design::check_size_only -initial_file $vars(func_dontch_list) -file $vars(rpt_dir)/$design_name.init.size_only.rpt
    }
    if {$dont_touch_list != ""} {
        design::check_dont_touch -initial_file $vars(func_dontch_list) -file $vars(rpt_dir)/init.dont_touch.rpt
    }

    # 20. add spare cell 
    source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/common_script/add_spare_cell.tcl

    # 21. check none fixed mask
#    design::check_none_fixed_mask                          -file $vars(rpt_dir)/$design_name.check_none_fixed_mask.rpt

    # 22. check block ports (width spacing and not in DPT layer)
    design::check_block_ports  -clock -data       -file $vars(rpt_dir)/$design_name.check_block_ports.rpt

    # 23. check all clock ports distribution for better clock quality (func scan)
    design::check_clock_ports_distance -distance 50.0      -file $vars(rpt_dir)/$design_name.check_clock_ports_distance.rpt

    # 24. check pin assignment
    checkPinAssignment -outFile $vars(rpt_dir)/$design_name.check_PinAssignment.rpt
    # 25. check routing blkage in boundary
	design::check_blkage_in_boundary -insideBlockRoutingBlockage $check_blkage_in_boundary_length -file $vars(rpt_dir)/$design_name.check_blkage_in_boundary.rpt
} elseif {$vars(step) == "place"} {
    #######################################################################################################################
    # 1. check invs log error
    design::check_log_error -check_log_error               -file $vars(rpt_dir)/$design_name.check_log_error.rpt

    # 2. check place 
    redirect -file $vars(rpt_dir)/$design_name.check_place.rpt  {checkPlace}

    # 3. multi bit
    design::report_multi_bit_dff                           -file $vars(rpt_dir)/$design_name.report_multi_bit_dff.rpt

    # 4. check cell legal  
    design::check_cell_legal_location                      -file $vars(rpt_dir)/$design_name.check_cell_legal_location.rpt
    # 5. if design have the cell that missing lef , invs will exit
    design::check_missing_lef                              -file $vars(rpt_dir)/$design_name.check_missing_lef.rpt
    if {![info exists flow_check_missing_lef_exit] || $flow_check_missing_lef_exit == 1} {
        design::check_error_exit                           -file $vars(rpt_dir)/$design_name.check_missing_lef.rpt
    }

    # 6. if design have the cell that missing timing information , invs will exit
    design::check_missing_timing_library                   -file $vars(rpt_dir)/$design_name.check_missing_timing_library.rpt
    if {![info exists flow_check_missing_timing_exit] || $flow_check_missing_timing_exit == 1} {
        design::check_error_exit                           -file $vars(rpt_dir)/$design_name.check_missing_timing_library.rpt
    }
} elseif {$vars(step) == "cts"} {
    #######################################################################################################################
    # 1. check log error
    design::check_log_error -check_log_error               -file $vars(rpt_dir)/$design_name.check_log_error.rpt

    # 2. 
    design::report_multi_bit_dff                           -file $vars(rpt_dir)/$design_name.report_multi_bit_dff.rpt
    # 3.
    redirect -file $vars(rpt_dir)/$design_name.check_place.rpt  {checkPlace}
    # 4.
    design::check_clock_tree_quality -clock_output_ports   -file $vars(rpt_dir)/$design_name.check_clock_tree_quality.rpt
    # 5. 
    design::check_clock_mux_s_in_tree                      -file $vars(rpt_dir)/$design_name.check_clock_mux_s_in_clock_tree.rpt

    # 6. 
    design::check_net_length -clock_max_length $check_clock_net_max_length -data_max_length $check_data_net_max_length -file $vars(rpt_dir)/$design_name.check_net_length.rpt
    # 7. if design have the cell that missing lef , invs will exit
    design::check_missing_lef                              -file $vars(rpt_dir)/$design_name.check_missing_lef.rpt
    if {![info exists flow_check_missing_lef_exit] || $flow_check_missing_lef_exit == 1} {
        design::check_error_exit                           -file $vars(rpt_dir)/$design_name.check_missing_lef.rpt
    }

    # 8. if design have the cell that missing timing information , invs will exit
    design::check_missing_timing_library                   -file $vars(rpt_dir)/$design_name.check_missing_timing_library.rpt
    if {![info exists flow_check_missing_timing_exit] || $flow_check_missing_timing_exit == 1} {
        design::check_error_exit                           -file $vars(rpt_dir)/$design_name.check_missing_timing_library.rpt
    }
	# 9.
	design::check_clock_ndr                                -file $vars(rpt_dir)/$design_name.check_clock_ndr.rpt
} elseif {$vars(step) == "route"} {
    #######################################################################################################################
    # 1. check log error
    design::check_log_error -check_log_error               -file $vars(rpt_dir)/$design_name.check_log_error.rpt
    # 2. report clock skew
    report_ccopt_skew_groups -local_skew -summary          -file $vars(rpt_dir)/$design_name.ccopt_skew_groups.summary
    # 3. 
    design::report_multi_bit_dff                           -file $vars(rpt_dir)/$design_name.report_multi_bit_dff.rpt
    # 4
    redirect -file $vars(rpt_dir)/$design_name.check_place.rpt  {checkPlace}
    # 5. if design have the cell that missing lef , invs will exit
    design::check_missing_lef                              -file $vars(rpt_dir)/$design_name.check_missing_lef.rpt
    if {![info exists flow_check_missing_lef_exit] || $flow_check_missing_lef_exit == 1} {
        design::check_error_exit                           -file $vars(rpt_dir)/$design_name.check_missing_lef.rpt
    }

    # 6. if design have the cell that missing timing information , invs will exit
    design::check_missing_timing_library                   -file $vars(rpt_dir)/$design_name.check_missing_timing_library.rpt
    if {![info exists flow_check_missing_timing_exit] || $flow_check_missing_timing_exit == 1} {
        design::check_error_exit                           -file $vars(rpt_dir)/$design_name.check_missing_timing_library.rpt
    }
} elseif {$vars(step) == "postroute"} {
    #######################################################################################################################
    # 1. check log error
    design::check_log_error -check_log_error               -file $vars(rpt_dir)/$design_name.check_log_error.rpt
    # 2.
    redirect -file $vars(rpt_dir)/$design_name.check_place.rpt  {checkPlace}
    # 3. 
    design::report_multi_bit_dff                           -file $vars(rpt_dir)/$design_name.report_multi_bit_dff.rpt
    # 4. check cell legal  
    design::check_cell_legal_location                      -file $vars(rpt_dir)/$design_name.check_cell_legal_location.rpt
    # 5. 
    design::timing_budget_blkGen                           -file $vars(rpt_dir)/$design_name.timing_budget_blkGen.rpt
    # 6. if design have the cell that missing lef , invs will exit
    design::check_missing_lef                              -file $vars(rpt_dir)/$design_name.check_missing_lef.rpt
    if {![info exists flow_check_missing_lef_exit] || $flow_check_missing_lef_exit == 1} {
        design::check_error_exit                           -file $vars(rpt_dir)/$design_name.check_missing_lef.rpt
    }

    # 7. if design have the cell that missing timing information , invs will exit
    design::check_missing_timing_library                   -file $vars(rpt_dir)/$design_name.check_missing_timing_library.rpt
    if {![info exists flow_check_missing_timing_exit] || $flow_check_missing_timing_exit == 1} {
        design::check_error_exit                           -file $vars(rpt_dir)/$design_name.check_missing_timing_library.rpt
    }
} elseif {$vars(step) == "ecopr"} {
    #######################################################################################################################
    # 1. check log error
    design::check_log_error -check_log_error               -file $vars(rpt_dir)/$design_name.check_log_error.rpt
	# 2. dfm vias
	redirect -file $vars(rpt_dir)/$design_name.check_DFM_vias_status.rpt  {report_route -multi_cut}
    # 3.
    redirect -file $vars(rpt_dir)/$design_name.check_place.rpt  {checkPlace}
    # 4. check filler
    redirect -file $vars(rpt_dir)/$design_name.check_filler.rpt  {checkFiller}
    # 5. check netlist input floating and net multi-driver
    design::check_input_floating                           -file $vars(rpt_dir)/$design_name.check_input_floating.rpt
    # 6. report multi-bit 
    design::report_multi_bit_dff                           -file $vars(rpt_dir)/$design_name.report_multi_bit_dff.rpt
	# 7. 
	design::check_tie_cell -check_tie_net_length $check_tie_net_max_length -check_tie_net_fanout $check_tie_net_max_fanout -file $vars(rpt_dir)/$design_name.check_tie_cell.rpt
    # 8. check cell legal  
    design::check_cell_legal_location                      -file $vars(rpt_dir)/$design_name.check_cell_legal_location.rpt
	# 9.  
	design::check_macro_iso_buffer -max_length $check_macro_iso_max_length -file $vars(rpt_dir)/$design_name.check_macro_iso_buffer.rpt
	# 10. special waive list file
	design::check_iso_buffer -max_length $check_iso_max_length -file $vars(rpt_dir)/$design_name.check_iso_buffer.rpt
    # 12. check dont use
    design::check_dont_use_cell -dont_use_list $dont_use_lib_cells -file $vars(rpt_dir)/$design_name.check_dont_use_cell.rpt
	# 13. check dont touch and sizeOnly 
	if {[file exist $vars(rpt_dir)/../../init/$vars(view_rpt)/$design_name.init.size_only.rpt]} {
		design::check_size_only -size_only_file $vars(rpt_dir)/../../init/$vars(view_rpt)/$design_name.init.size_only.rpt -file $vars(rpt_dir)/$design_name.check_size_only.rpt
	}
    # 14. check block ports (width spacing)
    design::check_block_ports  -clock -data       -file $vars(rpt_dir)/$design_name.check_block_ports.rpt
	# 15. 
	design::check_blkage_in_boundary -insideBlockRoutingBlockage $check_blkage_in_boundary_length -file $vars(rpt_dir)/$design_name.check_blkage_in_boundary.rpt
	# 16. 
	if {$report_shielding == 1} {
        redirect -file $vars(rpt_dir)/$design_name.report_shieldint.rpt  {reportShield}
	}
	# 17.
	if {$check_pg_missing_via == 1} {
	    redirect -file $vars(rpt_dir)/$design_name.check_pg_missing_via.rpt {verifyPowerVia -error 9999}
	}
	# 19.
	design::check_clock_ndr                                -file $vars(rpt_dir)/$design_name.check_clock_ndr.rpt
    # 20. 
    design::check_net_length -clock_max_length $check_clock_net_max_length -data_max_length $check_data_net_max_length -file $vars(rpt_dir)/$design_name.check_net_length.rpt
    # 21. if design have the cell that missing lef , invs will exit
    design::check_missing_lef                              -file $vars(rpt_dir)/$design_name.check_missing_lef.rpt
    if {![info exists flow_check_missing_lef_exit] || $flow_check_missing_lef_exit == 1} {
        design::check_error_exit                           -file $vars(rpt_dir)/$design_name.check_missing_lef.rpt
    }

    # 22. if design have the cell that missing timing information , invs will exit
    design::check_missing_timing_library                   -file $vars(rpt_dir)/$design_name.check_missing_timing_library.rpt
    if {![info exists flow_check_missing_timing_exit] || $flow_check_missing_timing_exit == 1} {
        design::check_error_exit                           -file $vars(rpt_dir)/$design_name.check_missing_timing_library.rpt
    }
    # 23.
    redirect -file $vars(rpt_dir)/$design_name.check_unique.rpt  {checkUnique}
    # 24. dont touch
    design::get_dont_touch_object -known_net_prefix { _iso_buffer_net_ } -file $vars(rpt_dir)/get_dont_touch_object.rpt

	

}
redirect  -file $vars(rpt_dir)/global_runtime.rpt   {runTime global_post $post_plugins_start_runtime}
