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
  set bufferCelltypeExp {^(DC)?CKB.*} ; # using regexp -expanded
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
    # attachTerm inst cellpin netname
    if {[llength $temp_line] < 4} {
      incr errorCmdNum
      lappend checkResultList "ERROR(column should >= 4): line $linenum: $temp_line"
      continue
    }
    lassign $temp_line temp_attachTerm_cmd temp_inputinst temp_inputcellpin 
    regexp {.*get_nets\s+-of\s+([0-9a-zA-Z/_]+).*} $temp_line -> temp_output_instpin
    #set temp_timing_point_pins_col [all_fanout -from $temp_output_instpin -to $temp_inputinst/$temp_inputcellpin -only_cells]
    set flagInputOutputPinError 0
    if {[dbget top.insts.instTerms.name $temp_inputinst/$temp_inputcellpin -e] eq "" || ![dbget [dbget top.insts.instTerms.name $temp_inputinst/$temp_inputcellpin -p].isInput]} {
      lappend checkResultList "ERROR(input pin is invalid\[$temp_inputinst/$temp_inputcellpin\]): line $linenum: $temp_line"
      set flagInputOutputPinError 1
    } 
    if {[dbget top.insts.instTerms.name $temp_output_instpin -e] eq "" || ![dbget [dbget top.insts.instTerms.name $temp_output_instpin -p].isOutput]} {
      lappend checkResultList "ERROR(output pin is invalid\[$temp_output_instpin\]): line $linenum: $temp_line"
      set flagInputOutputPinError 1
    } 
    if {$flagInputOutputPinError} { incr errorCmdNum ; continue }

    # get timing path that need to check
    set temp_timing_point_pins_col [get_property [get_property [report_timing -collection -from $temp_output_instpin -to $temp_inputinst/$temp_inputcellpin] points] pin] ; #  这里的startpoint和endpoint不是data path上的，获取不到的。需要另想办法
    set temp_checkTimingPinCol $temp_timing_point_pins_col
    set flag_startRecordCheckTimingPath 0
    foreach_in_collection temp_pin_itr $temp_timing_point_pins_col {
      if {[get_object_name $temp_pin_itr] eq $temp_output_instpin} {
        set flag_startRecordCheckTimingPath 1
        set temp_checkTimingPinCol [remove_from_collection $temp_checkTimingPinCol $temp_pin_itr]
        continue
      } elseif {[get_object_name $temp_pin_itr] eq $temp_inputinst/$temp_inputcellpin} {
        set flag_startRecordCheckTimingPath 0
        set temp_checkTimingPinCol [remove_from_collection $temp_checkTimingPinCol $temp_pin_itr]
      } else {
        if {$flag_startRecordCheckTimingPath} {
          continue
        } else {
          set temp_checkTimingPinCol [remove_from_collection $temp_checkTimingPinCol $temp_pin_itr]
        }
      }
    }
    set temp_checkTimingInstNameList [lsort -u [get_property $temp_checkTimingPinCol cell_name]]

    # have non buffer or inverter cell
    set temp_error_notBufferOrInverter [list]
    foreach temp_inst $temp_checkTimingInstNameList {
      set temp_celltype [dbget [dbget top.insts.name $temp_inst -p].cell.name -e]
      if {![regexp -expanded $bufferCelltypeExp $temp_celltype] || ![regexp -expanded $inverterCelltypeExp $temp_celltype]} {
        lappend temp_error_notBufferOrInverter "ERROR:  $temp_celltype $temp_inst"
      }
    }
    if {$temp_error_notBufferOrInverter ne ""} {
      incr errorCmdNum 
      lappend checkResultList "ERROR(have non inverter/buffer cell): line $linenum: $temp_line"
      lappend checkResultList {*}$temp_error_notBufferOrInverter
      continue
    }

    # get inverter cell, remove buffer cell
    set temp_checkTimingCelltypeInverter [lmap temp_inst $temp_checkTimingInstNameList {
      set temp_celltype [dbget [dbget top.insts.name $temp_inst -p].cell.name -e]
      if {![regexp -expanded $inverterCelltypeExp $temp_celltype]} { continue } else {
        list $temp_celltype $temp_inst
      }
    }]

    # inverter num is not even number
    set temp_num_of_middle_inverter_cell [llength $temp_checkTimingCelltypeInverter]
    if {!$temp_num_of_middle_inverter_cell} {
      incr errorCmdNum
      lappend checkResultList "ERROR(0 inverter cell): line $linenum: $temp_line"
      continue
    }
    if {[expr {$temp_num_of_middle_inverter_cell % 2}]} {
      incr errorCmdNum
      lappend checkResultList "ERROR: line $linenum: $temp_line"
      foreach temp_cell_inst $temp_checkTimingCelltypeInverter {
        lappend checkResultList "ERROR:   middle inverter: $temp_cell_inst"
      }
    } else {
      incr successCmdNum
      lappend checkResultList "SUCCESS: line $linenum: $temp_line"
      foreach temp_cell_inst $temp_checkTimingCelltypeInverter {
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
    {-bufferCelltypeExp "specify the buffer celltype regexp expression" AString string optional}
  }
