#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/10 17:08:05 Wednesday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : gen cmd for globalNetConnect
# return    : 
# ref       : link url
# --------------------------
proc genCmd_globalNetConnect {args} {
  set insts_pins_nets_Lists {} ; # for example: {{{instname1 instname2 ...} {pin1 pin2 ...} {net1 net2 ...}}} ; # instnames can have much, pin and net can also have much, but both of pin and net must match one by one
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set cmdsList [list ]
  if {![llength $insts_pins_nets_Lists]} {
    error "proc genCmd_globalNetConnect: check your intput : insts_pins_nets_Lists($insts_pins_nets_Lists) is empty!!!" 
  }
  foreach temp_insts_pins_nets $insts_pins_nets_Lists {
    lassign $temp_insts_pins_nets temp_insts temp_pins temp_nets
    if {[llength $temp_pins] != [llength $temp_nets]} {
      error "proc genCmd_globalNetConnect: check your input : pins($temp_pins) and nets($temp_nets) are not match each other!!!" 
    }
    foreach temp_inst $temp_insts {
      if {[dbget top.insts.name $temp_inst -e] == ""} {
        error "proc genCmd_globalNetConnect: check your input : inst($temp_inst) is not found in invs db!!!" 
      }
      foreach temp_pin $temp_pins temp_net $temp_nets {
        if {[dbget [dbget top.insts.name $temp_inst -p].cell.pgTerms.name $temp_pin -e] == ""} {
          set temp_inst_cell_name [dbget [dbget top.insts.name $temp_inst -p].cell.name ]
          error "proc genCmd_globalNetConnect: check your input : pin($temp_pin) of cell($temp_inst_cell_name) of inst($temp_inst) is not found!!!" 
        }
        if {[dbget top.pgNets.name $temp_net -e] == ""} {
          error "proc genCmd_globalNetConnect: check your input : pg net($temp_net) is not found !!!" 
        }
        lappend cmdsList "globalNetConnect $temp_net -sinst $temp_inst -pin $temp_pin -type pgpin -override -verbose"
      } 
    } 
  }
  return $cmdsList
}
define_proc_arguments genCmd_globalNetConnect \
  -info "gen cmd for cmd globalNetConnect"\
  -define_args {
    {-insts_pins_nets_Lists "specify lists of \"insts pins nets\"" AList list optional}
  }

# for example
if {0} {
  set aon_insts [dbget [dbget -regexp top.insts.pstatus {^placed|fixed} -p].name *PDM_AON*]
  set ono_insts [dbget [dbget -regexp top.insts.pstatus {^placed|fixed} -p].name *PDM_ONO*]
  set insts_pins_nets_Lists [list [list $aon_insts {VDD VSS} {DVDD_AON DVSS}] [list $ono_insts {VDD VSS} {DVDD_ONO DVSS}]]
  puts [join [genCmd_globalNetConnect -insts_pins_nets_Lists $insts_pins_nets_Lists] \n]
}
