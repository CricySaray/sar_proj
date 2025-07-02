#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, focusing on data display and aesthetics
# descrip   : get number of fanout and name of input terms of a pin. ONLY one pin!!!
# ref       : link url
# --------------------------
proc get_fanoutNum_and_inputTermsName_of_pin {{pin ""}} {
  if {$pin == "" || $pin == "0x0" || [dbget top.insts.instTerms.name $pin -e] == ""} {
    return "0x0:1"
  } else {
    set netOfPinPtr  [dbget [dbget top.insts.instTerms.name $pin -p].net.]
    set netNameOfPin [dbget $netOfPinPtr.name]
    set fanoutNum    [dbget $netOfPinPtr.numInputTerms]
    set allinstTerms [dbget $netOfPinPtr.instTerms.name]
    #set inputTermsName "[lreplace $allinstTerms [lsearch $allinstTerms $pin] [lsearch $allinstTerms $pin]]"
    set inputTermsName "[lsearch -all -inline -not -exact $allinstTerms $pin]"
    #puts "$fanoutNum"
    #puts "$inputTermsName"
    set numToInputTermName [list ]
    lappend numToInputTermName $fanoutNum
    lappend numToInputTermName $inputTermsName
    return $numToInputTermName
  }
}
