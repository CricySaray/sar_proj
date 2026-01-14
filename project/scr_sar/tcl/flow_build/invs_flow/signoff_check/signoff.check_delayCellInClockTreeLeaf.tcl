#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/13 15:44:16 Tuesday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check if have delay cell in clock tree leaf
# return    : output file and format list
# ref       : link url
# --------------------------
source ../../../packages/table_format_with_title.package.tcl; # table_format_with_title
proc check_delayCellInClockTreeLeaf {args} {
  set rptName "signoff_check_delayCellInClockTreeLeaf.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set finalList [list]
  set totalNum 0
  set nets [get_nets *CTS*]
  foreach_in_collection temp_net_itr $nets {
    set temp_insts_col [get_cells -of $temp_net_itr -leaf]
    foreach_in_collection temp_inst_itr $temp_insts_col {
      set temp_celltype [get_property $temp_inst_itr ref_name] 
      if {[regexp "DEL" $temp_celltype]} {
        lappend finalList [list [get_object_name $temp_net_itr] $temp_celltype [get_object_name $temp_inst_itr]]
        incr totalNum
      }
    }
  }
  if {[llength $finalList]} {
    set finalList [linsert $finalList 0 [list rootNetName celltypeName instName]]
  }
  set fo [open $rptName w]
  puts $fo [join [table_format_with_title $finalList 0 left "" 0] \n]
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "dlyCellInTree $totalNum"
  close $fo
  return [list dlyCellInTree $totalNum]
}
define_proc_arguments check_delayCellInClockTreeLeaf \
  -info "check delay cell in clock tree leaf"\
  -define_args {
    {-rptName "specify inst to eco when type is add/delete" AString string optional}
  }
