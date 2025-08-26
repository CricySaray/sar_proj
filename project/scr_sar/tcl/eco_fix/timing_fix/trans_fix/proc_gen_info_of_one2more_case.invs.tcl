source ./proc_find_shortest_path_with_offset.invs.tcl; # find_shortest_path_with_offset
source ./proc_get_net_lenth.invs.tcl; # get_net_length
source ./proc_calculateDistance_betweenTwoPoint.invs.tcl; # calculateDistance
proc gen_info_of_one2more_case {{violValue 0} allInfoToShow allSinksPin} {
  if {[llength $allSinksPin] <= 1} {
    error "proc gen_info_of_one2more_case: check your input: allSinksPin($allSinksPin) need input one2more sinks!!!" 
  } else {
    set detailInfoOfMoreCase [list ]
    set i
    foreach sinkpin $allSinksPin {
      incr i
      set sinkpin_netLen []
      if {$i == 1} { lappend detailInfoOfMoreCase [list $violValue ] }
    }
    return $detailInfoOfMoreCase
  }
}
