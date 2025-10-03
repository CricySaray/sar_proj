#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/03 20:21:47 Friday
# label     : eco_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : This script identifies and filters out specific nets in densely routed areas of standard cells, then prioritizes routing for nets with violations; 
#             it also allows nets without violations and with sufficient margin to have a certain degree of detouring, ensuring routing resources are preferentially 
#             allocated to paths with violations.
# return    : 
# ref       : link url
# --------------------------
# TO_WRITE
proc genCmd_reRoute_for_denseNet_violationPrior {args} {
  
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
}

define_proc_arguments genCmd_reRoute_for_denseNet_violationPrior \
  -info "whatFunction"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
