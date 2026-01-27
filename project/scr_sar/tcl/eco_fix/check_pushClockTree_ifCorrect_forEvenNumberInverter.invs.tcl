#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/01/27 18:19:35 Tuesday
# label     : check_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Please use the format of 'attachTerm instname cellpinname [get_object_name [get_nets -of instpinname]]' to write valid 
#             commands. This can also prevent situations where net names change in some ECOs.
#
# return    : 
# ref       : link url
# --------------------------
proc check_pushClockTree_ifCorrect_forEvenNumberInverter {args} {
  set inputFilename ""
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {![file exists $inputFilename]} {
    error "proc check_pushClockTree_ifCorrect_forEvenNumberInverter: check your input file name (not exists): $inputFilename"
  }
  set fi [open $inputFilename]
  set content [split [read $fi] \n]
  close $fi
  set attachTermsCmdList [lsearch -regexp -all -inline $content {^\s*attachTerm}]
  puts [join $attachTermsCmdList \n]
  
}
define_proc_arguments check_pushClockTree_ifCorrect_forEvenNumberInverter \
  -info "whatFunction"\
  -define_args {
    {-inputFilename "specify file name to check" AString string optional}
  }
