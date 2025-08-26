#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
# descrip   : judge if a pin is output! ONLY one pin 
# ref       : link url
# --------------------------
proc if_driver_or_load {{pin ""}} {
  if {$pin == "" || $pin == "0x0" || [dbget top.insts.instTerms.name $pin -e] == ""} {
    #error "proc if_driver_or_load: check your input: pin($pin) not found in invs db!!!"
    return "0x0"
  } else {
    if {[dbget [dbget top.insts.instTerms.name $pin -p].isOutput] == 1} {
      return 1 
    } else {
      return 0 
    }
  }
}
