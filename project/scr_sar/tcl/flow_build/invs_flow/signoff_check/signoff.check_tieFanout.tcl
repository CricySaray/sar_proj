#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/15 17:31:15 Thursday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check tie cell fanout
# return    : output file and format list
# ref       : link url
# --------------------------
proc check_tieFanout {args} {
  set fanoutThreshold 1
  set rptName         "signoff_check_tieFanout.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set tieCells [dbget top.insts.cell.name *TIE* -u]
  set finalList [list]
  foreach temp_cell $tieCells {
    set temp_tieInsts [dbget [dbget top.insts.cell.name $temp_cell -p2].name -e] 
    foreach temp_inst $temp_tieInsts {
      set temp_netname [get_object_name [get_nets -of [get_pins -of [get_cells $temp_inst]]]] 
      set temp_fanout [llength [dbget [dbget top.nets.name $temp_netname -p].instTerms.isInput 1]]
      if {$temp_fanout > $fanoutThreshold} {
        lappend finalList [list $temp_fanout $temp_netname]
      }
    }
  }
  set fo [open $rptName w]
  set finalList [lsort -real -decreasing -index 0 $finalList]
  puts $fo [join $finalList \n]
  puts $fo ""
  set totalNum [llength $finalList]
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "tieFanout $totalNum"
  close $fo
  return [list tieFanout $totalNum]
}

define_proc_arguments check_tieFanout \
  -info "check tie cell fanout"\
  -define_args {
    {-fanoutThreshold "specify the threshold of length" AFloat float optional}
    {-rptName "specify output file name" AString string optional}
  }
