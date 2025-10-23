#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/23 12:25:19 Thursday
# label     : eco_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Modify GNC (GlobalNetConnect) for the specified insts' pgpin, committed to batch operations, semantically interpreting 
#             command execution rules, and ensuring the command execution process is sequential.
# return    : cmds List
# ref       : link url
# --------------------------
# TO_WRITE
proc genCmd_operateGlobalNetConnect_ofPgPin_forSpecifiedInsts {args} {
  set typeOfOperating "disconnect" ; # disconnect|connect|createPinAndConnect
  set insts [list]
  set typeOfPin "pgpin" ; # pgpin
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
}

define_proc_arguments genCmd_operateGlobalNetConnect_ofPgPin_forSpecifiedInsts \
  -info "gen cmd for operating GNC(globalNetConnect) of pgpin for insts"\
  -define_args {
    {-typeOfOperating "specify the type of operating" oneOfString one_of_string {optional value_type {values {disconnect connect createPinAndConnect}}}}
    {-insts "specify inst to operating" AList list optional}
    {-typeOfPin "specify the type of pin of specified insts" oneOfString one_of_string {optional value_type {values {pgpin}}}}
  }
