#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/10 11:42:07 Wednesday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : power plan for M1
# return    : cmds
# ref       : link url
# --------------------------
source ../../eco_fix/timing_fix/lut_build/proc_findCoreRectInsideBoundary.invsGUI.tcl;
source ../../packages/adjust_rectangle.rect_off.package.tcl; # adjust_boxes

# check: 
#   if have rects of every power domains
#   if have PG net of every power domains (power and ground)
#   if have specified the width and spacing of every power domains( can calculate it according to tech LEF file )

proc genCmd_powerPlan_usingAddStripeCmd {args} {
  set powerDomain_RectAndPGnetAndOrder  {} ; # for example : {{{{x y x1 y1} ...} {DVDD_AON DVSS} powerFirst} {{{x y x1 y1} ...} {DVDD_ONO DVSS} groundFirst} ...}
  set prefixNameOfBoundaryInsts "ENDCAP"
  set netHeght                  0.23
  set rowHeight                 1.26
  set area_off                  [list [expr $netHeght / 2] [expr $netHeght / 2] 0 0]
  set netRangeFromStart         {DVDD_ONO DVSS}
  set layerRange                {1 8} ; # must integer number : 1|2|3|...  not use M1|M2|...
  set layerStartAddStrip        4 ; # M1 is followpin/pg rail, 2 - ($layerStartAddStrip-1) is stacked via
  set direction                 "horizontal" ; # horizontal|vertical
  set start_from                "top" ; # top|bottom|left|right ; NOTICE: recommand : top
  set start_offset              0
  set spacing_inSetInner        [expr $rowHeight - $netHeght]
  set set_to_set_distance       [expr $rowHeight * 2]
  set user_subClass             "autoGen_sar" ; # diff with other stripe that has been existed before running this proc
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  ## Validate input
  if {0} {
   
  }
  ## calculate all statistics
  set boundaryInstsBox [concat [dbget [dbget top.insts.name ${prefixNameOfBoundaryInsts}* -p].box -e] [dbget [dbget top.insts.name */${prefixNameOfBoundaryInsts}* -p].box -e]]
  set coreInnerBoundaryWithBoundaryRects [findCoreRectsInsideBoundary_withBoundaryArea $boundaryInstsBox]
  # return $coreInnerBoundaryWithBoundaryRects
  set cmdsList [list ]
  lappend cmdsList "setEditMode -reset"
  lappend cmdsList "setEditMode -drc_on false \
                                -align false \
                                -check_design_boundary false \
                                -circle_NDR_vias_only false \
                                -close_polygons false \
                                -color_align_with_track false \
                                -connect_with_specified_layer false \
                                -create_crossover_vias false \
                                -create_is_edit_flag false \
                                -create_via_on_pin false \
                                -drc_aware_cross_metal false \
                                -no_merge_special_wire true \
                                -reshape false \
                                -return_object_pointer false \
                                -show_drc_info_for_edit_shape false \
                                -snap false \
                                -snap_bus_to_pin false \
                                -snap_to_track_honor_color false \
                                -snap_trim_metal_to_trim_grid false \
                                -stop_at_drc false \
                                -use_fixVia false \
                                -verbose true \
                                -via_allow_geom_drc false \
                                -via_auto_replace false \
                                -via_auto_snap false \
                                -via_snap_honor_color false \
                                -via_snap_to_intersection false \
                                -via_create_by viacell"
  lappend cmdsList "setAddStripeMode -stacked_via_bottom_layer $layer -stacked_via_top_layer [expr $layer + 1]"
  set coreInnerBoundaryWithBoundaryRects_ANDNOT $coreInnerBoundaryWithBoundaryRects
  if {[llength $powerDomain_RectAndPGnetAndOrder]} {
    foreach temp_powerDomain_RectAndPGnet $powerDomain_RectAndPGnetAndOrder {
      lassign $temp_powerDomain_RectAndPGnet temp_rects temp_PGnet temp_order
      lassign $temp_PGnet temp_powerNet temp_groundNet
      set temp_rects_offed [adjust_boxes $temp_rects $area_off]
      if {$temp_order == "powerFirst"} { set temp_netRangeFromStart [list $temp_powerNet $temp_groundNet] } else { set temp_netRangeFromStart [list $temp_groundNet $temp_powerNet] }
      lappend cmdsList "addStripe -nets \{$temp_netRangeFromStart\} \
                                  -layer $layer \
                                  -direction $direction \
                                  -start_from $start_from \
                                  -start_offset $start_offset \
                                  -width $netHeght \
                                  -spacing $spacing_inSetInner \
                                  -set_to_set_distance $set_to_set_distance \
                                  -max_same_layer_jog_length 0 \
                                  -area \{$temp_rects_offed\}"
      set coreInnerBoundaryWithBoundaryRects_ANDNOT [dbShape $coreInnerBoundaryWithBoundaryRects_ANDNOT ANDNOT $temp_rects]
    }
  }
  set coreInnerBoundaryWithBoundaryRects_ANDNOT_offed [adjust_boxes $coreInnerBoundaryWithBoundaryRects_ANDNOT $area_off]
  lappend cmdsList "addStripe -nets \{$netRangeFromStart\} \
                              -layer $layer \
                              -direction $direction \
                              -start_from $start_from \
                              -start_offset $start_offset \
                              -width $netHeght \
                              -spacing $spacing_inSetInner \
                              -set_to_set_distance $set_to_set_distance \
                              -max_same_layer_jog_length 0 \
                              -area \{$coreInnerBoundaryWithBoundaryRects_ANDNOT_offed\}"
  return $cmdsList
}
define_proc_arguments genCmd_M1powerPlan \
  -info "gen cmd of power plan for M1"\
  -define_args {
    {-powerDomain_RectAndPGnetAndOrder "specify the other power domain rects, pgnets and order from the direction that you select" AList list optional}
    {-prefixNameOfBoundaryInsts "specify the prefix of boundary insts" AString string optional}
    {-netHeght "specify the height of power or ground pin/net of M1 for calculating the width of net of addStripe cmd" AFloat float optional}
    {-rowHeight "specify the height of row for calculating the distance of set_to_set" AFloat float optional}
  }
