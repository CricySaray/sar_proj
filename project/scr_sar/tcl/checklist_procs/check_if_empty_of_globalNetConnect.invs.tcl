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
    set all_cellSubClass [dbget top.insts.cell.subClass -u -e]
    if {$all_cellSubClass == ""} {
      error "proc check_if_empty_of_globalNetConnect: check your design([dbget top.name]) is not found any insts!!!"
    } else {
      foreach subclass $all_cellSubClass {
        set all_subclassOfAllInsts [dbget top.insts.cell.subClass $subclass -p2]
        set all_subclassOfAllInsts [lsort -command {
          apply {{a b} {
            set a_len [llength [dbget top.insts.cell.subClass $a -p2]]
            set b_len [llength [dbget top.insts.cell.subClass $b -p2]]
            if {$a_len > $b_len} { return -1 }
            if {$b_len > $b_len} { return 1 } else { return 0 }
          }} 
        } $all_subclassOfAllInsts]
  puts $all_subclassOfAllInsts
        foreach temp_subclass $all_subclassOfAllInsts {
          puts "# - scanning subClass: $temp_subclass ..."
          set all_insts_of_this_subclass_ptr [dbget top.insts.cell.subClass $temp_subclass -p2]
          foreach inst_of_this_subclass_ptr $all_insts_of_this_subclass_ptr {
            set signalPins_ofInst [dbget $inst_of_this_subclass_ptr.instTerms.]
            foreach signalpin $signalPins_ofInst {
              set signal_net [dbget $signalpin.net.name -e] 
              if {}
            }
          }
        }
      } 
    }
  }
}
