#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/10 12:39:48 Thursday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> gui_proc   : for gui display, or effort can be viewed in invs GUI
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
#   -> dump_proc  : dump data with specific format from db(invs/pt/starrc/pv...)
# descrip   : createPhysicalPin only for select pg net (very simple proc without inputs checking)
# ref       : link url
# --------------------------
proc add_physicalPin_for_selectedPGNet {} {
  set net_ptr [dbget selected.]
  set netname [dbget $net_ptr.net.name]
  set netbox  [dbget $net_ptr.box]
  foreach name $netname box $netbox {
    createPhysicalPin $name -layer RDL -rect $box -net $name 
  }
}
