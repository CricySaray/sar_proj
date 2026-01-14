#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/13 09:20:04 Tuesday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check dfm via ratio
# return    : output file and format list
# ref       : link url
# --------------------------
proc check_dfmVia {args} {
  set rptName "signoff_check_dfmVia.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {[file exists temp_report_route_multi_cut.rpt]} {
    file delete temp_report_route_multi_cut.rpt 
  }
  report_route -multi_cut > temp_report_route_multi_cut.rpt
  set fi [open "temp_report_route_multi_cut.rpt" r]
  set lineList [split [read $fi] "\n"]
  close $fi
  set fo [open $rptName w]
  set dfm_table [lrange $lineList 0 25]
  puts $fo [join $dfm_table \n]
  set total_row [lsearch -regexp -inline $dfm_table {^\|\s+Total}]
  if {$total_row eq ""} {
    set DFM_ratio "-1%" 
  } else {
    set DFM_ratio [lindex [regsub {\(|\)} [lsearch -regexp -inline -all $total_row {\d+\.\d+%}] ""] end]
  }
  puts $fo "DFM_RATIO: $DFM_ratio"
  puts $fo "dfmVia $DFM_ratio"
  close $fo
  return [list dfmVia $DFM_ratio]
}
define_proc_arguments check_dfmVia \
  -info "signoff check: double via"\
  -define_args {
    {-rptName "specify output file name" AString string optional}
  }
