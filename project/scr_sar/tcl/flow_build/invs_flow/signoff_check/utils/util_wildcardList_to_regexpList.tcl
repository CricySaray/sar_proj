#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/01/13 11:05:22 Tuesday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Each item in the input list must meet the requirements of the wildcard. Generally, only the * symbol is used among special 
#             characters, with differences only in their positions. There are also some fixed requirements to adapt to specific conversions, 
#             and the function is very simple.
# return    : regexp list
# ref       : link url
# --------------------------
proc util_wildcardList_to_regexpList {args} {
  set wildcardList [list]
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
	set regexpList [lmap temp_wildcard $wildcardList {
    if {[expr {[string index $temp_wildcard 0] ne "*"}]} {
      set final_regexp [string cat "^" $temp_wildcard] 
    } else { set final_regexp $temp_wildcard }
    if {[expr {[string index $temp_wildcard end] ne "*"}]} {
      set final_regexp [string cat $final_regexp "$"]
    }
    set final_regexp
  }]
  set regexpList [regsub -all {\*} $regexpList {.*}]
  return $regexpList
}
define_proc_arguments util_wildcardList_to_regexpList \
  -info "whatFunction"\
  -define_args {
    {-wildcardList "specify the list of wildcard" AList list optional}
  }
