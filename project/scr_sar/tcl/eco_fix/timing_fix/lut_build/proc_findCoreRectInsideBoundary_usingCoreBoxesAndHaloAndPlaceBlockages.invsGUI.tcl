#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/12/28 19:26:46 Sunday
# label     : 
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
proc proc_findCoreRectInsideBoundary_usingCoreBoxesAndHaloAndPlaceBlockages_withBoundaryRects {} {
  set coreBoxes [dbShape [dbget top.fplan.rows.box -e] -output hrect]
  set memOrIps_ptrs [dbget top.insts.pstatus {^placed|^fixed} -regexp -p]
  set memOrIpsRects [lmap temp_inst_ptr $memOrIps_ptrs {
    set temp_rect [dbShape -output hrect [dbget $temp_inst_ptr.pHaloPoly -e]]
  }]
  set valideMemOrIpsRects [dbShape -output hrect $memOrIpsRects]
  set hardBlkgRects [dbShape -output hrect [dbget [dbget top.fplan.pBlkgs.type hard -p].boxes]]
  set memOrIpsOrHardBlkgsRects [dbShape -output hrect $valideMemOrIpsRects OR $hardBlkgRects]
  set coreRectsWithOutMemIpHardblkgs [dbShape -output hrect $coreBoxes ANDNOT $memOrIpsOrHardBlkgsRects]
  return $coreRectsWithOutMemIpHardblkgs
}
proc proc_findCoreRectInsideBoundary_usingCoreBoxesAndHaloAndPlaceBlockages {rects_of_boundary_cells} {
  set coreBoxes [dbShape [dbget top.fplan.rows.box -e] -output hrect]
  set memOrIps_ptrs [dbget top.insts.pstatus {^placed|^fixed} -regexp -p]
  set memOrIpsRects [lmap temp_inst_ptr $memOrIps_ptrs {
    set temp_rect [dbShape -output hrect [dbget $temp_inst_ptr.pHaloPoly -e]]
  }]
  set valideMemOrIpsRects [dbShape -output hrect $memOrIpsRects]
  set hardBlkgRects [dbShape -output hrect [dbget [dbget top.fplan.pBlkgs.type hard -p].boxes]]
  set memOrIpsOrHardBlkgsRects [dbShape -output hrect $valideMemOrIpsRects OR $hardBlkgRects]
  set coreRectsWithOutMemIpHardblkgs [dbShape -output hrect $coreBoxes ANDNOT $memOrIpsOrHardBlkgsRects]
  set coreRectsWithOutMemIpHardblkgsBoundaryCells [dbShape -output hrect $coreRectsWithOutMemIpHardblkgs ANDNOT $rects_of_boundary_cells]
  return $coreRectsWithOutMemIpHardblkgsBoundaryCells
}
