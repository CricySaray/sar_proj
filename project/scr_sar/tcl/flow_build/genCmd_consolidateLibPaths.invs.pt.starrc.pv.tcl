#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/23 17:17:28 Tuesday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : With a one-click operation, update the library files simultaneously and use the accompanying lib2db program to convert the latest lib files to db files. 
#             This ensures that all programs use library files with consistency.
# return    : cmds List
# ref       : link url
# --------------------------
source ../flow_build/common/convert_file_to_list.common.tcl; # convert_file_to_list
proc genCmd_consolidateLibPaths {args} {
  set lefListFileName ""
  set libListDividedByCornersFileName "" ; # This type of lib list file needs to be grouped by corner, and then variable settings for each group should be made through the files generated after grouping.
  set libListAllCornersFileName "" ; # This type of lib list file does not need to be grouped by corners. They are generally the lib names of IPs, and these lib paths will be added to all corner groups.
  set groupByCornerPythonScriptFileName "" ; # You need to configure in advance the regular expressions and group names used for path matching in each group. You can use two interactive Python scripts for testing.
  set 
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  
}
define_proc_arguments genCmd_consolidateLibPaths \
  -info "gen cmd for consolidating lib paths"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
