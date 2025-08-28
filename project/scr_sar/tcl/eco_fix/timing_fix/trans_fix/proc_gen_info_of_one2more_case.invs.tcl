#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/28 10:29:27 Thursday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : Obtain all sink information in the one2more scenario to facilitate display and information query.
# return    : list {{one2more case} {one2more case} ...}
# ref       : link url
# --------------------------
source ./proc_find_shortest_path_with_offset.invs.tcl; # find_shortest_path_with_offset
source ./proc_calculate_path_length_usingWirePts.invs.tcl; # calculate_path_length_usingWirePts
source ./proc_calculateDistance_betweenTwoPoint.invs.tcl; # calculateDistance
source ../lut_build/operateLUT.tcl; # operateLUT
source ./proc_getPt_ofObj.invs.tcl; # gpt
proc gen_info_of_one2more_case {{violValue 0} driverPin allSinksPin wirePts allInfoToShow} {
  if {[llength $allSinksPin] <= 1} {
    error "proc gen_info_of_one2more_case: check your input: allSinksPin($allSinksPin) need input one2more sinks!!!" 
  } else {
    set detailInfoOfMoreCase [list ]
    set i 0
    foreach sinkpin $allSinksPin {
      incr i
      set driverPt [gpt $driverPin]
      set sinkpinPt [gpt $sinkpin]
      set one_path [find_shortest_path_with_offset $driverPt $sinkpinPt $wirePts]
      if {$one_path == "" } {
        set sinkpin_netLen [calculateDistance $driverPt $sinkpinPt] 
      } else {
        set sinkpin_netLen [calculate_path_length_usingWirePts [find_shortest_path_with_offset $driverPt $sinkpinPt $wirePts]]
      }
      set sinkpin_celltype  [dbget [dbget top.insts.instTerms.name $sinkpin -p2].cell.name]
      set sinkpin_cellclass [operateLUT -type read -attr [list celltype $sinkpin_celltype class]]
      if {$i == 1} { lappend detailInfoOfMoreCase [list $violValue $sinkpin_netLen {*}[lreplace [lrange $allInfoToShow 0 end-3] 3 3] $sinkpin_cellclass $sinkpin_celltype $sinkpin] } else {
        lappend detailInfoOfMoreCase [list $violValue $sinkpin_netLen "/" "/" "/" "/" "/" "/" "/" $sinkpin_cellclass $sinkpin_celltype $sinkpin] 
      }
    }
    return $detailInfoOfMoreCase
  }
}
