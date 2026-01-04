#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/01/04 18:12:08 Sunday
# label     : 
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
proc runCmd_addRoutingBlockage_forCoreToDieArea {args} {
  set nameOfRoutingBlockage "boundary_rblkg"
  set layersOfTerms "M4 M5 M6"
  set layersToAddRoutingBlockage
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  catch {deleteRouteBlk -name $nameOfRoutingBlockage}
  set pin_lists [dbget top.terms.name]
  deselectAll
  foreach temp_layer $layersToAddRoutingBlockage {
    selectPhyPin -net $pin_lists -layer $temp_layer 
  }
  set boxes [dbShape -output hrect [dbget top.fplan.boxes] ANDNOT [dbShape [dbget top.fplan.boxes] SIZE -0.25] ANDNOT [dbShape [dbget selected.box] SIZE 0.01]]
  foreach box $boxes {
    createRouteBlk -box $box -layer {} 
  }
  
}
define_proc_arguments PROC_NAME \
  -info "whatFunction"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
