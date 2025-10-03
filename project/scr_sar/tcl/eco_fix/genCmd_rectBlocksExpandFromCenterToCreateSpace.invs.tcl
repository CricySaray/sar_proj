#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/03 10:57:19 Friday
# label     : eco_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : In areas of the invs where the local density is particularly high, it is sometimes necessary to insert buffers, inverters, or delay cells here. However, the RefinePlace 
#             command cannot legalize these instances. Therefore, it is required to move by spreading outward from the high-density center. This proc carries certain risks; it 
#             conducts large-scale analysis and then provides a movement strategy, so it needs to be used with caution.
# test example: SC5019_TOP: V0926_S0926_FP0926_092600_100_dft_v3_eco2_br_eco4_br_eco10_fixSetupHold_trans_inDMSA
#               it has some local high density area, which you can have a try using it as a test version
# return    : cmds list
# ref       : link url
# --------------------------
# TO_WRITE
proc genCmd_rectBlocksExpandFromCenterToCreateSpace {args} {
  
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }

}
define_proc_arguments genCmd_rectBlocksExpandFromCenterToCreateSpace \
  -info "gen cmd for rect blocks expanded from center to create space"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
