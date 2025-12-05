#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/12/05 14:22:12 Friday
# label     : check_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
proc check_if_memHaveBufferForOutputInputPin {args} {
  set memCelltypeExp {^ram_} ; # match mem cell
  set directionToCheck "input" ; # input|output|all
  set typeToCheck "clk" ; # clk|data
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  
  
}

define_proc_arguments check_if_memHaveBufferForOutputInputPin \
  -info "whatFunction"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
