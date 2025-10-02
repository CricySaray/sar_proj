#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/03 01:20:50 Friday
# label     : atomic_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : This script compares a test script (tst) against a reference script (ref), checking if each space-separated string in every line of tst exists in ref. It prints the 
#             corresponding lines from both scripts where matches are found into an output file.
# return    : diff file
# ref       : link url
# --------------------------
# TO_WRITE
proc genFile_diffEcoScript_forInstAndPin {args} {
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }

}

define_proc_arguments genFile_diffEcoScript_forInstAndPin \
  -info "gen file for diff eco scripts for pick out same inst or pin name dumped to output file"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
