#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/19 15:03:59 Friday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : By obtaining the positions of the pre-placed BOUNDARY cells in the invs db (it must be ensured that the BOUNDARY cells are placed correctly without errors), 
#             different power domains (or disconnected regions) are divided. Then, the gaps (narrow channels) between these power domains that meet the threshold requirements 
#             are identified, and RouteBlk is added in these regions to prevent the addition of redundant pg nets in these areas during powerPlan.
# return    : cmds list
# ref       : link url
# --------------------------
source ../packages/find_connected_regions.package.tcl; # find_connected_regions
source ../packages/find_narrow_channels.package.tcl; # find_narrow_channels
source ../eco_fix/timing_fix/lut_build/proc_findCoreRectInsideBoundary.invsGUI.tcl; # findCoreRectsInsideBoundary_withBoundaryArea
proc genCmd_add_routeBlk_for_gap_betweenDifferentEndcapGroups {{narrowChannelWidthThreshold 10} {off -1} {prefixNameOfBoundaryInsts "ENDCAP"} {routeBlkPrefix "autoGen_sar"} {layer {1 2 3 4 5 6}} {cutLayerOrViaLayer {1 2 3 4 5}} {debug 0}} {
  set boundaryInstsBox [concat [dbget [dbget top.insts.name ${prefixNameOfBoundaryInsts}* -p].box -e] [dbget [dbget top.insts.name */${prefixNameOfBoundaryInsts}* -p].box -e]]
  set coreInnerBoundaryWithBoundaryRects [findCoreRectsInsideBoundary_withBoundaryArea $boundaryInstsBox]
  set groupedForRects [lrange [find_connected_regions $coreInnerBoundaryWithBoundaryRects] 1 end]
  if {[llength $groupedForRects] == 1} {
    error "proc genCmd_add_routeBlk_for_gap_betweenDifferentEndcapGroups: only gen ONE group of rects, can't find the narrow channels!!!" 
  }
  set narrowChannelsList [find_narrow_channels $groupedForRects $narrowChannelWidthThreshold $off $debug]
  set cmdsList [list]
  foreach temp_channel $narrowChannelsList {
    lappend cmdsList "createRouteBlk -name $routeBlkPrefix -box \{$temp_channel\} -layer \{$layer\} -cutLayer \{$cutLayerOrViaLayer\}"
  }
  return $cmdsList
}
