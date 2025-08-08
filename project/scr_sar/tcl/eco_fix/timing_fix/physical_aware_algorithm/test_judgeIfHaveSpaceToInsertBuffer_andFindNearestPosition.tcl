#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/08 08:22:09 Friday
# label     : test_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : test and debug the correction of proc(judge_ifHaveSpaceToInsertBuffer_findNearestPosition) 
# return    : message prompt
# ref       : link url
# --------------------------
source ./judge_ifHaveSpaceToInsertBuffer_findNearestPosition.invs.tcl; # judge_ifHaveSpaceToInsertBuffer_findNearestPosition
source ./proc_get_blank_box.invs.tcl; # get_blank_box
proc test_judge_haveSpaceToInsertBuffer {instname} {
  set inst_ptr [dbget top.insts.name $instname -p]
  set instWidth [dbget $inst_ptr.box_sizex]
  set instHeight [dbget $inst_ptr.box_sizey]
  set instPt [lindex [dbget $inst_ptr.pt] 0]
  set instBox [lindex [dbget $inst_ptr.box] 0]
  set instPtCenter [db_rect -center $instBox]
  set blankBoxList [lindex [get_blank_box $instPt] 0]
  set blankWidthHeight [lmap temp $blankBoxList { db_rect -size $temp }]
  set ifHaveSpaceToInsertBuffer [judge_ifHaveSpaceToInsertBuffer_findNearestPosition $instPtCenter [list $instWidth $instHeight] $blankBoxList]
  puts "instWidth: $instWidth | instHeight: $instHeight | instPt : $instPt \n ifHaveSpaceToInsertBuffer: [lindex $ifHaveSpaceToInsertBuffer 0] with distance: [lindex $ifHaveSpaceToInsertBuffer 1]"
}
