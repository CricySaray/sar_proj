#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/10 10:29:46 Wednesday
# label     : 
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
proc genCmd_powerPlan {args} {
  set ifDeleteAllPowerPreorutes 0
  set ifResetAndSetEditMode 1
  set powerDomains {}
  set layers {}
  set 
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {} {
   
  }

}
define_proc_arguments genCmd_powerPlan \
  -info "gen cmd for power plan"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
