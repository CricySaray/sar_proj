# Tree Structure Breakpoint Analysis Tool
# Input root point, leaf points, and branch segments to calculate optimal breakpoint positions

package require Tcl 8.5
package require struct::list
package require math::statistics

# Main processing procedure
proc analyzeTreeBreakpoint {rootPoint leafPoints branchSegments {optionsDict {}}} {
  # Set default options
  array set options {
    -clusterThreshold 20.0
    -minClusterSize 3
    -connectionTolerance 0.2
    -nodeTolerance 1.0
    -debug 0
  }
  
  # Apply user-specified options
  array set options $optionsDict
  
  # Validate input data
  if {[catch {validateInput $rootPoint $leafPoints $branchSegments} errMsg]} {
    return -code error $errMsg
  }
  
  # Convert branch segment format
  set convertedSegments [convertBranchSegments $branchSegments]
  
  # Build tree structure considering various tolerances
  set treeData [buildTreeStructure $rootPoint $leafPoints $convertedSegments \
                $options(-connectionTolerance) $options(-nodeTolerance)]
  
  # Perform clustering analysis
  set clusters [clusterLeaves $leafPoints $options(-clusterThreshold) $options(-minClusterSize)]
  
  if {$options(-debug)} {
    puts "Clustering results: [llength $clusters] clusters"
    for {set i 0} {$i < [llength $clusters]} {incr i} {
      puts "  Cluster $i: [llength [lindex $clusters $i]] leaves"
    }
  }
  
  # Find best breakpoint for each cluster
  set breakpoints {}
  foreach cluster $clusters {
    lappend breakpoints [findBestBreakpoint $treeData $cluster $options(-debug)]
  }
  
  return $breakpoints
}

# Validate input data
proc validateInput {rootPoint leafPoints branchSegments} {
  # Validate root point
  if {[catch {validatePoint $rootPoint} errMsg]} {
    return -code error "Root point validation failed: $errMsg"
  }
  
  # Validate leaf points
  if {[llength $leafPoints] < 1} {
    return -code error "At least one leaf point is required"
  }
  
  foreach leaf $leafPoints {
    if {[catch {validatePoint $leaf} errMsg]} {
      return -code error "Leaf point validation failed: $errMsg"
    }
  }
  
  # Validate branch segments
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
  # Check if it's the old format {{x1 y1 x2 y2}}
  if {[llength $segment] == 4 && [string is double -strict [lindex $segment 0]]} {
    return 1
  }
  
  # Check if it's the new format {{x1 y1} {x2 y2}}
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
    # Check if it's the new format {{x1 y1} {x2 y2}}
    if {[llength $segment] == 2 && [llength [lindex $segment 0]] == 2} {
      lassign $segment p1 p2
      lassign $p1 x1 y1
      lassign $p2 x2 y2
      lappend converted [list $x1 $y1 $x2 $y2]
    } else {
      # Keep old format {x1 y1 x2 y2} unchanged
      lappend converted $segment
    }
  }
  
  return $converted
}

# Build tree structure considering various tolerances
proc buildTreeStructure {rootPoint leafPoints branchSegments connectionTolerance nodeTolerance} {
  # Initialize tree data structure
  set treeData [dict create]
  dict set treeData root $rootPoint
  dict set treeData leaves $leafPoints
  dict set treeData branches $branchSegments
  
  # Create a point map to treat points within tolerance as the same point
  set pointMap [dict create]
  set uniquePoints [list $rootPoint]
  
  # Add root point to the map
  dict set pointMap $rootPoint $rootPoint
  
  # Process endpoints of branch segments
  foreach segment $branchSegments {
    lassign $segment x1 y1 x2 y2
    set p1 [list $x1 $y1]
    set p2 [list $x2 $y2]
    
    # Check if the point exists in the map (considering connection tolerance)
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
  
  # Process leaf points (using larger node tolerance)
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
  
  # Process root point connection to branches (using node tolerance)
  set rootMapped 0
  foreach existingPoint $uniquePoints {
    if {[distance $rootPoint $existingPoint] <= $nodeTolerance} {
      dict set pointMap $rootPoint $existingPoint
      set rootMapped 1
      break
    }
  }
  
  # If root point is not mapped to any existing point, add it as a new point
  if {!$rootMapped} {
    lappend uniquePoints $rootPoint
    dict set pointMap $rootPoint $rootPoint
  }
  
  # Build adjacency list representation of the graph structure using mapped points
  set adjacencyList [dict create]
  
  # Add branch segment connections
  foreach segment $branchSegments {
    lassign $segment x1 y1 x2 y2
    set p1 [dict get $pointMap [list $x1 $y1]]
    set p2 [dict get $pointMap [list $x2 $y2]]
    
    # Update adjacency list
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
  
  # Use a simple distance-based clustering algorithm (simplified DBSCAN)
  set visitedPoints {}
  foreach point $leafPoints {
    if {[lsearch -exact $visitedPoints $point] != -1} {
      continue
    }
    
    lappend visitedPoints $point
    set currentCluster [list $point]
    set neighbors [getNeighbors $point $leafPoints $threshold]
    
    set i 0
    # Use floating-point safe loop
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
      
      # Use floating-point addition and then convert to integer index
      set i [expr {int(floor($i + 1))}]
    }
    
    # Keep only clusters that are large enough
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
  
  # Calculate the center point of the cluster
  set center [calculateCenter $cluster]
  
  if {$debug} {
    puts "Cluster center: [format "%.2f %.2f" {*}$center]"
  }
  
  # Find the endpoint on a branch segment closest to the center point
  set minDist inf
  set bestPoint {}
  
  # Use mapped points to find the closest point
  foreach segment $branches {
    lassign $segment x1 y1 x2 y2
    set p1 [dict get $pointMap [list $x1 $y1]]
    set p2 [dict get $pointMap [list $x2 $y2]]
    
    # Check both endpoints of the segment
    foreach endpoint [list $p1 $p2] {
      set dist [distance $center $endpoint]
      if {$dist < $minDist} {
        set minDist $dist
        set bestPoint $endpoint
      }
    }
  }
  
  # If no suitable endpoint is found, return the center point (theoretically this should not happen)
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
    # Use expr to ensure floating-point addition
    set sumX [expr {$sumX + $x}]
    set sumY [expr {$sumY + $y}]
    # Ensure count is an integer
    set count [expr {int(floor($count + 1))}]
  }
  
  if {$count > 0} {
    return [list [expr {$sumX / $count}] [expr {$sumY / $count}]]
  } else {
    return [list 0.0 0.0]
  }
}

# Example usage
if {0} {
  # Example data - including connection point errors, using new segment format
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
  
  # Analyze and get breakpoints, setting connection tolerance to 0.3 and node tolerance to 1.0
  set breakpoints [analyzeTreeBreakpoint $rootPoint $leafPoints $branchSegments \
                  {-connectionTolerance 0.3 -nodeTolerance 1.0 -debug 1}]
  
  puts "Recommended breakpoint positions:"
  foreach bp $breakpoints {
    puts "  [format "%.2f %.2f" {*}$bp]"
  }
}    
