#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/18 16:31:13 Thursday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|misc_proc)
#   perl -> (format_sub)
# descrip   :  A simple addFiller procedure
# return    : run cmd of addFiller
# ref       : link url
# --------------------------
# TO_WRITE
# TO_IMPROVE
proc runCmd_addFiller {args} {
  set fillerList      {FILL1BWP FILL2BWP FILL3BWP FILL4BWP FILL8BWP FILL16BWP FILL32BWP}
  set decapFillerList {TAPCELLBWP}
  set prefixOfFiller  "FILL_"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  deleteFiller -prefix $prefixOfFiller
  setFillerMode -reset
  setFillerMode -core [concat $fillerList $decapFillerList]
  setFillerMode -corePrefix $prefixOfFiller
  addFiller
  checkFiller
}

define_proc_arguments runCmd_addFiller \
  -info "whatFunction"\
  -define_args {
    {-fillerList "specify the list of filler cell" AString string optional}
    {-decapFillerList "specify the list of decap filler cell" AString string optional}
    {-prefixOfFiller "specify the prefix of filler" AString string optional}
  }
