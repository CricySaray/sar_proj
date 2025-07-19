#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/19 22:14:46 Saturday
# label     : gui_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : select whole net from from viol file, and check if there is any circling or going around in circles
# ref       : link url
# --------------------------
source ./eco_fix/timing_fix/trans_fix/proc_pw_puts_message_to_file_and_window.common.tcl; # pw
proc select_netOfPin_fromFile {{filename ""} {columnOfViolPin -1}} {
  if {$filename == "" || [glob -nocomplain $filename] == ""} {
    return "0x0:1"; # check your input
  } else {
    set fi [open $filename r]
    set fo [open getnet_script_from_${filename}.tcl w]
    while {[gets $fi line] > -1} {
      if {$columnOfViolPin >= 0 && [string is integer $columnOfViolPin]} {
        set pin [lindex $line $columnOfViolPin]
        if {[dbget top.insts.instTerms.name $pin -e] == ""} {
          set notFindPin "# x - not find valid pin info"
          pw $fo $notFindPin
          #return "0x0:2"; # column specified to pin is incorrect
        } else {
          set pin_ptr [dbget top.insts.instTerms.name $pin -p]
          set net [dbget $pin_ptr.net.name -e]
          if {$net == ""} {
            set noNet   "# x - no net connected to this pin : $pin"
            pw $fo $noNet
            #return "0x0:3"; # no net connect to this pin
          } else {
            set fromPin "# ->  from pin: $pin"
            set cmd1 "selectNet $net"
            pw $fo $fromPin; pw $fo $cmd1
          }
        }
      } else {
        set hitFlag 0
        foreach item $line {
          if {[dbget top.insts.instTerms.name $item -e] != ""} {
            set hitFlag 1
            set pin_ptr [dbget top.insts.instTerms.name $item -p]
            set net [dbget $pin_ptr.net.name -e]
            if {$net == ""} {
              set noNet   "# x - no net connected to this pin : $item"
              pw $fo $noNet
              #return "0x0:3"; # no net connect to this pin
            } else {
              set fromPin "# ->  from pin: $item"
              set cmd1 "selectNet $net"
              pw $fo $fromPin; pw $fo $cmd1
            }
          }
        }
        if {!$hitFlag} {
          set notFindPin "# x - not find valid pin info"
          pw $fo $notFindPin
        }
      }
    }
  close $fi; close $fo
  }
}
