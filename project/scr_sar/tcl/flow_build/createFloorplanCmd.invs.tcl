#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/31 20:26:07 Sunday
# label     : flow_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
# descrip   : Create the core and die area sizes of a simple Floorplan through various parameters, with the ability to specify the coreToDie distance.
# return    : string of floorplan cmd
# ref       : link url
# --------------------------
source ../packages/adjust_rectangle.package.tcl; # adjust_rectangle
source ../packages/adjust_to_multiple_of_num.package.tcl; # adjust_to_multiple_of_num
proc createFloorplanCmd {{memAndIPsubClass block} {IOinstSubClassName padAreaIO} {coreAreaSiteName "sc9mc_cln40lp"} {coreDensity 0.55} {coreAspectRatio 1} {specifyWidthOrHeight {die height 2285.54}} {adjustPolicy "roundUp"} {adjustForDieOfMultiple 1.00}} {
  set allIPmemInst [dbget [dbget -regexp top.insts.cell.subClass $memAndIPsubClass -p2].name]
  set padHeight [lindex {*}[dbget [dbget top.insts.cell.subClass $IOinstSubClassName -p].size -u] 1]
  set coreToDieDistance [expr $padHeight + 27]
  set siteHW {*}[dbget [dbget head.sites.name $coreAreaSiteName -p].size]
  set rectangleInfo [createRectangle -instsSpecialSuchAsIPAndMem $allIPmemInst -coreWHMultipliers $siteHW -coreToDieDistance $coreToDieDistance -coreInstsCellsubClass {core} -coreDensity $coreDensity -coreAspectRatio $coreAspectRatio -fixedDim $specifyWidthOrHeight -adjustPolicy $adjustPolicy]
  lassign $rectangleInfo dieAreaLeftBottomPointAndRightTopPoint coreAreaLeftBottomPointAndRightTopPoint finalCoreToDie
  set die_box [lmap tempNum [join $dieAreaLeftBottomPointAndRightTopPoint] { adjust_to_multiple_of_num $tempNum $adjustForDieOfMultiple roundUp }]
  set core_box [join $coreAreaLeftBottomPointAndRightTopPoint]
  set off_value [expr 0 - $padHeight]
  set io_box [adjust_rectangle $die_box $off_value]
  set floorplan_b [list {*}$die_box {*}$io_box {*}$core_box]
  set floorplan_cmd "floorplan -noSnapToGrid -flip f -b \{$floorplan_b\}"
  return $floorplan_cmd
}

#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/31 18:30:25 Sunday
# label     : gui_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : The 'createRectangle' procedure calculates and returns dimensions of outer and inner rectangles based on parameters like 
#             special instances, width/height multipliers, core-to-die distances, and constraints, ensuring inner dimensions adhere 
#             to specified multipliers.
# arguments : instsSpecialSuchAsIPAndMem  : list containing special instances (like IP and memory), which can be normal instances or placeToDie sublists  
#             coreWHMultipliers           : list of 2 positive numbers (width_multiplier height_multiplier) to constrain dimensions as their integer multiples  
#             coreToDieDistance           : 1 or 4 positive numbers specifying distance from core to die (single value for all, or 4 values for top/bottom/left/right)  
#             coreInstsCellsubClass       : non-empty list of subclass names that core instances belong to  
#             coreDensity                 : number between 0 and 1 specifying the density of the core area  
#             coreAspectRatio             : positive number specifying the aspect ratio of core area (width/height)  
#             fixedDim                    : optional 3-element list {die|core width|height value} to specify fixed dimension of outer (die) or inner (core) rectangle  
#             adjustPolicy                : "roundUp" or "roundDown" (default "roundUp") specifying adjustment policy for fixed dimensions to fit multipliers
#             debug                       : 0 or 1 (default 0) specifying whether to output debug information  
# return    : [list $dieAreaLeftBottomPointAndRightTopPoint $coreAreaLeftBottomPointAndRightTopPoint $finalCoreToDie]
#               $dieAreaLeftBottomPointAndRightTopPoint   : The coordinates of the bottom-left and top-right corners of the die area
#               $coreAreaLeftBottomPointAndRightTopPoint  : The coordinates of the bottom-left and top-right corners of the core area
#               $finalCoreToDie                           : The final sizes of coreToDie in four directions (in the order of top, bottom, left, right)
# ref       : link url
# --------------------------
### usage of proc:createRectangle : for example: 

proc createRectangle {args} {
  set instsSpecialSuchAsIPAndMem {inst1 inst2 inst3 ...}
  set coreWHMultipliers          {*}[dbget [dbget head.sites.name sc9mc_cln40lp -p].size]
  set coreToDieDistance          [expr {[lindex {*}[dbget [dbget top.insts.cell.subClass padAreaIO -p].size -u] 1] + 27}]
    # this num:27 is distance from edge of core to edge of IO area
  set coreInstsCellsubClass      {core}
  set coreDensity                0.55
  set coreAspectRatio            1
  set fixedDim                   {} ; # for example : {die height 2285}
  set adjustPolicy               "roundUp"
  set prioritizeAspectRatio      0
  set debug                      0
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  # New parameter 'fixedDim' format: {die|core width|height value}, e.g., {die width 2014}
  # New parameter: 'prioritizeAspectRatio' 1=aspect ratio priority, 0=area priority when fixedDim is set
  # ============================================================================
  # Step 1: Error Defense - Validate All Parameters
  # ============================================================================
  # Validate instsSpecialSuchAsIPAndMem (list of normal insts or placeToDie sublists)
  if {![llength $instsSpecialSuchAsIPAndMem]} {
    error "proc createRectangle: ERROR: Parameter 'instsSpecialSuchAsIPAndMem' cannot be empty"
  }
  foreach item $instsSpecialSuchAsIPAndMem {
    set itemLen [llength $item]
    if {$itemLen == 0} {
      error "proc createRectangle: ERROR: Empty item found in 'instsSpecialSuchAsIPAndMem'"
    } elseif {$itemLen == 1} {
      set instName [lindex $item 0]
      if {[string match "* *" $instName]} {
        error "proc createRectangle: ERROR: Normal instance name '$instName' cannot contain spaces"
      }
    } else {
      if {$itemLen < 3} {
        error "proc createRectangle: ERROR: PlaceToDie sublist '$item' needs at least 3 elements"
      }
      lassign $item subInstName subPlaceType subPosType
      
      if {[string match "* *" $subInstName]} {
        error "proc createRectangle: ERROR: PlaceToDie instance name '$subInstName' cannot contain spaces"
      }
      if {$subPlaceType ne "placeToDie"} {
        error "proc createRectangle: ERROR: PlaceToDie sublist '$item' must have 'placeToDie' as 2nd element"
      }
      if {$subPosType ni {corner edge}} {
        error "proc createRectangle: ERROR: PlaceToDie sublist '$item' 3rd element must be 'corner' or 'edge'"
      }
      if {$subPosType eq "edge" && $itemLen < 4} {
        error "proc createRectangle: ERROR: 'edge' type sublist '$item' needs 4th element (width/height)"
      }
      if {$subPosType eq "edge" && [lindex $item 3] ni {width height}} {
        error "proc createRectangle: ERROR: PlaceToDie 'edge' sublist '$item' 4th element must be 'width' or 'height'"
      }
    }
  }

  # Validate coreWHMultipliers (list of 2 positive numbers: width_multiplier height_multiplier)
  if {[llength $coreWHMultipliers] != 2} {
    error "proc createRectangle: ERROR: 'coreWHMultipliers' must be list of 2 elements (got: [llength $coreWHMultipliers])"
  }
  lassign $coreWHMultipliers multiWidth multiHeight
  if {![string is double -strict $multiWidth] || $multiWidth <= 0} {
    error "proc createRectangle: ERROR: Width multiplier in 'coreWHMultipliers' must be positive (got: $multiWidth)"
  }
  if {![string is double -strict $multiHeight] || $multiHeight <= 0} {
    error "proc createRectangle: ERROR: Height multiplier in 'coreWHMultipliers' must be positive (got: $multiHeight)"
  }

  # Validate coreToDieDistance (single positive or list of 4 positives: top bottom left right)
  set initTd 0.0; set initBd 0.0; set initLd 0.0; set initRd 0.0
  if {[llength $coreToDieDistance] == 1} {
    set singleVal [lindex $coreToDieDistance 0]
    if {![string is double -strict $singleVal] || $singleVal <= 0} {
      error "proc createRectangle: ERROR: 'coreToDieDistance' single value must be positive (got: $singleVal)"
    }
    set initTd $singleVal; set initBd $singleVal; set initLd $singleVal; set initRd $singleVal
  } elseif {[llength $coreToDieDistance] == 4} {
    lassign $coreToDieDistance initTd initBd initLd initRd
    foreach val [list $initTd $initBd $initLd $initRd] dir [list top bottom left right] {
      if {![string is double -strict $val] || $val <= 0} {
        error "proc createRectangle: ERROR: '$dir' value in 'coreToDieDistance' must be positive (got: $val)"
      }
    }
  } else {
    error "proc createRectangle: ERROR: 'coreToDieDistance' must be 1 or 4 elements (got: [llength $coreToDieDistance])"
  }

  # Validate coreInstsCellsubClass (non-empty list of class names)
  if {![llength $coreInstsCellsubClass]} {
    error "proc createRectangle: ERROR: Parameter 'coreInstsCellsubClass' cannot be empty"
  }
  foreach className $coreInstsCellsubClass {
    if {[string trim $className] eq ""} {
      error "proc createRectangle: ERROR: Empty class name in 'coreInstsCellsubClass'"
    }
  }

  # Validate coreDensity (0 < density < 1)
  if {![string is double -strict $coreDensity] || $coreDensity <= 0 || $coreDensity >= 1} {
    error "proc createRectangle: ERROR: 'coreDensity' must be 0 < value < 1 (got: $coreDensity)"
  }

  # Validate coreAspectRatio (positive number: width/height)
  if {![string is double -strict $coreAspectRatio] || $coreAspectRatio <= 0} {
    error "proc createRectangle: ERROR: 'coreAspectRatio' must be positive (got: $coreAspectRatio)"
  }

  # Validate fixedDim (new parameter)
  if {[llength $fixedDim] != 0 && [llength $fixedDim] != 3} {
    error "proc createRectangle: ERROR: 'fixedDim' must be empty or 3-element list (got: [llength $fixedDim])"
  }
  set fixedType ""; set fixedDir ""; set fixedVal 0.0
  if {[llength $fixedDim] == 3} {
    lassign $fixedDim fixedType fixedDir fixedVal
    if {$fixedType ni {die core}} {
      error "proc createRectangle: ERROR: 'fixedDim' first element must be 'die' or 'core' (got: $fixedType)"
    }
    if {$fixedDir ni {width height}} {
      error "proc createRectangle: ERROR: 'fixedDim' second element must be 'width' or 'height' (got: $fixedDir)"
    }
    if {![string is double -strict $fixedVal] || $fixedVal <= 0} {
      error "proc createRectangle: ERROR: 'fixedDim' third element must be positive number (got: $fixedVal)"
    }
    # Validate adjustPolicy for fixedDim
    if {$adjustPolicy ni {roundUp roundDown}} {
      error "proc createRectangle: ERROR: 'adjustPolicy' must be 'roundUp' or 'roundDown' (got: $adjustPolicy)"
    }
  }
  # Validate prioritizeAspectRatio (new parameter)
  if {$prioritizeAspectRatio ni {0 1}} {
    error "proc createRectangle: ERROR: 'prioritizeAspectRatio' must be 0 or 1 (got: $prioritizeAspectRatio)"
  }

  # ============================================================================
  # Step 2: Adjust coreToDieDistance to Match Multipliers
  # ============================================================================
  set quotientTd [expr {$initTd / $multiHeight}]
  set finalTd [expr {ceil($quotientTd) * $multiHeight}]
  
  set quotientBd [expr {$initBd / $multiHeight}]
  set finalBd [expr {ceil($quotientBd) * $multiHeight}]
  
  set quotientLd [expr {$initLd / $multiWidth}]
  set finalLd [expr {ceil($quotientLd) * $multiWidth}]
  
  set quotientRd [expr {$initRd / $multiWidth}]
  set finalRd [expr {ceil($quotientRd) * $multiWidth}]

  if {$debug} {
    puts "DEBUG: Initial coreToDieDistance: {top:$initTd bottom:$initBd left:$initLd right:$initRd}"
    puts "DEBUG: Adjusted coreToDieDistance: {top:$finalTd bottom:$finalBd left:$finalLd right:$finalRd}"
  }

  # ============================================================================
  # Step 3: Calculate Total Area of Core Instances
  # ============================================================================
  set coreTotalArea 0.0
  foreach className $coreInstsCellsubClass {
    set instNames [dbget [dbget top.insts.cell.subClass $className -p2].name]
    if {![llength $instNames]} {
      puts "WARNING: No instances found for class '$className'"
      continue
    }
    foreach inst $instNames {
      set instArea [dbget [dbget top.insts.name $inst -p].area -e]
      if {![llength $instArea] || ![string is double -strict $instArea]} {
        error "proc createRectangle: ERROR: Failed to get valid area for core instance '$inst' (class: $className)"
      }
      set coreTotalArea [expr {$coreTotalArea + $instArea}]
    }
  }
  if {$coreTotalArea <= 0} {
    error "proc createRectangle: ERROR: Total area of core instances is non-positive ($coreTotalArea)"
  }
  if {$debug} {
    puts "DEBUG: Total area of core instances: $coreTotalArea"
  }

  # ============================================================================
  # Step 4: Process instsSpecialSuchAsIPAndMem
  # ============================================================================
  set normalTotalArea 0.0
  set placeToDieTotalArea 0.0
  set placeToDieMiddleArea 0.0
  set placeToDieCache [list]

  foreach item $instsSpecialSuchAsIPAndMem {
    if {[llength $item] == 1} {
      set instName [lindex $item 0]
      set instArea [dbget [dbget top.insts.name $instName -p].area -e]
      if {![llength $instArea] || ![string is double -strict $instArea]} {
        error "proc createRectangle: ERROR: Failed to get valid area for normal instance '$instName'"
      }
      set normalTotalArea [expr {$normalTotalArea + $instArea}]
      if {$debug} {
        puts "DEBUG: Normal instance '$instName' area: $instArea (total: $normalTotalArea)"
      }
    } else {
      lassign $item instName _ posType edgeType
      set instArea [dbget [dbget top.insts.name $instName -p].area -e]
      if {![llength $instArea] || ![string is double -strict $instArea]} {
        error "proc createRectangle: ERROR: Failed to get valid area for placeToDie instance '$instName'"
      }
      set placeToDieTotalArea [expr {$placeToDieTotalArea + $instArea}]
      set instSize [dbget [dbget top.insts.name $instName -p].cell.size]
      if {[llength $instSize] != 2} {
        error "proc createRectangle: ERROR: Invalid size for placeToDie instance '$instName' (got: $instSize)"
      }
      lassign $instSize instW instH
      if {$instW <= 0 || $instH <= 0} {
        error "proc createRectangle: ERROR: Non-positive size for placeToDie instance '$instName' (w:$instW h:$instH)"
      }
      lappend placeToDieCache [list $instName $posType $edgeType $instW $instH]
      if {$debug} {
        puts "DEBUG: PlaceToDie instance '$instName' area:$instArea size:(w:$instW h:$instH) pos:$posType"
      }
    }
  }
  if {$debug} {
    puts "DEBUG: Total placeToDie instance area: $placeToDieTotalArea"
    puts "DEBUG: Total normal instance area: $normalTotalArea"
  }

  # ============================================================================
  # Step 5: Calculate PlaceToDie Instance Area in Outer-Inner Gap
  # ============================================================================
  foreach cacheEntry $placeToDieCache {
    lassign $cacheEntry instName posType edgeType instW instH
    set gapArea 0.0

    if {$posType eq "corner"} {
      if {$instW >= $finalLd && $instH >= $finalBd} {
        set bottomRectArea [expr {$instW * $finalBd}]
        set leftRectArea [expr {($instH - $finalBd) * $finalLd}]
        set gapArea [expr {$bottomRectArea + $leftRectArea}]
      } else {
        set overlapW [expr {min($instW, $finalLd)}]
        set overlapH [expr {min($instH, $finalBd)}]
        set gapArea [expr {$overlapW * $overlapH}]
      }
    } elseif {$posType eq "edge"} {
      if {$edgeType eq "width"} {
        set overlapH [expr {min($instH, $finalBd)}]
        set gapArea [expr {$instW * $overlapH}]
      } else {
        set overlapW [expr {min($instW, $finalLd)}]
        set gapArea [expr {$overlapW * $instH}]
      }
    }

    set placeToDieMiddleArea [expr {$placeToDieMiddleArea + $gapArea}]
    if {$debug} {
      puts "DEBUG: PlaceToDie '$instName' gap area: $gapArea (total gap: $placeToDieMiddleArea)"
    }
  }

  set placeToDieRemainArea [expr {$placeToDieTotalArea - $placeToDieMiddleArea}]
  if {$placeToDieRemainArea < 0} {
    error "proc createRectangle: ERROR: Negative remaining area for placeToDie instances (total:$placeToDieTotalArea gap:$placeToDieMiddleArea)"
  }

  # ============================================================================
  # Step 6: Calculate Inner Rectangle Dimensions (Base Calculation)
  # ============================================================================
  set coreScaledArea [expr {$coreTotalArea / $coreDensity}]
  set innerTotalArea [expr {$coreScaledArea + $normalTotalArea + $placeToDieRemainArea}]
  if {$innerTotalArea <= 0} {
    error "proc createRectangle: ERROR: Non-positive inner rectangle area ($innerTotalArea)"
  }

  # Base dimensions without fixedDim
  set innerW [expr {sqrt($innerTotalArea * $coreAspectRatio)}]
  set innerH [expr {sqrt($innerTotalArea / $coreAspectRatio)}]
  if {$innerW <= 0 || $innerH <= 0} {
    error "proc createRectangle: ERROR: Invalid base inner dimensions (w:$innerW h:$innerH)"
  }

  # ============================================================================
  # Step 7: Handle fixedDim Parameter (Enforce Multiples and Adjust Dimensions)
  # ============================================================================
  set outerW [expr {$innerW + $finalLd + $finalRd}]
  set outerH [expr {$innerH + $finalBd + $finalTd}]

  if {[llength $fixedDim] == 3} {
    set multiplier [expr {$fixedDir eq "width" ? $multiWidth : $multiHeight}]
    # Adjust fixed value to be multiple of multiplier
    if {$adjustPolicy eq "roundUp"} {
      set adjustedFixedVal [expr {ceil($fixedVal / $multiplier) * $multiplier}]
    } else {
      set adjustedFixedVal [expr {floor($fixedVal / $multiplier) * $multiplier}]
    }
    if {$adjustedFixedVal <= 0} {
      error "proc createRectangle: ERROR: Adjusted fixed value is non-positive ($adjustedFixedVal)"
    }

    # Apply fixed dimension and recalculate related dimension
    if {$fixedType eq "core"} {
      if {$fixedDir eq "width"} {
        set innerW $adjustedFixedVal
        # Calculate based on priority: aspect ratio or area
        if {$prioritizeAspectRatio} {
          # Prioritize aspect ratio: H = W / aspect ratio
          set idealH [expr {$innerW / $coreAspectRatio}]
        } else {
          # Prioritize area: H = total inner area / W
          set idealH [expr {$innerTotalArea / $innerW}]
        }
        # Adjust to multiHeight multiple
        set scaleH [expr {round($idealH / $multiHeight)}]
        set innerH [expr {$scaleH * $multiHeight}]
      } else {
        set innerH $adjustedFixedVal
        # Calculate based on priority: aspect ratio or area
        if {$prioritizeAspectRatio} {
          # Prioritize aspect ratio: W = H * aspect ratio
          set idealW [expr {$innerH * $coreAspectRatio}]
        } else {
          # Prioritize area: W = total inner area / H
          set idealW [expr {$innerTotalArea / $innerH}]
        }
        # Adjust to multiWidth multiple
        set scaleW [expr {round($idealW / $multiWidth)}]
        set innerW [expr {$scaleW * $multiWidth}]
      }
    } else {  ; # fixedType eq "die"
      if {$fixedDir eq "width"} {
        set outerW $adjustedFixedVal
        set innerW [expr {$outerW - $finalLd - $finalRd}]
        # Ensure innerW is multiple of multiWidth
        set scaleW [expr {round($innerW / $multiWidth)}]
        set innerW [expr {$scaleW * $multiWidth}]
        # Recalculate H based on priority
        if {$prioritizeAspectRatio} {
          set idealH [expr {$innerW / $coreAspectRatio}]
        } else {
          set idealH [expr {$innerTotalArea / $innerW}]
        }
        set scaleH [expr {round($idealH / $multiHeight)}]
        set innerH [expr {$scaleH * $multiHeight}]
      } else {
        set outerH $adjustedFixedVal
        set innerH [expr {$outerH - $finalBd - $finalTd}]
        # Ensure innerH is multiple of multiHeight
        set scaleH [expr {round($innerH / $multiHeight)}]
        set innerH [expr {$scaleH * $multiHeight}]
        # Recalculate W based on priority
        if {$prioritizeAspectRatio} {
          set idealW [expr {$innerH * $coreAspectRatio}]
        } else {
          set idealW [expr {$innerTotalArea / $innerH}]
        }
        set scaleW [expr {round($idealW / $multiWidth)}]
        set innerW [expr {$scaleW * $multiWidth}]
      }
    }

    # Recalculate outer dimensions after inner adjustment
    set outerW [expr {$innerW + $finalLd + $finalRd}]
    set outerH [expr {$innerH + $finalBd + $finalTd}]

    if {$debug} {
      puts "DEBUG: Applied fixedDim {[join $fixedDim]} -> adjusted to $adjustedFixedVal"
      puts "DEBUG: Aspect ratio priority: $prioritizeAspectRatio"
      puts "DEBUG: Final inner dimensions (multiplier-constrained) (w:$innerW h:$innerH)"
      puts "DEBUG: Final outer dimensions (w:$outerW h:$outerH)"
    }
  }


  # ============================================================================
  # Step 8: Validate Rectangle Nesting
  # ============================================================================
  set innerTrX [expr {$finalLd + $innerW}]
  set innerTrY [expr {$finalBd + $innerH}]
  if {$innerTrX > $outerW || $innerTrY > $outerH} {
    error "proc createRectangle: ERROR: Inner rectangle exceeds outer rectangle (innerTr:{$innerTrX $innerTrY} outerTr:{$outerW $outerH})"
  }
  if {$innerW >= $outerW || $innerH >= $outerH} {
    error "proc createRectangle: ERROR: Inner dimensions not smaller than outer (inner:w$innerW h$innerH outer:w$outerW h$outerH)"
  }

  if {$debug} {
    puts "DEBUG: Outer rectangle: bottom-left {0 0} top-right {$outerW $outerH}"
    puts "DEBUG: Inner rectangle: bottom-left {$finalLd $finalBd} top-right {$innerTrX $innerTrY}"
  }

  # ============================================================================
  # Step 9: Organize and Return Result with 3 decimal places
  # ============================================================================
  # Format all numeric values to 3 decimal places
  set fmt "%.3f"
  set outerBlX [format $fmt 0.0]
  set outerBlY [format $fmt 0.0]
  set outerTrX [format $fmt $outerW]
  set outerTrY [format $fmt $outerH]
  
  set innerBlX [format $fmt $finalLd]
  set innerBlY [format $fmt $finalBd]
  set innerTrX [format $fmt $innerTrX]
  set innerTrY [format $fmt $innerTrY]
  
  set finalTdFmt [format $fmt $finalTd]
  set finalBdFmt [format $fmt $finalBd]
  set finalLdFmt [format $fmt $finalLd]
  set finalRdFmt [format $fmt $finalRd]
  
  set dieAreaLeftBottomPointAndRightTopPoint [list [list $outerBlX $outerBlY] [list $outerTrX $outerTrY]]
  set coreAreaLeftBottomPointAndRightTopPoint [list [list $innerBlX $innerBlY] [list $innerTrX $innerTrY]]
  set finalCoreToDie [list $finalTdFmt $finalBdFmt $finalLdFmt $finalRdFmt]
  
  return [list $dieAreaLeftBottomPointAndRightTopPoint $coreAreaLeftBottomPointAndRightTopPoint $finalCoreToDie]
}
define_proc_arguments createRectangle \
  -info "create rectangle for floorplan"\
  -define_args {
    {-instsSpecialSuchAsIPAndMem "list containing special instances (like IP and memory), which can be normal instances or placeToDie sublists  " AList list require}
    {-coreWHMultipliers "list of 2 positive numbers (width_multiplier height_multiplier) to constrain dimensions as their integer multiples  " AList list require}
    {-coreToDieDistance "1 or 4 positive numbers specifying distance from core to die (single value for all, or 4 values for top/bottom/left/right)  " AList list require}
    {-coreInstsCellsubClass "non-empty list of subclass names that core instances belong to  " AList list require}
    {-coreDensity "number between 0 and 1 specifying the density of the core area  " AFloat float require}
    {-coreAspectRatio "positive number specifying the aspect ratio of core area (width/height)  " AInt int require}
    {-fixedDim "3-element list {die|core width|height value} to specify fixed dimension of outer (die) or inner (core) rectangle  " AList list optional}
    {-adjustPolicy "\"roundUp\" or \"roundDown\" (default \"roundUp\") specifying adjustment policy for fixed dimensions to fit multipliers" AString string optional}
    {-prioritizeAspectRatio "1=aspect ratio priority, 0=area priority when fixedDim is set" "" boolean optional}
    {-debug "0 or 1 (default 0) specifying whether to output debug information  " "" boolean optional}
  }
