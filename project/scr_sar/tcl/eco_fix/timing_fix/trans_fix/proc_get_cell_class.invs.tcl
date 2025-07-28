#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Sun Jul  6 00:41:35 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|task_proc)
# descrip   : get class of cell, like logic/sequential/buffer/inverter/CLKcell/gating/other
#             songNOTE: NOTICE: this proc must be run at invs db with Timing Library Info!!!
# update    : 2025/07/27 17:34:54 Sunday
#             can input instname or pinname or celltype, it can only input instname and pinname before
# ref       : link url
# --------------------------
proc get_cell_class {{instOrPinOrCelltype ""}} {
  if {$instOrPinOrCelltype == "" || $instOrPinOrCelltype == "0x0" || [expr  {[dbget top.insts.name $instOrPinOrCelltype -e] == "" && [dbget top.insts.instTerms.name $instOrPinOrCelltype -e] == ""}]} {
    return "0x0:1"; # have no instOrPinOrCelltype 
  } else {
    if {[dbget top.insts.name $instOrPinOrCelltype -e] != ""} {
      return [logic_of_mux $instOrPinOrCelltype]
    } elseif {[dbget top.insts.instTerms.name $instOrPinOrCelltype -e] != ""} {
      set inst_ofPin [dbget [dbget top.insts.instTerms.name $instOrPinOrCelltype -p2].name]
      return [logic_of_mux $inst_ofPin]
    } elseif {[dbget head.libCells.name $instOrPinOrCelltype -e] != ""} {
      return [logic_of_mux $instOrPinOrCelltype]
    }
  }
}

# songNOTE: NOTICE: if you open invs db without timing info, you will get incorrect judgement for cell class, you can only get logic and sequential!
#           ADVANCE: it can test if you open noTiming invs db. if it is, it judge it by other rule
# now : please open invs db with timing info
proc logic_of_mux {instOrCelltype} {
  if {[dbget top.insts.name $instOrCelltype -e] != ""} {
    set celltype [dbget [dbget top.insts.name $instOrCelltype -p].cell.name]
    if {[get_property [get_cells $instOrCelltype] is_memory_cell]} {
      return "mem"
    } elseif {[get_property [get_cells $instOrCelltype] is_sequential]} {
      return "sequential"
    } elseif {[regexp {CLK} $celltype]} {
      if {[get_property [get_cells $instOrCelltype] is_buffer]} {
        return "CLKbuffer"
      } elseif {[get_property [get_cells $instOrCelltype] is_inverter]} {
        return "CLKinverter"
      } elseif {[get_property [get_cells $instOrCelltype] is_combinational]} {
        return "CLKlogic" 
      } else {
        return "CLKcell" 
      }
    } elseif {[regexp {^DEL} $celltype] && [get_property [get_cells $instOrCelltype] is_buffer]} {
      return "delay"
    } elseif {[get_property [get_cells $instOrCelltype] is_buffer]} {
      return "buffer" 
    } elseif {[get_property [get_cells $instOrCelltype] is_inverter]} {
      return "inverter" 
    } elseif {[get_property [get_cells $instOrCelltype] is_integrated_clock_gating_cell]} {
      return "gating"
    } elseif {[get_property [get_cells $instOrCelltype] is_combinational]} {
      return "logic" 
    } else {
      return "other" 
    }
  } elseif {[dbget head.libCells.name $instOrPinOrCelltype -e] == ""} {
    if {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_memory_cell]]} {
      return "mem"
    } elseif {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_sequential]]} {
      return "sequential"
    } elseif {[regexp {CLK} $instOrCelltype]} {
      if {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_buffer]]} {
        return "CLKbuffer"
      } elseif {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_inverter]]} {
        return "CLKinverter"
      } elseif {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_combinational]]} {
        return "CLKlogic" 
      } else {
        return "CLKcell" 
      }
    } elseif {[regexp {^DEL} $instOrCelltype] && [lsort -unique [get_property [get_lib_cells $instOrCelltype] is_buffer]]} {
      return "delay"
    } elseif {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_buffer]]} {
      return "buffer" 
    } elseif {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_inverter]]} {
      return "inverter" 
    } elseif {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_integrated_clock_gating_cell]]} {
      return "gating"
    } elseif {[lsort -unique [get_property [get_lib_cells $instOrCelltype] is_combinational]]} {
      return "logic" 
    } else {
      return "other" 
    }

  }

}
