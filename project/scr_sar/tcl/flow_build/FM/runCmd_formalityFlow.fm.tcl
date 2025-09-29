#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/29 19:30:23 Monday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : simple formal flow
# return    : /
# ref       : link url
# --------------------------
proc runCmd_formalityFlow {args} {
  set designName       ""
  set dbList           "" ; # can be any rc corner db list
  set referenceNetlist ""
  set implementNetlist ""
  set logFileName      ""
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {![every x [list $referenceNetlist $implementNetlist] {file isfile $x}]} {
    error "proc runCmd_formalityFlow: check your input: referenceNetlist($referenceNetlist) or implementNetlist($implementNetlist) is not found!!!" 
  } else {
    if {$dbList == ""} {
      error "proc runCmd_formalityFlow: check your input: dbList($dbList) is empty!!!" 
    } else {
      if {![file isdirectory [file dirname $logFileName]]} {
        error "proc runCmd_formalityFlow: check your input: dirname([file dirname $logFileName]) of logFileName($logFileName) is not a directory"
      }
    }
  }
}

define_proc_arguments runCmd_formalityFlow \
  -info "run cmd of Formality flow"\
  -define_args {
    {-designName "specify the design name" AString string optional}
    {-dbList "specify any rc corner db list" AList list optional}
    {-referenceNetlist "specify reference netlist path" AString string optional}
    {-implementNetlist "specify implement netlist path" AString string optional}
    {-logFileName "specify the log file name" AString string optional}
  }
