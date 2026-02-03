#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/07 23:22:55 Thursday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : fix long net situation.
# return    : solutions of eco cmds for fixing long nets
# ref       : link url
# --------------------------
source ../trans_fix/fix_trans.invs.tcl; # fix_trans
source ../../../flow_build/common/convert_file_to_list.common.tcl; # convert_file_to_list
proc fix_longnet {args} {
  set violValueByUser                         -0.05
  set file_longnetname                        ""
  set ecoNewInstNamePrefix                    ""
  set suffixFilename                          ""
  set temp_middle_file                        ".temp_middle_file.viol.rpt"
  set ifcanChangeVtCapacityWhenAddingRepeater 1
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set longnetlist [convert_file_to_list $file_longnetname]
  set fo [open $temp_middle_file w]
  foreach temp_longnet $longnetlist {
    set temp_driverPin [dbget [dbget [dbget top.nets.name $temp_longnet -p].instTerms.isOutput 1 -p].name]
    puts $fo "$violValueByUser $temp_driverPin"
  }
  close $fo
  fix_trans -file_viol_pin $temp_middle_file -violValue_pin_columnIndex {0 1} -canChangeVT 0 -canChangeDriveCapacity 0 -canChangeVtWhenChangeCapacity 0 -canAddRepeater 1 -canChangeVtCapacityWhenAddingRepeater $ifcanChangeVtCapacityWhenAddingRepeater -ecoNewInstNamePrefix $ecoNewInstNamePrefix -suffixFilename $suffixFilename
}

define_proc_arguments fix_longnet \
  -info "fix long net"\
  -define_args {
    {-violValueByUser "specify the viol value by user" AString string optional}
    {-file_longnetname "specify the file name of long net name" AString string optional}
    {-temp_middle_file "specify the temp middle file name" AString string optional}
    {-ifcanChangeVtCapacityWhenAddingRepeater "if can change vt and capacity when adding repeater" AInt int {optional value_type {values {0 1}}}}
    {-ecoNewInstNamePrefix "specify a new name for inst when adding new repeater" AList list required}
    {-suffixFilename "specify suffix of result filename" AString string required}
  }
