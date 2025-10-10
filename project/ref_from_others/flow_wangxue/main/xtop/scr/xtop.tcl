########################################
# author: llsun
# Date: 2022/11/03 18:27:22
# Version: 1.0
# xtop main script for timing eco
########################################
set version $env(DATAOUT_VERSION)
set scenarios "scan_ssm40_cworst_T func_ssm40_2p5vio_cworst_T scan_ff125_rcworst scan_ff125_cbest func_ff125_2p5vio_rcworst func_ff125_2p5vio_cbest func_ssm40_1p8vio_rcworst_T func_ss125_2p5vio_cworst_T func_ff125_1p8vio_rcworst func_ff125_1p8vio_cbest func_ssm40_0p8std_cworst_T func_ssm40_0p8std_cworst " 
set FIX_DRV "true"
set FIX_SETUP "true"
set FIX_HOLD "true"
set FIX_LKG "false"
set EFFORT "high" ;#low medium high ultra_high extreme_high

set PBA_MODE "false"

set prefix [exec date +%m%d%H%M]


#source ../common_setup.tcl

set vars(top_or_block) top

source /home/user3/project/CX200UR1/lib_conf/lib_setup.tcl
 
set vars(dont_use_cells) "*D0BWP* *D1BWP* *D20BWP*  ISOSR* PT* .*35P140$"
#set vars(dont_use_cells) "*D0BWP* *D1BWP* *D20BWP*  ISOSR* PT* *LVT .*35P140$"

set vars(dont_touch_files) "/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/fm/dont_touch.tcl"

set_parameter max_thread_number {8}
# Create Workspace
create_workspace work/${version} -overwrite 
link_reference_library -format lef "$vars(lef_files)"

# Auto create design for physical hierarchical design
#if {$vars(top_or_block) == "top" && $vars(isFlatten) == "true"} {
#	set subs [glob -tails -types d -path ../dataout/${version}/sub/ * ]
#	set netlists ""
#	set defs ""
#	foreach sub $subs {
#		lappend  netlists "../dataout/${version}/sub/${sub}/netlist/${sub}.pr.v.gz"
#		lappend  defs "../dataout/${version}/sub/${sub}/def/${sub}.pr.def.gz"
#	}
#	lappend netlists "../dataout/${version}/netlist/$vars(design).pr.v.gz"
#	lappend defs "../dataout/${version}/def/$vars(design).pr.def.gz"
#	define_designs -verilogs $netlists -defs $defs
#} else {
define_designs -verilogs "/home95/user3/project/CX200UR1/CX250UR1_SOC_TOP/dataout/$env(DATAOUT_VERSION)/netlist/CX250UR1_SOC_TOP.pr.v.gz" -defs "/home95/user3/project/CX200UR1/CX250UR1_SOC_TOP/dataout/$env(DATAOUT_VERSION)/def/CX250UR1_SOC_TOP.pr.def.gz"

#}

# Set site map
#set_site_map {unit core12T}
#set_site_map -design blockA {unit core9T}
#set_site_map -design blockB {unit core6T}

# Import design date
import_designs

# Import power domain information
#import_power_domain -design "top" -upf_file "top.upf" -region_file "top.pd"
#import_power_domain -design "blockA" -upf_file "blockA.upf" -region_file "blockA.pd"

#import_power_domain -design "CX250UR1_SOC_TOP" -upf_file "/process/TSMC28/projects/CX200UR1/frontend/upf/cx200_ur1.upf"

# Check placement readiness
check_placement_readiness

# Save workspace
save_workspace


# Create corner/mode/scenario
set modes ""
set corners ""
foreach scenario $scenarios {
	regexp {([^_]*)_(.*)} $scenario dummy mode corner
	lappend modes $mode
	lappend corners $corner
}
set modes [lsort -u $modes]
set corners [lsort -u $corners]

foreach mode $modes {
	create_mode $mode
}
foreach corner $corners {
	create_corner $corner
}
foreach scenario $scenarios {
	regexp {([^_]*)_(.*)} $scenario dummy mode corner
	create_scenario -corner $corner -mode $mode $scenario
}

foreach corner $corners {
	regexp {([^_]*)_.*} $corner dummy libset
	if {$vars(top_or_block) == "top" } {
		#add all libs
#		set allLibs [concat $vars(CCS_LIBS_[string toupper ${libset}]) $vars(CCS_STDCELL_7T_0P8_[string toupper ${libset}]) $vars(CCS_IP_0P8_[string toupper ${libset}])]
		#set allLibs [concat $vars(tt_85_2p5io,timing)]
		#link_timing_library -corner $corner -search_type min_max $allLibs
                if {[regexp tt $corner]} {
                  if {[regexp 3v3vio $$corner aa bb]} {                
                  set allLibs [concat $vars(tt_85_3v3io,timing)]
                  } elseif {[regexp 2p5vio $$corner aa bb]} {
                  set allLibs [concat $vars(tt_85_2p5io,timing)] 
                  } elseif {[regexp 1p8vio $$corner aa bb]} {
                  set allLibs [concat $vars(tt_85_1p8io,timing)]
                  } else {
                  set allLibs [concat $vars(tt_85_0p8std,timing)]
                  } 
                 } elseif {[regexp ssm40 $corner]} {
                  if {[regexp 3v3vio $$corner aa bb]} {                
                  set allLibs [concat $vars(ssm40_3v3io,timing)]
                  } elseif {[regexp 2p5vio $$corner aa bb]} {
                  set allLibs [concat $vars(ssm40_2p5io,timing)] 
                  } elseif {[regexp 1p8vio $$corner aa bb]}  {
                  set allLibs [concat $vars(ssm40_1p8io,timing)]
                  } else {
                  set allLibs [concat $vars(ssm40_0p8std,timing)]
                  } 
                 } elseif {[regexp ss125 $corner]} {
                  if {[regexp 3v3vio $$corner aa bb]} {                
                  set allLibs [concat $vars(ss125_3v3io,timing)]
                  } elseif {[regexp 2p5vio $$corner aa bb]} {
                  set allLibs [concat $vars(ss125_2p5io,timing)] 
                  } elseif  {[regexp 1p8vio $$corner aa bb]} {
                  set allLibs [concat $vars(ss125_1p8io,timing)]
                  } else {
                  set allLibs [concat $vars(ss125_0p8std,timing)]
                  }  
                 } elseif {[regexp ffm40 $corner]} {
                  if {[regexp 3v3vio $$corner aa bb]} {                
                  set allLibs [concat $vars(ffm40_3v3io,timing)]
                  } elseif {[regexp 2p5vio $$corner aa bb]} {
                  set allLibs [concat $vars(ffm40_2p5io,timing)] 
                  } elseif  {[regexp 1p8vio $$corner aa bb]}  {
                  set allLibs [concat $vars(ffm40_1p8io,timing)]
                  } else {
                  set allLibs [concat $vars(ffm40_0p8std,timing)]
                  }  
                 } elseif {[regexp ff125 $corner]} {
                  if {[regexp 3v3vio $$corner aa bb]} {                
                  set allLibs [concat $vars(ff125_3v3io,timing)]
                  } elseif {[regexp 2p5vio $$corner aa bb]} {
                  set allLibs [concat $vars(ff125_2p5io,timing)] 
                  } elseif {[regexp 1p8vio $$corner aa bb]}  {
                  set allLibs [concat $vars(ff125_1p8io,timing)]
                  } else {
                  set allLibs [concat $vars(ff125_0p8std,timing)]
                  }
                 }
         	link_timing_library -corner $corner -search_type min_max $allLibs
	} else {
		link_timing_library -corner $corner -search_type min_max [join $vars(CCS_LIBS_[string toupper ${libset}])]
	}
}

#read_timing_data -data_dir ../STA/output/${version}/xtop

read_timing_data -data_dir /home/user3/project/CX200UR1/CX250UR1_SOC_TOP/dataout/$env(DATAOUT_VERSION)/xtop_data

# set lib per instance
#set_lib_per_instance {regs/dram1/C3} {tutorialbc.idb} -corner fast  ;# set the libraries to use for the specified module instance.
#foreach corner $corners {
#	regexp {([^_]*)_.*} $corner dummy libset
#	set_lib_per_instance "u_rtc_wrapper/u_rtc_top" [concat $vars(CCS_STDCELL_7T_0P8_[string toupper ${libset}]) $vars(CCS_IP_0P8_[string toupper ${libset}])] -corner $corner  ;# set the libraries to use for the specified module instance.
#}

check_inst_reference_library
check_inst_timing_library


## dont use & dont touch 
foreach i $vars(dont_use_cells) {
	set_dont_use $i
}

source $vars(dont_touch_files) 
#source /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pnr/run_1p0_run5/work/dont_touch.tcl
#if {[info exists vars(dont_touch_files)] && [string trim $vars(dont_touch_files)] != "" } { 
#    foreach f $vars(dont_touch_files) {
#        if {![file exists $f]} {
#            puts "ERROR: $f file not found!"
#        } else {
#          source $vars(dont_touch_files
#        #    open fc [open $f r]
#	#		while {[gets $fc line] >= 0} {
#	#			set_dont_touch [get_nets $line]
#	#		}
#	#		close $fc
#        }
#    }   
#}

### legalize related
set_parameter placement_legalization_mode {true} ;# set the eco placement to legalization mode
set_placement_constraint -max_displacement {10 1}  ;# set the max displacement constraints for eco inst and original inst in the design. The unit is um.
#set_placement_constraint -max_displacement {10 0} -max_density 0.5 -design {sub} ;# set the max placement density constraint for design sub.
report_placement_constraint ;#report the placement constraint settings.

# eco buffer
#set_parameter eco_new_object_prefix {xtop}  ;# set the prefix for names of newly created cells or nets in eco actions.	
#set_parameter eco_buffer_list_for_hold {BUF1 DEL1 DEL2}  ;# set buffers used to fix hold violations in eco.
#set_parameter eco_buffer_list_for_setup {BUF2 BUF4 BUF6}  ;# set buffers used to fix setup, transition, capactance violations in eco.The 1st buffer specified in this parameter can also be used for si/fanout/wire length fixing.
#set_parameter eco_max_buffer_chain_length 8  ;# set the maximum buffer chain length inserted at one pin in automatic eco flow.

# size related
set_parameter eco_buffer_group {BUF* DEL*} ;# set macro buffer group for buffers with different types.
set_parameter eco_cell_classify_rule {cell_attribute}  ;# set the cell classify rule for gate sizing: cell_attribute, nominal_keywords, and nominal_regex
set_parameter eco_cell_match_attribute {footprint} ;# set the size cell attribute matching type: footprint, user_function_class, pin_function
set_parameter eco_cell_nominal_swap_keywords {"LVT@30P" "LVT@35P" "LVT@40P" "@30P" "@35P" "@40P" "HVT@30P" "HVT@35P" "HVT@40P"}  ;# set the nominal keywords for swapping cells.
set_parameter eco_cell_nominal_sizing_pattern {D([0-9]+)BWP}  ;# set the nominal pattern for sizing cells.

# remove buffer related
#set_parameter eco_remove_inverter_pair true ; enable remove inverter pair in remove buffer method.

# eco slack target and margin
#set_parameter eco_setup_slack_target 0  ;# setup slack target for fixing setup violations, with unit ns.
#set_parameter eco_setup_slack_margin 0  ;# setup slack margin while fixing hold violations, with unit ns.
#set_parameter eco_hold_slack_target 0  ;# hold slack target for fixing hold violations, with unit ns.
#set_parameter eco_hold_slack_margin 0  ;# hold slack margin while fixing setup violations, with unit ns.
#set_parameter eco_transition_slack_target 0  ;# transition slack target while fixing transition violations, with unit ns.
#set_parameter eco_transition_slack_margin 0  ;# transition slack margin while fixing hold, setup, transition, capacitance violations, with unit ns.
#set_parameter eco_capacitance_slack_target 0  ;# capacitance slack target while fixing capacitance violations, with unit pF.
#set_parameter eco_capacitance_slack_margin 0  ;# capacitance slack margin while fixing hold, setup, transition, capacitance violations, with unit pF.
#set_parameter eco_gain_threshold 0.001  ;# acceptable minumum gain when fix hold/setup/transition, the unit is ns.

# user defined constraints
#set_parameter max_si 0.05  ;# define the allowed maximum delta delay caused by SI, with unit ns.
#set_parameter max_fanout 64  ;# define the allowed maximum fanout for pins.
#set_parameter max_wire_length 3000  ;# define the allowed max wire length for nets, with unit micrometer.

# skip timing commands
#set_skip_scenarios [get_scenario *T] -min true
#set_skip_scenarios [get_scenario *t]  -max true

# set removable fillers
set_removable_fillers {FILL* DCAP* GFILL* GDCAP*} ;# specify lib cell name pattern of removable fillers.

####### user setting 
#set_module_dont_touch rtc_wrapper true
#set_module_dont_touch bb_top true
#set_module_dont_touch archipelago_wrapper true
#
#set_specific_lib_cells -design rtc_wrapper [get_lib_cells *7T*HVT] -recursive  ;# set specific library cells for specified design.

########### Pre opt report #################
set report_dir "rpt/${version}"
exec rm -rf $report_dir
exec mkdir $report_dir

set eco_output_dir "eco_output/${version}"
exec rm -rf $eco_output_dir
exec mkdir $eco_output_dir 

redirect -file $report_dir/mem.log {puts "Before opt the memory is [mem] KB."}

########### Fix Leakage power  ###########
#Note: if you fix leakage, please don't fix others together.
if {$FIX_LKG == "true"} {
	if {$vars(top_or_block) == "block"} {
		set_dont_touch [get_io_path_pins] true
	}
	redirect -file $report_dir/leakage_preopt.rpt {summarize_leakage_power -as_reference}
	redirect -file $report_dir/leakage_preopt.rpt -append {summarize_gba_violations -exclude_path -as_reference -setup}
	redirect -file $report_dir/leakage_preopt.rpt -append {summarize_gba_violations -exclude_path -as_reference -hold}
	optimize_leakage_power -setup_margin 0.02 -transition_margin 0.02 -effort $EFFORT
	optimize_leakage_power -setup_margin 0.02 -transition_margin 0.02 -effort $EFFORT -dff_only
	redirect -file $report_dir/mem.log -append {puts "After opt the memory is [mem] KB."}
	redirect -file $report_dir/leakage_postopt.rpt {summarize_eco_actions}
	redirect -file $report_dir/leakage_postopt.rpt -append {summarize_leakage_power -with_reference -with_delta}
	redirect -file $report_dir/leakage_postopt.rpt -append {summarize_gba_violations -exclude_path -with_reference -with_delta -setup}
	redirect -file $report_dir/leakage_postopt.rpt -append {summarize_gba_violations -exclude_path -with_reference -with_delta -hold}
	write_design_changes -format INNOVUS -eco_file_prefix xtop_opt_innovus_leakage -output_dir $eco_output_dir
}
########### Fix DRV violations ###########
if { $FIX_DRV == "true"} {
	# max_tran
	set_parameter eco_new_object_prefix "xtop_tran_${prefix}"
	redirect -file $report_dir/drv_preopt.rpt {summarize_transition_violations -as_reference}
	
	fix_transition_violations -methods "size_cell" -size_rule nominal_keywords
	fix_transition_violations -methods "size_cell" -size_rule nominal_regex
	
	redirect -file $report_dir/drv_postopt.rpt {summarize_eco_actions}
	redirect -file $report_dir/drv_postopt.rpt -append {summarize_transition_violations -with_reference -with_delta}
	
	# max_cap
	set_parameter eco_new_object_prefix "xtop_cap_${prefix}"
	redirect -file $report_dir/drv_preopt.rpt -append {summarize_capacitance_violations -as_reference}
	
	fix_capacitance_violations  -method "size_cell"
	
	redirect -file $report_dir/drv_postopt.rpt {summarize_eco_actions}
	redirect -file $report_dir/drv_postopt.rpt -append {summarize_capacitance_violations -with_reference -with_delta}
	redirect -file $report_dir/mem.log -append {puts "After drv opt the memory is [mem] KB."}
	
	write_design_changes -format INNOVUS -eco_file_prefix xtop_opt_innovus_drv -output_dir $eco_output_dir
	write_design_changes -format INNOVUS -eco_file_prefix xtop_opt_innovus_drv_atomic -output_dir $eco_output_dir -write_atomic_cmd -keep_route
}

if {$vars(top_or_block) == "block"} {
	set_dont_touch [get_io_path_pins] true
}
########### Fix setup violations ###########
if {$FIX_SETUP == "true"} {
	set_parameter eco_new_object_prefix "xtop_setup_${prefix}"

	if {$PBA_MODE == "false"} {
		redirect -file $report_dir/setup_preopt.rpt {summarize_gba_violations -as_reference -setup -r2r_only}
	} else {
		redirect -file $report_dir/setup_preopt.rpt {summarize_path_violations -as_reference}
	}

	if { $PBA_MODE == "false"} {
		# Fix setup violations by GBA mode. (path slack is used)
		#fix_setup_gba_violations -remove_buffer_only
		#fix_setup_gba_violations -methods "size_cell" -effort high -setup_target 0.005 -hold_margin 0.0
		fix_setup_gba_violations -methods "size_cell" -effort $EFFORT -size_rule nominal_keywords -setup_target 0.005 -hold_margin 0.0
		fix_setup_gba_violations -methods "size_cell" -effort $EFFORT -size_rule nominal_keywords -setup_target 0.005 -hold_margin 0.0 -dff_only
		fix_setup_gba_violations -methods "size_cell" -effort $EFFORT -size_rule nominal_regex -setup_target 0.005 -hold_margin 0.0

		set_parameter eco_buffer_group {BUFF* DEL*}
		fix_setup_gba_violations -methods "size_cell" -effort $EFFORT -size_rule cell_attribute -setup_target 0.005 -hold_margin 0.0
		#fix_setup_gba_violations -methods "insert_buffer" -setup_target 0.005 -hold_margin 0.0
	} else {
		# Fix setup violations by path. (only fix violations on path)
		#fix_setup_path_violations -remove_buffer_only
		fix_setup_path_violations -methods "size_cell" -effort high -setup_target 0.005 -hold_margin 0.0
		fix_setup_path_violations -methods "size_cell" -size_rule nominal_keywords -setup_target 0.005 -hold_margin 0.0
		fix_setup_path_violations -methods "insert_buffer" -setup_target 0.005 -hold_margin 0.0
	}

	redirect -file $report_dir/mem.log -append {puts "After setup opt the memory is [mem] KB."}
	redirect -file $report_dir/setup_postopt.rpt {summarize_eco_actions}
	if {$PBA_MODE == "false"} {
		redirect -file $report_dir/setup_postopt.rpt -append {summarize_gba_violations -with_reference -with_delta -setup -r2r_only -with_fail_reason -with_top_n 1000 }
	} else {
		redirect -file $report_dir/setup_postopt.rpt -append {summarize_path_violations -with_reference -with_delta -with_fail_reason -with_top_n 1000}
	}
	
	write_design_changes -format INNOVUS -eco_file_prefix xtop_opt_innovus_setup -output_dir $eco_output_dir
	write_design_changes -format INNOVUS -eco_file_prefix xtop_opt_innovus_setup_atomic -output_dir $eco_output_dir -write_atomic_cmd -keep_route
}

########### Fix hold violations ###########
if {$vars(top_or_block) == "top" } {
set hold_buf1 "\
	DEL250MD1BWP7T40P140HVT DEL200MD1BWP7T40P140HVT DEL150MD1BWP7T40P140HVT DEL100MD1BWP7T40P140HVT DEL075MD1BWP7T40P140HVT DEL050MD1BWP7T40P140HVT DEL025D1BWP7T40P140HVT BUFFD2BWP7T40P140HVT BUFFD1BWP7T40P140HVT \
"
set hold_buf2 "\
	DEL250MD1BWP7T40P140HVT DEL200MD1BWP7T40P140HVT DEL150MD1BWP7T40P140HVT DEL100MD1BWP7T40P140HVT DEL075MD1BWP7T40P140HVT DEL050MD1BWP7T40P140HVT DEL025D1BWP7T40P140HVT BUFFD2BWP7T40P140HVT BUFFD1BWP7T40P140HVT \
"
set hold_buf3 "\
	BUFFD1BWP7T40P140HVT  BUFFD2BWP7T40P140HVT  \
"
}
if {$FIX_HOLD == "true"} {
	set_parameter eco_new_object_prefix "xtop_hold_${prefix}"

	if {$PBA_MODE == "false"} {
		redirect -file $report_dir/hold_preopt.rpt {summarize_gba_violations -as_reference -hold -r2r_only}
	} else {
		redirect -file $report_dir/hold_preopt.rpt {summarize_path_violations -as_reference}
	}

	set_placement_constraint -max_displacement {1 1} -min_filler_width 0
	report_placement_constraint
	if { $PBA_MODE == "false"} {
		# Fix hold violations by GBA mode. (path slack is used)
		#size_cell
		fix_hold_gba_violations -size_cell_only -size_rule nominal_keywords -hold_target 0.005 -setup_margin 0.01 -transition_margin 0.01
		fix_hold_gba_violations -size_cell_only -size_rule nominal_keywords -hold_target 0.005 -setup_margin 0.10 -transition_margin 0.01 -dff_only
		fix_hold_gba_violations -size_cell_only -size_rule nominal_regex    -hold_target 0.005 -setup_margin 0.01 -transition_margin 0.01
		set_parameter eco_buffer_group {BUFF* DEL*}
		fix_hold_gba_violations -size_cell_only -size_rule cell_attribute   -hold_target 0.005 -setup_margin 0.03 -transition_margin 0.02
	
		#1st insert
		set_parameter eco_buffer_list_for_hold $hold_buf1 
		fix_hold_gba_violations -effort high -hold_target 0.005 -setup_margin 0.005 -transition_margin 0.005
		#2nd insert
		set_placement_constraint -max_displacement {10 1} -min_filler_width 0
		report_placement_constraint
		set_parameter eco_buffer_list_for_hold $hold_buf2
		fix_hold_gba_violations -effort high -hold_target 0.005 -setup_margin 0.005 -transition_margin 0.005
		#3rd insert
		set_placement_constraint -max_displacement {30 1} -min_filler_width 0
		report_placement_constraint
		set_parameter eco_buffer_list_for_hold $hold_buf3
		fix_hold_gba_violations -effort high -hold_target 0.005 -setup_margin 0.005 -transition_margin 0.005

	} else {
		# Fix hold violations by path. (only fix violations on path)
		#size_cell
		fix_hold_path_violations -size_cell_only -size_rule nominal_keywords -hold_target 0.005 -setup_margin 0.01 -transition_margin 0.01
		fix_hold_path_violations -size_cell_only -size_rule nominal_keywords -hold_target 0.005 -setup_margin 0.01 -transition_margin 0.01 -dff_only
		fix_hold_path_violations -size_cell_only -size_rule nominal_regex    -hold_target 0.005 -setup_margin 0.01 -transition_margin 0.01
		set_parameter eco_buffer_group {BUFF* DEL*}
		fix_hold_path_violations -size_cell_only -size_rule cell_attribute   -hold_target 0.005 -setup_margin 0.02 -transition_margin 0.01

		#1st insert
		set_parameter eco_buffer_list_for_hold $hold_buf1 
		fix_hold_path_violations -effort high -hold_target 0.005 -setup_margin 0.005 -transition_margin 0.005
		#2nd insert
		set_placement_constraint -max_displacement {10 1} -min_filler_width 0
		report_placement_constraint
		set_parameter eco_buffer_list_for_hold $hold_buf2
		fix_hold_path_violations -effort high -hold_target 0.005 -setup_margin 0.005 -transition_margin 0.005
		#3rd insert
		set_placement_constraint -max_displacement {30 1} -min_filler_width 0
		report_placement_constraint
		set_parameter eco_buffer_list_for_hold $hold_buf3
		fix_hold_path_violations -effort high -hold_target 0.005 -setup_margin 0.005 -transition_margin 0.005
	}

	redirect -file $report_dir/mem.log -append {puts "After hold opt the memory is [mem] KB."}
	redirect -file $report_dir/hold_postopt.rpt {summarize_eco_actions}
	if {$PBA_MODE == "false"} {
		redirect -file $report_dir/hold_postopt.rpt -append {summarize_gba_violations -with_reference -with_delta -hold -r2r_only -with_fail_reason -with_top_n 1000 }
	} else {
		redirect -file $report_dir/hold_postopt.rpt -append {summarize_path_violations -with_reference -with_delta -with_fail_reason -with_top_n 1000}
	}
	
	write_design_changes -format INNOVUS -eco_file_prefix xtop_opt_innovus_hold -output_dir $eco_output_dir
	write_design_changes -format INNOVUS -eco_file_prefix xtop_opt_innovus_hold_atomic -output_dir $eco_output_dir -write_atomic_cmd -keep_route
}

write_design_changes -format INNOVUS -eco_file_prefix xtop_opt_innovus_all -output_dir $eco_output_dir
write_design_changes -format INNOVUS -eco_file_prefix xtop_opt_innovus_all_atomic -output_dir $eco_output_dir -write_atomic_cmd -keep_route

#exit

