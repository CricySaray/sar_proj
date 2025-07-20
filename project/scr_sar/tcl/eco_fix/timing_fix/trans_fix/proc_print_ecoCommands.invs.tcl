#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Mon Jul  7 20:42:42 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
# descrip   : print eco command refering to args, you can specify instname/celltype/terms/newInstNamePrefix/loc/relativeDistToSink to control one to print
# ref       : link url
# --------------------------
proc print_ecoCommand {args} {
  set type                "change"; # change|add|delete
  set inst                ""
  set terms               ""
  set celltype            ""
  set newInstNamePrefix   ""
  set loc                 {}
  set relativeDistToSink  ""
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$type == ""} {
    return "0x0:1"; # check your input $type
  } else {
    if {$type == "change"} {
      if {$inst == "" || $celltype == "" || [dbget top.insts.name $inst -e] == "" || [dbget head.libCells.name $celltype -e] == ""} {
        return "pe:0x0:2"; # change: error instname or celltype 
      }
      return "ecoChangeCell -cell $celltype -inst $inst"
    } elseif {$type == "add"} {
      if {$celltype == "" || [dbget head.libCells.name $celltype -e] == "" || ![llength $terms]} {
        return "0x0:3"; # add: error celltype/terms or loc is out of FPlan boxes
      }
      if {$newInstNamePrefix != ""} {
        if {[llength $loc] && [ifInBoxes $loc]} {
          if {$relativeDistToSink != "" && $relativeDistToSink > 0 && $relativeDistToSink < 1} {
            return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\} -loc \{$loc\} -relativeDistToSink $relativeDistToSink" 
          } elseif {$relativeDistToSink != "" && $relativeDistToSink < 0 || $relativeDistToSink != "" && $relativeDistToSink > 1} {
            return "0x0:5"; # check $relativeDistToSink 
          } else {
            return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\} -loc \{$loc\}" 
          }
        } elseif {[llength $loc] && ![ifInBoxes $loc]} {
          return "0x0:4"; # check your loc value, it is out of fplan boxes
        } elseif {![llength $loc] && $relativeDistToSink != "" && $relativeDistToSink > 0 && $relativeDistToSink < 1} {
          return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\} -relativeDistToSink $relativeDistToSink" 
        } else {
          return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\}"
        }
      } else {
        if {[llength $loc] && [ifInBoxes $loc]} {
          if {$relativeDistToSink != "" && $relativeDistToSink > 0 && $relativeDistToSink < 1} {
            return "ecoAddRepeater -cell $celltype -term \{$terms\} -loc \{$loc\} -relativeDistToSink $relativeDistToSink" 
          } elseif {$relativeDistToSink != "" && $relativeDistToSink < 0 || $relativeDistToSink != "" && $relativeDistToSink > 1} {
            return "0x0:5"; # check $relativeDistToSink 
          } else {
            return "ecoAddRepeater -cell $celltype -term \{$terms\} -loc \{$loc\}" 
          }
        } elseif {[llength $loc] && ![ifInBoxes $loc]} {
          return "0x0:6"; # check your loc value, it is out of fplan boxes
        } elseif {![llength $loc] && $relativeDistToSink != "" && $relativeDistToSink > 0 && $relativeDistToSink < 1} {
          return "ecoAddRepeater -cell $celltype -term \{$terms\} -relativeDistToSink $relativeDistToSink" 
        } elseif {$relativeDistToSink != "" && $relativeDistToSink <= 0 || $relativeDistToSink >= 1} {
          return "0x0:7"; # $relativeDistToSink range error
        } else {
          return "ecoAddRepeater -cell $celltype -term \{$terms\}"
        }
      }
    } elseif {$type == "delete"} {
      if {$inst == "" || [dbget top.insts.name $inst -e] == ""} {
        return "0x0:5"; # delete: error instname
      }
      return "ecoDeleteRepeater -inst $inst" 
    } else {
      return "0x0:0"; # have no choice in type
    }
  }
}
define_proc_arguments print_ecoCommand \
  -info "print eco command"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delete}}}}
    {-inst "specify inst to eco when type is add/delete" AString string optional}
    {-terms "specify terms to eco when type is add" AString string optional}
    {-celltype "specify celltype to add when type is add" AString string optional}
    {-newInstNamePrefix "specify new inst name prefix when type is add" AString string optional}
    {-loc "specify location of new inst when type is add" AString string optional}
    {-relativeDistToSink "specify relative value when type is add.(use it when loader is only one)" AFloat float optional}
  }
proc ifInBoxes {{loc {0 0}} {boxes {{}}}} {
  if {![llength [lindex $boxes 0]]} {
    set fplanBoxes [lindex [dbget top.fplan.boxes] 0]
  }
  foreach box $fplanBoxes {
    if {[ifInBox $loc $box]} {
      return 1 
    }
  }
  return 0
}
proc ifInBox {{loc {0 0}} {box {0 0 10 10}}} {
  set xRange [list [lindex $box 0] [lindex $box 2]]
  set yRange [list [lindex $box 1] [lindex $box 3]]
  set x [lindex $loc 0]
  set y [lindex $loc 1]
  if {[lindex $xRange 0] < $x && $x < [lindex $xRange 1] && [lindex $yRange 0] < $y && $y < [lindex $yRange 1]} {
    return 1 
  } else {
    return 0 
  }
}
