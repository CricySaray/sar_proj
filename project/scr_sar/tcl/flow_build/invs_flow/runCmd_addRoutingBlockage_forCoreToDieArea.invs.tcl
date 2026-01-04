#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/01/04 18:12:08 Sunday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Add a routing blockage to the position of coreToDie, considering the physical pin shape of the port
# return    : cmds list
# ref       : link url
# --------------------------
proc runCmd_addRoutingBlockage_forCoreToDieArea {args} {
  set nameOfRoutingBlockage "boundary_rblkg"
  set layersOfTerms "M4 M5 M6"
  set layersToAddRoutingBlockage "M2 VIA2 M3 VIA3 M4 VIA4 M5 VIA5 M6"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  catch {deleteRouteBlk -name $nameOfRoutingBlockage}
  set pin_lists [dbget top.terms.name]
  deselectAll
  foreach temp_layer $layersOfTerms {
    selectPhyPin -net $pin_lists -layer $temp_layer 
  }
  set boxes [dbShape -output hrect [dbget top.fplan.boxes] ANDNOT [dbShape [dbget top.fplan.boxes] SIZE -0.25] ANDNOT [dbShape [dbget selected.box] SIZE 0.01]]
  foreach box $boxes {
    createRouteBlk -box $box -layer $layersToAddRoutingBlockage -name $nameOfRoutingBlockage
  }
  deselectAll
}
define_proc_arguments runCmd_addRoutingBlockage_forCoreToDieArea \
  -info "run cmd to add routing blockage for area of core to die"\
  -define_args {
    {-nameOfRoutingBlockage "specify the name of routing blockage" AString string optional}
    {-layersOfTerms "specify layers of terms" AString string optional}
    {-layersToAddRoutingBlockage "specify layers to add routing blockage" AString string optional}
  }
