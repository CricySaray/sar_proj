#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/06 16:22:00 Wednesday
# label     : math_proc package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : A Tcl procedure that automatically clusters 2-35 points into up to 3 clusters, using simple distance-based 
#             clustering for small datasets (<=10 points) and optimized DBSCAN for medium ones (>10 points), with support 
#             for single-point clusters.
# return    : list: cluster1_centerPT({x y}) + itemsPTinsideCluster({{x1 y1} {x2 y2} ...}) {{{x y} {{x1 y1} {x2 y2} ...}} {{x y} {{x1 y1} {x2 y2} ...}} ...}
# ref       : link url
# --------------------------
source ../eco_fix/timing_fix/trans_fix/proc_calculateResistantCenter.invs.tcl; # calculateResistantCenter_fromPoints
proc cluster_points {points {threshold 25} {min_pts 3} {max_clusters 3} {verbose 0}} {
  # Error checking for input validity
  if {![llength $points]} {
    error "Invalid input: Empty point list"
  }
  foreach point $points {
    if {[llength $point] != 2} {
      error "Invalid point format: $point. Use {x y} format"
    }
    lassign $point x y
    if {![string is double -strict $x] || ![string is double -strict $y]} {
      error "Invalid coordinates in point $point: must be numeric"
    }
  }

  set num_points [llength $points]
  if {$num_points < 2} {
    # Handle single point case
    error "proc cluster_points: num of points($num_points) need be larger than 1"
  }

  # Helper function: Euclidean distance between two points
  proc distance {p1 p2} {
    lassign $p1 x1 y1
    lassign $p2 x2 y2
    set dx [expr {$x2 - $x1}]
    set dy [expr {$y2 - $y1}]
    return [expr {sqrt($dx*$dx + $dy*$dy)}]
  }

  # Auto-select algorithm based on number of points
  if {$num_points <= 10} {
    # Simple distance-based clustering for small datasets
    if {$verbose} {puts "Using simple distance clustering (n=$num_points)"}
    set clusters [list [list 0]]  ;# Initialize with first point in cluster 0

    for {set i 1} {$i < $num_points} {incr i} {
      set matched 0
      # Try to add to existing clusters
      for {set c 0} {$c < [llength $clusters]} {incr c} {
        set cluster [lindex $clusters $c]
        # Check distance to any point in current cluster
        foreach idx $cluster {
          set d [distance [lindex $points $i] [lindex $points $idx]]
          if {$d <= $threshold} {
            lset clusters $c [lappend cluster $i]
            set matched 1
            break
          }
        }
        if {$matched} break
      }
      # Create new cluster if no match
      if {!$matched && [llength $clusters] < $max_clusters} {
        lappend clusters [list $i]
      } elseif {!$matched} {
        # If max clusters reached, add to closest cluster
        set min_d [distance [lindex $points $i] [lindex $points [lindex [lindex $clusters 0] 0]]]
        set best_c 0
        for {set c 1} {$c < [llength $clusters]} {incr c} {
          set d [distance [lindex $points $i] [lindex $points [lindex [lindex $clusters $c] 0]]]
          if {$d < $min_d} {
            set min_d $d
            set best_c $c
          }
        }
        lset clusters $best_c [lappend [lindex $clusters $best_c] $i]
      }
    }

    # Convert index clusters to point clusters
    set centerPin_itemPins_List [lmap clusterGroup $clusters {
      set centerPtOfItems [format "%.3f %.3f" {*}[calculateResistantCenter_fromPoints $clusterGroup]]
      set temp_center_itemPts [list $centerPtOfItems $clusterGroup]
    }]
    return $centerPin_itemPins_List

  } else {
    # Optimized DBSCAN for medium datasets (11-35 points)
    if {$verbose} {puts "Using DBSCAN (n=$num_points)"}
    set labels [lrepeat $num_points -1]  ;# -1: unclassified, 0: noise
    set cluster_id 0

    # DBSCAN helper: find all neighbors within threshold
    proc range_query {points idx threshold} {
      set neighbors [list]
      set p [lindex $points $idx]
      for {set i 0} {$i < [llength $points]} {incr i} {
        if {$i != $idx && [distance $p [lindex $points $i]] <= $threshold} {
          lappend neighbors $i
        }
      }
      return $neighbors
    }

    # Main DBSCAN loop
    for {set i 0} {$i < $num_points} {incr i} {
      if {[lindex $labels $i] != -1} continue

      set neighbors [range_query $points $i $threshold]
      if {[llength $neighbors] < $min_pts} {
        lset labels $i 0  ;# Mark as noise
        continue
      }

      if {$cluster_id >= $max_clusters} {
        lset labels $i 0
        continue
      }

      # Create new cluster
      lset labels $i [incr cluster_id]
      set seed_set $neighbors
      set seed_idx 0

      while {$seed_idx < [llength $seed_set]} {
        set j [lindex $seed_set $seed_idx]
        incr seed_idx

        if {[lindex $labels $j] == -1} {
          lset labels $j $cluster_id
          set j_neighbors [range_query $points $j $threshold]
          if {[llength $j_neighbors] >= $min_pts} {
            set seed_set [lsort -unique [concat $seed_set $j_neighbors]]
          }
        } elseif {[lindex $labels $j] == 0} {
          lset labels $j $cluster_id
        }
      }
    }

    # Handle single-point clusters (noise to cluster if under max)
    for {set i 0} {$i < $num_points} {incr i} {
      if {[lindex $labels $i] == 0 && $cluster_id < $max_clusters} {
        lset labels $i [incr cluster_id]
      }
    }

    # Organize results
    set result [dict create]
    for {set i 0} {$i < $num_points} {incr i} {
      set c [lindex $labels $i]
      dict lappend result $c [lindex $points $i]
    }
    # Clean up helper proc
    rename range_query ""
  }

  # Clean up distance proc
  rename distance ""

  set centerPin_itemPins_List [lmap clusterGroup [dict values $result] {
    set centerPtOfItems [format "%.3f %.3f" {*}[calculateResistantCenter_fromPoints $clusterGroup]]
    set temp_center_itemPts [list $centerPtOfItems $clusterGroup]
  }]

  if {$verbose} {
    puts "Final clusters: [llength $centerPin_itemPins_List]"
  }
  return $centerPin_itemPins_List
}

