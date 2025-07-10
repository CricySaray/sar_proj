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
#             specific inst and layer
#             have some switchs for control action of proc
# ref       : link url
# --------------------------
proc add_physicalPin_for_inst {args} {
  set inst                      "U_PMU_TOP"
  set layer                     "RDL"
  set testOrRun                 "test" ; # run | test
  set off                       {0 0 0 0}
  set terms                     {} ; # term list
  set ifReportNoNetPin          true
  set compareOriginBoxArea      true
  set AreaThreshold             0
  set typeToAddPhysicalPin      "all" ; # pg | signal | all
  set debug                     false
  set ignoreNoSignalOrNoPgTerms true
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg) 
  }
  # $off {top bottom left right}
  #       like : {-1 -0.3 1.1 2.0} 
  #        -1 / -0.3 : get to small
  #        1.1 / 2.0 : get bigger
  # $typeToAddPhysicalPin : 1: only add signal term physical pin
  #                         2: only add pg term physical pin
  #                         3: add signal and pg term physical pin
  # $testOrRun  : dry run mode (only print command but not to run it at real)
  # $ifReportNoNetPin     : 1: report no net pin
  #                         0: not to report
  # $compareOriginBoxArea : specify the area to compare, which can be 1 (original area of box) and 0 (modified area by $off of box)
  # $AreaThreshold        : specify the threshold of are of box. if it is smaller than $AreaThreshold, it can't be added physicalPin.
  # $debug                : if it is 1, it will print some processing info for debugging conviniently.
  set promptERROR "songERROR:"
  set promptWARN "songWARN:"
  if {$inst == "" || $inst == "0x0" || [dbget top.insts.name $inst -e] == "" || $layer == "" || $layer == "0x0" || [dbget head.layers.name $layer -e] == ""} {
    return "0x0:1"; # check your input: inst and layer
  } else {
    foreach item $off {
      if {[string is double $item] == 0} {
        return "0x0:2"; # off item is not a digit
      } 
    }
    if {[llength $terms] == 0} {
      ## signal term with net connection
      set inst_ptr [dbget top.insts.name $inst -p]
      if {$typeToAddPhysicalPin == "signal" || $typeToAddPhysicalPin == "all"} { ; # add signal term physicalPin
        set signal_term_ptr [dbget $inst_ptr.instTerms.cellTerm.pins.allShapes.layer.name $layer -p5 -e]
        if {$signal_term_ptr == "" && !$ignoreNoSignalOrNoPgTerms} {
          return "0x0:3"; # specific layer of inst has no signal terms 
        } elseif {$signal_term_ptr != ""} {
          puts "##### -------------------------------"
          puts "##### Begin adding physicals for inst: $inst"
          set signal_term_names [lsort -unique [dbget $signal_term_ptr.name ]]
if {$debug} {puts "signal term names \n$signal_term_names"}
          # one name maybe have more rects!!!
          set name_rect_D2List_signalTerms [list ]
          set names_signalTerms [dbget $signal_term_ptr.name]
          foreach name $signal_term_names {
            set rects [dbTransform -inst $inst -localPt [dbget [dbget [dbget top.insts.instTerms.name $name -p].cellTerm.pins.allShapes.layer.name $layer -p2].shapes.rect]]
            foreach rect $rects {lappend name_rect_D2List_signalTerms [list $name $rect]}
          }
          set names_signalTerms [lsort -unique $names_signalTerms]
          # using proc : modify_boxes_and_get_area_toD3List
          set name_rect_area_biggerThanAreaThreshold_D3List_signalTerms [modify_boxes_and_get_area_toD3List $name_rect_D2List_signalTerms $off $AreaThreshold $compareOriginBoxArea $debug]
if {$debug} {puts "signal term name_rect_area \n$name_rect_area_biggerThanAreaThreshold_D3List_signalTerms"}
          if {[llength $name_rect_area_biggerThanAreaThreshold_D3List_signalTerms] == 0} {
            return "0x0:4"; # have no signal term which of area is bigger than $AreaThreshold
          }
          # pick out terms which is connect to net
          #
          set name_rect_area_net_D4List [list ]
          set name_rect_area_woNet_D3List [list ]
          foreach name_rect_area $name_rect_area_biggerThanAreaThreshold_D3List_signalTerms {
            set net [dbget [dbget [dbget [dbget top.insts.name $inst -p].instTerms.name [lindex $name_rect_area 0] -p].cellTerm.pins.allShapes.layer.name $layer -p5].net.name -e -u]
            if {$net != ""} {lappend name_rect_area_net_D4List [lappend name_rect_area $net]} else {lappend name_rect_area_woNet_D3List $name_rect_area}
          }
          if {[llength $name_rect_area_woNet_D3List]} {
            puts "-> have signal term which is not connect net. please globalConnectNet:"
            foreach name_rect_area $name_rect_area_woNet_D3List {
              puts "noNetTerm: [lindex $name_rect_area 0] located: [lindex $name_rect_area 1]"
            }
            #if {$ifReportNoNetPin} {
            #  foreach name_rect_area $name_rect_area_woNet_D3List {
            #    regexp {.*\/(.*)} [lindex $name_rect_area 0] wholename termName
            #    set cmd_signalTerms_woNet "createPhysicalPin $wholename -layer $layer -rect [lindex $name_rect_area 1]"
            #    puts "# --- signal term physicalPin (without net) : (area: [lindex $name_rect_area 2]) $cmd_signalTerms_woNet "
            #    if {$testOrRun == "run"} {
            #      set runErr [catch {eval $cmd_signalTerms_woNet} errorInfo]
            #      if {$runErr} {
            #        puts "$promptERROR $cmd_signalTerms_woNet"
            #        return "0x0:5"; # error occurs when run cmd_signalTerms_woNet
            #      }
            #    }
            #  }
            #}
          }
          foreach name_rect_area_net $name_rect_area_net_D4List {
            set cmd_signalTerms_wiNet "createPhysicalPin [lindex $name_rect_area_net 0] -layer $layer -rect [lindex $name_rect_area_net 1] -net [lindex $name_rect_area_net 3]" 
            puts "# --- signal term physicalPin    (with net) : (area: [lindex $name_rect_area_net 2]) $cmd_signalTerms_wiNet "
            if {$testOrRun == "run"} {
              set runErr [catch {eval $cmd_signalTerms_wiNet} errorInfo]
              if {$runErr} {
                puts "$promptERROR $cmd_signalTerms_wiNet"
                return "0x0:6"; # error occurs when run cmd_signalTerms_wiNet
              }
            }
          }
        }
        if {$signal_term_ptr == "" && $ignoreNoSignalOrNoPgTerms} {
          puts "$promptWARN no signal terms specified inst($inst) and layer($layer), but it is ignored!!!" 
        }
      } 
      if {$typeToAddPhysicalPin == "pg" || $typeToAddPhysicalPin == "all"} { ; # add pg term physicalPin
        set pg_term_ptr [dbget $inst_ptr.pgInstTerms.term.pins.allShapes.layer.name $layer -p5 -e]
        if {$pg_term_ptr == "" && !$ignoreNoSignalOrNoPgTerms} {
          return "0x0:7"; # have no pg term in specific layer
        } elseif {$pg_term_ptr != ""} {
          set pg_terms_names [lsort -unique [dbget $pg_term_ptr.name]]
if {$debug} {puts "pg term names \n$pg_terms_names"}
          set name_rect_D2List_pgTerms [list ]
          foreach name $pg_terms_names {
            set rects [dbTransform -inst $inst -localPt [dbget [dbget [dbget top.insts.pgInstTerms.name $name -p].term.pins.allShapes.layer.name $layer -p2].shapes.rect] ]
            foreach rect $rects {lappend name_rect_D2List_pgTerms [list $name $rect]}
          }
          set name_rect_D2List_pgTerms [lsort -unique $name_rect_D2List_pgTerms]
if {$debug} {puts "pg term name_rect :\n$name_rect_D2List_pgTerms"}
          # using proc : modify_boxes_and_get_area_toD3List
          set name_rect_area_biggerThanAreaThreshold_D3List_pgTerms [modify_boxes_and_get_area_toD3List $name_rect_D2List_pgTerms $off $AreaThreshold $compareOriginBoxArea $debug]
if {$debug} {puts "pg term name_rect_area : \n$name_rect_area_biggerThanAreaThreshold_D3List_pgTerms"}
          if {[llength $name_rect_area_biggerThanAreaThreshold_D3List_pgTerms] == 0} {
            return "0x0:8"; # have no pg term which of area is bigger than $AreaThreshold
          }
          # pick out terms which is connect to net
          set name_rect_area_net_D4List_pg [list ]
          set name_rect_area_woNet_D3List_pg [list ]
          foreach name_rect_area $name_rect_area_biggerThanAreaThreshold_D3List_pgTerms {
            set net [dbget [dbget [dbget [dbget top.insts.name $inst -p].pgInstTerms.name [lindex $name_rect_area 0] -p].term.pins.allShapes.layer.name $layer -p5].net.name -e -u]
            if {$net != ""} {lappend name_rect_area_net_D4List_pg [lappend name_rect_area $net]} else {lappend name_rect_area_woNet_D3List_pg $name_rect_area}
          }
          if {[llength $name_rect_area_woNet_D3List_pg]} {
            puts "-> have pg term whis is not connect net. please globalConnectNet:"
            foreach name_rect_area $name_rect_area_woNet_D3List_pg {
              puts "noNetTerm: [lindex $name_rect_area 0] located: [lindex $name_rect_area 1]"
            }
            #if {$ifReportNoNetPin } {
            #  foreach name_rect_area $name_rect_area_woNet_D3List_pg {
            #    regexp {.*\/(.*)} [lindex $name_rect_area 0] wholename termName
            #    set cmd_pgTerms_woNet "createPhysicalPin $wholename -layer $layer -rect [lindex $name_rect_area 1]"
            #    puts "# ------- pg term physicalPin (without net) : (area: [lindex $name_rect_area 2]) $cmd_pgTerms_woNet "
            #    if {$testOrRun == "run"} {
            #      set runErr [catch {eval $cmd_pgTerms_woNet} errorInfo]
            #      if {$runErr} {
            #        puts "$promptERROR $cmd_pgTerms_woNet"
            #        return "0x0:9"; # error occurs when run cmd_pgTerms_woNet
            #      }
            #    }
            #  }
            #}
            return "0x0:9"; # have pg term whis is not connect net. please globalConnectNet
          }
          foreach name_rect_area_net $name_rect_area_net_D4List_pg {
            set cmd_pgTerms_wiNet "createPhysicalPin $inst/[lindex $name_rect_area_net 0] -layer $layer -rect [lindex $name_rect_area_net 1] -net [lindex $name_rect_area_net 3]" 
            puts "# ------- pg term physicalPin (with net)    : (area: [lindex $name_rect_area_net 2]) $cmd_pgTerms_wiNet "
            if {$testOrRun == "run"} {
              set runErr [catch {eval $cmd_pgTerms_wiNet} errorInfo]
              if {$runErr} {
                puts "$promptERROR $cmd_pgTerms_wiNet"
                return "0x0:10"; # error occurs when run cmd_pgTerms_wiNet
              }
            }
          }
        }
        if {$pg_term_ptr == "" && $ignoreNoSignalOrNoPgTerms} {
          puts "$promptWARN no pg terms specified inst($inst) and layer($layer), but it is ignored!!!" 
        }
      } else {
        return "0x0:11"; # $typeToAddPhysicalPin have value that is not support 
      }
    } else { ; #specified terms by user
      
    }
  }
}

define_proc_arguments add_physicalPin_for_inst \
  -info "add physicalPin for a inst" \
  -define_args {
    {-inst "specify a inst" AString string optional}
    {-layer "specify layer of pin" AString string optional}
    {-testOrRun "test(only print commands to run) or run(print commands and execute it)" "oneOfString" one_of_string {optional value_help {values {test run}}}}
    {-off "off value: for top/bottom/left/rigth" AList list optional}
    {-terms "specify terms of specified inst" AList list optional}
    {-ifReportNoNetPin "if report no net term" AList list optional}
    {-compareOriginBoxArea "specify the one to compare with \$AreaThreshold" "" boolean optional}
    {-AreaThreshold "specify the threshold of area" AFloat float optional}
    {-typeToAddPhysicalPin "specify types to add physical pin" oneOfString one_of_string {optional value_help {values {signal pg all}}}}
    {-debug "print some internal vars for debugging" "" boolean optional}
    {-ignoreNoSignalOrNoPgTerms "when no signal or pg terms occurs, it only is warned but no errors to interrupt" "" boolean optional}
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
proc modify_boxes_and_get_area_toD3List {{name_rect_D2List {}} {off {0 0 0 0} } {AreaThreshold 0} {compareOriginBoxArea 1} {debug 1}} {
  set off_top [lindex $off 0]
  set off_bottom [lindex $off 1]
  set off_left [lindex $off 2]
  set off_right [lindex $off 3]
  # Anonymous function, for convenience
  set ceilValue [list apply {{x} {set manufacturingGrid [dbget head.mfgGrid]; expr ceil([expr [lindex $x 0] / $manufacturingGrid]) * $manufacturingGrid}}]
  set floorValue [list apply {{x} {set manufacturingGrid [dbget head.mfgGrid]; expr floor([expr [lindex $x 0] / $manufacturingGrid]) * $manufacturingGrid}}]
  set modified_name_rect_D2List [lmap name_rect $name_rect_D2List {
    set modified_rect_lb [lrange [lindex [dbShape [lindex $name_rect 1] SIZEX $off_left SIZEY $off_bottom] 0] 0 1]
    set modified_rect_ur [lrange [lindex [dbShape [lindex $name_rect 1] SIZEX $off_right SIZEY $off_top] 0] 2 3]
    # solve the problem of not being in manufacturing grid
    set modified_rect_lb [list [eval $ceilValue [lindex $modified_rect_lb 0]] [eval $ceilValue [lindex $modified_rect_lb 1]]] 
    set modified_rect_ur [list [eval $floorValue [lindex $modified_rect_ur 0]] [eval $floorValue [lindex $modified_rect_ur 1]]] 
    set modified_rect [concat $modified_rect_lb $modified_rect_ur]
    set modified_name_rect [list [lindex $name_rect 0] $modified_rect]
  }]
if {$debug} {puts "modified_name_rect_D2List : \n$modified_name_rect_D2List"}
  if {$compareOriginBoxArea == 1} {set name_rect_ToCalculateArea_D2List $name_rect_D2List} else {set name_rect_ToCalculateArea_D2List $modified_name_rect_D2List}
  set name_rect_area_D3List [lmap name_rect $name_rect_ToCalculateArea_D2List {
    # using proc : calculate_area_of_box
    set area [calculate_area_of_box [lindex $name_rect 1]]
    lappend name_rect $area
  }]
if {$debug} {puts "name_rect_area without comparition\n$name_rect_area_D3List"}
  # compare area according to specific area value by user. if area is smaller than $AreaThreshold, it will be removed
  set name_rect_area_biggerThanAreaThreshold_D3List [lmap name_rect_area $name_rect_area_D3List {
    if {[lindex $name_rect_area 2] >= $AreaThreshold} {set name_rect_area } else {continue} 
  }]
  return $name_rect_area_biggerThanAreaThreshold_D3List
}
