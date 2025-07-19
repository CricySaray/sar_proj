set tmp $env(MODE)_sdc

####==========================================================####
#### initcheck proc
####==========================================================####
source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/initchk_check/initchk_proc.tcl
####==========================================================####
#### common setting
####==========================================================####
set start_time                            [clock seconds]
set link_create_black_boxes               $env(black_boxes)
set_host_options -max_cores               16
set sh_message_limit                      20
set sh_source_uses_search_path            true
set session                               $env(top).$env(MODE)_$env(corner)
set SDC                                   $env($tmp)

set vars(step)      "initchk"
set vars(view_from)  $env(view_from)
set vars(view_rpt)   $env(view_rpt)
set vars(path_dir)   [join [lrange [split [pwd] /] 0 end-1] /]
set vars(rpt_dir)    "$vars(path_dir)/rpt/$vars(step)/$vars(view_rpt)/$session"
set vars(log_dir)    "$vars(path_dir)/log/$vars(step)/$vars(view_rpt)/$session"
set vars(data_dir)   "$vars(path_dir)/db/$vars(step)/$vars(view_rpt)/$session"
exec mkdir -p $vars(rpt_dir)
exec mkdir -p $vars(log_dir)
exec mkdir -p $vars(data_dir)
##star time
puts "begin $vars(step) start"
####==========================================================####
#### link library
####==========================================================####
source  $env(liblist)
set link_library "* $vars(CCSDB_9T_0P9V_WCZ_LIBS) $vars(CCSDB_7T_0P9V_WCZ_LIBS) $vars(DB_RAM_0P9VP_0P9VC_WCZ_LIBS) $vars(DB_ROM_0P9VP_0P9VC_WCZ_LIBS) $vars(DB_IP_FUNC_WCZ_CWORST_HOLD_LIBS) $vars(DB_IO_3P3V0P9V_WCZ_LIBS)"

# for add extra db 
set link_library   [concat $link_library $env(extra_db)]
####==========================================================####
#### update timing
####==========================================================####
echo "Begin to read netlist ..." > $vars(log_dir)/read_verilog.log
foreach VNET $env(netlist_list) {
    echo "Reading ${VNET} ..."  >> $vars(log_dir)/read_verilog.log
    read_verilog  ${VNET}       >> $vars(log_dir)/read_verilog.log
}

#----link design
echo "Link $env(top) ..." > $vars(log_dir)/link.log
current_design $env(top)
link >> $vars(log_dir)/link.log


#---- read SDC
echo "Begin to read sdc ..."  > $vars(log_dir)/read_sdc.log
foreach sdc $SDC {
    echo " Reading $sdc ..."  >> $vars(log_dir)/read_sdc.log
    source -echo $sdc         >> $vars(log_dir)/read_sdc.log
}

#---- uncertainty
set uncertainty_file "/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8801/david/flow/ict8810/initchk_check/uncertainty_pt.tcl"
if {[file exists $uncertainty_file]} {
    source $uncertainty_file
}

#---- update timing
#set_app_var timing_input_port_default_clock true
set timing_input_port_default_clock true
update_timing -full > $vars(log_dir)/update_timing.log


foreach_in_collection id [get_nets -quiet -hierarchical -filter "number_of_leaf_loads > 50" -top_net_of_hierarchical_group ] { 
    if {[sizeof [get_pins -quiet -of [get_nets $id] -filter "direction ==out" -leaf]] > 0} {
        set_annotated_delay  -net 0.01 -load_delay net -from [get_pins -of [get_nets $id] -filter "direction ==out" -leaf]
    }   
}

foreach_in_collection id [get_nets -quiet -hierarchical -filter "number_of_leaf_loads > 50" -top_net_of_hierarchical_group ] { 
    if {[sizeof [get_pins -quiet -of [get_nets $id] -leaf]]>0} {
        set_annotated_transition 0.05 [get_pins -of [get_nets $id] -leaf]
    }   
}

foreach_in_collection id [get_nets -quiet -hierarchical -filter "number_of_leaf_loads > 50" -top_net_of_hierarchical_group ] { 
    if {[sizeof [get_pins -quiet -of [get_nets $id] -filter "direction ==out" -leaf]]>0} {
        set_annotated_delay  -net 0.01 -load_delay cell -from [get_pins -of [get_nets $id] -filter "direction ==out" -leaf]
    }   
}

foreach_in_collection id [get_nets -quiet -hierarchical -filter "number_of_leaf_loads > 50" -top_net_of_hierarchical_group ] { 
    if {[sizeof [get_pins -quiet -of [get_nets $id] -filter "direction ==out" -leaf]]>0} {
        set_annotated_delay -cell 0.01 -load_delay cell -to [get_pins -of [get_nets $id] -filter "direction ==out" -leaf]
    }   
}

foreach_in_collection id [get_cells -quiet -hierarchical -filter "ref_name =~ BUF*D1BWP* || ref_name =~ INV*D1BWP* || ref_name =~ *BUF*_1 || ref_name =~ *INV*_1"] {
    if {[sizeof [get_pins -quiet -of [get_cells $id] -filter "direction ==out" -leaf]]>0} {
        set_annotated_delay -cell 0.01 -load_delay cell -to [get_pins -of [get_cells $id] -filter "direction ==out" -leaf]
    }   
}

save_session  $vars(data_dir)/$env(top).$env(MODE)_$env(corner).session

redirect -file $vars(rpt_dir)/$env(top).check_timing.rpt {check_timing -verbose -override_defaults {generated_clocks no_input_delay unconstrained_endpoints no_clock loops}}
redirect -file $vars(rpt_dir)/$env(top).global_timing.rpt  {report_global_timing}
report_timing -transition_time -nets -derate -delay_type max -slack_lesser_than 0 -nosplit -significant_digits 3 -max_path 100000 > $vars(rpt_dir)/$env(top).timing.rpt
report_min_pulse_width -crosstalk_delta -all_violators -significant_digits 3 -nosplit -path_type full_clock_expanded -input_pins > $vars(rpt_dir)/$env(top).min_pulse.rpt
report_constraint -nosplit -significant_digits 3 -all_violators -verbose -min_period > $vars(rpt_dir)/$env(top).min_period.rpt

redirect -file $vars(rpt_dir)/$env(top).design.rpt                    {report_design_status}
redirect -file $vars(rpt_dir)/$env(top).cell.status.rpt               {report_cell_status}
redirect -file $vars(rpt_dir)/$env(top).pin.status.rpt                {report_floating_pins}
redirect -file $vars(rpt_dir)/$env(top).net.status.rpt                {report_net_status}
redirect -file $vars(rpt_dir)/$env(top).port.status.rpt               {report_port_status}
redirect -file $vars(rpt_dir)/$env(top).clock.status.rpt              {report_clock_status}
redirect -file $vars(rpt_dir)/$env(top).dont_use_cell.rpt             {report_dont_use_status $env(dont_use_cells)}
redirect -file $vars(rpt_dir)/$env(top).vt_group.rpt                  {report_vt_usage}
redirect -file $vars(rpt_dir)/$env(top).memory.rpt                    {check_memory_info}
redirect -file $vars(rpt_dir)/$env(top).async.rpt                     {report_asyn_status}
redirect -file $vars(rpt_dir)/$env(top).dont_touch.rpt                {report_dont_touch_status}
redirect -file $vars(rpt_dir)/$env(top).DFT.status.rpt                {report_dft_status}
#redirect -file $vars(rpt_dir)/$env(top).logic_levels.rpt              {report_logic_levels}

redirect -file $vars(rpt_dir)/run_time.rpt               {run_time $vars(step) $start_time}

exit
