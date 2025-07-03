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
proc add_physicalPin_for_inst {{inst ""} {layer "RDL"} {off {0 0 0 0}} {terms {}} {ifAddforNoNetPin 1} {compareOriginBoxArea 1} {AreaThreshold 0} {typeToAddPhysicalPin 2}} {
  # $off {top bottom left right}
  #       like : {-1 -0.3 1.1 2.0} 
  #        -1 / -0.3 : get to small
  #        1.1 / 2.0 : get bigger
  # $ifAddforNoNetPin : if a inst term have connection with a net, (1) createPhysicalPin for pin itself, (0) not to createPhysicalPin
  # $typeToAddPhysicalPin : 1: only add signal term physical pin
  #                         2: only add pg term physical pin
  #                         3: add signal and pg term physical pin
  set promptERROR "songERROR:"
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

      if {$typeToAddPhysicalPin == 1 || $typeToAddPhysicalPin == 3} { ; # add signal term physicalPin
        set signal_term_ptr [dbget $inst_ptr.instTerms.layer.name $layer -p2 -e]
        if {$signal_term_ptr == ""} {
          return "0x0:3"; # specific layer of inst has no signal terms 
        }
        set signal_term_names [dbget $signal_term_ptr.name ]
  puts $signal_term_names 
        # one name maybe have more rects!!!
        set name_rect_D2List_signalTerms [list ]
        foreach ptr $signal_term_ptr {
          set name [dbget $ptr.name]
          set rects [dbTransform -inst $inst -localPt [dbget $ptr.cellTerm.pins.allShapes.shapes.rect]]
          foreach rect $rects {lappend name_rect_D2List_signalTerms [list $name $rect]}
        }
  puts $name_rect_D2List_signalTerms
        #set signal_term_rects [dbTransform -inst $inst -localPt [dbget $signal_term_ptr.cellTerm.pins.allShapes.shapes.rect -e]]; # global pt
        set modified_name_rect_D2List_signalTerms [lmap name_rect $name_rect_D2List_signalTerms {
          set modified_rect_lb [lrange [lindex [dbShape [lindex $name_rect 1] SIZEX $off_left SIZEY $off_bottom] 0] 0 1]
          set modified_rect_ur [lrange [lindex [dbShape [lindex $name_rect 1] SIZEX $off_right SIZEY $off_top] 0] 2 3]
          set modified_rect [concat $modified_rect_lb $modified_rect_ur]
          set modified_name_rect [list [lindex $name_rect 0] $modified_rect]
        }]
  puts $modified_name_rect_D2List_signalTerms
        if {$compareOriginBoxArea == 1} {set name_rect_ToCalculateArea_D2List $name_rect_D2List_signalTerms} else {set name_rect_ToCalculateArea_D2List $modified_name_rect_D2List_signalTerms}
        set name_rect_area_D3List [lmap name_rect $name_rect_ToCalculateArea_D2List {
          set area [calculate_area_of_box [lindex $name_rect 1]]
          lappend name_rect $area
        }]
  puts $name_rect_area_D3List
        # compare area according to specific area value by user. if area is smaller than $AreaThreshold, it will be removed
        set name_rect_biggerThanAreaThreshold_D2List_signalTerms [lmap name_rect_area $name_rect_area_D3List {
          if {[lindex $name_rect_area 2] >= $AreaThreshold} {set name_rect [list [lindex $name_rect_area 0] [lindex $name_rect_area 1]]} else {continue} 
        }]
  puts $name_rect_biggerThanAreaThreshold_D2List_signalTerms
        if {[llength $name_rect_biggerThanAreaThreshold_D2List_signalTerms] == 0} {
          return "0x0:4"; # have no signal term which of area is bigger than $AreaThreshold
        }
        # pick out terms which is connect to net
        #
        set name_rect_net_D3List [list ]
        set name_rect_woNet_D2List [list ]
        foreach name_rect $name_rect_biggerThanAreaThreshold_D2List_signalTerms {
          set net [dbget [dbget top.insts.instTerms.name [lindex $name_rect 0] -p].net.name -e]
          if {$net != ""} {lappend name_rect_net_D3List [lappend name_rect $net]} else {lappend name_rect_woNet_D2List $name_rect}
        }
        if {$ifAddforNoNetPin} {
          foreach name_rect $name_rect_woNet_D2List {
            regexp {.*\/(.*)} [lindex $name_rect 0] wholename termName
            set cmd_signalTerms_woNet "createPhysicalPin $termName -layer $layer -rect [lindex $name_rect 1]"
            puts "# --- signal term physicalPin (without net) : $cmd_signalTerms_woNet"
            set runErr [catch {eval $cmd_signalTerms_woNet} errorInfo]
            if {$runErr} {
              puts "$promptERROR $cmd_signalTerms_woNet"
              return "0x0:5"; # error occurs when run cmd_signalTerms_woNet
            }
          }
        }
        foreach name_rect_net $name_rect_net_D3List {
          set cmd_signalTerms_wiNet "createPhysicalPin [lindex $name_rect_net 2] -layer $layer -rect [lindex $name_rect_net 1] -net [lindex $name_rect_net 2]" 
          puts "# --- signal term physicalPin (with net) : $cmd_signalTerms_wiNet"
          set runErr [catch {eval $cmd_signalTerms_wiNet} errorInfo]
          if {$runErr} {
            puts "$promptERROR $cmd_signalTerms_wiNet"
            return "0x0:6"; # error occurs when run cmd_signalTerms_wiNet
          }
        }
      } elseif {$typeToAddPhysicalPin == 2 || $typeToAddPhysicalPin == 3} { ; # add pg term physicalPin
        set pg_term_ptr [dbget $inst_ptr.pgInstTerms.term.layer.name $layer -p3 -e]
        if {$pg_term_ptr == ""} {
          return "0x0:7"; # have no pg term in specific layer
        }
        set pg_terms_name [dbget $pg_term_ptr.name]
  puts $pg_terms_name
        set name_rect_D2List_pgTerms [list ]
        foreach ptr $pg_term_ptr {
          set name [dbget $ptr.name]
          set rects [dbTransform -inst $inst -localPt [dbget $ptr.term.pins.allShapes.shapes.poly] ]; #!!!
        }
      }
      
    } else { ; #specified terms by user
      
    }
  }
}
proc calculate_area_of_box {{box {}}} {
  if {![llength $box] || [lindex [lindex $box 0] 0] == ""} {
    return "0x0:1"; # not input box
  } else {
    set falseItem 0
    foreach item $box {if {![string is double $item]} {set falseItem 1}}
    if {[llength $box] == 4 && !$falseItem} {
      set x1 [lindex $box 0]
      set y1 [lindex $box 1]
      set x2 [lindex $box 2]
      set y2 [lindex $box 3]
      set area [expr ($x2 - $x1) * ($y2 - $y1)]
      return $area
    } else {
      return "0x0:2"; # only one box
    }
  }
}
