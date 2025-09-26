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
# BUG       : When adding routeBlk in the gaps, some of the shapes do not meet the expected requirements. They are larger than intended and need to be modified manually. 
#             In the currently tested cases, when adding 4 rectangular routeBlks, 1 of them does not meet the expectations. So far, the cause of the problem has not been debugged.
# return    : cmds list
# ref       : link url
# --------------------------
source ../packages/find_connected_regions.package.tcl; # find_connected_regions
source ../packages/find_narrow_channels.package.tcl; # find_narrow_channels
source ../eco_fix/timing_fix/lut_build/proc_findCoreRectInsideBoundary.invsGUI.tcl; # findCoreRectsInsideBoundary_withBoundaryArea
proc genCmd_addRouteBlk_for_gap_betweenDifferentEndcapGroups {args} {
  set narrowChannelWidthThreshold 10
  set off                         -1
  set prefixNameOfBoundaryInsts   "ENDCAP"
  set routeBlkPrefix              "autoGen_sar"
  set layers                       {1 2 3 4 5 6}
  set cutLayerOrViaLayers          {1 2 3 4 5}
  set debug                       0
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set boundaryInstsBox [concat [dbget [dbget top.insts.name ${prefixNameOfBoundaryInsts}* -p].box -e] [dbget [dbget top.insts.name */${prefixNameOfBoundaryInsts}* -p].box -e]]
  set coreInnerBoundaryWithBoundaryRects [findCoreRectsInsideBoundary_withBoundaryArea $boundaryInstsBox]
  set groupedForRects [lrange [find_connected_regions $coreInnerBoundaryWithBoundaryRects] 1 end]
  if {[llength $groupedForRects] == 1} {
    error "proc genCmd_add_routeBlk_for_gap_betweenDifferentEndcapGroups: only gen ONE group of rects, can't find the narrow channels!!!" 
  }
  set narrowChannelsList [find_narrow_channels $groupedForRects $narrowChannelWidthThreshold $off $debug]
  set cmdsList [list]
  foreach temp_channel $narrowChannelsList {
    lappend cmdsList "createRouteBlk -name $routeBlkPrefix -box \{$temp_channel\} -layer \{$layers\} -cutLayer \{$cutLayerOrViaLayers\}"
  }
  return $cmdsList
}

define_proc_arguments genCmd_add_routeBlk_for_gap_betweenDifferentEndcapGroups \
  -info "gen cmd for adding routeBlk for gap between different endcap groups(normally different power domains)"\
  -define_args {
    {-narrowChannelWidthThreshold "Set the judgment threshold for whether a channel is narrow. Channels with a size less than or equal to this value are identified as narrow channels." AFloat float optional}
    {-off "specify an offset for the obtained narrow channel (gap) size, where positive numbers indicate enlargement and negative numbers indicate reduction." AFloat float optional}
    {-prefixNameOfBoundaryInsts "specify the prefix name of boundary insts to search, default: ENDCAP" AString string optional}
    {-routeBlkPrefix "specify the prefix name of offed routeBlk that will add on gap" AString string optional}
    {-layers "specify the layers that need block for routing" AList list optional}
    {-cutLayerOrViaLayers "specify the cut layers (via layers) that need block for routing" AList list optional}
    {-debug "debug mode" "" boolean optional}
  }
