#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/22 17:35:18 Wednesday
# label     : eco_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : First, select the inst, then extract the globalNetConnect (GNC) of the pgpin of the selected inst.
# return    : cmds List
# ref       : link url
# --------------------------
proc genCmd_getGlobalNetConnect_GNCinfoOfPgPin_forSelectedInsts {args} {
  set ifClearGNC_atFirst 1
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
}

define_proc_arguments genCmd_getGlobalNetConnect_GNCinfoOfPgPin_forSelectedInsts \
  -info "gen cmd of getting globalNetConnect info of pg pin of selected insts"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
