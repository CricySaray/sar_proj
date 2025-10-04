#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/04 14:29:54 Saturday
# label     : dump_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : Output various types of data for the chipfinish phase, with everything designed to facilitate easy usage and access.
# return    : output data for pv/starrc/pt/pa
# ref       : link url
# --------------------------
source ../flow_build/invs_flow/runCmd_addFiller.invs.tcl; # runCmd_addFiller
proc dumpData_forChipfinish {args} {
  set designName                                    "SC5019_TOP"
  set inputInvsDB                                   ""
  set mapFileForGDS                                 ""
  set suffixForDumpedDataFile                       "" ; # you can input version name
  set listOfIncludePhysicalCellForNetlistWithPGinfo {FILL1BWP FILL2BWP FILL3BWP FILL4BWP FILL8BWP FILL16BWP FILL32BWP TAPCELLBWP}
  set listOfExcludeCellForLVSnetlist                {FILL1BWP FILL2BWP FILL3BWP FILL4BWP FILL8BWP FILL16BWP FILL32BWP TAPCELLBWP ...}
  set outputDir                                     "./"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  restoreDesign $inputInvsDB $designName
  runCmd_addFiller
  set lefDefOutVersion 5.8
  set defOutLefNDR 1
  set defOutLefVia 1
  set dbgLefDefOutVersion 5.8
  set dbgDefOutFixedViasShape 1
  set gdsUnit [dbGet head.dbUnits]
  remove_assigns
  deleteEmptyModule
  # lef
  write_lef_abstract $outputDir/$designName.lef -PgpinLayer 6 -specifyTopLayer 6 -stripePin -extractBlockObs
  # def
  defOut -routing -usedVia -wrongwa
}

define_proc_arguments dumpData_forChipfinish \
  -info "dump data for stage of chipfinish"\
  -define_args {
    {-outputDir "specify the output directory" AString string optional}
    {-suffixForDumpedDataFile "specify the suffix for dumped data output file" AString string optional}
    {-designName "specify the design name for block or chip" AString string optional}
    {-listOfIncludePhysicalCellForNetlistWithPGinfo "specify the list of includePhysicalCell of cmd: saveNetlist for netlist with PG info" AList list optional}
    {-listOfExcludeCellForLVSnetlist "specify the excludeCell of cmd: saveNetlist for netlist for LVS" AList list optional}
  }
