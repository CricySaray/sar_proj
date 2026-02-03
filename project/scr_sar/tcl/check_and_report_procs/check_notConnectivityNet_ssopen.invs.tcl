#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/02/02 21:38:24 Monday
# label     : check_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
source ../packages/judge_ifAllSegmentsConnected.package.tcl; # judge_ifAllSegmentsConnected
proc check_notConnectivityNet_ssopen {args} {
  set netsToCheck [list]
  set outputFilename "sor_check_notConnectivityNet_ssopen.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$netsToCheck eq ""} {
    set netsToCheck [dbget top.nets.name -e]
  }
  set resultList [list]
  foreach temp_net $netsToCheck {
    set temp_wiresPts [dbget [dbget top.nets.name $temp_net -p].wires.pts -e]
    set ifNetConnected [judge_ifAllSegmentsConnected $temp_wiresPts]
    if {!$ifNetConnected} {
      lappend resultList $temp_net
    }
  }
  set fo [open $outputFilename w]
  puts $fo [join $resultList \n]
  close $fo
}

define_proc_arguments check_notConnectivityNet_ssopen \
  -info "check nets that not connect, (short short open)"\
  -define_args {
    {-netsToCheck "specify inst to eco when type is add/delete" AString string optional}
    {-outputFilename "specify the output file name" AString string optional}
  }
