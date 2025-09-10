proc place_rectangles {specRegions rectNames minSpacing mapList {returnMode "coordinates"} {debug 0}} {
  # Validate input parameters
  if {[llength $specRegions] == 0} {
    error "Specification regions cannot be empty"
  }
  if {[llength $rectNames] == 0} {
    error "Rectangle names list cannot be empty"
  }
  if {![string is double -strict $minSpacing] || $minSpacing < 0} {
    error "Minimum spacing must be a non-negative number"
  }
  if {[llength $mapList] == 0} {
    error "Orientation mapping list cannot be empty"
  }
  # Validate return mode parameter
  if {$returnMode ne "movements" && $returnMode ne "coordinates"} {
    error "Invalid return mode: $returnMode. Must be either 'movements' or 'coordinates'"
  }

  # Parse specification regions
  set specRegionList [list]
  foreach region $specRegions {
    if {[llength $region] != 4} {
      error "Invalid region format: $region, expected {x y x1 y1}"
    }
    lassign $region x y x1 y1
    if {![string is double -strict $x] || ![string is double -strict $y] ||
        ![string is double -strict $x1] || ![string is double -strict $y1]} {
      error "Region coordinates must be numbers: $region"
    }
    if {$x >= $x1 || $y >= $y1} {
      error "Invalid region coordinates, x must be less than x1 and y must be less than y1: $region"
    }
    lappend specRegionList [list $x $y $x1 $y1]
  }

  # Collect all rectangle information
  set rectInfo [dict create]
  foreach memName $rectNames {
    # Get rectangle region
    if {$debug} {
      puts "Retrieving region information for rectangle $memName..."
    }
    if {[catch {set memRect {*}[dbget [dbget top.insts.name $memName -p].box]} err]} {
      error "Failed to get region info for $memName: $err"
    }
    if {[llength $memRect] != 4} {
      error "Invalid region format for $memName: $memRect, expected {x y x1 y1}"
    }
    lassign $memRect x y x1 y1
    if {$x >= $x1 || $y >= $y1} {
      error "Invalid coordinates for $memName: $memRect"
    }

    # Get rectangle orientation
    if {$debug} {
      puts "Retrieving orientation information for rectangle $memName..."
    }
    if {[catch {set memOrient [dbget [dbget top.insts.name $memName -p].orient]} err]} {
      error "Failed to get orientation for $memName: $err"
    }

    # Determine reference direction
    set refDir ""
    foreach map $mapList {
      if {[llength $map] != 2} {
        error "Invalid map format: $map, expected {{orientList} refDir}"
      }
      lassign $map orientList dir
      if {[lsearch -exact $orientList $memOrient] != -1} {
        set refDir $dir
        break
      }
    }
    if {$refDir eq ""} {
      error "No reference direction found for $memName with orientation $memOrient"
    }

    # Calculate center point
    set centerX [expr {($x + $x1) / 2.0}]
    set centerY [expr {($y + $y1) / 2.0}]

    # Check if completely outside all specification regions
    set fullyOutside 1
    foreach specRegion $specRegionList {
      lassign $specRegion rx ry rx1 ry1
      # Check if there's any overlap with the specification region
      if {!($x1 < $rx || $x > $rx1 || $y1 < $ry || $y > $ry1)} {
        set fullyOutside 0
        break
      }
    }
    if {$fullyOutside} {
      error "Rectangle $memName is completely outside all specification regions"
    }

    # Save rectangle information including original position
    dict set rectInfo $memName [dict create \
      originalRect $memRect \
      originalX $x \
      originalY $y \
      x $x \
      y $y \
      x1 $x1 \
      y1 $y1 \
      width [expr {$x1 - $x}] \
      height [expr {$y1 - $y}] \
      centerX $centerX \
      centerY $centerY \
      orient $memOrient \
      refDir $refDir \
    ]

    if {$debug} {
      puts "Rectangle $memName info: region=$memRect, orientation=$memOrient, refDir=$refDir, center=($centerX, $centerY)"
    }
  }

  # Determine relative positions between rectangles
  set relativePositions [dict create]
  foreach memA $rectNames {
    dict set relativePositions $memA [dict create]
    set aInfo [dict get $rectInfo $memA]
    set aCenterX [dict get $aInfo centerX]
    set aCenterY [dict get $aInfo centerY]

    foreach memB $rectNames {
      if {$memA eq $memB} { continue }
      
      set bInfo [dict get $rectInfo $memB]
      set bCenterX [dict get $bInfo centerX]
      set bCenterY [dict get $bInfo centerY]

      # Determine relative position
      set pos ""
      if {$aCenterY > $bCenterY + 1e-6} { ;# A is above B
        set pos "above"
      } elseif {$aCenterY < $bCenterY - 1e-6} { ;# A is below B
        set pos "below"
      } elseif {$aCenterX < $bCenterX - 1e-6} { ;# A is left of B
        set pos "left"
      } elseif {$aCenterX > $bCenterX + 1e-6} { ;# A is right of B
        set pos "right"
      } else { ;# Centers overlap
        set pos "overlap"
      }

      dict set relativePositions $memA $memB $pos
      if {$debug} {
        puts "Position of $memA relative to $memB: $pos"
      }
    }
  }

  # Identify corner rectangles
  set cornerRects [list]
  foreach memName $rectNames {
    set info [dict get $rectInfo $memName]
    set x [dict get $info x]
    set y [dict get $info y]
    set x1 [dict get $info x1]
    set y1 [dict get $info y1]

    # Check if near any corner of specification regions
    set isCorner 0
    foreach specRegion $specRegionList {
      lassign $specRegion rx ry rx1 ry1
      
      # Check near top-left corner
      if {abs($x - $rx) < 1e-6 && abs($y1 - $ry1) < 1e-6} {
        set isCorner 1
        break
      }
      # Check near top-right corner
      if {abs($x1 - $rx1) < 1e-6 && abs($y1 - $ry1) < 1e-6} {
        set isCorner 1
        break
      }
      # Check near bottom-left corner
      if {abs($x - $rx) < 1e-6 && abs($y - $ry) < 1e-6} {
        set isCorner 1
        break
      }
      # Check near bottom-right corner
      if {abs($x1 - $rx1) < 1e-6 && abs($y - $ry) < 1e-6} {
        set isCorner 1
        break
      }
    }
    
    if {$isCorner} {
      lappend cornerRects $memName
      if {$debug} {
        puts "Rectangle $memName identified as corner rectangle"
      }
    }
  }

  # Determine processing order: corner rectangles first, then others
  set processingOrder [list]
  set nonCornerRects [list]
  foreach memName $rectNames {
    if {[lsearch -exact $cornerRects $memName] != -1} {
      lappend processingOrder $memName
    } else {
      lappend nonCornerRects $memName
    }
  }
  # Add non-corner rectangles to processing order
  eval lappend processingOrder $nonCornerRects

  if {$debug} {
    puts "Rectangle processing order: $processingOrder"
  }

  # Initialize placed rectangles information
  set placedRects [dict create]

  # Process each rectangle
  foreach memName $processingOrder {
    set info [dict get $rectInfo $memName]
    set originalX [dict get $info originalX]
    set originalY [dict get $info originalY]
    set x [dict get $info x]
    set y [dict get $info y]
    set width [dict get $info width]
    set height [dict get $info height]
    set refDir [dict get $info refDir]

    if {$debug} {
      puts "Processing rectangle $memName with reference direction: $refDir"
    }

    # Calculate initial position within specification regions
    set newX $x
    set newY $y

    # Check if on region boundary, move to inner boundary if needed
    foreach specRegion $specRegionList {
      lassign $specRegion rx ry rx1 ry1
      
      # Left boundary check
      if {$newX < $rx} {
        set newX $rx
        if {$debug} {
          puts "Rectangle $memName moved to left boundary: $newX"
        }
      }
      # Right boundary check
      if {$newX + $width > $rx1} {
        set newX [expr {$rx1 - $width}]
        if {$debug} {
          puts "Rectangle $memName moved to right boundary: $newX"
        }
      }
      # Bottom boundary check
      if {$newY < $ry} {
        set newY $ry
        if {$debug} {
          puts "Rectangle $memName moved to bottom boundary: $newY"
        }
      }
      # Top boundary check
      if {$newY + $height > $ry1} {
        set newY [expr {$ry1 - $height}]
        if {$debug} {
          puts "Rectangle $memName moved to top boundary: $newY"
        }
      }
    }

    # Adjust position based on already placed rectangles
    foreach placedMem [dict keys $placedRects] {
      set placedInfo [dict get $placedRects $placedMem]
      set placedX [dict get $placedInfo x]
      set placedY [dict get $placedInfo y]
      set placedWidth [dict get $placedInfo width]
      set placedHeight [dict get $placedInfo height]
      set placedRefDir [dict get $placedInfo refDir]

      # Get relative position
      set pos [dict get $relativePositions $memName $placedMem]

      # Adjust based on relative position
      switch $pos {
        "left" {
          # Current rectangle is to the left of placed rectangle
          set minX [expr {$placedX - $width - $minSpacing}]
          if {$newX > $minX} {
            set newX $minX
            if {$debug} {
              puts "Rectangle $memName adjusted to left of $placedMem, new X: $newX"
            }
          }

          # Check if opposite edges of reference directions need alignment
          if {$refDir eq "top" && $placedRefDir eq "top"} {
            # Both use top as reference, align bottom edges
            set newY [expr {$placedY + $placedHeight - $height}]
            if {$debug} {
              puts "Rectangle $memName aligned with $placedMem's bottom edge, new Y: $newY"
            }
          } elseif {$refDir eq "bottom" && $placedRefDir eq "bottom"} {
            # Both use bottom as reference, align top edges
            set newY $placedY
            if {$debug} {
              puts "Rectangle $memName aligned with $placedMem's top edge, new Y: $newY"
            }
          } elseif {$refDir ne $placedRefDir} {
            puts "Warning: Reference directions of $memName and $placedMem do not match, manual adjustment may be needed"
          }
        }
        "right" {
          # Current rectangle is to the right of placed rectangle
          set minX [expr {$placedX + $placedWidth + $minSpacing}]
          if {$newX < $minX} {
            set newX $minX
            if {$debug} {
              puts "Rectangle $memName adjusted to right of $placedMem, new X: $newX"
            }
          }

          # Check if opposite edges of reference directions need alignment
          if {$refDir eq "top" && $placedRefDir eq "top"} {
            # Both use top as reference, align bottom edges
            set newY [expr {$placedY + $placedHeight - $height}]
            if {$debug} {
              puts "Rectangle $memName aligned with $placedMem's bottom edge, new Y: $newY"
            }
          } elseif {$refDir eq "bottom" && $placedRefDir eq "bottom"} {
            # Both use bottom as reference, align top edges
            set newY $placedY
            if {$debug} {
              puts "Rectangle $memName aligned with $placedMem's top edge, new Y: $newY"
            }
          } elseif {$refDir ne $placedRefDir} {
            puts "Warning: Reference directions of $memName and $placedMem do not match, manual adjustment may be needed"
          }
        }
        "above" {
          # Current rectangle is above placed rectangle
          set minY [expr {$placedY + $placedHeight + $minSpacing}]
          if {$newY < $minY} {
            set newY $minY
            if {$debug} {
              puts "Rectangle $memName adjusted above $placedMem, new Y: $newY"
            }
          }
        }
        "below" {
          # Current rectangle is below placed rectangle
          set minY [expr {$placedY - $height - $minSpacing}]
          if {$newY > $minY} {
            set newY $minY
            if {$debug} {
              puts "Rectangle $memName adjusted below $placedMem, new Y: $newY"
            }
          }
        }
      }

      # Check minimum distance for reference direction edges
      set refDist 0
      switch $refDir {
        "top" {
          set refY1 [expr {$newY + $height}]
        }
        "bottom" {
          set refY1 $newY
        }
        "left" {
          set refX1 $newX
        }
        "right" {
          set refX1 [expr {$newX + $width}]
        }
      }

      switch $placedRefDir {
        "top" {
          set placedRefY1 [expr {$placedY + $placedHeight}]
        }
        "bottom" {
          set placedRefY1 $placedY
        }
        "left" {
          set placedRefX1 $placedX
        }
        "right" {
          set placedRefX1 [expr {$placedX + $placedWidth}]
        }
      }

      # Calculate distance between reference direction edges
      if {($refDir eq "left" || $refDir eq "right") && 
          ($placedRefDir eq "left" || $placedRefDir eq "right")} {
        set refDist [expr {abs($refX1 - $placedRefX1)}]
      } elseif {($refDir eq "top" || $refDir eq "bottom") && 
                ($placedRefDir eq "top" || $placedRefDir eq "bottom")} {
        set refDist [expr {abs($refY1 - $placedRefY1)}]
      }

      # Check if reference edge distance is greater than minimum spacing
      if {$refDist > 0 && $refDist <= $minSpacing} {
        puts "Warning: Reference edge distance between $memName and $placedMem is too small: $refDist, should be greater than $minSpacing"
      }
    }

    # Save placed rectangle information including original position for movement calculation
    dict set placedRects $memName [dict create \
      originalX $originalX \
      originalY $originalY \
      x $newX \
      y $newY \
      width $width \
      height $height \
      refDir $refDir \
      rect [list $newX $newY [expr {$newX + $width}] [expr {$newY + $height}]] \
    ]

    if {$debug} {
      puts "Rectangle $memName placed at: ([list $newX $newY [expr {$newX + $width}] [expr {$newY + $height}]])"
    }
  }

  # Prepare result based on return mode
  set result [list]
  if {$returnMode eq "coordinates"} {
    # Return mode 1: new bottom-left coordinates
    foreach memName $rectNames {
      set info [dict get $placedRects $memName]
      set newX [dict get $info x]
      set newY [dict get $info y]
      lappend result [list $memName [list $newX $newY]]
    }
  } else {
    # Return mode 2: movement directions and distances
    # Using 'up' and 'down' for vertical movements, 'left' and 'right' for horizontal
    foreach memName $rectNames {
      set info [dict get $placedRects $memName]
      set originalX [dict get $info originalX]
      set originalY [dict get $info originalY]
      set newX [dict get $info x]
      set newY [dict get $info y]
      
      # Calculate X movement (left/right remain unchanged)
      set xDiff [expr {$newX - $originalX}]
      if {abs($xDiff) > 1e-6} {  # Consider as movement if difference is significant
        if {$xDiff > 0} {
          lappend result [list $memName "right" $xDiff]
        } else {
          lappend result [list $memName "left" [expr {abs($xDiff)}]]
        }
      }
      
      # Calculate Y movement (using up/down instead of top/bottom)
      set yDiff [expr {$newY - $originalY}]
      if {abs($yDiff) > 1e-6} {  # Consider as movement if difference is significant
        if {$yDiff > 0} {
          lappend result [list $memName "up" $yDiff]
        } else {
          lappend result [list $memName "down" [expr {abs($yDiff)}]]
        }
      }
    }
  }

  return $result
}

