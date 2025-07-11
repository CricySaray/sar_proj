# ---------------------
# API:
set design                    $env(design)
set netlist                   $env(netlist)
set sdc_func                  $env(sdc_func)
set sdc_scan                  $env(sdc_scan)
set scenario                  $env(scenario)
set rpt_dir                   $env(rpt_dir)
  # for example : func_setup_0p99v_cworst_m40c
  #               scan_hold_1p1v_typical_25c
set rc                        [lindex [split $scenario "_"] 3]
set temp                      [lindex [split $scenario "_"] 4]
set spef                      "../STARRC/run/$env(view_from)/output/${top}.spef.${rc}_${temp}.gz"
set path_group_scr            "./last/path_group.pt.tcl"
set post_rpt_scr              "./last/global_post_rpt.tcl"
set report_timing_scr         "./last/report_timing_only_internal_path.tcl"
set check_clock_cell_type_scr "./last/check_clock_cell_type.tcl"
set report_dir                "$rpt_dir/$scenario/"

# ---------------------
# PT variables setting 
set timing_non_unate_clock_compatibility        true
set timing_remove_clock_reconvergence_pessimism true
set timing_report_unconstrained_paths           true
set si_enable_analysis                          true
set power_enable_analysis                       true
set auto_wire_load_selection                    false
set sh_source_uses_search_path                  true
set link_create_black_boxes                     false

# ---------------------
# PT variables setting 
set search_path ". ./inputs/"
switch -regexp $env(scenario) {
                                        # below tcl is setting for every scenario
  ".*0p99v_cworst_125c"  {  source  -v  ./link_library/0p99v_cworst_125c.link_library.command.pt.tcl  }
  ".*0p99v_cworst_m40c"  {  source  -v  ./link_library/0p99v_cworst_m40c.link_library.command.pt.tcl  }
  ".*1p21v_cbest_125c"   {  source  -v  ./link_library/1p21v_cbest_125c.link_library.command.pt.tcl   }
  ".*1p21v_cbest_m40c"   {  source  -v  ./link_library/1p21v_cbest_m40c.link_library.command.pt.tcl   }
  ".*1p1v_typical_25c"   {  source  -v  ./link_library/1p1v_typical_25c.link_library.command.pt.tcl   }
}

# ---------------------
# run analysis timing
read_verilog $netlist
current_design $design
link_design -verbose > $report_dir/link.rpt
read_parasitics -format SPEF -keep_capacitive_coupling -verbose $spef
switch -regexp $scenario {
  "func.*" { source $sdc_func }
  "scan.*" { source $sdc_scan }
}
source -v $path_group_scr
# ---------------------
## constraint setting
switch -regexp $scenario {
  ".*hold_0p99v_cworst.*" {
    set_clock_uncertainty -hold 0.13 [all_clocks]
    ## hold SS
    # cell
    set_timing_derate -early -clock -cell_delay [expr 1 - 0.125] [get_lib_cells */*]
    set_timing_derate -early -data  -cell_delay [expr 1 - 0.125] [get_lib_cells */*]
    # net
    set_timing_derate -early -clock -net_delay [expr 1 - 0.125] 
    set_timing_derate -late  -clock -net_delay [expr 1 + 0.125] 
    set_timing_derate -early -data  -net_delay [expr 1 - 0.125] 
  }
  ".*hold_1p21v_cbest.*" {
    set_clock_uncertainty -hold 0.12 [all_clocks]
    ## hold FF
    # cell
    set_timing_derate -late -clock -cell_delay [expr 1 + 0.176] [get_lib_cells */*]
    # net
    set_timing_derate -early -clock -net_delay [expr 1 - 0.176] 
    set_timing_derate -late  -clock -net_delay [expr 1 + 0.176] 
    set_timing_derate -early -data  -net_delay [expr 1 - 0.176] 
  }
  ".*steup_0p99v_cworst.*" {
    set_clock_uncertainty -setup 0.08 [all_clocks]
    ## setup 
    # cell
    set_timing_derate -early -clock -cell_delay [expr 1 - 0.075] [get_lib_cells */*]
    # net
    set_timing_derate -early -clock -net_delay [expr 1 - 0.075] 
    set_timing_derate -late  -clock -net_delay [expr 1 + 0.075] 
    set_timing_derate -late  -data  -net_delay [expr 1 + 0.075] 
  }
  ".*typical.*" { set_clock_uncertainty -hold 0.04 [all_clocks]}
}
set_operating_conditions -analysis_type on_chip_variation
set_propagated_clock [all_clocks]
update_timing
update_noise
foreach fi [concat $post_rpt_scr $report_timing_scr $check_clock_cell_type_scr] {
  source -v $fi
}
save_session $rpt_dir/$scenario/$scenario.session
