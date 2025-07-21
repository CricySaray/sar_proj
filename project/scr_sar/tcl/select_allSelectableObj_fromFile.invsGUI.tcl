#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/21 09:55:05 Monday
# label     : gui_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : select all objects that is accept to select(it is inst/pin/net as normal). if there are a lot obj meeting conditions, it will select all these.
# ref       : link url
# --------------------------
source eco_fix/timing_fix/trans_fix/proc_pw_puts_message_to_file_and_window.common.tcl; # pw
proc select_allSelectableObj_fromFile {{filename ""}} {
  if {$filename == "" || [glob -nocomplain $filename ] == ""} {
    error "proc select_allSelectableObj_fromFile: check your input filename!!! can't find it." 
  } else {
    set fi [open $filename r]
    set finame [file tail $filename]
    set fo [open "selectAllObjFrom_${finame}.tcl" w]
    while {[gets $fi line] > -1} {
      foreach l $line {
        set inst_ptr [dbget top.insts.name $l -e -p]
        if {$inst_ptr != ""} {
          set instname [dbget $inst_ptr.name] 
          select_obj $instname
          set inf "# find inst: $instname"; pw $fo $inf
          set cmd "select_obj $instname"; pw $fo $cmd; eval $cmd
          continue
        }
        set pin_ptr [dbget top.insts.instTerms.name $l -e -p]
        if {$pin_ptr != ""} {
          set pinname [dbget $pin_ptr.name]
          select_obj $pinname
          set inf "# find pin: $pinname"; pw $fo $inf
          set cmd "select_obj $pinname"; pw $fo $cmd; eval $cmd
          continue 
        }
        set net_ptr [dbget top.nets.name $l -e -p]
        if {$net_ptr != ""} {
          set netname [dbget $net_ptr.name]
          select_obj $netname
          set inf "# find inst: $netname"; pw $fo $inf
          set cmd "select_obj $netname"; pw $fo $cmd; eval $cmd
          continue 
        }
      }
    } 
  close $fi; close $fo
  }
}
