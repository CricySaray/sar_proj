# TO_IMPROVE
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

  # Parse specification regions and calculate combined bounding box
  set specRegionList [list]
  set combinedRx [expr {1e20}]
  set combinedRy [expr {1e20}]
  set combinedRx1 [expr {-1e20}]
  set combinedRy1 [expr {-1e20}]
  
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
    
    # Update combined bounding box
    set combinedRx [expr {min($combinedRx, $x)}]
    set combinedRy [expr {min($combinedRy, $y)}]
    set combinedRx1 [expr {max($combinedRx1, $x1)}]
    set combinedRy1 [expr {max($combinedRy1, $y1)}]
  }
  
  # Calculate region divisions for keeping relative positions
  set regionWidth [expr {$combinedRx1 - $combinedRx}]
  set regionHeight [expr {$combinedRy1 - $combinedRy}]
  set thirdWidth [expr {$regionWidth / 3.0}]
  set thirdHeight [expr {$regionHeight / 3.0}]

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

    # Determine general area within combined region to prevent large movements
    set generalAreaX "middle"
    if {$centerX < $combinedRx + $thirdWidth} {
      set generalAreaX "left"
    } elseif {$centerX > $combinedRx1 - $thirdWidth} {
      set generalAreaX "right"
    }
    
    set generalAreaY "middle"
    if {$centerY < $combinedRy + $thirdHeight} {
      set generalAreaY "bottom"
    } elseif {$centerY > $combinedRy1 - $thirdHeight} {
      set generalAreaY "top"
    }
    set generalArea [list $generalAreaX $generalAreaY]

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

    # Save rectangle information including original position and general area
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
      generalArea $generalArea \
      orient $memOrient \
      refDir $refDir \
    ]

    if {$debug} {
      puts "Rectangle $memName info: region=$memRect, general area=[lindex $generalArea 0],[lindex $generalArea 1], refDir=$refDir"
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
    set generalArea [dict get $info generalArea]
    lassign $generalArea areaX areaY

    if {$debug} {
      puts "Processing rectangle $memName (general area: $areaX,$areaY) with reference direction: $refDir"
    }

    # Calculate initial position within specification regions
    set newX $x
    set newY $y

    # Keep within general area to prevent large movements
    set minAreaX $combinedRx
    set maxAreaX $combinedRx1
    set minAreaY $combinedRy
    set maxAreaY $combinedRy1
    
    # Apply area constraints based on general area classification
    if {$areaX eq "left"} {
      set maxAreaX [expr {$combinedRx + $thirdWidth + $width}]
    } elseif {$areaX eq "right"} {
      set minAreaX [expr {$combinedRx1 - $thirdWidth - $width}]
    }
    
    if {$areaY eq "bottom"} {
      set maxAreaY [expr {$combinedRy + $thirdHeight + $height}]
    } elseif {$areaY eq "top"} {
      set minAreaY [expr {$combinedRy1 - $thirdHeight - $height}]
    }

    # Check if on region boundary, move to inner boundary if needed but stay in general area
    foreach specRegion $specRegionList {
      lassign $specRegion rx ry rx1 ry1
      
      # Left boundary check with area constraint
      if {$newX < $rx} {
        set newX $rx
      }
      if {$newX < $minAreaX} {
        set newX $minAreaX
      }
      
      # Right boundary check with area constraint
      if {$newX + $width > $rx1} {
        set newX [expr {$rx1 - $width}]
      }
      if {$newX + $width > $maxAreaX} {
        set newX [expr {$maxAreaX - $width}]
      }
      
      # Bottom boundary check with area constraint
      if {$newY < $ry} {
        set newY $ry
      }
      if {$newY < $minAreaY} {
        set newY $minAreaY
      }
      
      # Top boundary check with area constraint
      if {$newY + $height > $ry1} {
        set newY [expr {$ry1 - $height}]
      }
      if {$newY + $height > $maxAreaY} {
        set newY [expr {$maxAreaY - $height}]
      }
    }

    # Adjust position based on already placed rectangles to prevent overlaps
    set overlapFound 1
    set iteration 0
    set maxIterations 20  ;# Prevent infinite loops
    while {$overlapFound && $iteration < $maxIterations} {
      set overlapFound 0
      set iteration [expr {$iteration + 1}]
      
      foreach placedMem [dict keys $placedRects] {
        set placedInfo [dict get $placedRects $placedMem]
        set placedX [dict get $placedInfo x]
        set placedY [dict get $placedInfo y]
        set placedWidth [dict get $placedInfo width]
        set placedHeight [dict get $placedInfo height]
        set placedRefDir [dict get $placedInfo refDir]

        # Check for overlap
        set overlap [expr {
          $newX < $placedX + $placedWidth &&
          $newX + $width > $placedX &&
          $newY < $placedY + $placedHeight &&
          $newY + $height > $placedY
        }]

        if {$overlap} {
          set overlapFound 1
          if {$debug} {
            puts "Overlap detected between $memName and $placedMem, adjusting position..."
          }

          # Get relative position
          set pos [dict get $relativePositions $memName $placedMem]

          # Adjust based on relative position to resolve overlap
          switch $pos {
            "left" {
              # Move left to resolve overlap
              set requiredX [expr {$placedX - $width - $minSpacing}]
              if {$requiredX >= $minAreaX && $requiredX < $newX} {
                set newX $requiredX
              } else {
                # If can't move left enough, try moving up/down
                set verticalSpace [expr {max($placedY - ($newY + $height), ($newY - ($placedY + $placedHeight)))}]
                if {$verticalSpace < $minSpacing} {
                  set needed [expr {$minSpacing - $verticalSpace}]
                  if {$newY + $height + $needed + $placedHeight <= $maxAreaY} {
                    set newY [expr {$newY + $needed}]
                  } elseif {$newY - $needed >= $minAreaY} {
                    set newY [expr {$newY - $needed}]
                  } else {
                    error "Cannot resolve overlap between $memName and $placedMem without moving outside general area"
                  }
                }
              }
            }
            "right" {
              # Move right to resolve overlap
              set requiredX [expr {$placedX + $placedWidth + $minSpacing}]
              if {$requiredX + $width <= $maxAreaX && $requiredX > $newX} {
                set newX $requiredX
              } else {
                # If can't move right enough, try moving up/down
                set verticalSpace [expr {max($placedY - ($newY + $height), ($newY - ($placedY + $placedHeight)))}]
                if {$verticalSpace < $minSpacing} {
                  set needed [expr {$minSpacing - $verticalSpace}]
                  if {$newY + $height + $needed + $placedHeight <= $maxAreaY} {
                    set newY [expr {$newY + $needed}]
                  } elseif {$newY - $needed >= $minAreaY} {
                    set newY [expr {$newY - $needed}]
                  } else {
                    error "Cannot resolve overlap between $memName and $placedMem without moving outside general area"
                  }
                }
              }
            }
            "above" {
              # Move up to resolve overlap
              set requiredY [expr {$placedY + $placedHeight + $minSpacing}]
              if {$requiredY + $height <= $maxAreaY && $requiredY > $newY} {
                set newY $requiredY
              } else {
                # If can't move up enough, try moving left/right
                set horizontalSpace [expr {max($placedX - ($newX + $width), ($newX - ($placedX + $placedWidth)))}]
                if {$horizontalSpace < $minSpacing} {
                  set needed [expr {$minSpacing - $horizontalSpace}]
                  if {$newX + $width + $needed + $placedWidth <= $maxAreaX} {
                    set newX [expr {$newX + $needed}]
                  } elseif {$newX - $needed >= $minAreaX} {
                    set newX [expr {$newX - $needed}]
                  } else {
                    error "Cannot resolve overlap between $memName and $placedMem without moving outside general area"
                  }
                }
              }
            }
            "below" {
              # Move down to resolve overlap
              set requiredY [expr {$placedY - $height - $minSpacing}]
              if {$requiredY >= $minAreaY && $requiredY < $newY} {
                set newY $requiredY
              } else {
                # If can't move down enough, try moving left/right
                set horizontalSpace [expr {max($placedX - ($newX + $width), ($newX - ($placedX + $placedWidth)))}]
                if {$horizontalSpace < $minSpacing} {
                  set needed [expr {$minSpacing - $horizontalSpace}]
                  if {$newX + $width + $needed + $placedWidth <= $maxAreaX} {
                    set newX [expr {$newX + $needed}]
                  } elseif {$newX - $needed >= $minAreaX} {
                    set newX [expr {$newX - $needed}]
                  } else {
                    error "Cannot resolve overlap between $memName and $placedMem without moving outside general area"
                  }
                }
              }
            }
            "overlap" {
              # Complete overlap, try to move in the direction with most space
              set spaceRight [expr {$maxAreaX - ($newX + $width)}]
              set spaceLeft [expr {$newX - $minAreaX}]
              set spaceUp [expr {$maxAreaY - ($newY + $height)}]
              set spaceDown [expr {$newY - $minAreaY}]
              
              set maxSpace [max($spaceRight, $spaceLeft, $spaceUp, $spaceDown)]
              
              if {$maxSpace < $minSpacing} {
                error "Cannot resolve overlap between $memName and $placedMem - insufficient space in general area"
              }
              
              if {$maxSpace == $spaceRight} {
                set newX [expr {$newX + $minSpacing}]
              } elseif {$maxSpace == $spaceLeft} {
                set newX [expr {$newX - $minSpacing}]
              } elseif {$maxSpace == $spaceUp} {
                set newY [expr {$newY + $minSpacing}]
              } else {
                set newY [expr {$newY - $minSpacing}]
              }
            }
          }

          # After adjustment, check if still in general area
          if {$newX < $minAreaX || $newX + $width > $maxAreaX ||
              $newY < $minAreaY || $newY + $height > $maxAreaY} {
            error "Adjusting $memName to avoid overlap would move it outside general area"
          }

          # Check reference direction alignment after overlap resolution
          if {($pos eq "left" || $pos eq "right") && $refDir eq $placedRefDir} {
            if {$refDir eq "top"} {
              # Align bottom edges
              set newY [expr {$placedY + $placedHeight - $height}]
            } elseif {$refDir eq "bottom"} {
              # Align top edges
              set newY $placedY
            }
          }
        }
      }
    }

    if {$iteration >= $maxIterations && $overlapFound} {
      error "Failed to resolve overlaps for $memName after $maxIterations iterations"
    }

    # Check reference direction edge distances
    foreach placedMem [dict keys $placedRects] {
      set placedInfo [dict get $placedRects $placedMem]
      set placedX [dict get $placedInfo x]
      set placedY [dict get $placedInfo y]
      set placedWidth [dict get $placedInfo width]
      set placedHeight [dict get $placedInfo height]
      set placedRefDir [dict get $placedInfo refDir]

      # Calculate reference direction edge positions
      switch $refDir {
        "top" {
          set refY [expr {$newY + $height}]
        }
        "bottom" {
          set refY $newY
        }
        "left" {
          set refX $newX
        }
        "right" {
          set refX [expr {$newX + $width}]
        }
      }

      switch $placedRefDir {
        "top" {
          set placedRefY [expr {$placedY + $placedHeight}]
        }
        "bottom" {
          set placedRefY $placedY
        }
        "left" {
          set placedRefX $placedX
        }
        "right" {
          set placedRefX [expr {$placedX + $placedWidth}]
        }
      }

      # Calculate distance between reference direction edges
      set refDist 0
      if {($refDir eq "left" || $refDir eq "right") && 
          ($placedRefDir eq "left" || $placedRefDir eq "right")} {
        set refDist [expr {abs($refX - $placedRefX)}]
      } elseif {($refDir eq "top" || $refDir eq "bottom") && 
                ($placedRefDir eq "top" || $placedRefDir eq "bottom")} {
        set refDist [expr {abs($refY - $placedRefY)}]
      }

      # Check if reference edge distance is greater than minimum spacing
      if {$refDist > 0 && $refDist <= $minSpacing} {
        puts "Warning: Reference edge distance between $memName and $placedMem is too small: $refDist, should be greater than $minSpacing"
      }
    }

    # Save placed rectangle information
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
      puts "Rectangle $memName placed at: ([list $newX $newY [expr {$newX + $width}] [expr {$newY + $height}]]), moved [expr {abs($newX - $originalX)}] in X, [expr {abs($newY - $originalY)}] in Y"
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
    foreach memName $rectNames {
      set info [dict get $placedRects $memName]
      set originalX [dict get $info originalX]
      set originalY [dict get $info originalY]
      set newX [dict get $info x]
      set newY [dict get $info y]
      
      # Calculate X movement
      set xDiff [expr {$newX - $originalX}]
      if {abs($xDiff) > 1e-6} {
        if {$xDiff > 0} {
          lappend result [list $memName "right" $xDiff]
        } else {
          lappend result [list $memName "left" [expr {abs($xDiff)}]]
        }
      }
      
      # Calculate Y movement
      set yDiff [expr {$newY - $originalY}]
      if {abs($yDiff) > 1e-6} {
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

