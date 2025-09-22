#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/22 17:06:08 Monday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : gen cmd for init check in pt
# return    : cmds list
# ref       : link url
# --------------------------
source ../../packages/timer.tcl; # start_timer end_timer
source ../common/convert_file_to_list.common.tcl; # convert_file_to_list
source ../../packages/every_any.package.tcl; # any
proc genCmd_init_check {args} {
  set dbListFile         ""
  set formatExpOfResultFile "<design>_<suffix>.rpt" ; # like: "initCheck_<design>_<suffix>.rpt"; optional <design>|<suffix>
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set designName [get_object_name [get_design]]
  set optionsOfFormatExp [list "<design>" "<suffix>"]
# check input correction
  if {![file isfile $dbListFile]} {
    error "proc genCmd_init_check: check your input: dbListFile($dbListFile) is not found!!!" 
  }
  if {$formatExpOfResultFile == "" || [any x $optionsOfFormatExp { regexp $x $formatExpOfResultFile }]} {
    error "proc genCmd_init_check: check your input: for" 
  }

# logic part
  start_timer
  
  set timeSpend [end_timer "string"]
}

define_proc_arguments genCmd_init_check \
  -info "gen cmd for initial checking on PT(PrimeTime of Synopsys)"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
