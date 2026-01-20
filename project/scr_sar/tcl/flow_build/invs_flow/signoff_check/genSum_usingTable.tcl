#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/01/20 17:53:55 Tuesday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : gen sum file using table
# return    : output file and format list
# ref       : link url
# --------------------------
source ../../common/sort_list_by_referencelist.common.tcl; # sort_list_by_referencelist
source ../../../packages/table_format_with_title.package.tcl; # table_format_with_title
proc genSum_usingTable {} {
  set targetDir "./"
  set prefixOfFilename "signoff_check_"
  set sumFilename "sum_subblock.csv"
  set allResultFilenam [glob -nocomplain $targetDir/$prefixOfFilename*]
  set checkItemsOrder {antennaCell weakDriveInstNetLength clockCellFixed clockPathLength clockTreeCells dataPathLength decapDensity \
    delayCellInClockTreeLeaf delayCellLevel dfmVia dontTouchCell dontUseCell inputTermsFloating ipMemInputBufCellDriveSize ipMemPinNetLength \
    maxFanout missingVia place portNetLength signalNetOutofDieAndOverlapWithRoutingBlkg stdUtilization tieCellLoadLength tieFanout vtRatio}
  set finalSumList [list]
  if {$allResultFilenam ne ""} {
    foreach temp_resultfile $allResultFilenam {
      set endline [_get_endLineOfFile $temp_resultfile]
      if {![llength $endline]} {
        error "proc genSum_usingTable: check your input file(have no content of end line): $temp_resultfile"
      } elseif {[expr {[llength $endline] % 2}] == 1} {
        error "proc genSum_usingTable: check your end line of file(not even item): $temp_resultfile" 
      } else {
        for {set i 0} {$i < [llength $endline]} {incr i 2} {
          lappend finalSumList [list [lindex $endline $i] [lindex $endline [expr $i + 1]]]
        }
      }
    }
    set finalSumList [sort_list_by_referencelist $checkItemsOrder $finalSumList 0 0]
    set finalSumTransposedList [list]
    set temp_firstRowList [list]
    set temp_secondRowList [list]
    foreach temp_item $finalSumList {
      lappend temp_firstRowList [lindex $temp_item 0]
    }
    foreach temp_item $finalSumList {
      lappend temp_secondRowList [lindex $temp_item 1]
    }
    set finalSumTransposedList [list $temp_firstRowList $temp_secondRowList]
    set fo [open $sumFilename w]
    puts $fo [join [table_format_with_title $finalSumTransposedList 0 left "" 0] \n]
    close $fo
  } else {
    error "proc genSum_usingTable: check your input: targetDir($targetDir) have on matched result file." 
  }
}

proc _get_endLineOfFile {{filename ""}} {
  if {$filename eq ""} {
    error "proc _get_endLineOfFile: check your input filename, it is empty!!!" 
  } elseif {![file exists $filename]} {
    error "proc _get_endLineOfFile: check your input filename(not exists): $filename"
  } else {
    set endline [lindex [split [exec cat $filename | grep -v "^\s*$"] "\n"] end]
    return $endline
  }
}
