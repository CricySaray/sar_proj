#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/13 11:50:20 Tuesday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : what?
# return    : output file and format list
# ref       : link url
# --------------------------
proc check_decapDensity {args} {
  set rptName "signoff_check_decapDensity.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set decapResult [lmap temp_decapcell [dbget top.insts.cell.name DCAP* -u -e] {
    set temp_num [llength [dbget top.insts.cell.name $temp_decapcell]] 
    list $temp_num $temp_decapcell
  }]
  set fo [open $rptName w]
  puts $fo [join $decapResult \n]
  proc temp_add {x y} { expr $x + $y }
  
  set decap_area [struct::list::Lfold [dbget [dbget top.insts.cell.name DCAP* -e -p2].area -e] 0 temp_add]
  checkFPlan -reportUtil > ./temp_checkFPlan_reportUtil.rpt
  set alloc_area [regsub -all {\(|\)} [lindex  [split [exec grep alloc_area temp_checkFPlan_reportUtil.rpt | tail -n 1] "sites"] end 0] ""]
  if {$alloc_area == 0 || $decap_area == 0} {
    return [list decapDensity -1]
  }
  set decap_density [format "%.2f" [expr {$decap_area / double($alloc_area)}]]
  puts $fo "DECAP_DENSITY: $decap_density"
  close $fo
  # dump out gif of decap
  set decapInstList [dbget [dbget top.insts.cell.name DCAP* -p2].name -e]
  fit
  deselectAll
  highlight $decapInstList
  setLayerPreference violation -isVisible 0
  setLayerPreference node_route -isVisible 0
  setLayerPreference node_blockage -isVisible 0
  setLayerPreference node_layer -isVisible 1
  gui_dump_picture gif_signoff_check_decap_density.gif -format GIF
  dehighlight
  return [list decapDensity $decap_density]
}

define_proc_arguments check_decapDensity \
  -info "whatFunction"\
  -define_args {
    {-rptName "specify output file name" AString string optional}
  }
