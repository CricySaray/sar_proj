#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/15 17:41:39 Thursday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check port buffer net length
# return    : output file and format list
# ref       : link url
# --------------------------
source ../../../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl; # get_net_length
proc check_portNetLength {args} {
  set rptName "signoff_check_portNetLength.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set finalList [list]
  set ports [get_object_name [get_ports -of *]]
  foreach temp_port $ports {
    set temp_netname [get_object_name [get_nets -of $temp_port]]
    set temp_netlength [get_net_length $temp_netname]
    if 
  }
  set finalList [lsort -real -index 0 -decreasing $finalList]
  set totalNum [llength $finalList]
  set fo [open $rptName w]
  puts $fo [join $finalList \n]
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "portLength $totalNum"
  close $fo
  return [list portLength $totalNum]
  
}

define_proc_arguments check_portNetLength \
  -info "check port net length"\
  -define_args {
    {-rptName "specify output file name" AString string optional}
  }
