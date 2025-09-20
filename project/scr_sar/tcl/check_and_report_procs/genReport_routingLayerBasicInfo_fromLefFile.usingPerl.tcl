#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/20 14:41:38 Saturday
# label     : report_proc cross_lang_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : Process LEF files via Perl scripts to obtain the corresponding data, then convert it to data in Tcl's list format, and use procs in Tcl for data interaction with other procs.
# return    : print
# ref       : link url
# --------------------------
source ../packages/table_format_with_title.package.tcl; # table_format_with_title
proc genReport_routingLayerBasicInfo_fromLefFile {args} {
  set perlScriptFileName  ""
  set techlefFileName     ""
  set columWidth          0
  set suffixOuputFileName ""
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$suffixOuputFileName == ""} {
    set outputfilename "sor_routingLayerInfo_fromTechLefFile.table" 
  } else {
    set outputfilename "sor_routingLayerInfo_fromTechLefFile_$suffixOuputFileName.table"
  }
  set routingLayersInfoList {*}[exec perl $perlScriptFileName -type "list" -file $techlefFileName]
  #puts "$routingLayersInfoList"
  set tableOfRoutingLayersInfo [table_format_with_title $routingLayersInfoList]
  #puts $tableOfRoutingLayersInfo
  set fi [open $outputfilename w]
  puts $fi [join $tableOfRoutingLayersInfo \n]
  close $fi
  return [join $tableOfRoutingLayersInfo \n]
}

define_proc_arguments genReport_routingLayerBasicInfo_fromLefFile \
  -info "gen report of routing layer basic info from tech lef file"\
  -define_args {
    {-perlScriptFileName "specify the path name of perl script" AString string optional}
    {-techlefFileName "specify file name of tech lef" AString string optional}
    {-columWidth "specify the width of every column" AInt int optional}
    {-suffixOuputFileName "specify the suffix of output file name" AString string optional}
  }
