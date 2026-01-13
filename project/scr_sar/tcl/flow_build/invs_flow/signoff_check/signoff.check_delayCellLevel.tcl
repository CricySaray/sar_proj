#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/13 16:39:57 Tuesday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : 
# return    : output file and format list
# ref       : link url
# --------------------------
proc check_delayCellLevel {args} {
  set levelThreshold 10
  set rptName "signoff_check_delayCellLeval.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set all_delay_cells [lsort -u -ascii -increasing [dbget [dbget top.insts.cell.name DEL* -p2].name -e]]
  foreach temp_delay_cell $all_delay_cells {
     

  }
  
}

define_proc_arguments check_delayCellLevel \
  -info "check delay cell level"\
  -define_args {
    {-levelThreshold "specify the threshold of delay cell level" AInt int optional}
    {-rptName "specify inst to eco when type is add/delete" AString string optional}
  }
