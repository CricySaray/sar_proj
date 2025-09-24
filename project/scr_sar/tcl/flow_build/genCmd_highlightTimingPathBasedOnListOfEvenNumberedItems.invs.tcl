#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/23 23:14:45 Tuesday
# label     : gui_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : According to the input list of even-numbered items, each item is a pin name, and every two items form a pair. Pins in a pair must be on the same net. If they are 
#             not on the same net, an error message will be triggered. You can choose to use functions like "flight line" or "whole_net" to highlight the connection relationship, 
#             which will be accompanied by arrows indicating the direction. It is possible to customize a circular list of highlight colors (including colors for nets and insts), 
#             and you can specify whether to highlight insts or nets.
# return    : cmds list
# ref       : link url
# --------------------------
proc genCmd_highlightTimingPathBasedOnListOfEvenNumberedItems {} {
  set evenNumberList {}

  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
}

define_proc_arguments genCmd_highlightTimingPathBasedOnListOfEvenNumberedItems \
  -info "gen cmd for highlighting timing path based on list of even-numbered items"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
