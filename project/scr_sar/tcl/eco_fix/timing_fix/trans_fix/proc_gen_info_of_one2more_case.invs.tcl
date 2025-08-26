source ./proc_find_shortest_path_with_offset.invs.tcl; # find_shortest_path_with_offset
source ./proc_calculate_path_length_usingWirePts.invs.tcl; # calculate_path_length_usingWirePts
source ./proc_calculateDistance_betweenTwoPoint.invs.tcl; # calculateDistance
proc gen_info_of_one2more_case {{violValue 0} driverPin allSinksPin wirePts driverPt allInfoToShow} {
  if {[llength $allSinksPin] <= 1} {
    error "proc gen_info_of_one2more_case: check your input: allSinksPin($allSinksPin) need input one2more sinks!!!" 
  } else {
    set detailInfoOfMoreCase [list ]
    set i
    foreach sinkpin $allSinksPin {
      incr i
      set driverPt [gpt $driverPin]
      set sinkpin_netLen [calculate_path_length_usingWirePts [find_shortest_path_with_offset $dri]]
      if {$i == 1} { lappend detailInfoOfMoreCase [list $violValue ] }
    }
    return $detailInfoOfMoreCase
  }
}
