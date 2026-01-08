#!/bin/tclsh
# --------------------------
# author    : yzq
# date      : 2026/01/08 17:40:59 Thursday
# label     : snippet
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Obtain the timing path summary of the specified slack interval for the specified path group to get a table file
# return    : output file
# ref       : link url
# --------------------------
source ../packages/table_format_with_title.package.tcl; # table_format_with_title
proc bk_summary_path {group {slackThreshold -0.15}} {
  set fo [open ./$group.rpt w] 
  set resultList [list]
  set paths [report_timing -collection -path_group $group -max_path 10000 -max_slack $slackThreshold]
  foreach_in_collection temp_path_itr $paths {
    set start [get_object_name [get_property $temp_path_itr launching_point]] 
    set end   [get_object_name [get_property $temp_path_itr capturing_point]] 
    set slack [get_property $temp_path_itr slack]
    lappend resultList [list $slack $end $start]
  }
  puts $fo [join [table_format_with_title $resultList 0 left "" 0]]
  close $fo
}
