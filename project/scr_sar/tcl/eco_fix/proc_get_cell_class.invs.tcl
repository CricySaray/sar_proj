#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Sun Jul  6 00:41:35 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|task_proc)
# descrip   : get class of cell, like logic/sequential/buffer/inverter/CLKcell/gating/other
# ref       : link url
# --------------------------
proc get_cell_class {{instOrPin ""}} {
  if {$instOrPin == "" || $instOrPin == "0x0" || [expr  {[dbget top.insts.name $instOrPin -e] == "" && [dbget top.insts.instTerms.name $instOrPin -e] == ""}]} {
    return "0x0:1"; # have no instOrPin 
  } else {
    if {[dbget top.insts.name $instOrPin -e] != ""} {
      return [logic_of_mux $instOrPin]
    } elseif {[dbget top.insts.instTerms.name $instOrPin -e] != ""} {
      set inst_ofPin [dbget [dbget top.insts.instTerms.name $instOrPin -p2].name]
      return [logic_of_mux $inst_ofPin]
    }
  }
}
proc logic_of_mux {inst} {
  if {[get_property [get_cells $inst] is_sequential]} {
    return "sequential"
  } elseif {[regexp {CLK} [dbget [dbget top.insts.name $inst -p].cell.name]]} {
    return "CLKcell" 
  } elseif {[get_property [get_cells $inst] is_buffer]} {
    return "buffer" 
  } elseif {[get_property [get_cells $inst] is_inverter]} {
    return "inverter" 
  } elseif {[get_property [get_cells $inst] is_integrated_clock_gating_cell]} {
    return "gating"
  } elseif {[get_property [get_cells $inst] is_combinational]} {
    return "logic" 
  } else {
    return "other" 
  }
}
