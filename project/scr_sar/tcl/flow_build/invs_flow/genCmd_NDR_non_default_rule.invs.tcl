#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/01/07 19:27:41 Wednesday
# label     : 
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
proc genCmd_NDR_non_default_rule {args} {
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set_ccopt_property target_max_trans 0.12
  set_ccopt_property target_insertion_delay 0.0
  set_ccopt_property max_fanout 32
  set_ccopt_property -cts_target_skew 0.04
  
}

define_proc_arguments PROC_NAME \
  -info "whatFunction"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
