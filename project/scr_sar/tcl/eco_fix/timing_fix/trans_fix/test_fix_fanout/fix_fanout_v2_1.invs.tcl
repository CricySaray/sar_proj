# Tree Structure Breakpoint Analysis Tool
# Input root point, leaf points, and branch segments to calculate optimal breakpoint positions
package require Tcl 8.5
#package require struct::list
package require math::statistics
# Main processing procedure
proc analyzeTreeBreakpoint {rootPoint leafPoints branchSegments {optionsDict {}}} {
  array set options {
    -clusterThreshold 20.0
    -minClusterSize 3
    -connectionTolerance 0.2
    -nodeTolerance 1.0
    -debug 0
  }
  array set options $optionsDict
  if {[catch {validateInput $rootPoint $leafPoints $branchSegments} errMsg]} {
    return -code error $errMsg
  }
  set convertedSegments [convertBranchSegments $branchSegments]
  set treeData [buildTreeStructure $rootPoint $leafPoints $convertedSegments \
                $options(-connectionTolerance) $options(-nodeTolerance)]
  set clusters [clusterLeaves $leafPoints $options(-clusterThreshold) $options(-minClusterSize)]
  if {$options(-debug)} {
    puts "Clustering results: [llength $clusters] clusters"
    for {set i 0} {$i < [llength $clusters]} {incr i} {
      puts "  Cluster $i: [llength [lindex $clusters $i]] leaves"
    }
  }
  set breakpoints {}
  foreach cluster $clusters {
    lappend breakpoints [findBestBreakpoint $treeData $cluster $options(-debug)]
  }
  return $breakpoints
}
# Analyze power distribution with generator, repeaters and loads
proc analyzePowerDistribution {rootPoint leafPoints branchSegments generatorCapacity {optionsDict {}}} {
  array set options {
    -clusterThreshold 20.0
    -minClusterSize 3
    -connectionTolerance 0.2
    -nodeTolerance 1.0
    -debug 0
    -loadCapacity 4
    -repeaterCapacities {4 6 8 12 16}
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
                $options(-connectionTolerance) $options(-nodeTolerance)]
  set clusters [clusterLeaves $leafPoints $options(-clusterThreshold) $options(-minClusterSize)]
  set allLeafPoints $leafPoints
  set clusteredPoints {}
  foreach cluster $clusters {
    foreach point $cluster {
      lappend clusteredPoints $point
    }
  }
  set isolatedPoints {}
  foreach point $allLeafPoints {
    if {[lsearch -exact $clusteredPoints $point] == -1} {
      lappend isolatedPoints $point
    }
  }
  if {$options(-debug)} {
    puts "Clustering results: [llength $clusters] clusters"
    for {set i 0} {$i < [llength $clusters]} {incr i} {
      puts "  Cluster $i: [llength [lindex $clusters $i]] leaves"
    }
    puts "Isolated points: [llength $isolatedPoints]"
  }
  set distances [calculateDistances $treeData $rootPoint]
  set powerPlan [dict create]
  dict set powerPlan generator [list $rootPoint $generatorCapacity]
  dict set powerPlan repeaters [list]
  dict set powerPlan isolatedLoads [list]
  foreach point $isolatedPoints {
    dict lappend powerPlan isolatedLoads [list $point $options(-loadCapacity)]
  }
  foreach cluster $clusters {
    set clusterSize [llength $cluster]
    set clusterCenter [calculateCenter $cluster]
    set avgDistance 0.0
    foreach point $cluster {
      if {[dict exists $distances $point]} {
        incr avgDistance [dict get $distances $point]
      }
    }
    if {$clusterSize > 0} {
      set avgDistance [expr {$avgDistance / $clusterSize}]
    }
    set optimalRepeaterCapacity [selectOptimalRepeaterCapacity \
                                  $generatorCapacity $options(-loadCapacity) \
                                  $clusterSize $avgDistance $options(-repeaterCapacities)]
    set breakpoint [findBestBreakpoint $treeData $cluster $options(-debug)]
    dict lappend powerPlan repeaters [list $breakpoint $optimalRepeaterCapacity $cluster]
  }
  if {[catch {validatePowerPlan $powerPlan $options(-loadCapacity)} errMsg]} {
    if {$options(-debug)} {
      puts "Warning: Power plan validation failed: $errMsg"
      puts "Attempting to adjust capacities..."
    }
    set powerPlan [adjustPowerPlan $powerPlan $options(-loadCapacity) $options(-repeaterCapacities)]
  }
  return $powerPlan
}
# Calculate distances from root to each node
proc calculateDistances {treeData rootPoint} {
  set adjacencyList [dict get $treeData adjacencyList]
  set pointMap [dict get $treeData pointMap]
  set distances [dict create]
  set visited [list]
  set queue [list [list $rootPoint 0.0]]
  while {[llength $queue] > 0} {
    lassign [lindex $queue 0] currentNode currentDist
    set queue [lrange $queue 1 end]
    if {[lsearch -exact $visited $currentNode] != -1} {
      continue
    }
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
  set distanceFactor [expr {1.0 / (1.0 + 0.1 * pow($distance, 2))}]
  set adjustedLoad [expr {$baseLoad / $distanceFactor}]
  foreach capacity $sortedCapacities {
    if {$capacity >= $adjustedLoad} {
      return $capacity
    }
  }
  return [lindex $sortedCapacities end]
}
# Validate the power plan
proc validatePowerPlan {powerPlan loadCapacity} {
  set generator [dict get powerPlan generator]
  lassign $generator genPoint genCapacity
  set repeaters [dict get powerPlan repeaters]
  set isolatedLoads [dict get powerPlan isolatedLoads]
  set isolatedLoadTotal [expr {[llength $isolatedLoads] * $loadCapacity}]
  set repeaterLoadTotal 0
  foreach repeater $repeaters {
    lassign $repeater repPoint repCapacity repLoads
    set repLoadCount [llength $repLoads]
    set repLoad [expr {$repLoadCount * $loadCapacity}]
    if {$repCapacity < $repLoad} {
      return -code error "Repeater capacity ($repCapacity) insufficient for load ($repLoad)"
    }
    incr repeaterLoadTotal $repLoad
  }
  set totalGenLoad [expr {$isolatedLoadTotal + $repeaterLoadTotal}]
  if {$genCapacity < $totalGenLoad} {
    return -code error "Generator capacity ($genCapacity) insufficient for total load ($totalGenLoad)"
  }
  return 1
}
# Adjust power plan to meet capacity requirements
proc adjustPowerPlan {powerPlan loadCapacity availableCapacities} {
puts [dict get powerPlan]
  set generator [dict get powerPlan generator]
  lassign $generator genPoint genCapacity
  set repeaters [dict get powerPlan repeaters]
  set isolatedLoads [dict get powerPlan isolatedLoads]
  set sortedCapacities [lsort -decreasing -integer $availableCapacities]
  set isolatedLoadTotal [expr {[llength $isolatedLoads] * $loadCapacity}]
  set newRepeaters {}
  set totalRepeaterLoad 0
  foreach repeater $repeaters {
    lassign $repeater repPoint oldCapacity repLoads
    set repLoadCount [llength $repLoads]
    set repLoad [expr {$repLoadCount * $loadCapacity}]
    set newCapacity $oldCapacity
    foreach capacity $sortedCapacities {
      if {$capacity >= $repLoad} {
        set newCapacity $capacity
        break
      }
    }
    lappend newRepeaters [list $repPoint $newCapacity $repLoads]
    incr totalRepeaterLoad $repLoad
  }
  dict set powerPlan repeaters $newRepeaters
  return $powerPlan
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
    return -code error "Point must be two coordinate values (x y): $point"
  }
  foreach coord $point {
    if {![string is double -strict $coord]} {
      return -code error "Coordinate value must be a valid number: $coord"
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
        return -code error "Point format error in segment: $errMsg"
      }
    }
    return 1
  }
  return -code error "Segment format error, should be {{x1 y1} {x2 y2}} or {x1 y1 x2 y2}: $segment"
}
# Convert branch segment format to unified {x1 y1 x2 y2} format
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
# Build tree structure considering various tolerances
proc buildTreeStructure {rootPoint leafPoints branchSegments connectionTolerance nodeTolerance} {
  set treeData [dict create]
  dict set treeData root $rootPoint
  dict set treeData leaves $leafPoints
  dict set treeData branches $branchSegments
  set pointMap [dict create]
  set uniquePoints [list $rootPoint]
  dict set pointMap $rootPoint $rootPoint
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
  set rootMapped 0
  foreach existingPoint $uniquePoints {
    if {[distance $rootPoint $existingPoint] <= $nodeTolerance} {
      dict set pointMap $rootPoint $existingPoint
      set rootMapped 1
      break
    }
  }
  if {!$rootMapped} {
    lappend uniquePoints $rootPoint
    dict set pointMap $rootPoint $rootPoint
  }
  set adjacencyList [dict create]
  foreach segment $branchSegments {
    lassign $segment x1 y1 x2 y2
    set p1 [dict get $pointMap [list $x1 $y1]]
    set p2 [dict get $pointMap [list $x2 $y2]]
    if {![dict exists $adjacencyList $p1]} {
      dict set adjacencyList $p1 [list]
    }
    if {![dict exists $adjacencyList $p2]} {
      dict set adjacencyList $p2 [list]
    }
    dict lappend adjacencyList $p1 $p2
    dict lappend adjacencyList $p2 $p1
  }
  dict set treeData adjacencyList $adjacencyList
  dict set treeData pointMap $pointMap
  return $treeData
}
# Cluster leaf nodes
proc clusterLeaves {leafPoints threshold minSize} {
  set clusters {}
  set visitedPoints {}
  foreach point $leafPoints {
    if {[lsearch -exact $visitedPoints $point] != -1} {
      continue
    }
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
      set i [expr {int(floor($i + 1))}]
    }
    if {[llength $currentCluster] >= $minSize} {
      lappend clusters $currentCluster
    }
  }
  return $clusters
}
# Get neighbors of a specified point
proc getNeighbors {point points threshold} {
  set neighbors {}
  foreach p $points {
    if {$p == $point} {
      continue
    }
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
# Find the best breakpoint
proc findBestBreakpoint {treeData cluster {debug 0}} {
  set root [dict get $treeData root]
  set branches [dict get $treeData branches]
  set adjacencyList [dict get $treeData adjacencyList]
  set pointMap [dict get $treeData pointMap]
  set center [calculateCenter $cluster]
  if {$debug} {
    puts "Cluster center: [format "%.2f %.2f" {*}$center]"
  }
  set minDist inf
  set bestPoint {}
  foreach segment $branches {
    lassign $segment x1 y1 x2 y2
    set p1 [dict get $pointMap [list $x1 $y1]]
    set p2 [dict get $pointMap [list $x2 $y2]]
    foreach endpoint [list $p1 $p2] {
      set dist [distance $center $endpoint]
      if {$dist < $minDist} {
        set minDist $dist
        set bestPoint $endpoint
      }
    }
  }
  if {$bestPoint eq ""} {
    set bestPoint $center
  }
  if {$debug} {
    puts "Best breakpoint: [format "%.2f %.2f" {*}$bestPoint]"
  }
  return $bestPoint
}
# Calculate the center point of a set of points
proc calculateCenter {points} {
  set sumX 0.0
  set sumY 0.0
  set count 0
  foreach point $points {
    lassign $point x y
    set sumX [expr {$sumX + $x}]
    set sumY [expr {$sumY + $y}]
    set count [expr {int(floor($count + 1))}]
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
    {{0 0} {10.1 0.2}}
    {{9.9 0.1} {20.2 0.1}}
    {{19.8 0.3} {30.2 10.1}}
    {{30.1 9.9} {40.3 20.2}}
    {{19.9 0.2} {20.1 20.3}}
    {{20.2 19.8} {20.3 30.1}}
    {{20.1 30.2} {30.3 40.1}}
    {{20.3 0.1} {50.2 0.3}}
    {{49.8 0.2} {60.1 10.3}}
    {{60.2 9.9} {70.1 20.3}}
    {{70.3 20.1} {80.2 30.3}}
    {{80.1 29.9} {70.2 40.1}}
  }
  puts "Running tree breakpoint analysis..."
  set breakpoints [analyzeTreeBreakpoint $rootPoint $leafPoints $branchSegments \
                  {-connectionTolerance 0.3 -nodeTolerance 1.0 -debug 1}]
  puts "Recommended breakpoint positions:"
  foreach bp $breakpoints {
    puts "  [format "%.2f %.2f" {*}$bp]"
  }
  puts "\nRunning power distribution analysis..."
  set powerPlan [analyzePowerDistribution $rootPoint $leafPoints $branchSegments 8 \
                {-connectionTolerance 0.3 -nodeTolerance 1.0 -debug 1}]
  puts "\nPower Distribution Plan:"
  lassign [dict get $powerPlan generator] genPoint genCapacity
  puts "Generator: [format "%.2f %.2f" {*}$genPoint] (Capacity: $genCapacity)"
  puts "Repeaters:"
  foreach repeater [dict get $powerPlan repeaters] {
    lassign $repeater repPoint repCapacity repLoads
    puts "  Repeater: [format "%.2f %.2f" {*}$repPoint] (Capacity: $repCapacity, Loads: [llength $repLoads])"
  }
  puts "Isolated Loads: [llength [dict get $powerPlan isolatedLoads]]"
}
