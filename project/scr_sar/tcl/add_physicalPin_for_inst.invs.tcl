#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Thu Jul  3 12:37:08 CST 2025
# label     : task_proc
#   -> (atomic_proc|display_proc|task_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
# descrip   : create physical pin for many inst(IP/mem/IOpad...)
# ref       : link url
# --------------------------
proc add_physicalPin_for_inst {{inst ""} {layer "RDL"} {off {0 0 0 0}} {terms {}} {ifAddforNoNetPin 1}} {
  # $off {top bottom left right}
  #       like : {-1 -0.3 1.1 2.0} 
  if {$inst == "" || $inst == "0x0" || [dbget top.insts.name $inst -e] == "" || $layer == "" || $layer == "0x0" || [dbget head.layers.name $layer -e] == ""} {
    return "0x0:1"; # check your input: inst and layer
  } else {
    foreach item $off {
      if {[string is double $item] == 0} {
        return "0x0:2"; # off item is not a digit
      } 
    }
    set off_top [lindex $off 0]
    set off_bottom [lindex $off 1]
    set off_left [lindex $off 2]
    set off_right [lindex $off 3]
    if {[llength $terms] == 0} {
      ## signal term with net connection
      set inst_ptr [dbget top.insts.name $inst -p]
      set signal_term_ptr [dbget $inst_ptr.instTerms.layer.name $layer -p2]
      if {$signal_term_ptr == ""} {
        return "0x0:3"; # specific layer of inst has no signal terms 
      }
      set signal_term_rects [dbTransform -inst $inst -localPt [dbget $signal_term_ptr.cellTerm.pins.allShapes.shapes.rect -e]]; # global pt
      set modified_rects [lmap rect $signal_term_rects {
        set modified_rect_lb [lrange [dbShape $rect SIZEX $off_left SIZEY $off_bottom] 0 1]
        set modified_rect_ur [lrange [dbShape $rect SIZEX $off_right SIZEY $off_top] 2 3]
        set modified_rect [concat $modified_rect_lb $modified_rect_ur]; # 左和下起作用，但是上和右没有作用。
      }]
      puts $modified_rects
    } else { ; #specified terms by user
     
    }
  }
}
