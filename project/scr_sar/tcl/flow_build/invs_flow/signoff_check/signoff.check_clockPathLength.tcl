#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/13 15:00:04 Tuesday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check clock path net length
# return    : output file and format list
# ref       : link url
# --------------------------
source ../../../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl; # get_net_length
source ../../../packages/table_format_with_title.package.tcl; # table_format_with_title
proc check_clockPathLength {args} {
  set lengthThreshold 240
  set rptName         "signoff_check_clockPathLength.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set finalList [list]
  set totalNum 0
  set nets_list_ptr [dbget top.nets. {.isClock == 1 && .isPwrOrGnd == 0}]
  foreach temp_net_ptr $nets_list_ptr {
    set temp_net_name [lindex [dbget $temp_net_ptr.name] 0 0]
    set temp_net_length [get_net_length $temp_net_name] 
    if {$temp_net_length > $lengthThreshold} {
      lappend finalList [list $temp_net_length $temp_net_name]
      incr totalNum
    }
  }
  set finalList [lsort -decreasing -index 0 -real $finalList]
  set fo [open $rptName w]
  puts $fo [join [table_format_with_title $finalList 0 left "" 0] \n]
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "clockLength $totalNum"
  close $fo
  return [list clockLength $totalNum]
}
define_proc_arguments check_clockPathLength \
  -info "check clock path net length"\
  -define_args {
    {-lengthThreshold "specify the threshold of net length" AFloat float optional}
    {-rptName "specify output file name" AString string optional}
  }
