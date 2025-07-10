#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/10 08:45:27 Thursday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> gui_proc   : for gui display, or effort can be viewed in invs GUI
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
#   -> dump_proc  : dump data with specific format from db(invs/pt/starrc/pv...)
# descrip   : add endcap and welltap in floorplan
# ref       : link url
# --------------------------
proc add_endcap_welltap_cell {{powerdomains ""} {tapcell ""} {top {}} {bottom {}} {left {}} {right {}} {lefttop {}} {leftbottom {}} {righttop {}} {rightbottom}} {
  if {![llength $tapcell] || ![llength $top] || ![llength $bottom] || ![llength $left] ![llength $right] || ![llength $lefttop] || ![llength $leftbottom] || ![llength $righttop] ||![llength $rightbottom]} {
    return "0x0:1" ; # check your input 
  } else {
    setPlaceMode -reset
    setPlaceMode -place_detail_check_route true \
      -place_detail_preserve_routing true \
      -place_detail_check_cut_spacing true \
      -place_detail_use_check_drc true \
      -place_global_uniform_density true \
      -place_detail_legalization_inst_gap 2
      
      deleteFiller -prefix ENDCAP
      deleteFiller -prefix WELLTAP

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
      
      foreach pd $powerdomains {
        addEndCap   -prefix ENDCAP  -powerDomain $pd
        addWellTap  -prefix WELLTAP -powerDomain $pd -cellInterval 81.48 -checkerBoard -avoidAbutment
      }
      verifyEndCap
      verifyWellTap
  }
}

