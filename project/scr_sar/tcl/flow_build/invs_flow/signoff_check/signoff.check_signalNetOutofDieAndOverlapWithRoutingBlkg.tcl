#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/13 14:09:35 Tuesday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check signal net out of die rects and overlaping with routing blockage
# return    : output file and format list
# ref       : link url
# --------------------------
proc check_signalNetOutofDieAndOverlapWithRoutingBlkg {args} {
  set layersToCheck "M2 M3 M4 M5 M6 M7"
  set rptName "signoff_check_signalOutofDieAndOverlapWithRoutingBlkg.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set dieRects [dbShape -output hrect [dbget top.fplan.boxes]]
  set finalList [list]
  set totalNum 0
  foreach temp_layer $layersToCheck {
    set temp_routingBlkg_rects [dbget [dbget top.fplan.rblkgs.layer.name $temp_layer -e -p2].boxes -e]
    set temp_coreAvailableRects [dbShape -output hrect $dieRects ANDNOT $temp_routingBlkg_rects]
    set temp_nets_list_ptr [dbget top.nets.wires.layer.name $temp_layer -e -p3]
    foreach temp_net_ptr $temp_nets_list_ptr {
      set temp_wire_rects [dbShape -output hrect [dbget $temp_net_ptr.wires.box -e]]
      if {[dbShape $temp_wire_rects INSIDE $temp_coreAvailableRects] eq ""} {
        set rectsOutOfAvailable [dbShape $temp_wire_rects ANDNOT $temp_coreAvailableRects]
        lappend finalList [list [dbget $temp_net_ptr.name] $rectsOutOfAvailable] 
        incr totalNum
      }
    }
  }
  set fo [open $rptName w] 
  puts $fo [join $finalList \n]
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "signalNetOut $totalNum"
  close $fo
  return [list signalNetOut $totalNum]
}

define_proc_arguments check_signalNetOutofDieAndOverlapWithRoutingBlkg \
  -info "check signal net out of die and overlap with routing blockage"\
  -define_args {
    {-layersToCheck "specify the layer list to check" AList list optional}
    {-rptName "specify inst to eco when type is add/delete" AString string optional}
  }
