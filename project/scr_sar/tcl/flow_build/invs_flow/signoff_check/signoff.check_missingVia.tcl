#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/14 23:34:42 Wednesday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check missing via
# return    : output file and format list
# ref       : link url
# --------------------------
# TO_WIRTE
proc check_missingVia {args} {
  set layersToCheck {M4 M5 M6 M7 M8} ; # from bottom to top layer
  set rptName "signoff_check_missingVia.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set rootdir [lrange [split $rptName "/"] 0 end-1]
  set temp_filename [lindex [split $rptName "/"] end]
  set extensionOfRptName [lindex [split $temp_filename "."] end]
  set basenameOfRptName [lrange [split $temp_filename "."] 0 end-1]
  deselectAll
  delete_gui_object -all
  fit
  gui_dim_foreground -lightness_level medium
  setLayerPreference node_route -isVisible 0
  setLayerPreference node_blockage -isVisible 0
  setLayerPreference node_layer -isVisible 1
  setLayerPreference violation -isVisible 1
  foreach upLayer [lrange $layersToCheck 1 end] downLayer [lrange $layersToCheck 0 end-1] {
    clearDrc
    deselectAll
    select_obj [dbget -v top.nets.swires.shape notype -p]
    verifyPowerVia -report [join [concat $rootdir middleFile_${basenameOfRptName}_$downLayer$upLayer.$extensionOfRptName] "/"] -layerRange [list $upLayer $downLayer] -nonOrthogonalCheck -error 1000000 -checkWirePinOverlap -selected
    deselectAll
    gui_dump_picture [join [concat $rootdir gif_${basenameOfRptName}_$downLayer$upLayer.gif] "/"] -format GIF
    saveDrc [join [concat $rootdir drc_${basenameOfRptName}_$downLayer$upLayer.drc] "/"]
  }
  # for MAIN_SUB
  set pgGap 6
  clearDrc
  deselectAll
  editSelect -type Special -shape {FOLLOWPIN STRIPE} -layer {M2 M5}
  verifyPowerVia -report [join [concat $rootdir middleFile_${basenameOfRptName}_stackM2M5.$extensionOfRptName] "/"] -layer_rail M2 -layer_stripe M5 -stackedVia -stripe_rule $pgGap -layerRange {M2 M5} -selected -error 1000000
  deselectAll
  gui_dump_picture [join [concat $rootdir gif_${basenameOfRptName}_stackM2M5.gif] "/"] -format GIF
  saveDrc [join [concat $rootdir drc_${basenameOfRptName}_stackM2M5.drc] "/"]
  set totalNum 0
  if {[glob -nocomplain drc_*.drc] ne ""} {
    catch {set totalNum [exec grep Violate [glob -nocomplain drc_*.drc] | wc -l]}
  }
  set fo [open $rptName w]
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "missingViaViol $totalNum"
  close $fo
  return [list missingViaViol $totalNum]
}
define_proc_arguments check_missingVia \
  -info "check missing via"\
  -define_args {
    {-layersToCheck "specify the list of layers to check" AList list optional}
    {-rptName "specify output file name" AString string optional}
  }
