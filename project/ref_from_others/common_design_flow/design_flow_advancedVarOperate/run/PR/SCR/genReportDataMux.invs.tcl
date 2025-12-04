#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/15 13:27:25 Wednesday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : 
# return    : 
# ref       : link url
# --------------------------
source ~/project/scr_sar/tcl/check_and_report_procs/genReport_vt_ratio_count.invs.tcl; # genReport_vt_ratio_count
proc genReportDataMux {args} {
  set stage              "" ; # init|preplace|preplace_drc|place|cts|postcts|route|postroute|chipfinish
  set designName         ""
  set outputDir          "./"
  set suffixOfOutputFile ""

  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$suffixOfOutputFile == ""} {
    set outputReportFile "$outputDir/${designName}.$stage.<body>.rpt"
  } else {
    set outputReportFile "$outputDir/${designName}.$stage.<body>.$suffixOfOutputFile.rpt"
  }
  set mapFilename [list apply {{body} {upvar 1 outputReportFile tempReportFile ; string map [list <body> $body] $tempReportFile}}]
  switch -regexp $stage {
    "init" {
      checkUnique -verbose > [eval $mapFilename checkUnique]
      checkNetlist -output [eval $mapFilename checkNetlist]
      checkDesign -danglingNet -netlist -physicalLibrary -timingLibrary -noHtml -outfile [eval $mapFilename checkDesign]
      check_timing -varbose > [eval $mapFilename check_timing]
      timeDesign -prePlace -expandedViews -prefix "${designName}.${stage}.setup" -outdir $outputDir
      summaryReport -noHtml -outfile [eval $mapFilename design_summary]
      genReport_vt_ratio_count -outputFilename [eval $mapFilename vt_ratio_count]
    } 
    "preplace" {
      checkPlace > [eval $mapFilename checkPlace]
      reportIgnoredNets -outfile [eval $mapFilename reportIgnoredNets]
    }
  }
  
}
define_proc_arguments genReportDataMux \
  -info "multiplexer of generating reports and data"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
