#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/15 10:45:46 Thursday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check clock cell status
# return    : output file and format list
# ref       : link url
# --------------------------
proc check_clockCellFixed {args} {
  set rptName "signoff_check_clockCellFixed.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set fo [open $rptName w]
  set totalNum 0
  set allTreeInsts_col [get_cells -q [get_clock_network_objects -type cell] -filter "!is_sequential"]
  foreach_in_collection temp_inst_itr $allTreeInsts_col {
    set temp_inst_name [get_object_name $temp_inst_itr] 
    if {![regexp fixed [dbget [dbget top.insts.name $temp_inst_name -p].pStatusCTS]] && ![regexp fixed [dbget [dbget top.insts.name $temp_inst_name -p].pStatus]]} {
      highlight $temp_inst_name -color yellow
      puts $fo "notFixedOrCTSFixed: $temp_inst_name"
      incr totalNum
    }
  }
  set rootdir [lrange [split $rptName "/"] 0 end-1]
  set temp_filename [lindex [split $rptName "/"] end]
  set basenameFile [join [lrange [split $temp_filename "."] 0 end-1] "."]
  deselectAll
  gui_dump_picture [join [concat $rootdir gif_$basenameFile.gif] "/"] -format GIF
  dehighlight
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "clkCellFixed $totalNum"
  close $fo
  return [list clkCellFixed $totalNum]
}

define_proc_arguments check_clockCellFixed \
  -info "check clock cell status"\
  -define_args {
    {-rptName "specify output file name" AString string optional}
  }
