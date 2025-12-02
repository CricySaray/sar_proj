#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/12/02 15:34:39 Tuesday
# label     : 
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
proc check_length_ofMemBufferToMem {args} {
  set instExp {_BUF_}
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set insts_core [dbget -regexp [dbget -regexp top.insts.pstatus {placed|fixed} -p].name $instExp]
  foreach temp_inst $insts_core {
    set inputTerm [lindex [dbget [dbget [dbget top.insts.name $temp_inst -p].instTerms.isInput 1 -p].name] 0]
    set outputTerm [lindex [dbget [dbget [dbget top.insts.name $temp_inst -p].instTerms.isOutput 1 -p].name ] 0]
  }
  
}

define_proc_arguments check_length_ofMemBufferToMem \
  -info "whatFunction"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
