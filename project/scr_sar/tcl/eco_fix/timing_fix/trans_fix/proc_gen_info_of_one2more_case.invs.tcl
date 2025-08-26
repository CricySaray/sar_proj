source ./proc_find_shortest_path_with_offset.invs.tcl; # find_shortest_path_with_offset
source ./proc_calculate_path_length_usingWirePts.invs.tcl; # calculate_path_length_usingWirePts
source ./proc_calculateDistance_betweenTwoPoint.invs.tcl; # calculateDistance
source ../lut_build/operateLUT.tcl; # operateLUT
proc gen_info_of_one2more_case {{violValue 0} driverPin allSinksPin wirePts driverPt allInfoToShow} {
  if {[llength $allSinksPin] <= 1} {
    error "proc gen_info_of_one2more_case: check your input: allSinksPin($allSinksPin) need input one2more sinks!!!" 
  } else {
    set detailInfoOfMoreCase [list ]
    set i
    foreach sinkpin $allSinksPin {
      incr i
      set driverPt [gpt $driverPin]
      set sinkpinPt [gpt $sinkpin]
      set sinkpin_netLen [calculate_path_length_usingWirePts [find_shortest_path_with_offset $driverPin $sinkpinPt $wirePts]]
      set sinkpin_celltype  [dbget [dbget top.insts.instTerms.name $sinkpin -p2].cell.name]
      set sinkpin_cellclass [operateLUT -type read -attr [list celltype $sinkpin_celltype class]]
      if {$i == 1} { lappend detailInfoOfMoreCase [list $violValue $sinkpin_netLen {*}[lrange $allInfoToShow 0 end-3] ] } else {
        lappend detailInfoOfMoreCase [list $violValue $sinkpin_netLen "/" "/" "/" "/" "/" "/" "/" ] 
      }
    }
    return $detailInfoOfMoreCase
  }
}
