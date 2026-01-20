#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/19 21:26:51 Monday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check std cell utilization
# return    : output file and format list
# ref       : link url
# --------------------------
source ../../../eco_fix/timing_fix/lut_build/proc_findCoreRectInsideBoundary_usingCoreBoxesAndHaloAndPlaceBlockages.invsGUI.tcl; # proc_findCoreRectInsideBoundary_usingCoreBoxesAndHaloAndPlaceBlockages_withBoundaryRects
proc check_stdUtilization {args} {
  set rptName "signoff_check_stdUtilization.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set coreRects_withBoundary [proc_findCoreRectInsideBoundary_usingCoreBoxesAndHaloAndPlaceBlockages_withBoundaryRects]
  set coreArea_withBoundary [dbShape -output area $coreRects_withBoundary]
  proc _add {a b} {expr $a + $b}
  set stdCellAreaWoPhys [struct::list::Lfold [dbget [dbget [dbget top.insts.cell.subClass core -p2].isPhysOnly 0 -p].area -e] 0 _add]
  set stdCellAreaWiPhys [struct::list::Lfold [dbget [dbget top.insts.cell.subClass core -p2].area -e] 0 _add]
  set stdUtilization "[format "%.2f" [expr {double($stdCellAreaWoPhys) / double($coreArea_withBoundary) * 100}]]%"
  set fo [open $rptName w]
  puts $fo "coreRects_withBoundary: \{$coreRects_withBoundary\}"
  puts $fo ""
  puts $fo ""
  puts $fo "coreArea_withBoundary: $coreArea_withBoundary um^2"
  puts $fo "stdCellArea(withoutPhysicalCell): $stdCellAreaWoPhys um^2"
  puts $fo "stdCellArea(withPhysicalCell): $stdCellAreaWiPhys um^2"
  puts $fo "stdUtilization: $stdUtilization  (\$coreArea_withBoundary / \$stdCellAreaWoPhys * 100)%"
  puts $fo ""
  puts $fo "stdUtilization $stdUtilization"
  close $fo
  return [list stdUtilization $stdUtilization]
}

define_proc_arguments check_stdUtilization \
  -info "check std cell utilization"\
  -define_args {
    {-rptName "specify the output file name" AString string optional}
  }
