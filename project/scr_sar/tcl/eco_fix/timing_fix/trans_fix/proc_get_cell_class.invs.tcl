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
# update    : 2025/08/08 15:32:45 Friday
#             (U001) add custom map list for user, it supports custom config
#             it can't support any wildcard or regexp like TAP*, AR?L?H?9, X[0-9] , which are not support!!!
#             customMapList: for example {{physical {TAP0X1AR9 FILLER4AR9}} {IOpad {RCLIB_PLVDDHA}} {IOfiller {RCLIB_PLFLR5 RCLIB_PLFLR1}}}
#             (U002) you can expanded regExp to get matched Lib CellTypes, and give these to variable, proc get_class_of_celltype can be input to inner of proc
#             you can generate this expanded list when sourcing this script(like U003), and it need be set global variable inside proc, which is FASTER method!!!
# ref       : link url
# --------------------------
proc get_cell_class {{instOrPinOrCelltype ""}} {
  if {$instOrPinOrCelltype == "" || $instOrPinOrCelltype == "0x0" || [expr  {[dbget top.insts.name $instOrPinOrCelltype -e] == "" && [dbget top.insts.instTerms.name $instOrPinOrCelltype -e] == "" && [dbget head.libCells.name $instOrPinOrCelltype -e] == ""}]} {
    return "0x0:1"; # have no instOrPinOrCelltype 
  } else {
    if {[dbget top.insts.name $instOrPinOrCelltype -e] != ""} {
      set celltype_ofInst [dbget [dbget top.insts.name $instOrPinOrCelltype].cell.name]
      return [get_class_of_celltype $celltype_ofInst]
    } elseif {[dbget top.insts.instTerms.name $instOrPinOrCelltype -e] != ""} {
      set celltype_ofPin [dbget [dbget top.insts.instTerms.name $instOrPinOrCelltype -p2].cell.name]
      return [get_class_of_celltype $celltype_ofPin]
    } elseif {[dbget head.libCells.name $instOrPinOrCelltype -e] != ""} {
      return [get_class_of_celltype $instOrPinOrCelltype]
    }
  }
}

# songNOTE: NOTICE: if you open invs db without timing info, you will get incorrect judgement for cell class, you can only get logic and sequential!
#           ADVANCE: it can test if you open noTiming invs db. if it is, it judge it by other rule
# prompt : please open invs db with timing info
proc expandMapList {{customMapList {}}} {
  if {[llength $customMapList]} {
    set expandedMapList [lmap item_map $customMapList {
      set item_class [lindex $item_map 0]
      set item_matchedCellType [list ]
      foreach itemExp [lindex $item_map 1] {
        set matched_second [dbget -regexp head.libCells.name $itemExp -e]
        lappend item_matchedCellType {*}$matched_second
      }
      set temp_class_matchedCellTypes [list $item_class $item_matchedCellType]
    }]
    return $expandedMapList
  } else {
    return [list ] 
  }
}
set customMapList_example {{filler {{FILLERC*\d+A[HRL]9}}} {ANT {{ANTENNA*}}} {noCare {{BUSHOLD*}}} {IOfiller {{RCLIB_PLFLR\d$}}} {cutCell {{RCLIB_PLFLR5_CUT*}}} {IOpad {{RCLIB_*}}} {tapCell {{TAP*}}} {tieCell {{TIE\d+X\d+A[HLR]9}}}} ; # U002
set expandedMapList [expandMapList $customMapList_example] ; # U003: you need write cmd "global expandedMapList" when the beginning of proc
proc get_class_of_celltype {celltype {customMapList {}} {clkExp "CLK"} {delayCellExp "DEL"}} {
  if {[llength $customMapList]} {
    # customMapList: for example {{physical {TAP0X1AR9 FILLER4AR9}} {IOpad {RCLIB_PLVDDHA}} {IOfiller {RCLIB_PLFLR5 RCLIB_PLFLR1}}}
    foreach item_map $customMapList { ; # U001
      set class_name [lindex $item_map 0]
      set toMatchCelltype [lindex $item_map 1]
      if {[llength $toMatchCelltype] && [expr {$celltype in $toMatchCelltype || $celltype == $toMatchCelltype}]} {
        return $class_name
      } elseif {![llength $toMatchCelltype]} {
        error "proc get_class_of_celltype: check your customMapList($item_map): can't match any celltype in toMatchList" 
      }
    }
  } 
  set lib_cells [get_lib_cells $celltype -q]
  if {$lib_cells == ""} {
    return "notFoundLibCell" 
  } else {
    if {[lsort -unique [get_property $lib_cells is_memory_cell]]} {
      return "mem"
    } elseif {[lsort -unique [get_property $lib_cells is_black_box]]} {
      return "IP"
    } elseif {[lsort -unique [get_property $lib_cells is_integrated_clock_gating_cell]]} {
      return "gating"
    } elseif {[lsort -unique [get_property $lib_cells is_sequential]]} {
      return "sequential"
    } elseif {[regexp $clkExp $celltype]} {
      if {[lsort -unique [get_property $lib_cells is_buffer]]} {
        return "CLKbuffer"
      } elseif {[lsort -unique [get_property $lib_cells is_inverter]]} {
        return "CLKinverter"
      } elseif {[lsort -unique [get_property $lib_cells is_combinational]]} {
        return "CLKlogic" 
      } else {
        return "CLKcell" 
      }
    } elseif {[regexp "^$delayCellExp" $celltype] && [lsort -unique [get_property $lib_cells is_buffer]]} {
      return "delay"
    } elseif {[lsort -unique [get_property $lib_cells is_buffer]]} {
      return "buffer" 
    } elseif {[lsort -unique [get_property $lib_cells is_inverter]]} {
      return "inverter" 
    } elseif {[lsort -unique [get_property $lib_cells is_combinational]]} {
      return "logic" 
    } else {
      return "other" 
    }
  }
}
