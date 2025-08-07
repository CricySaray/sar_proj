source ./judge_ifHaveSpaceToInsertBuffer.invs.tcl; # judge_ifHaveSpaceToInsertBuffer
source ./proc_get_blank_box.invs.tcl; # get_blank_box
proc test_judge_haveSpaceToInsertBuffer {instname} {
  set inst_ptr [dbget top.insts.name $instname -p]
  set instWidth [dbget $inst_ptr.box_sizex]
  set instHeight [dbget $inst_ptr.box_sizey]
  set instPt [lindex [dbget $inst_ptr.pt] 0]
  set blankBoxList [lindex [get_blank_box $instPt] 0]
  set blankWidthHeight [lmap temp $blankBoxList { db_rect -size $temp }]
  set ifHaveSpaceToInsertBuffer [judge_ifHaveSpaceToInsertBuffer [list $instWidth $instHeight] $blankBoxList]
  puts "instWidth: $instWidth | instHeight: $instHeight | instPt : $instPt \n blankBoxList: $blankBoxList \n $blankWidthHeight \n ifHaveSpaceToInsertBuffer: $ifHaveSpaceToInsertBuffer"
}
