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
proc genSum_usingTable {} {
  set targetDir "./"
  set prefixOfFilename "signoff_check_"
  set allResultFilenam [glob -nocomplain $targetDir/$prefixOfFilename*]
  if {$allResultFilenam ne ""} {
    foreach temp_resultfile $allResultFilenam {
      set endline [_get_endLineOfFile $temp_resultfile]
      if {[expr {[llength $endline] % 2 == 1}]}
    }
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
