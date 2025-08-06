#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/06 18:38:52 Wednesday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : judge if it has loop problem using Algorithm DBSCAN(proc cluster_points)
# test entry: you can test all nets ratio of all design using ../../../scr_sar/tcl/packages/testAllNetRatio_using_cluster_point.test.tcl
#             and then specify the threshold that is been loopped!
# return    : 0|1|2|3
#             0: no loop
#             1|2|3: have loop problem
# ref       : link url
# --------------------------
source ./proc_ifInBoxes.invs.tcl; # ifInBoxes
source ../../../packages/every_any.package.tcl; # every
source ../../../packages/cluster_point.package.tcl; # cluster_points
proc judgeIfLoop_forOne2More {{driverPinPt {}} {sinksPinPt {}} {netLength 0} {checkMode normal}} {
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
    switch $checkMode {
      "strict" { set threshold {1.4 1.8 2.3} } 
      "normal" { set threshold {1.7 2.3 3} } 
      "relax"  { set threshold {2.3 3.2 4} }
    }
    return $ratio
  }
}
