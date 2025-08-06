#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Mon Jul  7 20:42:42 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
# descrip   : print eco command refering to args, you can specify instname/celltype/terms/newInstNamePrefix/loc/relativeDistToSink to control one to print
# update    : 2025/07/27 22:23:08 Sunday
#             add new option: $radius, and fix some logical error
# ref       : link url
# --------------------------
source ./proc_ifInBoxes.invs.tcl; # ifInBoxes
proc print_ecoCommand {args} {
  set type                "change"; # change|add|delRepeater|delNet
  set inst                ""
  set terms               ""
  set celltype            ""
  set newInstNamePrefix   ""
  set loc                 {}
  set relativeDistToSink  ""
  set radius              ""
  set net                 ""
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$type == ""} {
    error "proc print_ecoCommand: check your input: must provide valid type name!!!"; # check your input $type
  } else {
    if {$type == "change"} {
      if {$inst == "" || $celltype == "" || [dbget top.insts.name $inst -e] == "" || [dbget head.libCells.name $celltype -e] == ""} {
        error "proc print_ecoCommand: check your input: not found instname($instname) or celltype($celltype) when type is $type"; # change: error instname or celltype 
      }
      return "ecoChangeCell -cell $celltype -inst $inst"
    } elseif {$type == "add"} {
      if {$celltype == "" || [dbget head.libCells.name $celltype -e] == "" || ![llength $terms]} {
        error "proc print_ecoCommand: check your input: not found celltype($celltype) or the terms($terms) is empty!!!"; # add: error celltype/terms or loc is out of FPlan boxes
      }
      if {$newInstNamePrefix != ""} {
        if {[llength $loc] && [ifInBoxes $loc]} {
          if {$radius != "" && [string is double $radius]} {
            return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\} -loc \{$loc\} -radius $radius" 
          } else {
            return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\} -loc \{$loc\}" 
          }
        } elseif {[llength $loc] && ![ifInBoxes $loc]} {
          error "proc print_ecoCommand: check your input: invalid location($loc), it is out of fplan boxes!!!"; # check your loc value, it is out of fplan boxes
        } elseif {![llength $loc] && $relativeDistToSink != "" && $relativeDistToSink > 0 && $relativeDistToSink < 1} {
          if {$radius != "" && [string is double $radius]} {
            return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\} -relativeDistToSink $relativeDistToSink -radius $radius" 
          } else {
            return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\} -relativeDistToSink $relativeDistToSink" 
          }
        } else {
          return "ecoAddRepeater -name $newInstNamePrefix -cell $celltype -term \{$terms\}"
        }
      } else {
        if {[llength $loc] && [ifInBoxes $loc]} {
          if {$radius != "" && [string is double $radius]} {
            return "ecoAddRepeater -cell $celltype -term \{$terms\} -loc \{$loc\} -radius $radius" 
          } else {
            return "ecoAddRepeater -cell $celltype -term \{$terms\} -loc \{$loc\}" 
          }
        } elseif {[llength $loc] && ![ifInBoxes $loc]} {
          error "proc print_ecoCommand: check your input: invalid location($loc), it is out of fplan boxes!!!"; # check your loc value, it is out of fplan boxes
        } elseif {![llength $loc] && $relativeDistToSink != "" && $relativeDistToSink > 0 && $relativeDistToSink < 1} {
          if {$radius != "" && [string is double $radius]} {
            return "ecoAddRepeater -cell $celltype -term \{$terms\} -relativeDistToSink $relativeDistToSink -radius $radius" 
          } else {
            return "ecoAddRepeater -cell $celltype -term \{$terms\} -relativeDistToSink $relativeDistToSink" 
          }
        } elseif {$relativeDistToSink != "" && $relativeDistToSink <= 0 || $relativeDistToSink >= 1} {
          error "proc print_ecoCommand: check your input: the var relativeDistToSink($relativeDistToSink) is out of range, need be inside 0-1"; # $relativeDistToSink range error
        } else {
          return "ecoAddRepeater -cell $celltype -term \{$terms\}"
        }
      }
    } elseif {$type == "delRepeater"} {
      if {$inst == "" || [dbget top.insts.name $inst -e] == ""} {
        error "proc print_ecoCommand: check your input : not find instname($instname)"; # delRepeater: error instname
      }
      return "ecoDeleteRepeater -inst $inst" 
    } elseif {$type == "delNet"} {
      if {$terms != "" && [llength $terms] == 1 && [dbget top.insts.instTerms.name $terms -e] != "" } {
        set netname [dbget [dbget top.insts.instTerms.name $tems -e -p].net.name]
        return "editDelete -net $netname"
      } elseif {$net != "" && [dbget top.nets.name $net -e] != ""} {
        return "editDelete -net $net" 
      } else {
        error "proc print_ecoCommand: check your input of net($net) or terms($terms) when type is $type" 
      }
    } else {
      error "proc print_ecoCommand: check your input: have no this type of action: $type"; # have no choice in type
    }
  }
}
define_proc_arguments print_ecoCommand \
  -info "print eco command"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater}}}}
    {-inst "specify inst to eco when type is add/delete" AString string optional}
    {-terms "specify terms to eco when type is add" AString string optional}
    {-celltype "specify celltype to add when type is add" AString string optional}
    {-newInstNamePrefix "specify new inst name prefix when type is add" AString string optional}
    {-loc "specify location of new inst when type is add" AString string optional}
    {-relativeDistToSink "specify relative value when type is add.(use it when loader is only one)" AFloat float optional}
    {-radius "specify radius searching location" AFloat float optional}
    {-net "specify netname to delete" AString string optional}
  }
