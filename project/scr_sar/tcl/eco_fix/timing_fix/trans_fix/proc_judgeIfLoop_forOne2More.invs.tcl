source ./proc_ifInBoxes.invs.tcl; # ifInBoxes
source ../../../packages/every_any.package.tcl; # every
source ../../../packages/cluster_point.package.tcl; # cluster_points
proc judgeIfLoop_forOne2More {{driverPinPt {}} {sinksPinPt {}} {netLength 0}} {
  if {![ifInBoxes $driverPinPt] || ![every x $sinksPinPt { ifInBoxes $x }]} {
    error "proc judgeIfLoop_forOne2More: check your input: pts is not in fplan boxes!!!" 
  } else {
    set clusters [cluster_points $sinksPinPt]
    set ruleNetLength 0
    foreach clusterGroup $clusters {
      set centerPtOfCluster [lindex $clusterGroup 0]
      set lengthOfCenterToEveryItems 0
      foreach itemPt [lindex $clusterGroup 1] {
        set distanceOfcenterToItem [expr sqrt([expr abs([expr [lindex $centerPtOfCluster 0] - [lindex $itemPt 0]])**2 + abs([expr [lindex $centerPtOfCluster 1] - [lindex $itemPt 1]])**2])]
        set lengthOfCenterToEveryItems [expr $lengthOfCenterToEveryItems + $distanceOfcenterToItem] 
      }
      set lengthDriverPtToCenterPtOfCluster [expr abs([expr [lindex $centerPtOfCluster 0] - [lindex $itemPt 0]]) + abs([expr [lindex $centerPtOfCluster 1] - [lindex $itemPt 1]])]
      set clusterLength [expr $lengthOfCenterToEveryItems + $lengthDriverPtToCenterPtOfCluster]
      set ruleNetLength [expr $ruleNetLength + $clusterLength]
    }
    set ratio [expr $netLength / $ruleNetLength]
    return $ratio
  }
}
