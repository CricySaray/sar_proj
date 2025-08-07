#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/06 18:38:52 Wednesday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : judge if it has loop problem using Algorithm DBSCAN(proc cluster_points)
# test entry: songNOTE: NOTICE you need test all nets ratio of all design using ../../../scr_sar/tcl/test_procs/test_ifLoop_forAllNets_usingClusterPointMethod.test.tcl
#             and then specify the threshold that is been looped!
# return    : 0|1|2|3
#             0: no loop
#             1|2|3: have loop problem
# ref       : link url
# --------------------------
source ./proc_ifInBoxes.invs.tcl; # ifInBoxes
source ../../../packages/every_any.package.tcl; # every
source ../../../packages/cluster_point.package.tcl; # cluster_points
proc judgeIfLoop_forOne2More {{driverPinPt {}} {sinksPinPt {}} {netLength 0} {netThreshold 16} {debug 0}} {
  if {![ifInBoxes $driverPinPt] || ![every x $sinksPinPt { ifInBoxes $x }]} {
    error "proc judgeIfLoop_forOne2More: check your input: pts is not in fplan boxes!!!" 
  } else {
    set clusters [cluster_points $sinksPinPt]
    if {$debug} { puts "clustersNum: [llength $clusters] | clusters: $clusters" }
    set ruleNetLength 0
    foreach clusterGroup $clusters {
      set centerPtOfCluster [lindex $clusterGroup 0]
      set lengthOfCenterToEveryItems 0
      foreach itemPt [lindex $clusterGroup 1] {
        set distanceOfcenterToItem [expr sqrt([expr abs([expr [lindex $centerPtOfCluster 0] - [lindex $itemPt 0]])**2 + abs([expr [lindex $centerPtOfCluster 1] - [lindex $itemPt 1]])**2])]
        set lengthOfCenterToEveryItems [expr $lengthOfCenterToEveryItems + $distanceOfcenterToItem] 
      }
      set lengthDriverPtToCenterPtOfCluster [expr abs([expr [lindex $centerPtOfCluster 0] - [lindex $driverPinPt 0]]) + abs([expr [lindex $centerPtOfCluster 1] - [lindex $driverPinPt 1]])]
      set clusterLength [expr $lengthOfCenterToEveryItems + $lengthDriverPtToCenterPtOfCluster]
      set ruleNetLength [format "%.3f" [expr $ruleNetLength + $clusterLength]]
    }
    set ratio [format "%.3f" [expr $netLength / $ruleNetLength]]
    set ifLoop 0
    set stairsOfLoopThresholdBig [list 1.3 1.7 2.4] ; # if bigger than $netThreshold 
    set stairsOfLoopThresholdSmall [list 2.4 3.1 4.1] ; # if smaller than $netThreshold
    if {$netLength > $netThreshold} {
      if {$ratio > [lindex $stairsOfLoopThresholdBig 0] && $ratio <= [lindex $stairsOfLoopThresholdBig 1]} {
        set ifLoop 1
      } elseif {$ratio > [lindex $stairsOfLoopThresholdBig 1] && $ratio <= [lindex $stairsOfLoopThresholdBig 2]} {
        set ifLoop 2
      } elseif {$ratio > [lindex $stairsOfLoopThresholdBig 2]} {
        set ifLoop 3
      }
    } else {
      if {$ratio > [lindex $stairsOfLoopThresholdSmall 0] && $ratio <= [lindex $stairsOfLoopThresholdSmall 1]} {
        set ifLoop 1
      } elseif {$ratio > [lindex $stairsOfLoopThresholdSmall 1] && $ratio <= [lindex $stairsOfLoopThresholdSmall 2]} {
        set ifLoop 2
      } elseif {$ratio > [lindex $stairsOfLoopThresholdSmall 2]} {
        set ifLoop 3
      }
    }
    return [list $ifLoop $ratio $netLength $ruleNetLength]
  }
}
