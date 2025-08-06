#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/06 21:27:29 Wednesday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : Use the K-means algorithm to divide the input point coordinates into two clusters. 
# return    : The return value includes the centroid coordinates of each cluster and the point coordinates contained in each cluster. 
# ref       : link url
# --------------------------
source ../eco_fix/timing_fix/trans_fix/proc_calculateResistantCenter.invs.tcl; # calculateResistantCenter_fromPoints
proc group_points_by_kmeans_2clusters {points} {
  # Helper procedure to calculate Euclidean distance between two points
  proc distance {point1 point2} {
    set x1 [lindex $point1 0]
    set y1 [lindex $point1 1]
    set x2 [lindex $point2 0]
    set y2 [lindex $point2 1]
    
    set dx [expr {$x2 - $x1}]
    set dy [expr {$y2 - $y1}]
    
    return [expr {sqrt($dx*$dx + $dy*$dy)}]
  }
  
  # Helper procedure to compute centroid of a cluster
  proc compute_centroid {cluster} {
    set num_points [llength $cluster]
    if {$num_points == 0} {
      return {0 0}
    }
    
    set sum_x 0
    set sum_y 0
    
    foreach point $cluster {
      set sum_x [expr {$sum_x + [lindex $point 0]}]
      set sum_y [expr {$sum_y + [lindex $point 1]}]
    }
    
    set centroid_x [expr {$sum_x / $num_points}]
    set centroid_y [expr {$sum_y / $num_points}]
    
    return [list $centroid_x $centroid_y]
  }
  
  # Check if input is valid
  if {[llength $points] == 0} {
    return [list]
  }
  
  # If only one point, return a single cluster
  if {[llength $points] == 1} {
    return [list [list 1 $points]]
  }
  
  # Maximum number of iterations
  set max_iterations 100
  # Convergence threshold
  set epsilon 0.001
  
  # Randomly select two initial centroids
  set num_points [llength $points]
  set idx1 [expr {int(rand() * $num_points)}]
  set idx2 $idx1
  while {$idx2 == $idx1} {
    set idx2 [expr {int(rand() * $num_points)}]
  }
  set centroid1 [lindex $points $idx1]
  set centroid2 [lindex $points $idx2]
  
  set iteration 0
  set converged 0
  
  while {$iteration < $max_iterations && !$converged} {
    # Initialize two clusters
    set cluster1 [list]
    set cluster2 [list]
    
    # Assign each point to the nearest centroid
    foreach point $points {
      set dist1 [distance $point $centroid1]
      set dist2 [distance $point $centroid2]
      
      if {$dist1 <= $dist2} {
        lappend cluster1 $point
      } else {
        lappend cluster2 $point
      }
    }
    
    # Check if any cluster is empty
    if {[llength $cluster1] == 0} {
      # All points in cluster2
      return [list [list [calculateResistantCenter_fromPoints $cluster2] $cluster2]]
    }
    if {[llength $cluster2] == 0} {
      # All points in cluster1
      return [list [list [calculateResistantCenter_fromPoints $cluster1] $cluster1]]
    }
    
    # Compute new centroids
    set new_centroid1 [compute_centroid $cluster1]
    set new_centroid2 [compute_centroid $cluster2]
    
    # Check for convergence
    set centroid1_diff [distance $centroid1 $new_centroid1]
    set centroid2_diff [distance $centroid2 $new_centroid2]
    
    if {$centroid1_diff < $epsilon && $centroid2_diff < $epsilon} {
      set converged 1
    }
    
    # Update centroids
    set centroid1 $new_centroid1
    set centroid2 $new_centroid2
    
    incr iteration
  }
  
  # Check if clusters should be merged (centroids are too close)
  set final_distance [distance $centroid1 $centroid2]
  if {$final_distance < $epsilon} {
    # Merge into one cluster
    set merged [concat $cluster1 $cluster2]
    return [list [list [calculateResistantCenter_fromPoints $merged] $merged]]
  }
  
  # Return two clusters
  return [list [list [calculateResistantCenter_fromPoints $cluster1] $cluster1] [list [calculateResistantCenter_fromPoints $cluster2] $cluster2]]
}

