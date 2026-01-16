#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/16 10:59:52 Friday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check place
# return    : output file and format list
# ref       : link url
# --------------------------
proc check_place {args} {
  set rptName "signoff_check_place.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set rootdir [lrange [split $rptName "/"] 0 end-1]
  set temp_filename [lindex [split $rptName "/"] end]
  set middle_file [join [concat $rootdir middleFile_$temp_filename] "/"]
  checkPlace -ignoreFillerInUtil > $middle_file
  set fi [open $middle_file r]
  set temp_content [split [read $fi] "\n"]
  close $fi
  set overlapNum [lindex [lsearch -regexp -inline $temp_content "^Overlapping with other instance: "] end]
  set temp_fillerGapsList [lsearch -regexp -all -inline $temp_content "^FillerGap Violation:"]
  set fillerGapNum 0
  foreach temp_fillergap $temp_fillerGapsList {
    set temp_fillernum [lindex $temp_fillergap end] 
    set fillerGapNum [expr $fillerGapNum + int($temp_fillernum)]
  }
  set unplacedInstNum [lindex [lsearch -regexp -inline $temp_content "\\*info: Unplaced ="] end]
  set densityRatio [lindex [regexp -inline -expanded {\d+(\.\d+)?%} [lsearch -regexp -inline $temp_content "^Placement Density:"]] 0]
  if {$overlapNum eq ""} { set overlapNum 0 }
  set fo [open $rptName w]
  puts $fo "overlapNum $overlapNum fillerGapNum $fillerGapNum unplacedInstNum $unplacedInstNum densityRatio $densityRatio"
  close $fo
  return [list overlapNum $overlapNum fillerGapNum $fillerGapNum unplacedInstNum $unplacedInstNum densityRatio $densityRatio]
}

define_proc_arguments check_place \
  -info "check place"\
  -define_args {
    {-rptName "specify output file name" AString string optional}
  }
