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
  set inverterCelltypeExp {^(DC)?CKN.*} ; # using regexp -expanded
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

  # reserved function:
  set attachTermsCmdList [lsearch -regexp -all -inline $content {^\s*attachTerm}]
  # puts [join $attachTermsCmdList \n]


  set linenum 0
  set attachTermCmdNum 0
  set errorCmdNum 0
  set successCmdNum 0
  set checkResultList [list]
  foreach temp_line $content {
    incr linenum
    if {![regexp -expanded {^\s*attachTerm } $temp_line]} { continue }
    incr attachTermCmdNum
    lassign $temp_line temp_inputinst temp_inputcellpin 
    regexp {.*get_nets\s+-of\s+([0-9a-zA-Z/_]+).*} $temp_line -> temp_output_instpin
    set temp_insts_usingAllFanoutCmd [all_fanout -from $temp_output_instpin -to $temp_inputinst/$temp_inputcellpin -only_cells]
    set temp_middle_insts $temp_insts_usingAllFanoutCmd
    set temp_middle_insts [lsearch -not -all -inline -exact $temp_middle_insts "$temp_inputinst"]
    set temp_middle_insts [lsearch -not -all -inline -exact $temp_middle_insts [join [lrange [split $temp_output_instpin "/"] 0 end-1] "/"]]
    set temp_inverter_middle_insts [lmap temp_inst $temp_middle_insts {
      set temp_cellname [dbget [dbget top.insts.name $temp_inst -p].cell.name -e] 
      if {[regexp $inverterCelltypeExp $temp_cellname]} {
        set temp_cell_inst [list $temp_cellname $temp_inst]
      } else { continue }
    }]
    set temp_num_of_middle_inverter_cell [llength $temp_inverter_middle_insts]
    if {[expr {$temp_num_of_middle_inverter_cell % 2}]} {
      incr errorCmdNum
      lappend checkResultList "ERROR: line $linenum: $temp_line"
      foreach temp_cell_inst $temp_inverter_middle_insts {
        lappend checkResultList "ERROR:   middle inverter: $temp_cell_inst"
      }
    } else {
      incr successCmdNum
      lappend checkResultList "SUCCESS: line $linenum: $temp_line"
      foreach temp_cell_inst $temp_inverter_middle_insts {
        lappend checkResultList "SUCCESS:   middle inverter: $temp_cell_inst" 
      }
    }
  }
  if {$errorCmdNum} {
    set checkResultList [linsert $checkResultList 0 "ERROR lines, must check it!!!:"]
  } else {
    set checkResultList [linsert $checkResultList 0 "SUCCESS for all cmds!!!"]
  }
  set checkResultList [linsert $checkResultList 0 ""]
  set checkResultList [linsert $checkResultList 0 "ALL attachTerm cmds num: $attachTermCmdNum"]

  return $checkResultList
  
}
define_proc_arguments check_pushClockTree_ifCorrect_forEvenNumberInverter \
  -info "whatFunction"\
  -define_args {
    {-inputFilename "specify file name to check" AString string optional}
    {-inverterCelltypeExp "specify the inverter celltype regexp expression" AString string optional}
  }
