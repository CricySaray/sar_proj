# Tree Structure Power Distribution Analysis Tool
package require Tcl 8.5
package require math::statistics

# Create enum simulation
proc createEnum {name values} {
  upvar 1 $name enumDict
  array set enumDict {}
  set index 0
  foreach value $values {
    set enumDict($value) $index
    incr index
  }
}

# Create repeater strategy enum
createEnum RepeaterStrategy {
  STRATEGY_MINIMIZE_REPEATERS
  STRATEGY_MAXIMIZE_REPEATERS
  STRATEGY_AUTOMATIC
}

# Analyze power distribution
proc analyzePowerDistribution {rootPoint leafPoints branchSegments generatorCapacity {optionsDict {}}} {
  array set options {
    -clusterThreshold 20.0
    -minClusterSize 3
    -maxClusterRatio 0.6
    -connectionTolerance 0.2
    -nodeTolerance 1.0
    -debug 0
    -loadCapacity 4
    -repeaterCapacities {4 6 8 12 16}
    -mainBranchThreshold 0.7
    -maxRepeaters 1
    -repeaterStrategy $RepeaterStrategy(STRATEGY_MINIMIZE_REPEATERS)
  }
  
  upvar 1 RepeaterStrategy RepeaterStrategy
  array set options $optionsDict

  if {[catch {validateInput $rootPoint $leafPoints $branchSegments} errMsg]} {
    return -code error $errMsg
  }
  if {$generatorCapacity <= 0} {
    return -code error "Generator capacity must be positive"
  }
  if {$options(-maxRepeaters) < 0} {
    return -code error "Maximum repeaters must be non-negative"
  }

  set convertedSegments [convertBranchSegments $branchSegments]
  set treeData [buildTreeStructure $rootPoint $leafPoints $convertedSegments \
                $options(-connectionTolerance) $options(-nodeTolerance) $options(-mainBranchThreshold)]
  set pointMap [dict get $treeData pointMap]
  set clusters [clusterLeavesOptimized $leafPoints $options(-clusterThreshold) $options(-minClusterSize)]
  set mappedClusters [mapClustersToTreePoints $clusters $pointMap]
  set totalLoadCount [llength $leafPoints]
  set processedClusters [processClusters $mappedClusters $totalLoadCount $options(-maxClusterRatio) $treeData $pointMap]

  set distances [calculateDistances $treeData $rootPoint]
  set powerPlan [dict create]
  dict set powerPlan generator [list $rootPoint $generatorCapacity]
  dict set powerPlan repeaters [list]
  dict set powerPlan directLoads [list]
  dict set powerPlan repeaterDrivenLoads [dict create]

  set sortedClusters [lsort -command [list sortClustersByDistance $distances $pointMap] $processedClusters]

  set usedRepeaters 0
  set hasRepeaterLoads 0

  # Phase 1: Allocate loads based on strategy
  foreach cluster $sortedClusters {
    set clusterSize [llength $cluster]
    set clusterCenter [calculateCenter $cluster]
    set avgDistance [calculateClusterAvgDistance $cluster $distances $pointMap]

    set useRepeater 0
    if {$options(-repeaterStrategy) == $RepeaterStrategy(STRATEGY_MAXIMIZE_REPEATERS)} {
      if {$usedRepeaters < $options(-maxRepeaters)} {
        set useRepeater 1
      }
    } elseif {$options(-repeaterStrategy) == $RepeaterStrategy(STRATEGY_MINIMIZE_REPEATERS)} {
      if {[shouldUseRepeater $avgDistance $clusterSize $totalLoadCount] && $usedRepeaters < $options(-maxRepeaters)} {
        set useRepeater 1
      }
    } elseif {$options(-repeaterStrategy) == $RepeaterStrategy(STRATEGY_AUTOMATIC)} {
      set useRepeater [decideAutomaticRepeaterUsage $avgDistance $clusterSize $totalLoadCount \
                      $generatorCapacity $options(-loadCapacity) $usedRepeaters $options(-maxRepeaters)]
    }

    if {$useRepeater} {
      set optimalRepeaterCapacity [selectOptimalRepeaterCapacity \
                                  $generatorCapacity $options(-loadCapacity) \
                                  $clusterSize $avgDistance $options(-repeaterCapacities)]
      set breakpoint [findBestMainBranchBreakpoint $treeData $cluster $options(-debug)]
      dict lappend powerPlan repeaters [list $breakpoint $optimalRepeaterCapacity $cluster]
      dict set powerPlan repeaterDrivenLoads $breakpoint $cluster
      incr usedRepeaters
      set hasRepeaterLoads 1
    } else {
      foreach point $cluster {
        dict lappend powerPlan directLoads [list $point $options(-loadCapacity)]
      }
    }
  }

  # Phase 2: Ensure at least one repeater is used
  if {$usedRepeaters == 0 && $options(-maxRepeaters) >= 1 && $totalLoadCount > 0} {
    if {[llength $sortedClusters] > 0} {
      set cluster [lindex $sortedClusters 0]
      set clusterSize [llength $cluster]
      set clusterCenter [calculateCenter $cluster]
      set optimalRepeaterCapacity [selectOptimalRepeaterCapacity \
                                  $generatorCapacity $options(-loadCapacity) \
                                  $clusterSize [calculateClusterAvgDistance $cluster $distances $pointMap] \
                                  $options(-repeaterCapacities)]
      set breakpoint [findBestMainBranchBreakpoint $treeData $cluster $options(-debug)]
      dict lappend powerPlan repeaters [list $breakpoint $optimalRepeaterCapacity $cluster]
      dict set powerPlan repeaterDrivenLoads $breakpoint $cluster
      
      # Remove this cluster from direct loads
      set newDirectLoads [list]
      foreach load [dict get $powerPlan directLoads] {
        lassign $load point capacity
        if {[lsearch -exact $cluster $point] == -1} {
          lappend newDirectLoads $load
        }
      }
      dict set powerPlan directLoads $newDirectLoads
      incr usedRepeaters
      set hasRepeaterLoads 1
    }
  }

  # Validate and adjust power plan
  if {[catch {validatePowerPlan $powerPlan $options(-loadCapacity)} errMsg]} {
    if {$options(-debug)} {
      puts "Warning: Power plan validation failed: $errMsg"
      puts "Attempting to adjust capacities..."
    }
    set powerPlan [adjustPowerPlan $powerPlan $options(-loadCapacity) $options(-repeaterCapacities)]
  }

  # Ensure at least one repeater drives loads
  if {$hasRepeaterLoads == 0 && $usedRepeaters > 0} {
    if {[llength [dict get $powerPlan directLoads]] > 0} {
      set firstRepeater [lindex [dict get $powerPlan repeaters] 0]
      lassign $firstRepeater repPoint repCapacity repLoads
      
      set firstDirectLoad [lindex [dict get $powerPlan directLoads] 0]
      lassign $firstDirectLoad loadPoint loadCapacity
      
      # Add to repeater loads
      lappend repLoads $loadPoint
      set newRepeaters [list]
      foreach r [dict get $powerPlan repeaters] {
        if {$r eq $firstRepeater} {
          lappend newRepeaters [list $repPoint $repCapacity $repLoads]
        } else {
          lappend newRepeaters $r
        }
      }
      dict set powerPlan repeaters $newRepeaters
      dict set powerPlan repeaterDrivenLoads $repPoint $repLoads
      
      # Remove from direct loads
      set newDirectLoads [lrange [dict get $powerPlan directLoads] 1 end]
      dict set powerPlan directLoads $newDirectLoads
      
      set hasRepeaterLoads 1
    }
  }

  return $powerPlan
}

# Build tree structure
proc buildTreeStructure {rootPoint leafPoints branchSegments connectionTolerance nodeTolerance mainBranchThreshold} {
  set treeData [dict create]
  dict set treeData root $rootPoint
  dict set treeData leaves $leafPoints
  dict set treeData branches $branchSegments

  set pointMap [dict create]
  set uniquePoints [list]
  # Add root point to map first
  dict set pointMap $rootPoint $rootPoint
  lappend uniquePoints $rootPoint

  # Map all branch points
  foreach segment $branchSegments {
    lassign $segment x1 y1 x2 y2
    set p1 [list $x1 $y1]
    set p2 [list $x2 $y2]
    foreach point [list $p1 $p2] {
      if {![dict exists $pointMap $point]} {
        set found 0
        foreach existingPoint $uniquePoints {
          if {[distance $point $existingPoint] <= $connectionTolerance} {
            dict set pointMap $point $existingPoint
            set found 1
            break
          }
        }
        if {!$found} {
          lappend uniquePoints $point
          dict set pointMap $point $point
        }
      }
    }
  }

  # Map leaf points
  foreach leaf $leafPoints {
    if {![dict exists $pointMap $leaf]} {
      set found 0
      foreach existingPoint $uniquePoints {
        if {[distance $leaf $existingPoint] <= $nodeTolerance} {
          dict set pointMap $leaf $existingPoint
          set found 1
          break
        }
      }
      if {!$found} {
        lappend uniquePoints $leaf
        dict set pointMap $leaf $leaf
      }
    }
  }

  # Build adjacency list
  set adjacencyList [dict create]
  foreach segment $branchSegments {
    lassign $segment x1 y1 x2 y2
    set p1 [dict get $pointMap [list $x1 $y1]]
    set p2 [dict get $pointMap [list $x2 $y2]]
    dict lappend adjacencyList $p1 $p2
    dict lappend adjacencyList $p2 $p1
  }

  # Ensure root point is in adjacency list
  set mappedRoot [dict get $pointMap $rootPoint]
  if {![dict exists $adjacencyList $mappedRoot]} {
    dict set adjacencyList $mappedRoot [list]
    
    # Find closest node to root
    set minDist inf
    set closestNode ""
    foreach node [dict keys $adjacencyList] {
      if {$node eq $mappedRoot} {continue}
      set dist [distance $mappedRoot $node]
      if {$dist < $minDist} {
        set minDist $dist
        set closestNode $node
      }
    }
    
    # Add bidirectional connection
    if {$closestNode ne ""} {
      dict lappend adjacencyList $mappedRoot $closestNode
      dict lappend adjacencyList $closestNode $mappedRoot
    }
  }

  # Identify main branches
  set mainBranches [identifyMainBranchesIterative $adjacencyList $rootPoint $leafPoints $mainBranchThreshold $pointMap]

  dict set treeData adjacencyList $adjacencyList
  dict set treeData pointMap $pointMap
  dict set treeData mainBranches $mainBranches
  return $treeData
}

# Iterative main branch identification (avoids recursion limits)
proc identifyMainBranchesIterative {adjacencyList rootPoint leaves threshold pointMap} {
  set leafCount [llength $leaves]
  set branchWeights [dict create]
  set visited [dict create]
  set mappedRoot [dict get $pointMap $rootPoint]
  set stack [list [list $mappedRoot "" 0]]

  while {[llength $stack] > 0} {
    lassign [lindex $stack end] current parent processing
    set stack [lrange $stack 0 end-1]

    if {$processing} {
      set count 0
      if {[lsearch -exact $leaves [dict get $pointMap $current]] != -1} {
        incr count
      }
      foreach neighbor [dict get $adjacencyList $current] {
        if {$parent ne "" && $neighbor eq [dict get $pointMap $parent]} {
          continue
        }
        set branch [list $current $neighbor]
        if {[dict exists $branchWeights $branch]} {
          incr count [dict get $branchWeights $branch]
        }
      }
      if {$parent ne ""} {
        set mappedParent [dict get $pointMap $parent]
        dict set branchWeights [list $mappedParent $current] $count
        dict set branchWeights [list $current $mappedParent] $count
      }
      continue
    }

    if {[dict exists $visited $current]} {
      continue
    }
    dict set visited $current 1
    lappend stack [list $current $parent 1]

    foreach neighbor [dict get $adjacencyList $current] {
      if {$parent ne "" && $neighbor eq [dict get $pointMap $parent]} {
        continue
      }
      lappend stack [list $neighbor $current 0]
    }
  }

  set mainBranches [list]
  foreach branch [dict keys $branchWeights] {
    set weight [dict get $branchWeights $branch]
    if {$leafCount > 0 && [expr {double($weight) / $leafCount}] >= $threshold} {
      lappend mainBranches [lindex $branch 1]
    }
  }
  return $mainBranches
}

# Optimized clustering algorithm using spatial indexing
proc clusterLeavesOptimized {leafPoints threshold minSize} {
  set clusters [list]
  set visited [dict create]
  set leafCount [llength $leafPoints]
  if {$leafCount == 0} {
    return $clusters
  }

  # Build spatial index
  set spatialIndex [dict create]
  foreach point $leafPoints {
    lassign $point x y
    set gridX [expr {int(floor($x / $threshold))}]
    set gridY [expr {int(floor($y / $threshold))}]
    dict lappend spatialIndex [list $gridX $gridY] $point
  }

  # Cluster based on spatial index
  foreach point $leafPoints {
    if {[dict exists $visited $point]} {
      continue
    }
    dict set visited $point 1
    set currentCluster [list $point]
    set queue [list $point]

    while {[llength $queue] > 0} {
      set current [lindex $queue 0]
      set queue [lrange $queue 1 end]
      lassign $current x y
      set gridX [expr {int(floor($x / $threshold))}]
      set gridY [expr {int(floor($y / $threshold))}]

      # Check neighboring grids
      for {set dx -1} {$dx <= 1} {incr dx} {
        for {set dy -1} {$dy <= 1} {incr dy} {
          set neighborGrid [list [expr {$gridX + $dx}] [expr {$gridY + $dy}]]
          if {![dict exists $spatialIndex $neighborGrid]} {
            continue
          }
          foreach neighbor [dict get $spatialIndex $neighborGrid] {
            if {[dict exists $visited $neighbor]} {
              continue
            }
            if {[distance $current $neighbor] <= $threshold} {
              dict set visited $neighbor 1
              lappend currentCluster $neighbor
              lappend queue $neighbor
            }
          }
        }
      }
    }

    if {[llength $currentCluster] >= $minSize} {
      lappend clusters $currentCluster
    }
  }

  return $clusters
}

# Calculate distances from root to all points
proc calculateDistances {treeData rootPoint} {
  set adjacencyList [dict get $treeData adjacencyList]
  set pointMap [dict get $treeData pointMap]
  set distances [dict create]
  set visited [dict create]
  set mappedRoot [dict get $pointMap $rootPoint]
  set queue [list [list $mappedRoot 0.0]]

  # BFS traversal to calculate distances
  while {[llength $queue] > 0} {
    lassign [lindex $queue 0] currentNode currentDist
    set queue [lrange $queue 1 end]
    if {[dict exists $visited $currentNode]} {
      continue
    }
    dict set visited $currentNode 1
    dict set distances $currentNode $currentDist

    if {[dict exists $adjacencyList $currentNode]} {
      foreach neighbor [dict get $adjacencyList $currentNode] {
        if {![dict exists $visited $neighbor]} {
          set edgeDist [distance $currentNode $neighbor]
          lappend queue [list $neighbor [expr {$currentDist + $edgeDist}]]
        }
      }
    }
  }

  # Ensure all leaves have distance values
  foreach leaf [dict get $treeData leaves] {
    set mappedLeaf [dict get $pointMap $leaf]
    if {![dict exists $distances $mappedLeaf]} {
      set dist [distance $mappedRoot $mappedLeaf]
      dict set distances $mappedLeaf $dist
    }
  }

  return $distances
}

# Validate input data
proc validateInput {rootPoint leafPoints branchSegments} {
  if {[catch {validatePoint $rootPoint} errMsg]} {
    return -code error "Root point validation failed: $errMsg"
  }
  if {[llength $leafPoints] < 1} {
    return -code error "At least one leaf point is required"
  }
  foreach leaf $leafPoints {
    if {[catch {validatePoint $leaf} errMsg]} {
      return -code error "Leaf point validation failed: $errMsg"
    }
  }
  if {[llength $branchSegments] < 1} {
    return -code error "At least one branch segment is required"
  }
  foreach segment $branchSegments {
    if {[catch {validateSegment $segment} errMsg]} {
      return -code error "Branch segment validation failed: $errMsg"
    }
  }
  return 1
}

# Validate point format
proc validatePoint {point} {
  if {[llength $point] != 2} {
    return -code error "Point must be two coordinates (x y): $point"
  }
  foreach coord $point {
    if {![string is double -strict $coord]} {
      return -code error "Coordinate must be a number: $coord"
    }
  }
  return 1
}

# Validate segment format
proc validateSegment {segment} {
  if {[llength $segment] == 4 && [string is double -strict [lindex $segment 0]]} {
    return 1
  }
  if {[llength $segment] == 2} {
    foreach point $segment {
      if {[catch {validatePoint $point} errMsg]} {
        return -code error "Point format error: $errMsg"
      }
    }
    return 1
  }
  return -code error "Segment format error (use {x1 y1 x2 y2} or {{x1 y1} {x2 y2}}): $segment"
}

# Convert segment format
proc convertBranchSegments {segments} {
  set converted {}
  foreach segment $segments {
    if {[llength $segment] == 2 && [llength [lindex $segment 0]] == 2} {
      lassign $segment p1 p2
      lassign $p1 x1 y1
      lassign $p2 x2 y2
      lappend converted [list $x1 $y1 $x2 $y2]
    } else {
      lappend converted $segment
    }
  }
  return $converted
}

# Map clusters to tree points
proc mapClustersToTreePoints {clusters pointMap} {
  set mappedClusters {}
  foreach cluster $clusters {
    set mappedCluster {}
    foreach point $cluster {
      set mappedPoint [dict get $pointMap $point]
      lappend mappedCluster $mappedPoint
    }
    lappend mappedClusters $mappedCluster
  }
  return $mappedClusters
}

# Process clusters
proc processClusters {clusters totalLoadCount maxRatio treeData pointMap} {
  set processed [list]
  set maxSize [expr {int(floor($totalLoadCount * $maxRatio))}]
  set distances [calculateDistances $treeData [dict get $treeData root]]
  
  foreach cluster $clusters {
    set clusterSize [llength $cluster]
    if {$clusterSize <= $maxSize} {
      lappend processed $cluster
    } else {
      # Split large clusters
      set sorted [lsort -command [list sortByDistance $distances $pointMap] $cluster]
      set mid [expr {int(floor($clusterSize / 2))}]
      lappend processed [lrange $sorted 0 [expr {$mid - 1}]]
      lappend processed [lrange $sorted $mid end]
    }
  }
  
  # Ensure all leaves are clustered
  set allClustered [lsort -unique [concat {*}$processed]]
  set allLeavesMapped [list]
  foreach leaf [dict get $treeData leaves] {
    lappend allLeavesMapped [dict get $pointMap $leaf]
  }
  
  foreach leafMapped $allLeavesMapped {
    if {[lsearch -exact $allClustered $leafMapped] == -1} {
      lappend processed [list $leafMapped]
    }
  }
  
  return $processed
}

# Sort clusters by distance
proc sortClustersByDistance {distances pointMap a b} {
  set avgA [calculateClusterAvgDistance $a $distances $pointMap]
  set avgB [calculateClusterAvgDistance $b $distances $pointMap]
  if {$avgA < $avgB} {
    return 1
  } elseif {$avgA > $avgB} {
    return -1
  } else {
    return 0
  }
}

# Sort points by distance
proc sortByDistance {distances pointMap a b} {
  set dA [expr {[dict exists $distances $a] ? [dict get $distances $a] : 0.0}]
  set dB [expr {[dict exists $distances $b] ? [dict get $distances $b] : 0.0}]
  if {$dA < $dB} {
    return -1
  } elseif {$dA > $dB} {
    return 1
  } else {
    return 0
  }
}

# Calculate average distance of a cluster
proc calculateClusterAvgDistance {cluster distances pointMap} {
  set sum 0.0
  set count 0
  foreach point $cluster {
    if {[dict exists $distances $point]} {
      set sum [expr {$sum + [dict get $distances $point]}]
      incr count
    }
  }
  return [expr {$count > 0 ? $sum / $count : 0.0}]
}

# Determine if a repeater should be used
proc shouldUseRepeater {avgDistance clusterSize totalLoads} {
  return [expr {$avgDistance > 20.0 || $clusterSize > 0.1 * $totalLoads}]
}

# Get neighboring points
proc getNeighbors {point points threshold} {
  set neighbors {}
  foreach p $points {
    if {$p eq $point} {
      continue
    }
    if {[distance $point $p] <= $threshold} {
      lappend neighbors $p
    }
  }
  return $neighbors
}

# Calculate distance between two points
proc distance {p1 p2} {
  lassign $p1 x1 y1
  lassign $p2 x2 y2
  return [expr {sqrt(pow($x2 - $x1, 2) + pow($y2 - $y1, 2))}]
}

# Find best breakpoint for main branch
proc findBestMainBranchBreakpoint {treeData cluster {debug 0}} {
  set mainBranches [dict get $treeData mainBranches]
  set branches [dict get $treeData branches]
  set pointMap [dict get $treeData pointMap]
  set center [calculateCenter $cluster]
  
  set candidatePoints $mainBranches
  if {[llength $candidatePoints] == 0} {
    # Use all branch points if no main branches
    foreach segment $branches {
      lassign $segment x1 y1 x2 y2
      lappend candidatePoints [dict get $pointMap [list $x1 $y1]]
      lappend candidatePoints [dict get $pointMap [list $x2 $y2]]
    }
    set candidatePoints [lsort -unique $candidatePoints]
  }
  
  # Find closest point to cluster center
  set minDist inf
  set bestPoint {}
  foreach point $candidatePoints {
    set dist [distance $center $point]
    if {$dist < $minDist} {
      set minDist $dist
      set bestPoint $point
    }
  }
  
  if {$bestPoint eq ""} {
    set bestPoint $center
  }
  
  return $bestPoint
}

# Calculate center of points
proc calculateCenter {points} {
  set sumX 0.0
  set sumY 0.0
  set count 0
  foreach point $points {
    lassign $point x y
    set sumX [expr {$sumX + $x}]
    set sumY [expr {$sumY + $y}]
    incr count
  }
  return [list [expr {$count > 0 ? $sumX / $count : 0.0}] [expr {$count > 0 ? $sumY / $count : 0.0}]]
}

# Select optimal repeater capacity
proc selectOptimalRepeaterCapacity {generatorCapacity loadCapacity loadCount distance capacities} {
  set sortedCapacities [lsort -integer $capacities]
  set baseLoad [expr {$loadCount * $loadCapacity}]
  set distanceFactor [expr {1.0 / (1.0 + 0.1 * pow($distance, 2))}]
  set adjustedLoad [expr {$baseLoad / $distanceFactor}]
  set maxAllowed [expr {$generatorCapacity * 0.8}]
  
  # Select smallest capacity that meets requirements
  foreach capacity $sortedCapacities {
    if {$capacity >= $adjustedLoad && $capacity <= $maxAllowed} {
      return $capacity
    }
  }
  
  # Return maximum allowed if no exact match
  return [expr {min($maxAllowed, [lindex $sortedCapacities end])}]
}

# Validate power plan
proc validatePowerPlan {powerPlan loadCapacity} {
  if {![dict exists $powerPlan generator]} {
    return -code error "Power plan missing 'generator' key"
  }
  if {![dict exists $powerPlan repeaters]} {
    return -code error "Power plan missing 'repeaters' key"
  }
  if {![dict exists $powerPlan directLoads]} {
    return -code error "Power plan missing 'directLoads' key"
  }
  
  lassign [dict get $powerPlan generator] genPoint genCapacity
  set repeaters [dict get $powerPlan repeaters]
  set directLoads [dict get $powerPlan directLoads]
  
  set directLoadTotal [expr {[llength $directLoads] * $loadCapacity}]
  set repeaterLoadTotal 0
  
  foreach repeater $repeaters {
    lassign $repeater repPoint repCapacity repLoads
    set repLoad [expr {[llength $repLoads] * $loadCapacity}]
    if {$repCapacity < $repLoad} {
      return -code error "Repeater capacity ($repCapacity) insufficient for load ($repLoad)"
    }
    incr repeaterLoadTotal $repCapacity
  }
  
  set totalGenLoad [expr {$directLoadTotal + $repeaterLoadTotal}]
  if {$genCapacity < $totalGenLoad} {
    return -code error "Generator capacity ($genCapacity) insufficient for total load ($totalGenLoad)"
  }
  
  return 1
}

# Adjust power plan
proc adjustPowerPlan {powerPlan loadCapacity availableCapacities} {
  if {![dict exists $powerPlan generator]} {
    return -code error "Power plan missing 'generator' key"
  }
  if {![dict exists $powerPlan repeaters]} {
    dict set powerPlan repeaters [list]
    return $powerPlan
  }
  if {![dict exists $powerPlan directLoads]} {
    dict set powerPlan directLoads [list]
  }
  
  lassign [dict get $powerPlan generator] genPoint genCapacity
  set repeaters [dict get $powerPlan repeaters]
  set sortedCapacities [lsort -decreasing -integer $availableCapacities]
  set newRepeaters {}
  
  foreach repeater $repeaters {
    lassign $repeater repPoint oldCapacity repLoads
    set repLoad [expr {[llength $repLoads] * $loadCapacity}]
    set newCapacity $oldCapacity
    
    # Select appropriate capacity
    foreach capacity $sortedCapacities {
      if {$capacity >= $repLoad && $capacity <= $genCapacity * 0.8} {
        set newCapacity $capacity
        break
      }
    }
    
    lappend newRepeaters [list $repPoint $newCapacity $repLoads]
  }
  
  dict set powerPlan repeaters $newRepeaters
  return $powerPlan
}

# Decide automatically whether to use a repeater
proc decideAutomaticRepeaterUsage {avgDistance clusterSize totalLoads generatorCapacity loadCapacity usedRepeaters maxRepeaters} {
  set clusterLoad [expr {$clusterSize * $loadCapacity}]
  set generatorRemaining [expr {$generatorCapacity - ($usedRepeaters * 4)}]
  
  if {$avgDistance > 25 && $clusterSize > 3 && $clusterLoad < $generatorRemaining && $usedRepeaters < $maxRepeaters} {
    return 1
  } elseif {$clusterSize > 0.2 * $totalLoads && $usedRepeaters < $maxRepeaters} {
    return 1
  } else {
    return 0
  }
}

# Main program entry
if {[info exists argv0] && [string equal [file tail $argv0] [file tail [info script]]]} {
  set rootPoint {0 0}
  set leafPoints {{30.1 20.2} {35.3 25.1} {40.2 20.3} {45.1 25.2} {20.3 40.1} {25.2 45.3} {30.1 40.2} {35.3 45.1} {60.2 40.1} {65.1 45.3} {70.3 40.2} {75.2 45.1}}
  set branchSegments {{{0 0} {10.1 0.2}} {{9.9 0.1} {20.2 0.1}} {{19.8 0.3} {30.2 10.1}} {{30.1 9.9} {40.3 20.2}} {{19.9 0.2} {20.1 20.3}} {{20.2 19.8} {20.3 30.1}} {{20.1 30.2} {30.3 40.1}} {{20.3 0.1} {50.2 0.3}} {{49.8 0.2} {60.1 10.3}} {{60.2 9.9} {70.1 20.3}} {{70.3 20.1} {80.2 30.3}} {{80.1 29.9} {70.2 40.1}}}
  
  puts "Running power distribution analysis..."
  set powerPlan [analyzePowerDistribution $rootPoint $leafPoints $branchSegments 30 \
                {-connectionTolerance 0.3 -nodeTolerance 1.0 -debug 1 -maxClusterRatio 0.4 -maxRepeaters 2 -repeaterStrategy $RepeaterStrategy(STRATEGY_MINIMIZE_REPEATERS)}]
  
  puts "\nPower Distribution Plan:"
  lassign [dict get $powerPlan generator] genPoint genCapacity
  puts "Generator: [format "%.2f %.2f" {*}$genPoint] (Capacity: $genCapacity)"
  
  puts "\nRepeaters:"
  foreach repeater [dict get $powerPlan repeaters] {
    lassign $repeater repPoint repCapacity repLoads
    puts "  Repeater: [format "%.2f %.2f" {*}$repPoint] (Capacity: $repCapacity, Loads: [llength $repLoads])"
    puts "    Driven Loads:"
    foreach load $repLoads {
      puts "      - [format "%.2f %.2f" {*}$load]"
    }
  }
  
  puts "\nDirect Loads (generator-driven): [llength [dict get $powerPlan directLoads]]"
  foreach load [dict get $powerPlan directLoads] {
    lassign $load point capacity
    puts "  - [format "%.2f %.2f" {*}$point] (Capacity: $capacity)"
  }
}
