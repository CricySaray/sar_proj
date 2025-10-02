#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/24 09:36:38 Wednesday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : Generate the command for setting max transition based on the cycle configuration of the clock.
# return    : cmds list
# ref       : link url
# --------------------------
proc genCmd_setMaxTransition_forDataClock_byClockPeriod_invs {args} {
  set ratioOfClockWhenSetMaxTranForClock      0.167 ; # cycle ratio of the clock when setting the clock max transition. 1 / 6
  set ratioOfClockWhenSetMaxTranForData       0.33 ; # cycle ratio of the clock when setting the clock max transition. 1 / 3
  set userSetClockMaxTransition               150  ; # ps
  set userSetDataMaxTransition                400 ; # ps
  set dataDefaultMaxTransitionInLibSet        378 ; # ps, default max transition in lib of std cell
  set ratioOfLibSetDefaultMaxTransitionOfData 0.67 ; # 2 / 3
  set extraDerateForClock                     10 ; # ps , Set stricter parameters for calculating subsequent values, and apply an additional margin if necessary.
  set extraDerateForData                      10 ; # ps
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  foreach_in_collection clk_itr [all_clocks] {
    set clk_name [lsort -u [get_property $clk_itr full_name]]
    set clk_period [lsort -u [get_property $clk_itr period -quiet]]
    if {$clk_period != ""} {
      set clk_arr($clk_name) $clk_period 
    } 
  }
  set clock_max_transition_cmdsList [list ]
  set data_max_transition_cmdsList [list ]
  # clock
  foreach {name period} [lsort -stride 2 -index 1 -real -decreasing [array get clk_arr]] {
    set ratioed_of_clock_period_for_clock [expr ($period * 1000.0 * $ratioOfClockWhenSetMaxTranForClock)] ; # ps
    set minValue_of_transition_clock [expr min($ratioed_of_clock_period_for_clock, $userSetClockMaxTransition)]
    set strict_min_of_transition_clock [expr $minValue_of_transition_clock - $extraDerateForClock]
    set maxTransitionForClock [expr $strict_min_of_transition_clock / 1000.0] ; # ns
    lappend clock_max_transition_cmdsList "set_max_transition $maxTransitionForClock -clock_path [lsort -u [get_object_name [get_clocks $name]]]"
  }
  # data
  foreach {name period} [lsort -stride 2 -index 1 -real -decreasing [array get clk_arr]] {
    set ratioed_of_clock_period_for_data  [expr (ceil($period * 1000.0 * $ratioOfClockWhenSetMaxTranForData))] ; # ps
    set ratioed_of_default_max_transition_of_std_cell_lib [expr ($dataDefaultMaxTransitionInLibSet * $ratioOfLibSetDefaultMaxTransitionOfData)] ; # ps
    set minValue_of_transition_data [expr min($ratioed_of_default_max_transition_of_std_cell_lib, $ratioed_of_clock_period_for_data, $userSetDataMaxTransition)]
    set strict_min_of_transition_clock [expr $minValue_of_transition_data - $extraDerateForClock]
    set maxTransitionForData [expr $strict_min_of_transition_clock / 1000.0] ; # ns
    lappend data_max_transition_cmdsList "set_max_transition $maxTransitionForData -data_path [lsort -u [get_object_name [get_clocks $name]]]"
  }
  return [concat $clock_max_transition_cmdsList $data_max_transition_cmdsList]
}

define_proc_arguments genCmd_setMaxTransition_forDataClock_byClockPeriod_invs \
  -info "gen cmd for set_max_transition on invs by clock period, it will return the min value of max_transition"\
  -define_args {
    {-ratioOfClockWhenSetMaxTranForClock "specify the ratio of clock period when set max transition for clock path" AFloat float optional}
    {-ratioOfClockWhenSetMaxTranForData "specify the ratio of clock period when set max transition for data path" AFloat float optional}
    {-ratioOfLibSetDefaultMaxTransitionOfData "specify the ratio of default set_max_transition in std cell lib when set max transition for data path" AFloat float optional}
    {-userSetClockMaxTransition "specify the min clock max_transition" AFloat float optional}
    {-userSetDataMaxTransition "specify the min data max_transition" AFloat float optional}
    {-dataDefaultMaxTransitionInLibSet "input the default set_max_transition in std cell lib file, please look up" AFloat float optional}
    {-extraDerateForClock "specify the extra derate value for clock final max_transition" AFloat float optional}
    {-extraDerateForData  "specify the extra derate value for data final max_transition" AFloat float optional}
  }
