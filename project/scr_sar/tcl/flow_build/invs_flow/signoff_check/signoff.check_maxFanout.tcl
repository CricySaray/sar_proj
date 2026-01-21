#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/15 00:30:32 Thursday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check max fanout
# return    : output file and format list
# ref       : link url
# --------------------------
# TO_WRITE
proc check_maxFanout {args} {
  set fanoutThreshold 32
  set rptName "signoff_check_maxFanout.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set_interactive_constraint_modes [lsearch -regexp -all -inline [all_constraint_modes] func]
  set_max_fanout $fanoutThreshold [current_design]
  report_constraint -drv_violation_type max_fanout -all_violators -view [lsearch -inline -regexp [all_analysis_views -type active] setup] > $rptName

  set totalNum []
  return [list maxFanoutViol $totalNum]
}

define_proc_arguments check_maxFanout \
  -info "check max fanout"\
  -define_args {
    {-fanoutThreshold "specify the max fanout threshold" AInt int optional}
    {-rptName "specify output file name" AString string optional}
  }
