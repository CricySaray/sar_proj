# Tree Structure Power Distribution Analysis Tool
# Input root (generator), leaves (loads), branches to calculate optimal repeater positions and load distribution
package require Tcl 8.5
package require math::statistics

# Analyze power distribution with generator, repeaters and loads
proc analyzePowerDistribution {rootPoint leafPoints branchSegments generatorCapacity {optionsDict {}}} {
  array set options {
    -clusterThreshold 20.0
    -minClusterSize 3
    -maxClusterRatio 0.6  ;# Max ratio of total load allowed in one cluster before splitting
    -connectionTolerance 0.2
    -nodeTolerance 1.0
    -debug 0
    -loadCapacity 4
    -repeaterCapacities {4 6 8 12 16}
    -mainBranchThreshold 0.7  ;# Ratio to identify main branches (longer, more critical paths)
  }
  array set options $optionsDict

  if {[catch {validateInput $rootPoint $leafPoints $branchSegments} errMsg]} {
    return -code error $errMsg
  }
  if {$generatorCapacity <= 0} {
    return -code error "Generator capacity must be positive"
  }

  set convertedSegments [convertBranchSegments $branchSegments]
  set treeData [buildTreeStructure $rootPoint $leafPoints $convertedSegments \
                $options(-connectionTolerance) $options(-nodeTolerance) $options(-mainBranchThreshold)]
  set clusters [clusterLeaves $leafPoints $options(-clusterThreshold) $options(-minClusterSize)]
  set totalLoadCount [llength $leafPoints]
  set processedClusters [processClusters $clusters $totalLoadCount $options(-maxClusterRatio) $treeData]

  set distances [calculateDistances $treeData $rootPoint]
  set powerPlan [dict create]
  dict set powerPlan generator [list $rootPoint $generatorCapacity]
  dict set powerPlan repeaters [list]
  dict set powerPlan directLoads [list]  ;# Loads directly driven by generator

  # Prioritize clusters by average distance (farther first)
  set sortedClusters [lsort -command [list sortClustersByDistance $distances] $processedClusters]

  foreach cluster $sortedClusters {
    set clusterSize [llength $cluster]
    set clusterCenter [calculateCenter $cluster]
    set avgDistance [calculateClusterAvgDistance $cluster $distances]

    # Determine if cluster should be handled by repeater or generator
    if {shouldUseRepeater $avgDistance $clusterSize $totalLoadCount} {
      set optimalRepeaterCapacity [selectOptimalRepeaterCapacity \
                                  $generatorCapacity $options(-loadCapacity) \
                                  $clusterSize $avgDistance $options(-repeaterCapacities)]
      set breakpoint [findBestMainBranchBreakpoint $treeData $cluster $options(-debug)]
      dict lappend powerPlan repeaters [list $breakpoint $optimalRepeaterCapacity $cluster]
    } else {
      foreach point $cluster {
        dict lappend powerPlan directLoads [list $point $options(-loadCapacity)]
      }
    }
  }

  # Validate and adjust power plan if necessary
  if {[catch {validatePowerPlan $powerPlan $options(-loadCapacity)} errMsg]} {
    if {$options(-debug)} {
      puts "Warning: Power plan validation failed: $errMsg"
      puts "Attempting to adjust capacities..."
    }
    set powerPlan [adjustPowerPlan $powerPlan $options(-loadCapacity) $options(-repeaterCapacities)]
  }
  return $powerPlan
}

# Calculate distances from root to each node using tree traversal
proc calculateDistances {treeData rootPoint} {
  set adjacencyList [dict get $treeData adjacencyList]
  set pointMap [dict get $treeData pointMap]
  set distances [dict create]
  set visited [list]
  set queue [list [list $rootPoint 0.0]]
  while {[llength $queue] > 0} {
    lassign [lindex $queue 0] currentNode currentDist
    set queue [lrange $queue 1 end]
    if {[lsearch -exact $visited $currentNode] != -1} {continue}
    lappend visited $currentNode
    dict set distances $currentNode $currentDist
    if {[dict exists $adjacencyList $currentNode]} {
      foreach neighbor [dict get $adjacencyList $currentNode] {
        if {[lsearch -exact $visited $neighbor] == -1} {
          set edgeDist [distance $currentNode $neighbor]
          lappend queue [list $neighbor [expr {$currentDist + $edgeDist}]]
        }
      }
    }
  }
  return $distances
}

# Select optimal repeater capacity based on distance and load
proc selectOptimalRepeaterCapacity {generatorCapacity loadCapacity loadCount distance capacities} {
  set sortedCapacities [lsort -integer $capacities]
  set baseLoad [expr {$loadCount * $loadCapacity}]
  set distanceFactor [expr {1.0 / (1.0 + 0.1 * pow($distance, 2))}]  ;# Farther loads need higher capacity
  set adjustedLoad [expr {$baseLoad / $distanceFactor}]
  # Ensure repeater capacity doesn't exceed generator capacity
  set maxAllowed [expr {$generatorCapacity * 0.8}]  ;# Repeater can't use more than 80% of generator capacity
  foreach capacity $sortedCapacities {
    if {$capacity >= $adjustedLoad && $capacity <= $maxAllowed} {
      return $capacity
    }
  }
  return [expr {min($maxAllowed, [lindex $sortedCapacities end])}]
}

# Validate the power plan structure and capacities
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
    incr repeaterLoadTotal $repCapacity  ;# Repeater itself is a load on generator
  }

  set totalGenLoad [expr {$directLoadTotal + $repeaterLoadTotal}]
  if {$genCapacity < $totalGenLoad} {
    return -code error "Generator capacity ($genCapacity) insufficient for total load ($totalGenLoad)"
  }
  return 1
}

# Adjust power plan to meet capacity requirements
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
    # Find smallest capacity that can handle load and fits in generator
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

# Validate input data format
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

# Validate point format (x y coordinates)
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

# Validate segment format (either {x1 y1 x2 y2} or {{x1 y1} {x2 y2}})
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

# Convert branch segments to unified {x1 y1 x2 y2} format
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

# Build tree structure with main branch identification
proc buildTreeStructure {rootPoint leafPoints branchSegments connectionTolerance nodeTolerance mainBranchThreshold} {
  set treeData [dict create]
  dict set treeData root $rootPoint
  dict set treeData leaves $leafPoints
  dict set treeData branches $branchSegments

  set pointMap [dict create]
  set uniquePoints [list $rootPoint]
  dict set pointMap $rootPoint $rootPoint

  # Map all branch points with tolerance
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

  # Map leaf points with tolerance
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

  # Identify main branches (critical paths with most leaves)
  set mainBranches [identifyMainBranches $adjacencyList $rootPoint $leafPoints $mainBranchThreshold]

  dict set treeData adjacencyList $adjacencyList
  dict set treeData pointMap $pointMap
  dict set treeData mainBranches $mainBranches
  return $treeData
}

# Identify main branches (carry most load, critical paths)
proc identifyMainBranches {adjacencyList rootPoint leaves threshold} {
  set leafCount [llength $leaves]
  set branchWeights [dict create]
  set visited [list]

  # Calculate weight of each branch (number of leaves in its subtree)
  proc calculateBranchWeights {node parent adjacencyList leaves weights} {
    set count [expr {[lsearch -exact $leaves $node] != -1 ? 1 : 0}]
    foreach neighbor [dict get $adjacencyList $node] {
      if {$neighbor eq $parent} {continue}
      incr count [calculateBranchWeights $neighbor $node $adjacencyList $leaves $weights]
    }
    dict set weights [list $parent $node] $count
    dict set weights [list $node $parent] $count
    return $count
  }

  calculateBranchWeights $rootPoint "" $adjacencyList $leaves branchWeights

  # Determine main branches (above threshold proportion of total leaves)
  set mainBranches [list]
  foreach branch [dict keys $branchWeights] {
    set weight [dict get $branchWeights $branch]
    if {[expr {double($weight) / $leafCount}] >= $threshold} {
      lappend mainBranches [lindex $branch 1]  ;# Add the child node of the branch
    }
  }
  return $mainBranches
}

# Cluster leaf nodes using distance-based clustering
proc clusterLeaves {leafPoints threshold minSize} {
  set clusters {}
  set visitedPoints {}
  foreach point $leafPoints {
    if {[lsearch -exact $visitedPoints $point] != -1} {continue}
    lappend visitedPoints $point
    set currentCluster [list $point]
    set neighbors [getNeighbors $point $leafPoints $threshold]
    set i 0
    while {$i < [llength $neighbors]} {
      set neighbor [lindex $neighbors $i]
      if {[lsearch -exact $visitedPoints $neighbor] == -1} {
        lappend visitedPoints $neighbor
        lappend currentCluster $neighbor
        set newNeighbors [getNeighbors $neighbor $leafPoints $threshold]
        foreach nn $newNeighbors {
          if {[lsearch -exact $neighbors $nn] == -1} {
            lappend neighbors $nn
          }
        }
      }
      incr i
    }
    if {[llength $currentCluster] >= $minSize} {
      lappend clusters $currentCluster
    }
  }
  return $clusters
}

# Process clusters: split oversize clusters and handle singletons
proc processClusters {clusters totalLoadCount maxRatio treeData} {
  set processed [list]
  set maxSize [expr {int(floor($totalLoadCount * $maxRatio))}]

  foreach cluster $clusters {
    set clusterSize [llength $cluster]
    if {$clusterSize <= $maxSize} {
      lappend processed $cluster
    } else {
      # Split large cluster into two based on distance from root
      set distances [calculateDistances $treeData [dict get $treeData root]]
      set sorted [lsort -command [list sortByDistance $distances] $cluster]
      set mid [expr {int(floor($clusterSize / 2))}]
      lappend processed [lrange $sorted 0 [expr {$mid - 1}]]
      lappend processed [lrange $sorted $mid end]
    }
  }

  # Handle unclustered points (isolated loads)
  set allClustered [lsort -unique [concat {*}$processed]]
  set allLeaves [lsort -unique [dict get $treeData leaves]]
  foreach leaf $allLeaves {
    if {[lsearch -exact $allClustered $leaf] == -1} {
      lappend processed [list $leaf]
    }
  }

  return $processed
}

# Helper to sort clusters by average distance (farther first)
proc sortClustersByDistance {distances a b} {
  set avgA [calculateClusterAvgDistance $a $distances]
  set avgB [calculateClusterAvgDistance $b $distances]
  return [expr {$avgB - $avgA}]  ;# Descending order
}

# Helper to sort points by distance from root
proc sortByDistance {distances a b} {
  set dA [dict get $distances $a]
  set dB [dict get $distances $b]
  return [expr {$dA - $dB}]  ;# Ascending order
}

# Calculate average distance of cluster from root
proc calculateClusterAvgDistance {cluster distances} {
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

# Determine if a cluster should use a repeater
proc shouldUseRepeater {avgDistance clusterSize totalLoads} {
  # Use repeater if:
  # - Distance > 20 units OR
  # - Cluster size > 10% of total loads
  return [expr {$avgDistance > 20.0 || $clusterSize > 0.1 * $totalLoads}]
}

# Get neighbors of a point within distance threshold
proc getNeighbors {point points threshold} {
  set neighbors {}
  foreach p $points {
    if {$p eq $point} {continue}
    if {[distance $point $p] <= $threshold} {
      lappend neighbors $p
    }
  }
  return $neighbors
}

# Calculate Euclidean distance between two points
proc distance {p1 p2} {
  lassign $p1 x1 y1
  lassign $p2 x2 y2
  return [expr {sqrt(pow($x2 - $x1, 2) + pow($y2 - $y1, 2))}]
}

# Find best breakpoint on main branches for repeater
proc findBestMainBranchBreakpoint {treeData cluster {debug 0}} {
  set mainBranches [dict get $treeData mainBranches]
  set branches [dict get $treeData branches]
  set pointMap [dict get $treeData pointMap]
  set center [calculateCenter $cluster]

  if {$debug} {
    puts "Cluster center: [format "%.2f %.2f" {*}$center]"
  }

  # Only consider points on main branches
  set candidatePoints $mainBranches
  if {[llength $candidatePoints] == 0} {
    # Fallback to all branch endpoints if no main branches identified
    foreach segment $branches {
      lassign $segment x1 y1 x2 y2
      lappend candidatePoints [dict get $pointMap [list $x1 $y1]]
      lappend candidatePoints [dict get $pointMap [list $x2 $y2]]
    }
    set candidatePoints [lsort -unique $candidatePoints]
  }

  # Find closest candidate point to cluster center
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
  if {$debug} {
    puts "Best main branch breakpoint: [format "%.2f %.2f" {*}$bestPoint]"
  }
  return $bestPoint
}

# Calculate center point of a set of points
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
  if {$count > 0} {
    return [list [expr {$sumX / $count}] [expr {$sumY / $count}]]
  } else {
    return [list 0.0 0.0]
  }
}

# Example usage
if {[info exists argv0] && [string equal [file tail $argv0] [file tail [info script]]]} {
  set rootPoint {0 0}
  set leafPoints {
    {30.1 20.2} {35.3 25.1} {40.2 20.3} {45.1 25.2}
    {20.3 40.1} {25.2 45.3} {30.1 40.2} {35.3 45.1}
    {60.2 40.1} {65.1 45.3} {70.3 40.2} {75.2 45.1}
  }
  set branchSegments {
    {{0 0} {10.1 0.2}} {{9.9 0.1} {20.2 0.1}} {{19.8 0.3} {30.2 10.1}}
    {{30.1 9.9} {40.3 20.2}} {{19.9 0.2} {20.1 20.3}} {{20.2 19.8} {20.3 30.1}}
    {{20.1 30.2} {30.3 40.1}} {{20.3 0.1} {50.2 0.3}} {{49.8 0.2} {60.1 10.3}}
    {{60.2 9.9} {70.1 20.3}} {{70.3 20.1} {80.2 30.3}} {{80.1 29.9} {70.2 40.1}}
  }

  puts "Running power distribution analysis..."
  set powerPlan [analyzePowerDistribution $rootPoint $leafPoints $branchSegments 30 \
                {-connectionTolerance 0.3 -nodeTolerance 1.0 -debug 1 -maxClusterRatio 0.4}]

  puts "\nPower Distribution Plan:"
  lassign [dict get $powerPlan generator] genPoint genCapacity
  puts "Generator: [format "%.2f %.2f" {*}$genPoint] (Capacity: $genCapacity)"
  
  puts "Repeaters:"
  foreach repeater [dict get $powerPlan repeaters] {
    lassign $repeater repPoint repCapacity repLoads
    puts "  Repeater: [format "%.2f %.2f" {*}$repPoint] (Capacity: $repCapacity, Loads: [llength $repLoads])"
  }
  
  puts "Direct Loads (generator-driven): [llength [dict get $powerPlan directLoads]]"
}
