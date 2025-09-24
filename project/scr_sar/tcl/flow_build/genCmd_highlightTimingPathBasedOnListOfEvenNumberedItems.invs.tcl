#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/23 23:14:45 Tuesday
# label     : gui_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : According to the input list of even-numbered items, each item is a pin name, and every two items form a pair. Pins in a pair must be on the same net. If they are 
#             not on the same net, an error message will be triggered. You can choose to use functions like "flight line" or "whole_net" to highlight the connection relationship, 
#             which will be accompanied by arrows indicating the direction. It is possible to customize a circular list of highlight colors (including colors for nets and insts), 
#             and you can specify whether to highlight insts or nets.
# return    : cmds list
# ref       : link url
# --------------------------
source ../packages/logic_AND_OR.package.tcl; # eo
proc genCmd_highlightTimingPathBasedOnListOfEvenNumberedItems {args} {
  set evenNumberList {} ; # must be even number
  set modeOfConnect "whole_net" ; # whole_net|flight_line
  set ifWithArrow   1; # 1|0
  set colorsIndexLoopListsForNet {60 50 62 63 61 55 52 4 6 14 15 17 28 29 31 56 57 61 64 42} ; # 20 items
  set colorsIndexLoopListsForInst {1 2 3 5 7 9 10 11 14 15 17 19 20 21 24 22 25 28 30 32} ; # 20 items
  set indexOfColorsForNetInst 0 ; # 0-19
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set colorsIndexLoopListsForNet [expr {$indexOfColorsForNetInst % [llength $colorsIndexLoopListsForNet]}]
  set colorsIndexLoopListsForInst [expr {$indexOfColorsForNetInst % [llength $colorsIndexLoopListsForInst]}]
  if {[expr {[llength $evenNumberList] % 2}]} {
    error "proc genCmd_highlightTimingPathBasedOnListOfEvenNumberedItems: check your evenNumberList（num: [llength $evenNumberList]) must be even number list!!!" 
  }
  set hiliteCmdsList [list ]
  foreach {pin1 pin2} $evenNumberList {
    set pin1_net [dbget [dbget top.insts.instTerms.name $pin1 -p].net.name -e] 
    set pin2_net [dbget [dbget top.insts.instTerms.name $pin2 -p].net.name -e]
    if {$pin1_net == "" || $pin2_net == ""} {
      error "proc genCmd_highlightTimingPathBasedOnListOfEvenNumberedItems: check your input: pin($pin1_net or $pin2_net) is not net to connect!!!" 
    } else {
      if {$pin1_net != $pin2_net} {
        error "proc genCmd_highlightTimingPathBasedOnListOfEvenNumberedItems: check your input: both pins($pin1_net and $pin2_net) are not on same net!!!" 
      } else {
        set netColor [lindex $colorsIndexLoopListsForNet $indexOfColorsForNetInst]
        set instColor [lindex $colorsIndexLoopListsForInst $indexOfColorsForNetInst]
        lappend hiliteCmdsList "highlight_pin_connection -from_pin $pin1 -to_pin $pin2 -mode $modeOfConnect [eo $ifWithArrow "-with_arrow" ""] -net_color_index $netColor -inst_color_index $instColor"
      }
    }
  }
  return $hiliteCmdsList
}

define_proc_arguments genCmd_highlightTimingPathBasedOnListOfEvenNumberedItems \
  -info "gen cmd for highlighting timing path based on list of even-numbered items"\
  -define_args {
    {-modeOfConnect "specify the type of eco" oneOfString one_of_string {optional value_type {values {whole_net flight_line}}}}
    {-evenNumberList "specify inst to eco when type is add/delete" AList list optional}
    {-ifWithArrow "if using arrow on line" oneOfString one_of_string {optional value_type {values {1 0}}}}
    {-colorsIndexLoopListsForNet "specify the colors index loop lists for net color" AList list optional}
    {-colorsIndexLoopListsForInst "specify the colors index loop lists for inst color" AList list optional}
    {-indexOfColorsForNetInst "specify the index of Net and Inst color, it can get index with circle" AInt int optional}
  }
