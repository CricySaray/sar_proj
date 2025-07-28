#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/26 10:37:57 Saturday
# label     : gui_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : for loop net, can delete input/output term net after placing instance to new location.
# ref       : link url
# --------------------------
source ./trans_fix/proc_ifInBoxes.invs.tcl; # ifInBoxes
proc placeAndReroute {{instname ""} {newLoc {}} {deleteInputOrOutputNet "all"} {testOrRun "test"}} {
  # $deleteInputOrOutputNet: input|output|all
  if {$instname == "" || [dbget top.insts.name $instname -e ] == "" || [llength $newLoc] != 2 || ![ifInBoxes $newLoc]} {
    error "proc placeAndReroute: check your input, have no instance name : $instname or the location pt($newLoc) is unvalid!!!"
  } else {
    select_obj $instname
    set inst_ptr [dbget top.insts.name $instname -p]
    set inputNet [dbget [dbget $inst_ptr.instTerms {.isInput}].net.name]
    set outputNet [dbget [dbget $inst_ptr.instTerms {.isOutput}].net.name]
    switch $deleteInputOrOutputNet {
      "input" { select_obj $inputNet }
      "output" { select_obj $outputNet }
      "all" { select_obj $inputNet ; select_obj $outputNet}
    }
    if {$testOrRun == "run"} {
      placeInstance $instname $newLoc
      switch $deleteInputOrOutputNet {
        "input" { editDelete -net $inputNet }
        "output" { editDelete -net $outputNet }
        "all" { editDelete -net $inputNet ; editDelete -net $outputNet}
      }
    }
  }
}
