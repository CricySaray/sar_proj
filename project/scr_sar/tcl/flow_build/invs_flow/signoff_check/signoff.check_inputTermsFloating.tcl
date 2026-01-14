#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/01/13 12:39:53 Tuesday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check input terms floating 
# return    : output file and format list
# ref       : link url
# --------------------------
proc check_inputTermsFloating {args} {
  set rptName "signoff_check_inputTermsFloating.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set allInputTerms_ptr [dbget top.insts.instTerms.isInput 1 -p]
  set floatingInputTermsList [list]
  set totalNum 0
  foreach temp_ptr $allInputTerms_ptr {
    if {![dbget $temp_ptr.net.isPwrOrGnd]} {
      if {[dbget $temp_ptr.net. -e] eq ""} {
        lappend floatingInputTermsList "NO_NET: [dbget $temp_ptr.name]"
        incr totalNum
      } elseif {![dbget $temp_ptr.net.numOutputTerms]} {
        lappend floatingInputTermsList "NO_OUTPUT_TERM: [dbget $temp_ptr.name]" 
        incr totalNum
      }
    }
  }
  set fo [open $rptName w]
  puts $fo [join $floatingInputTermsList \n]
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "inputTermFloat $totalNum"
  close $fo
  return [list inputTermFloat $totalNum]
}
define_proc_arguments signoff_check_inputTermsFloating \
  -info "check input terms floating"\
  -define_args {
    {-rptName "specify output file name" AString string optional}
  }
