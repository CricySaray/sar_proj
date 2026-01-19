#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/19 14:42:50 Monday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check ip/mem input pin buffer cell drive capacity size
# return    : output file and format list
# ref       : link url
# --------------------------
source ../../../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl; # get_net_length
source ../../../packages/table_format_with_title.package.tcl; # table_format_with_title
proc check_ipMemPinNetLength {args} {
  set removeInstExpList {mesh}
  set removeCelltypeExpList {mesh}
  set lengthThreshold     150
  set rptName           "signoff_check_ipMemPinNetLength.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set allIpMems_ptr [dbget top.insts.cell.subClass block -p2]
  set totalNum 0
  set fo [open $rptName w]
  set finalList [list]
  if {$allIpMems_ptr ne ""} {
    foreach temp_inst_ptr $allIpMems_ptr {
      if {![regexp [join $removeInstExpList "\|"] [dbget $temp_inst_ptr.name]] && ![regexp [join $removeCelltypeExpList "\|"] [dbget $temp_inst_ptr.cell.name]]} {
        set pins [dbget $temp_inst_ptr.instTerms.name -e]
        foreach temp_term $pins {
          set temp_net [dbget [dbget top.insts.instTerms.name $temp_term -p].net.name -e]
          if {$temp_net ne ""} {
            set temp_pinNetLength [get_net_length $temp_net] 
            if {$temp_pinNetLength > $lengthThreshold} {
              lappend finalList [list $temp_pinNetLength $temp_net $temp_term] 
            }
          }
        }
      }
    }
  }
  set totalNum [llength $finalList]
  set finalList [lsort -decreasing -index 0 -real $finalList]
  set finalList [linsert $finalList 0 [list netLen netName termName]]
  puts $fo [join [table_format_with_title $finalList 0 left "" 0] \n]
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "ipMemPinNetLength $totalNum"
  close $fo
  return [list ipMemPinNetLength $totalNum]
}

define_proc_arguments check_ipMemPinNetLength \
  -info "check ip/mem pin net length"\
  -define_args {
    {-removeInstExpList "specify the remove inst using expression list" AList list optional}
    {-removeCelltypeExpList "specify the remove celltype using expression list" AList list optional}
    {-lengthThreshold "specify the net length threshold" AFloat float optional}
    {-rptName "specify inst to eco when type is add/delete" AString string optional}
  }
