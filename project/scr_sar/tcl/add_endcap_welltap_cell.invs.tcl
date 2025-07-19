#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/10 08:45:27 Thursday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc)
# descrip   : add endcap and welltap in floorplan
# ref       : link url
# --------------------------
proc add_endcap_welltap_cell {{runOrVerifyOrDelete "veri"} {endcapPrefix "boundary"} {tapwellPrefix "tap"} {powerdomains {}} {tapcell ""} {top {}} {bottom {}} {left {}} {right {}} {lefttop {}} {leftbottom {}} {righttop {}} {rightbottom {}}} {
  # $runOrVerifyOrDelete: run|veri|del
  #               delrun : delete and readd endcap and welltap
  #               run : add and verify endcap and welltap
  #               veri: only verify endcap and welltap
  #               del : only delete endcap and welltap
  if {![llength $tapcell] || ![llength $top] || ![llength $bottom] || ![llength $left] || ![llength $right] || ![llength $lefttop] || ![llength $leftbottom] || ![llength $righttop] ||![llength $rightbottom]} {
    return "0x0:1" ; # check your input 
  } else {
    setPlaceMode -reset
    setPlaceMode -place_detail_check_route true \
      -place_detail_preserve_routing true \
      -place_detail_check_cut_spacing true \
      -place_detail_use_check_drc true \
      -place_global_uniform_density true \
      -place_detail_legalization_inst_gap 2
      
    if { $runOrVerifyOrDelete == "delrun" || $runOrVerifyOrDelete == "del"} {
      deleteFiller -prefix $endcapPrefix
      deleteFiller -prefix $tapwellPrefix
    }

    setEndCapMode -reset
    setEndCapMode \
      -topEdge              $top \
      -bottomEdge           $bottom \
      -leftEdge             $left \
      -rightEdge            $right \
      -leftTopCorner        $lefttop \
      -leftTopEdge          $lefttop \
      -leftBottomCorner     $leftbottom \
      -leftBottomEdge       $leftbottom \
      -rightTopCorner       $righttop \
      -rightTopEdge         $righttop \
      -rightBottomCorner    $rightbottom \
      -rightBottomEdge      $rightbottom \
      -boundary_tap         true \
      -fitGap               true
    # The number of rule and cellInterval must be an integer multiple of the row site
    set_well_tap_mode -rule 28.7 -bottom_tap_cell $tapcell -top_tap_cell $tapcell
    
    if { $runOrVerifyOrDelete == "run" || $runOrVerifyOrDelete == "delrun"} {
      if {$powerdomains == ""} {
        addEndCap   -prefix $endcapPrefix
        addWellTap  -prefix $tapwellPrefix -cellInterval 81.48 -checkerBoard -avoidAbutment -cell $tapcell
      } elseif {[llength $powerdomains] == [llength [lmap pd $powerdomains {set temp [dbget top.pds.name $pd -e]; if {$temp != ""} {set temp} else {continue}}]]} {
        foreach pd $powerdomains {
          addEndCap   -prefix ENDCAP  -powerDomain $pd
          addWellTap  -prefix WELLTAP -powerDomain $pd -cellInterval 81.48 -checkerBoard -avoidAbutment -cell $tapcell
        } else {
          return "0x0:2"; # check your $powerdomains input 
        }
      }
    }
    if {$runOrVerifyOrDelete == "run" || $runOrVerifyOrDelete == "delrun" || $runOrVerifyOrDelete == "veri"} {
      verifyEndCap
      verifyWellTap
    }
  }
}

