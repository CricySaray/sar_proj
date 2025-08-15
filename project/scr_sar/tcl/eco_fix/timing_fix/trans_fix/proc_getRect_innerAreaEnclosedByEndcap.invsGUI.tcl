#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/15 17:59:32 Friday
# label     : gui_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : get rects of inner area that is enclosed by boundary cell(endcap cell)
# return    : rects {{1 1 2 2} {2 2 3 3} ...}
# ref       : link url
# --------------------------
source ../lut_build/operateLUT.tcl; # operateLUT
proc getRect_innerAreaEnclosedByEndcap {} {
  set coreRects [operateLUT -type read -attr {core_rects}]
  set instsHaveHalo_ptr [dbget top.insts.isHaloBlock 1 -p]
  set allRects [lmap inst_ptr $instsHaveHalo_ptr {
    set temp_hrect [dbShape -output hrect [dbget $inst_ptr.pHaloPoly]] 
  }]
}
