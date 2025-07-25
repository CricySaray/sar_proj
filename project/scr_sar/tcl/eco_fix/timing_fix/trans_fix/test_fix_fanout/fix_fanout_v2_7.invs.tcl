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
    # Initialize default options
    # -clusterThreshold: Threshold for clustering leaf points (default 20.0)
    # -minClusterSize: Minimum size of a valid cluster (default 3)
    # -maxClusterRatio: Maximum ratio of total loads a cluster can have (default 0.6)
    # -connectionTolerance: Tolerance for connecting points (default 0.2)
    # -nodeTolerance: Tolerance for node proximity (default 1.0)
    # -debug: Enable debug output (default 0)
    # -loadCapacity: Load capacity per node (default 4)
    # -repeaterCapacities: Available repeater capacities (default {4 6 8 12 16})
    # -mainBranchThreshold: Threshold for identifying main branches (default 0.7)
    # -maxRepeaters: Maximum number of repeaters allowed (default 1)
    # -repeaterStrategy: Repeater placement strategy (0=minimize, 1=maximize, 2=automatic)
    # -balanceFactor: Weight for load balancing (0.0-1.0, default 0.6)
    # -treeStructureWeight: Weight for tree structure (default 0.4)
    # -maxBalanceIterations: Max iterations for load balancing (default 5)
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
        -repeaterStrategy 0
        -balanceFactor 0.6
        -treeStructureWeight 0.4
        -maxBalanceIterations 5
    }
    
    # Override default options with user-provided values
    array set options $optionsDict
    
    # Validate input
    if {[catch {validateInput $rootPoint $leafPoints $branchSegments} errMsg]} {
        return -code error $errMsg
    }
    if {$generatorCapacity <= 0} {
        return -code error "Generator capacity must be positive"
    }
    if {$options(-maxRepeaters) < 0} {
        return -code error "Maximum repeaters must be non-negative"
    }
    
    # Convert branch segments to standard format
    set convertedSegments [convertBranchSegments $branchSegments]
    
    # Build tree structure and validate
    set treeData [buildTreeStructure $rootPoint $leafPoints $convertedSegments \
                  $options(-connectionTolerance) $options(-nodeTolerance) $options(-mainBranchThreshold)]
    
    # Ensure all leaf points are in the tree
    set treeData [ensureAllPointsInTree $treeData $leafPoints $options(-debug)]
    
    # Calculate branch levels and node weights
    set treeData [calculateBranchLevels $treeData]
    
    # Cluster leaves
    set pointMap [dict get $treeData pointMap]
    set clusters [clusterLeavesOptimized $leafPoints $options(-clusterThreshold) $options(-minClusterSize)]
    set mappedClusters [mapClustersToTreePoints $clusters $pointMap]
    
    # Process clusters
    set totalLoadCount [llength $leafPoints]
    set processedClusters [processClusters $mappedClusters $totalLoadCount $options(-maxClusterRatio) $treeData $pointMap]
    
    # Calculate distances from root
    set distances [calculateDistances $treeData $rootPoint]
    
    # Initialize power plan
    set powerPlan [dict create]
    dict set powerPlan generator [list $rootPoint $generatorCapacity]
    dict set powerPlan repeaters [list]
    dict set powerPlan directLoads [list]
    dict set powerPlan repeaterDrivenLoads [dict create]
    
    # Special handling for single repeater case
    if {$options(-maxRepeaters) == 1 && $totalLoadCount > 1} {
        set singleRepeaterPlan [optimizeSingleRepeaterPlan $treeData $processedClusters $distances \
                               $generatorCapacity $options(-loadCapacity) $options(-repeaterCapacities) \
                               $options(-balanceFactor) $options(-treeStructureWeight) \
                               $options(-maxBalanceIterations) $options(-debug)]
        
        dict set powerPlan repeaters [list [list [lindex $singleRepeaterPlan 0] [lindex $singleRepeaterPlan 1] [lindex $singleRepeaterPlan 2]]]
        dict set powerPlan repeaterDrivenLoads [lindex $singleRepeaterPlan 0] [lindex $singleRepeaterPlan 2]
        dict set powerPlan directLoads $singleRepeaterPlan(3)
        
        if {$options(-debug)} {
            puts "Single repeater optimized plan:"
            puts "  Repeater at [format "%.2f %.2f" {*}[lindex $singleRepeaterPlan 0]] with capacity [lindex $singleRepeaterPlan 1]"
            puts "  Repeater loads: [llength [lindex $singleRepeaterPlan 2]]"
            puts "  Direct loads: [llength $singleRepeaterPlan(3)]"
        }
    } else {
        # Multi-repeater or default case
        set sortedClusters [lsort -command [list sortClustersByDistance $distances $pointMap] $processedClusters]
        
        # Track used repeaters
        set usedRepeaters 0
        set hasRepeaterLoads 0
        
        # Allocate loads based on strategy
        foreach cluster $sortedClusters {
            set clusterSize [llength $cluster]
            set clusterCenter [calculateCenter $cluster]
            set avgDistance [calculateClusterAvgDistance $cluster $distances $pointMap]
            
            # Decide whether to use a repeater
            set useRepeater 0
            switch -- $options(-repeaterStrategy) {
                0 { ;# STRATEGY_MINIMIZE_REPEATERS
                    if {[shouldUseRepeater $avgDistance $clusterSize $totalLoadCount] && $usedRepeaters < $options(-maxRepeaters)} {
                        set useRepeater 1
                    }
                }
                1 { ;# STRATEGY_MAXIMIZE_REPEATERS
                    if {$usedRepeaters < $options(-maxRepeaters)} {
                        set useRepeater 1
                    }
                }
                2 { ;# STRATEGY_AUTOMATIC
                    set useRepeater [decideAutomaticRepeaterUsage $avgDistance $clusterSize $totalLoadCount \
                                    $generatorCapacity $options(-loadCapacity) $usedRepeaters $options(-maxRepeaters)]
                }
                default {
                    error "Invalid repeater strategy: $options(-repeaterStrategy)"
                }
            }
            
            # Process cluster based on repeater decision
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
        
        # Ensure at least one repeater if required
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
    }
    
    # Validate and adjust power plan
    if {[catch {validatePowerPlan $powerPlan $options(-loadCapacity)} errMsg]} {
        if {$options(-debug)} {
            puts "Warning: Power plan validation failed: $errMsg"
            puts "Attempting to adjust capacities..."
        }
        set powerPlan [adjustPowerPlan $powerPlan $options(-loadCapacity) $options(-repeaterCapacities)]
    }
    
    # Ensure at least one repeater drives loads if repeaters are used
    set repeaters [dict get $powerPlan repeaters]
    if {[llength $repeaters] > 0} {
        set hasRepeaterLoads 0
        foreach repeater $repeaters {
            lassign $repeater repPoint repCapacity repLoads
            if {[llength $repLoads] > 0} {
                set hasRepeaterLoads 1
                break
            }
        }
        
        if {!$hasRepeaterLoads && [llength [dict get $powerPlan directLoads]] > 0} {
            set firstRepeater [lindex $repeaters 0]
            lassign $firstRepeater repPoint repCapacity repLoads
            
            set firstDirectLoad [lindex [dict get $powerPlan directLoads] 0]
            lassign $firstDirectLoad loadPoint loadCapacity
            
            # Move first direct load to repeater
            lappend repLoads $loadPoint
            set newRepeaters [list]
            foreach r $repeaters {
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

# Optimize power plan for single repeater case
proc optimizeSingleRepeaterPlan {treeData clusters distances generatorCapacity loadCapacity repeaterCapacities balanceFactor treeStructureWeight maxIterations debug} {
    set adjacencyList [dict get $treeData adjacencyList]
    set pointMap [dict get $treeData pointMap]
    set mainBranches [dict get $treeData mainBranches]
    set rootPoint [dict get $treeData root]
    
    # Check if branchLevels exists, calculate if not
    if {![dict exists $treeData branchLevels]} {
        if {$debug} {
            puts "Warning: branchLevels not found in treeData, calculating..."
        }
        set treeData [calculateBranchLevels $treeData]
    }
    
    set branchLevels [dict get $treeData branchLevels]
    
    # Flatten clusters into individual points
    set allPoints [lsort -unique [concat {*}$clusters]]
    set totalLoadCount [llength $allPoints]
    set targetLoadCount [expr {int(ceil($totalLoadCount / 2))}]
    
    # Calculate branch weights considering levels
    # Higher weight for lower levels (main branches)
    set branchWeights [dict create]
    foreach node [dict keys $adjacencyList] {
        if {[dict exists $branchLevels $node]} {
            set level [dict get $branchLevels $node]
            dict set branchWeights $node [expr {1.0 / (1.0 + $level)}]
        } else {
            if {$debug} {
                puts "Warning: Node $node not found in branchLevels, assigning default weight"
            }
            dict set branchWeights $node 0.5  ;# Default weight for nodes not in branchLevels
        }
    }
    
    # Find potential repeater locations (nodes on main branches)
    set potentialLocations [list]
    foreach node [dict keys $adjacencyList] {
        if {[dict exists $branchWeights $node] && [dict get $branchWeights $node] > 0.3} {
            lappend potentialLocations $node
        }
    }
    
    if {[llength $potentialLocations] == 0} {
        # Fallback to all nodes if no main branches found
        set potentialLocations [dict keys $adjacencyList]
    }
    
    # Initialize best configuration
    set bestLocation ""
    set bestRepeaterLoads [list]
    set bestDirectLoads [list]
    set bestBalanceScore inf
    set bestCapacity 0
    
    # Evaluate each potential location
    foreach location $potentialLocations {
        # Split tree into two parts: nodes reachable from location without going through root
        # and nodes that must pass through root
        set reachableNodes [list $location]
        set queue [list $location]
        set visited [dict create]
        dict set visited $location 1
        
        while {[llength $queue] > 0} {
            set current [lindex $queue 0]
            set queue [lrange $queue 1 end]
            
            # Check if current node exists in adjacency list
            if {![dict exists $adjacencyList $current]} {
                if {$debug} {
                    puts "Warning: Node $current not found in adjacency list, skipping..."
                }
                continue
            }
            
            foreach neighbor [dict get $adjacencyList $current] {
                if {![dict exists $visited $neighbor] && $neighbor ne $rootPoint} {
                    dict set visited $neighbor 1
                    lappend reachableNodes $neighbor
                    lappend queue $neighbor
                }
            }
        }
        
        # Assign each point to either repeater or direct based on reachability
        set repeaterLoads [list]
        set directLoads [list]
        
        foreach point $allPoints {
            if {[lsearch -exact $reachableNodes $point] != -1} {
                lappend repeaterLoads $point
            } else {
                lappend directLoads $point
            }
        }
        
        # Calculate balance score
        set loadDiff [expr {abs([llength $repeaterLoads] - $targetLoadCount)}]
        set structureScore [dict get $branchWeights $location]
        set balanceScore [expr {$balanceFactor * $loadDiff + (1.0 - $balanceFactor) * (1.0 - $structureScore)}]
        
        # Calculate required capacity
        set requiredCapacity [expr {[llength $repeaterLoads] * $loadCapacity}]
        set optimalCapacity [selectOptimalRepeaterCapacity $generatorCapacity $loadCapacity \
                           [llength $repeaterLoads] [calculateClusterAvgDistance $repeaterLoads $distances $pointMap] \
                           $repeaterCapacities]
        
        # Check if this is the best configuration so far
        if {$balanceScore < $bestBalanceScore || ($balanceScore == $bestBalanceScore && $optimalCapacity < $bestCapacity)} {
            set bestLocation $location
            set bestRepeaterLoads $repeaterLoads
            set bestDirectLoads $directLoads
            set bestBalanceScore $balanceScore
            set bestCapacity $optimalCapacity
        }
    }
    
    # Iterative adjustment for better balance
    for {set iter 0} {$iter < $maxIterations} {incr iter} {
        set loadDiff [expr {[llength $bestRepeaterLoads] - [llength $bestDirectLoads]}]
        if {abs($loadDiff) <= 1} {
            break  ;# Close enough balance
        }
        
        if {$loadDiff > 0} {
            # Need to move some loads from repeater to direct
            set candidates [list]
            foreach point $bestRepeaterLoads {
                set nodeWeight [dict exists $branchWeights $point] ? [dict get $branchWeights $point] : 0.5
                set distance [dict exists $distances $point] ? [dict get $distances $point] : 0.0
                # Prefer points on higher level branches and closer to root
                lappend candidates [list [expr {$nodeWeight * $distance}] $point]
            }
            
            if {[llength $candidates] > 0} {
                set sortedCandidates [lsort -index 0 $candidates]
                set pointToMove [lindex [lindex $sortedCandidates 0] 1]
                
                # Remove from repeater loads
                set newRepeaterLoads [list]
                foreach p $bestRepeaterLoads {
                    if {$p ne $pointToMove} {
                        lappend newRepeaterLoads $p
                    }
                }
                
                # Add to direct loads
                lappend bestDirectLoads $pointToMove
                set bestRepeaterLoads $newRepeaterLoads
            } else {
                break  ;# No candidates to move
            }
        } else {
            # Need to move some loads from direct to repeater
            set candidates [list]
            foreach point $bestDirectLoads {
                # Check if point can be connected to repeater location without going through root
                set canConnect 0
                set queue [list $point]
                set visited [dict create]
                dict set visited $point 1
                
                while {[llength $queue] > 0} {
                    set current [lindex $queue 0]
                    set queue [lrange $queue 1 end]
                    
                    # Check if current node exists in adjacency list
                    if {![dict exists $adjacencyList $current]} {
                        if {$debug} {
                            puts "Warning: Node $current not found in adjacency list, skipping connection check..."
                        }
                        continue
                    }
                    
                    if {$current eq $bestLocation} {
                        set canConnect 1
                        break
                    }
                    
                    foreach neighbor [dict get $adjacencyList $current] {
                        if {![dict exists $visited $neighbor] && $neighbor ne $rootPoint} {
                            dict set visited $neighbor 1
                            lappend queue $neighbor
                        }
                    }
                }
                
                if {$canConnect} {
                    set nodeWeight [dict exists $branchWeights $point] ? [dict get $branchWeights $point] : 0.5
                    set distance [dict exists $distances $point] ? [dict get $distances $point] : 0.0
                    # Prefer points on lower level branches and farther from root
                    lappend candidates [list [expr {-$nodeWeight * $distance}] $point]
                }
            }
            
            if {[llength $candidates] > 0} {
                set sortedCandidates [lsort -index 0 $candidates]
                set pointToMove [lindex [lindex $sortedCandidates 0] 1]
                
                # Remove from direct loads
                set newDirectLoads [list]
                foreach p $bestDirectLoads {
                    if {$p ne $pointToMove} {
                        lappend newDirectLoads $p
                    }
                }
                
                # Add to repeater loads
                lappend bestRepeaterLoads $pointToMove
                set bestDirectLoads $newDirectLoads
            } else {
                break  ;# No candidates to move
            }
        }
    }
    
    # Recalculate optimal capacity after adjustment
    set finalCapacity [selectOptimalRepeaterCapacity $generatorCapacity $loadCapacity \
                     [llength $bestRepeaterLoads] [calculateClusterAvgDistance $bestRepeaterLoads $distances $pointMap] \
                     $repeaterCapacities]
    
    if {$debug} {
        puts "Single repeater optimization results:"
        puts "  Best location: [format "%.2f %.2f" {*}$bestLocation], level: [dict exists $branchLevels $bestLocation] ? [dict get $branchLevels $bestLocation] : "unknown""
        puts "  Repeater loads: [llength $bestRepeaterLoads], Direct loads: [llength $bestDirectLoads]"
        puts "  Target load balance: $targetLoadCount, Actual diff: [expr {abs([llength $bestRepeaterLoads] - [llength $bestDirectLoads])}]"
    }
    
    # Ensure bestLocation exists in branchLevels
    if {![dict exists $branchLevels $bestLocation]} {
        if {$debug} {
            puts "Warning: Best location $bestLocation not found in branchLevels, assigning default level"
        }
        dict set branchLevels $bestLocation 0  ;# Assign default level 0 if not found
    }
    
    return [list $bestLocation $finalCapacity $bestRepeaterLoads $bestDirectLoads]
}

# Calculate branch levels for each node
proc calculateBranchLevels {treeData} {
    set adjacencyList [dict get $treeData adjacencyList]
    set rootPoint [dict get $treeData root]
    set branchLevels [dict create]
    
    # Initialize root level
    dict set branchLevels $rootPoint 0
    
    # BFS traversal to calculate levels
    set queue [list $rootPoint]
    
    while {[llength $queue] > 0} {
        set current [lindex $queue 0]
        set queue [lrange $queue 1 end]
        set currentLevel [dict get $branchLevels $current]
        
        # Check if current node exists in adjacency list
        if {![dict exists $adjacencyList $current]} {
            if {[info exists debug] && $debug} {
                puts "Warning: Node $current not found in adjacency list during level calculation, skipping..."
            }
            continue
        }
        
        foreach neighbor [dict get $adjacencyList $current] {
            if {![dict exists $branchLevels $neighbor]} {
                dict set branchLevels $neighbor [expr {$currentLevel + 1}]
                lappend queue $neighbor
            }
        }
    }
    
    dict set treeData branchLevels $branchLevels
    return $treeData
}

# Ensure all points are in the tree structure
proc ensureAllPointsInTree {treeData points debug} {
    set adjacencyList [dict get $treeData adjacencyList]
    set pointMap [dict get $treeData pointMap]
    set rootPoint [dict get $treeData root]
    
    # Collect all nodes in the current tree
    set treeNodes [dict keys $adjacencyList]
    
    # Check each point
    foreach point $points {
        if {[lsearch -exact $treeNodes $point] == -1} {
            if {$debug} {
                puts "Warning: Point $point not found in tree structure, adding..."
            }
            
            # Find the nearest node in the tree
            set nearestNode ""
            set minDistance inf
            
            foreach node $treeNodes {
                set dist [distance $point $node]
                if {$dist < $minDistance} {
                    set minDistance $dist
                    set nearestNode $node
                }
            }
            
            # Add the point to the tree
            if {$nearestNode ne ""} {
                # Update adjacency list
                lappend adjacencyList($nearestNode) $point
                dict set adjacencyList $point [list $nearestNode]
                
                # Update point map if it exists
                if {[dict exists $pointMap $nearestNode]} {
                    dict set pointMap $point [dict get $pointMap $nearestNode]
                }
            }
        }
    }
    
    # Update treeData
    dict set treeData adjacencyList $adjacencyList
    dict set treeData pointMap $pointMap
    
    return $treeData
}

# Calculate distance between two points
proc distance {p1 p2} {
    lassign $p1 x1 y1
    lassign $p2 x2 y2
    return [expr {sqrt(pow(($x2 - $x1), 2) + pow(($y2 - $y1), 2))}]
}

# 其余代码保持不变...

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


# Main program entry (for testing)
if {[info exists argv0] && [string equal [file tail $argv0] [file tail [info script]]]} {
    # Test case with sample data
    set rootPoint {0 0}
    set leafPoints {{30.1 20.2} {35.3 25.1} {40.2 20.3} {45.1 25.2} {20.3 40.1} {25.2 45.3} {30.1 40.2} {35.3 45.1} {60.2 40.1} {65.1 45.3} {70.3 40.2} {75.2 45.1}}
    set branchSegments {{{0 0} {10.1 0.2}} {{9.9 0.1} {20.2 0.1}} {{19.8 0.3} {30.2 10.1}} {{30.1 9.9} {40.3 20.2}} {{19.9 0.2} {20.1 20.3}} {{20.2 19.8} {20.3 30.1}} {{20.1 30.2} {30.3 40.1}} {{20.3 0.1} {50.2 0.3}} {{49.8 0.2} {60.1 10.3}} {{60.2 9.9} {70.1 20.3}} {{70.3 20.1} {80.2 30.3}} {{80.1 29.9} {70.2 40.1}}}
    
    puts "Running power distribution analysis..."
    set powerPlan [analyzePowerDistribution $rootPoint $leafPoints $branchSegments 30 \
                  {-connectionTolerance 0.3 -nodeTolerance 1.0 -debug 1 -maxRepeaters 1 -repeaterStrategy 0}]
    
    # Output results
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
