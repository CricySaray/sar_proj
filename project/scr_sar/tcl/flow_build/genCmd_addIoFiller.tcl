#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/08 14:24:31 Monday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : By specifying the order of iofillers - arranging them sequentially from wider fillers to narrower ones - you can fill the iofillers in one go. 
#             Additionally, multiple sides can be designated, and you can also specify which iofillers allow forced insertion.
# return    : cmds of addIoFiller, format of one:
#                     addIoFiller -cell xxx [-side xxx -fillAnyGap]
# ref       : link url
# --------------------------
source ../packages/every_any.package.tcl; # every
proc genCmd_addIoFiller {args} {
  set IoFillerCellOrder        {PFILL10_33_33_NT_DR PFILL5_33_33_NT_DR PFILL2_33_33_NT_DR PFILL1NC_33_33_NT_DR}
  set sides                    "all"
  set fillerTypeCanForceInsert {PFILL1NC_33_33_NT_DR}
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }

  if {![llength $IoFillerCellOrder]} {
    error "proc genCmd_addIoFiller: check your input: IoFillerCellOrder($IoFillerCellOrder) is empty!!!" 
  } elseif {[any x $IoFillerCellOrder { expr {[dbget head.libCells.name $x -e] == ""} }]} {
    error "proc genCmd_addIoFiller: check your input: IoFillerCellOrder($IoFillerCellOrder) has item that is not found in lef file!!!"
  } else {
    set cmdOptions [list]
    set cmds [list]
    if {$sides == "all"} {
      foreach iofiller $IoFillerCellOrder {
        if {$iofiller in $fillerTypeCanForceInsert} { lappend cmdOptions "-fillAnyGap" }
        lappend cmds "addIoFiller -cell $iofiller $cmdOptions"
        set cmdOptions [list]
      }
    } elseif {[llength $sides] > 1} {
      foreach side $sides {
        foreach iofiller $IoFillerCellOrder {
          if {$side in {left right top bottom}} { lappend cmdOptions "-side $side" }
          if {$iofiller in $fillerTypeCanForceInsert} { lappend cmdOptions "-fillAnyGap" }
          lappend cmds "addIoFiller -cell $iofiller $cmdOptions"
          set cmdOptions [list]
        }
      }
    }
    return $cmds
  }
}
define_proc_arguments genCmd_addIoFiller \
  -info "gen cmd for addIoFiller"\
  -define_args {
    {-IoFillerCellOrder "specify the io Filler type, arranging them sequentially from wider fillers to narrower ones" AList lsit optional}
    {-sides "specify the side for inserting io filler" oneOfString one_of_string {optional {values {all left right top bottom}}}}
    {-fillerTypeCanForceInsert "specify the io filler type that can insert forcely" AList list optional}
  }
