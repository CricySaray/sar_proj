#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/01 11:11:34 Friday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : judge if viol situation need insert repeater
# return    : 
# ref       : link url
# --------------------------
source ../trans_fix/proc_get_cell_class.invs.tcl; # get_cell_class
proc ifNeedInsertRepeater {{celltype ""} {violValue ""} {fastestVT "AL9"} {cellRegExp "X(\\d+).*(A\[HRL\]\\d+)$"}} {
  if {$celltype == "" || [dbget head.libCells.name $celltype -e] == "" || ![string is double $violValue]} {
    error "proc ifNeedUseInsertRepeater: check your input!!!"
  } else {
    if {[catch {regexp $cellRegExp $celltype wholename driveCapacity VTtype} errorInfo]} {
      error "can't regexp for celltype: $celltype\n ERROR info: $errorInfo"
    } elseif {![info exists wholename] || ![info exists driveCapacity] || ![info exists VTtype]} {
      error "regexp error: have no expression result for $celltype"
    } else {
      if {$driveCapacity == "05"} {set driveCapacity 0.5} ; # for HH40/M31 std cell library
      set cellclass [get_cell_class $celltype]
      if {$violValue >= -0.003} {
        if {$VTtype == $fastestVT} {
          return 1
        }
        return 0
      } elseif {$violValue >= -0.06} {
        if {$cellclass in {buffer inverter CLKbuffer CLKinverter} && $driveCapacity < 12} {
          if {[regexp CLK $celltype] && $driveCapacity < 8} {; # special rule for clk celltype
            return 0; # can fix viol by changing VT or capacity
          } 
          return 1; # need insert repeater to solve viol
        }
        if {$cellclass in {logic CLKlogic} && $driveCapacity <= 4 } {
          return 0
        }
        return 1
      } else {
        return 1
      }
    }
  }
}
