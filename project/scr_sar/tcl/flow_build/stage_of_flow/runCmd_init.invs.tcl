#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/27 10:47:29 Saturday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : run cmd for stage of init on invs
# return    : /
# ref       : link url
# --------------------------
proc runCmd_init {args} {
  set netlistFile ""
  set mmmcFile ""
  set FPdefFile ""
  set upfFile ""
  set GNCfile ""
  set resultDBdir ""
  set resultRptDir ""
  set resultLogDir ""
  set 
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
}

define_proc_arguments runCmd_init \
  -info "run cmd for stage of init on invs"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
