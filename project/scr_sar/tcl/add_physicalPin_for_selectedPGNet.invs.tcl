#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/10 12:39:48 Thursday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc)
# descrip   : createPhysicalPin for select pg nets or specified nets on specified searching area, 
#               only add PhysicalPins in the shape of small squares.
# ref       : link url
# --------------------------
proc add_physicalPin_for_selectedPGNet {{testOrRun test} {layer ""} {priorityPosition lb} {nets {}} {searchRect {}} {promptERROR "songERROR"}} {
  # $nets             : specify nets to addPhysicalPin
  # $priorityPosition : lb | ur | all
  #                     if it is lb, the square coordinates will be calculated using the lower left corner as the base point.
  #                     if it is ur, the square coordinates will be calculated using the upper right corner as the base point.
  #                     if it is all, lb and ur both will be specified.
  # $searchRect       : default: die area, you can also select rect
  #
  # 
  if {![llength $nets] && [dbget selected.objType -e] == ""} {
    return "0x0:1"; # no selected objects and not specify $nets
  } elseif {![llength $nets] && [dbget selected.objType -u -e] != "sWire"} {
    return "0x0:2"; # not specify $nets, but selected other objects instead of special nets(pg nets)
  } elseif {[llength $nets]} {
    if {![llength $searchRect]} { set searchRect [lindex [dbget top.fplan.boxes] 0]}
    set net_box_D2List ""
    foreach net $nets {
      if {[dbget top.pgNets.name $net -e] == ""} {
        return "0x0:3"; # can't find net from $nets
      } 
      set boxes [dbget [dbget [dbQuery -areas $searchRect -objType sWire -layer $layer].net.name $net -p2].box -e]
      if {$boxes == ""} {
        puts "$promptERROR : don't search specified net $net"
        return "0x0:4"; # don't have specified net $net 
      }
      set net_boxes_D2ListPartial [lmap box $boxes {
        set net_box [list $net $box] 
      }]
      set net_box_D2List [concat $net_box_D2List $net_boxes_D2ListPartial]
    }
    foreach net_box $net_box_D2List {
      set name  [lindex $net_box 0]
      set box   [lindex $net_box 1] 
      set width  [expr [lindex $box 2] - [lindex $box 0]]
      set height [expr [lindex $box 3] - [lindex $box 1]]
      set Off [expr $width < $height ? $width : $height]
      if {$priorityPosition == "lb"} {
        set offedBox [concat [lrange $box 0 1] [expr [lindex $box 0] + $Off] [expr [lindex $box 1] + $Off]]
        set cmd_specified_nets "createPhysicalPin $name -layer $layer -rect $offedBox -net $name" 
        puts $cmd_specified_nets; if {$testOrRun == "run"} { eval $cmd_specified_nets }
      } elseif {$priorityPosition == "ur"} {
        set offedBox [concat [expr [lindex $box 2] - $Off] [expr [lindex $box 3] - $Off] [lrange $box 2 3]]
        set cmd_specified_nets "createPhysicalPin $name -layer $layer -rect $offedBox -net $name" 
        puts $cmd_specified_nets; if {$testOrRun == "run"} { eval $cmd_specified_nets }
      } elseif {$priorityPosition == "all"} {
        set offedBox_lb [concat [lrange $box 0 1] [expr [lindex $box 0] + $Off] [expr [lindex $box 1] + $Off]]
        set offedBox_ur [concat [expr [lindex $box 2] - $Off] [expr [lindex $box 3] - $Off] [lrange $box 2 3]]
        foreach offB [list $offedBox_lb $offedBox_ur] {
          set cmd_specified_nets "createPhysicalPin $name -layer $layer -rect $offB -net $name" 
          puts $cmd_specified_nets; if {$testOrRun == "run"} { eval $cmd_specified_nets }
        }
      }
    }
  } else {
    set net_ptr [dbget selected.]
    set netname [dbget $net_ptr.net.name]
    set netbox  [dbget $net_ptr.box]
    foreach name $netname box $netbox {
      set width  [expr [lindex $box 2] - [lindex $box 0]]
      set height [expr [lindex $box 3] - [lindex $box 1]]
      set Off [expr $width < $height ? $width : $height]
      if {$priorityPosition == "lb"} {
        set offedBox [concat [lrange $box 0 1] [expr [lindex $box 0] + $Off] [expr [lindex $box 1] + $Off]]
        set cmd_selected_nets "createPhysicalPin $name -layer $layer -rect $offedBox -net $name" 
        puts $cmd_selected_nets; if {$testOrRun == "run"} { eval $cmd_selected_nets }
      } elseif {$priorityPosition == "ur"} {
        set offedBox [concat [expr [lindex $box 2] - $Off] [expr [lindex $box 3] - $Off] [lrange $box 2 3]]
        set cmd_selected_nets "createPhysicalPin $name -layer $layer -rect $offedBox -net $name" 
        puts $cmd_selected_nets; if {$testOrRun == "run"} { eval $cmd_selected_nets }
      } elseif {$priorityPosition == "all"} {
        set offedBox_lb [concat [lrange $box 0 1] [expr [lindex $box 0] + $Off] [expr [lindex $box 1] + $Off]]
        set offedBox_ur [concat [expr [lindex $box 2] - $Off] [expr [lindex $box 3] - $Off] [lrange $box 2 3]]
        foreach offB [list $offedBox_lb $offedBox_ur] {
          set cmd_selected_nets "createPhysicalPin $name -layer $layer -rect $offB -net $name" 
          puts $cmd_selected_nets; if {$testOrRun == "run"} { eval $cmd_selected_nets }
        }
      }
    }
  }
}
