#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/05/23 20:59:07 Saturday
# label     : task_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : add boundary buffer
# return    : cmd file
# ref       : link url
# --------------------------
proc genFile_addBoundaryBuffer {args} {
  set portlist           [list]
  set bufferCelltype     BUFFD4BWP...
  set ifPowerDomainAware 1 ; # use ecoAddRepeater option  : -hinstGuide
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  

}

define_proc_arguments genFile_addBoundaryBuffer \
  -info "whatFunction"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
