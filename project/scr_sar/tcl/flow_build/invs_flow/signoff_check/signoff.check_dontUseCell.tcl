#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/13 10:03:20 Tuesday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check dont use cell
# return    : output file and format list
# ref       : link url
# --------------------------
source ./utils/util_wildcardList_to_regexpList.tcl; # util_wildcardList_to_regexpList
proc check_dontUseCell {args} {
  set dontUseExpressionList       {G* K* CLK*}
  set ignoreCellExpressionList {G* CK* DCCK* TIE* FILL* DCAP* *SYNC* DEL*}
  set rptName                     "signoff_check_dontUseCell.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set cellList [dbget [dbget top.insts.cell.subClass core -p].name -u -e]
  if {![llength $dontUseExpressionList]} {
    return "-1"
  } else {
    set dontUseRegexpList [util_wildcardList_to_regexpList -wildcardList $dontUseExpressionList]
    set matchDontUseList [lsearch -regexp -all -inline $cellList [join $dontUseRegexpList "|"]]
    set ignoreCellRegexpList [util_wildcardList_to_regexpList -wildcardList $ignoreCellExpressionList]
    set removedIgnoreCellList [lsearch -regexp -not -all -inline $matchDontUseList [join $ignoreCellRegexpList "|"]]
    set totalNum 0
    set finalList [lmap temp_cell $removedIgnoreCellList {
      set temp_insts [dbget [dbget top.insts.cell.name $temp_cell -p2].name]
      set temp_len [llength $temp_insts]
      incr totalNum $temp_len
      list $temp_cell $temp_len $temp_insts
    }]
    set fo [open $rptName w]
    foreach temp_list $finalList {
      lassign $temp_list temp_cell temp_len temp_insts
      puts $fo "CELLNAME: $temp_cell LEN: $temp_len"
      puts $fo [join $temp_insts \n]
      puts $fo ""
    }
    puts $fo "TOTALNUM: $totalNum"
    puts $fo "dontUseNum $totalNum"
    close $fo
    return [list dontUseNum $totalNum]
  }
}
define_proc_arguments check_dontUseCell \
  -info "whatFunction"\
  -define_args {
    {-dontUseExpressionList "specify the dont use cell regExpression list" AList list optional}
    {-ignoreCellListRegExpression "specify the cell regExpression to ignore check" AString string optional}
    {-rptName "specify the output file name" AString string optional}
  }
