#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/02/03 15:05:19 Tuesday
# label     : task_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : fix max cap using proc of fixing trans
# return    : output file
# ref       : link url
# --------------------------
source ../trans_fix/fix_trans.invs.tcl; # fix_trans
proc fix_maxcap {args} {
  set file_viol_pin ""
  set violValue_pin_columnIndex {end-1 0}
  set ecoNewInstNamePrefix "sar_eco1_fix_max_cap_020315"
  set suffixFilename "eco1_fix_max_cap_020315"
  set canChangeVtCapacityWhenAddingRepeater 1
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  fix_trans -file_viol_pin $file_viol_pin -violValue_pin_columnIndex $violValue_pin_columnIndex -ecoNewInstNamePrefix $ecoNewInstNamePrefix -suffixFilename $suffixFilename \
    -canChangeVT 0 -canChangeDriveCapacity 0 -canChangeVtWhenChangeCapacity 0 -canAddRepeater 1 -canChangeVtCapacityWhenAddingRepeater $canChangeVtCapacityWhenAddingRepeater
}

define_proc_arguments fix_maxcap \
  -info "fix max cap"\
  -define_args {
    {-file_viol_pin "specify violation filename" AString string required}
    {-violValue_pin_columnIndex "specify the column of violValue and pinname" AList list optional}
    {-canChangeVtCapacityWhenAddingRepeater "if can change vt and capacity when adding repeater" oneOfString one_of_string {optional value_type {values {0 1}}}}
    {-ecoNewInstNamePrefix "specify a new name for inst when adding new repeater" AList list required}
    {-suffixFilename "specify suffix of result filename" AString string optional}
  }
