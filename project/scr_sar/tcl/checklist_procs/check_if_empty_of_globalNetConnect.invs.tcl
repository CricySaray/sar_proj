#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/08 17:47:04 Monday
# label     : check_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : check if the globalNetConnect of inst is empty 
# return    : output file
# ref       : link url
# --------------------------
proc check_if_empty_of_globalNetConnect {} {
  if {} {
   
  } else {
    set all_insts_ptr [dbget top.insts. -e] 
    set all_cellSubClass [dbget top.insts.cell.subClass -u -e]
    if {$all_insts_ptr == ""} {
      error "proc check_if_empty_of_globalNetConnect: check your design([dbget top.name]) is not found any insts!!!"
    } else {
      foreach inst_ptr $all_insts_ptr {
        set inst_allSignalPins_ptr [dbget $inst_ptr.instTerms.]
        if {$inst_allSignalPins_ptr != ""} {
          foreach inst_signalPin_ptr $inst_allSignalPins_ptr {
             
          }
        }
      } 
    }
  }
}
