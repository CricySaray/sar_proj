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
