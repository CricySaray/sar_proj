#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/17 21:19:15 Sunday
# label     : gui_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This proc is used to calculate the rect of the core area enclosed by boundary cells (usually endcap cells), 
#             excluding the boundary cell area. It can automatically remove internal Memory areas (Memory is also enclosed 
#             by boundary cells, but this part of the area needs to be excluded).
# NOTICE    : This proc can only search inward for one layer of Memory or IP areas. If an IP is ring-shaped—meaning there 
#             is a part inside the IP where std cells can be placed—this part of the area will not be included in the final 
#             area where std cells can be placed.  
#             However, usually, it is rare for an IP to be ring-shaped or have a "lake within an island" scenario (where 
#             the "lake" refers to the area where std cells can be placed). Therefore, this proc can handle most cases.
# input     : The input needs to be the boxes of all boundary cells, which can be obtained using the command 
#             [dbget [dbget top.insts.name *ENDCAP* -p].box]. The prerequisite is that these boundary cells must form a complete, 
#             gap-free ring, with corners not connected merely by points (i.e., without corner boundary cells). Such a scenario 
#             is not considered a complete ring and will make it impossible to calculate the correct core area (the area where 
#             std cells can be placed).
# return    : Returns the area where std cells can be placed.
#             {{x y x1 y1} {x y x1 y1} ...}
# ref       : link url
# --------------------------
source ../../../packages/every_any.package.tcl; # every
proc findCoreRectsInsideBoundary {rectsOfAllBoundaryCell} {
  if {![every x $rectsOfAllBoundaryCell { every y $x { string is double $y } }]} {
    error "proc findCoreRectsInsideBoundary: check your input: rectsOfAllBoundaryCell($rectsOfAllBoundaryCell) is invalid!!!"
  } else {
    set rectExp "{[join $rectsOfAllBoundaryCell "} OR {"]}"
    set mergedRects [dbShape -output hrect {*}$rectExp]
    set biggestRect [dbShape -output hrect $mergedRects NOHOLES]
    set rectsRemoveOutermostRectWithSomeHoles [dbShape -output hrect $biggestRect ANDNOT $mergedRects]
    set rectsRemoveBoundaryRectsWithOutHoles [dbShape -output hrect $rectsRemoveOutermostRectWithSomeHoles NOHOLES]
    set memoryRectsInsideRemoveOutermostRectWithOutHoles [dbShape -output hrect $mergedRects INSIDE $rectsRemoveBoundaryRectsWithOutHoles]
    set allMemoryRectInsideCoreRectWithOutBoundaryRects [dbShape -output hrect $memoryRectsInsideRemoveOutermostRectWithOutHoles NOHOLES]
    set rectsDigOutInnerMemoryRects [dbShape -output hrect $rectsRemoveBoundaryRectsWithOutHoles ANDNOT $allMemoryRectInsideCoreRectWithOutBoundaryRects]
    return $rectsDigOutInnerMemoryRects
  }
}
