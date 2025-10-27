#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/27 20:59:39 Monday
# label     : eco_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Fix the two types of DRC errors, VTL_N or VTL_P, by replacing the VT type of the filler.
# return    : cmds list
# ref       : link url
# --------------------------
proc genCmd_fixVTL_P_orVTL_N {args} {
  set markersNameList    [list VTL_N.S.1 VTL_P.S.1]
  set prefixOfToCelltype "LVT"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set boxes [lmap temp_marker $markersNameList {
    set temp_box [dbget [dbget top.markers.userType $temp_marker -p].box]
  }]
  set insts [dbget [dbQuery -areas $boxes -objType inst -enclose_only].name]
  if {$insts eq ""} {
    error "proc genCmd_fixVTL_P_orVTL_N: have no inst to get when markers == $markersNameList  !!!" 
  } else {
    set cmdsList [lmap temp_inst $insts {
      set temp_celltype [dbget [dbget top.insts.name $temp_inst -p].cell.name -e]
      if {[regexp {BWP$} $temp_celltype]} {
        set temp_celltype [string cat $temp_celltype $prefixOfToCelltype] 
      }
    }] 
  }
}

define_proc_arguments genCmd_fixVTL_P_orVTL_N \
  -info "whatFunction"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
