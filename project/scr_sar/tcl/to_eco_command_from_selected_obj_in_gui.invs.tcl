#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/10 12:47:04 Thursday
# label     : display_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> gui_proc   : for gui display, or effort can be viewed in invs GUI
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
#   -> dump_proc  : dump data with specific format from db(invs/pt/starrc/pv...)
# descrip   : print eco command according to selected obj(pin or inst) in invsGUI. 
#             It is convenient to write eco command by hand.
# ref       : link url
# --------------------------
proc to_eco_command_from_selected_obj_in_gui {{objs ""}} {
  if {$objs == ""} { set objs [dbget selected.name -e] }
  if {$objs == ""} {
    puts "error: no selected and no inputs!!!"
  } else {
    set insts ""
    set terms ""
    foreach obj $objs {
      set inst [dbget top.insts.name $obj -e]
      if {$inst != ""} {lappend insts $inst}
      set term [dbget top.insts.instTerms.name $obj -e]
      if {$term != ""} {lappend terms $term}
    }
    if {$insts != ""} {
      foreach i $insts { puts "ecoChangeCell -cell [dbget [dbget top.insts.name $i -p].cell.name] -inst $i" } 
    }
    if {$terms != ""} {
      foreach t $terms { puts "ecoAddRepeater -name sar_fix_what -cell what -term {$t} -loc { }"} 
    }
  }
}
alias toeco "to_eco_command_from_selected_obj_in_gui"
# 后面还得加一下假如是inst，那么需要看一下head.libCells.name 中还有什么其他驱动的同类型cell，可以用来替换的
