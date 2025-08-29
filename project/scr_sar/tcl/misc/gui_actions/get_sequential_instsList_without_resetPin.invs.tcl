#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 15:37:39 CST 2025
# descrip   : get all seqential insts, and get all pins name of every inst. if list does NOT has RB(reset pin name), append to list. return list 
# ref       : link url
# --------------------------
proc get_seqential_instsList_without_resetPin {{resetPinName "RB"}} {
  set seqs [get_object_name [get_cells -hier * -filter "is_sequential == true"]]
  set without_resetPin_insts [list ]
  foreach seq $seqs {
    set wholePinsName [dbget [dbget top.insts.name $seq -p].instTerms.name] 
    set onlyPinsName [lmap pin $wholePinsName {
      regsub {.*\/(\w+)} $pin {\1} result 
      set result
    }]
    if {[lsearch -exact $onlyPinsName $resetPinName] == -1} {lappend without_resetPin_insts $seq}
  }
  return [join $without_resetPin_insts \n]
}
