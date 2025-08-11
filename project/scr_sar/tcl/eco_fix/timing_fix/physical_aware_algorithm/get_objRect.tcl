#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/11 10:06:22 Monday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : get name+rect list of obj(instance)
# return    : {{instname {x y x1 y1}} {instname2 {x y x1 y1}} ...}
# ref       : link url
# --------------------------
proc get_objRect {{BoxList {}}} {
  set instsInRect_enclosed_ptr [dbQuery -areas $BoxList -objType inst -enclosed_only]
  set instsInRect_overlap_ptr [dbQuery -areas $BoxList -objType inst -overlap_only]
  set instsInRect_ptr [concat $instsInRect_enclosed_ptr $instsInRect_overlap_ptr]
  set instName_rect_D2List [lmap temp_inst_ptr $instsInRect_ptr {
    set tempinstname [dbget $temp_inst_ptr.name]
    set tempinstrect [lindex [dbget $temp_inst_ptr.box] 0]
    set temp_inst_rect [list $tempinstname $tempinstrect]
  }]
  return $instName_rect_D2List
}
