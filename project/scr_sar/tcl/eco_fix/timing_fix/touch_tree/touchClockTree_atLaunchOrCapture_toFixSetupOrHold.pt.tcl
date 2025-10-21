#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/21 21:55:03 Tuesday
# label     : task_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Add or remove cdb cells in the launch path or capture path to fix setup/hold violations.
# return    : cmds output file
# ref       : link url
# --------------------------
proc touchClockTree_atLaunchOrCapture_toFixSetupOrHold {args} {
  set typeToFix "setup" ; # setup|hold
  set strategy  "launch" ; # launch|capture
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
}

define_proc_arguments touchClockTree_atLaunchOrCapture_toFixSetupOrHold \
  -info "touch clock tree at clock launch path or clock capture path (not at common path) to fix setup or hold big violation case."\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
