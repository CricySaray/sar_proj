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
proc select_netOfPin_fromFile {{filepath ""} {columnOfViolPin -1} {ifSelect 1}} {
  # filepath can be abs path and relative path
  # columnOfViolPin must be 1 in beginning column
  if {$filepath == "" || [glob -nocomplain $filepath] == ""} {
    return "0x0:1"; # check your input
  } else {
    set fi [open $filepath r]
    set filename [file tail $filepath]
    set fo [open getnet_script_from_${filename}.tcl w]
    while {[gets $fi line] > -1} {
      if {$columnOfViolPin >= 1 && [string is integer $columnOfViolPin]} {
        set pin [lindex $line [expr $columnOfViolPin - 1]]
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
            if {$ifSelect} {eval $cmd1}
          }
        }
      } else {
        set hitFlag 0
        set i 0
        foreach item $line {
          incr i
          if {[dbget top.insts.instTerms.name $item -e] != ""} {
            set hitFlag 1
            set pin_ptr [dbget top.insts.instTerms.name $item -p]
            set net [dbget $pin_ptr.net.name -e]
            if {$net == ""} {
              set noNet   "# x - no net connected to this pin in column $i : $item"
              pw $fo $noNet
              break
              #return "0x0:3"; # no net connect to this pin
            } else {
              set fromPin "# ->  from pin in column $i : $item"
              set cmd1 "selectNet $net"
              pw $fo $fromPin; pw $fo $cmd1
              if {$ifSelect} {eval $cmd1}
              break
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
