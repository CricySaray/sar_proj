#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/06 18:01:50 Saturday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
source ./process_polygon.invsGUI.tcl; # process_polygon
proc genCmd_addIoInstance {args} {
  set refnameList {{name1 {DVDD_AON DVSS DVDDH_AON DVSSH} clockwise}}
  set typeMapList {{DVDD_ONO PVDD_11_11_NT_DR} {DVDD_AON PVDD_11_11_NT_DR} {DVDDH_ONO PDVDD_33_33_NT_DR} {DVDDH_AON PDVDD_33_33_NT_DR} {DVSS PVSS_11_11_NT_DR} {DVSSH PDVSS_33_33_NT_DR}}
  set polygonPoints [process_polygon {*}[dbShape [dbget top.fplan.box] -output polygon]]
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set results [fomatOptions_forCmd_addIoInstance_withRefInst_and_IoCelltype $refnameList $typeMapList $polygonPoints 1]
  set cmdList [list ]
  foreach temp_result $results {
    lassign $temp_result celltype instname refInst direction
    if {$direction == "clockwise"} {
      lappend cmdList "addIoInstance -cell $celltype -inst $instname -refInst $refInst"
    } elseif {$direction == "counter_clockwise"} {
      lappend cmdList "addIoInstance -ccw -cell $celltype -inst $instname -refInst $refInst"
    }
  }
  return $cmdList
}
define_proc_arguments genCmd_addIoInstance \
  -info "generate cmd for addIoInstance"\
  -define_args {
    {-refnameList "specify the list of refname"  AList list optional}
    {-typeMapList "specify the map list of type" AList list optional}
    {-polygonPoints "specify the polygon points" AList list optional}
  }

#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/06 18:01:46 Saturday
# label     : atomic_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : sorts refnames based on their proximity to a polygon's contour, processes type mappings according to specified directions, validates inputs, 
#             and generates a formatted result list with optional debug information.
# return    : list, for example {{celltype1 "DVDD_1" refInstname direction} {celltype2 "DVSS_2" refInstname direction}}
# ref       : link url
# --------------------------
proc fomatOptions_forCmd_addIoInstance_withRefInst_and_IoCelltype {refnameList typeMapList polygonPoints {debug 0}} {
  # Validate input parameters
  if {![validate_refname_list $refnameList]} {
    error "Invalid format for refnameList"
  }
  if {![validate_typemap_list $typeMapList]} {
    error "Invalid format for typeMapList"
  }
  if {![validate_polygon_points $polygonPoints]} {
    error "Invalid format for polygonPoints"
  }
  
  # Print debug info
  if {$debug} {
    puts "Debug mode enabled"
    puts "Number of refnames: [llength $refnameList]"
    puts "Number of type mappings: [llength $typeMapList]"
    puts "Number of polygon points: [llength $polygonPoints]"
  }
  
  # Check if polygon points are in clockwise order
  if {![is_clockwise $polygonPoints]} {
    error "Polygon points must be in clockwise order"
  }
  
  # Get center points for all refnames and store them
  set refnameCenters [list]
  foreach refData $refnameList {
    set refname [lindex $refData 0]
    if {$debug} {
      puts "Getting center point for refname: $refname"
    }
    
    # Get center point coordinates with error checking
    if {[catch {dbget top.insts.name $refname -p} instPath]} {
      error "Failed to get instance path for refname: $refname - $instPath"
    }
    
    if {[llength $instPath] == 0} {
      error "No instance found for refname: $refname"
    }
    
    if {[catch {dbget [lindex $instPath 0].box} boxCoords]} {
      error "Failed to get box coordinates for refname: $refname - $boxCoords"
    }
    
    if {[catch {db_rect -center $boxCoords} centerPoint]} {
      error "Failed to calculate center point for refname: $refname - $centerPoint"
    }
    
    if {[llength $centerPoint] != 2} {
      error "Invalid center point format for refname: $refname. Expected {x y}, got $centerPoint"
    }
    
    lappend refnameCenters [list $refname $centerPoint]
    
    if {$debug} {
      puts "Found center point for $refname: $centerPoint"
    }
  }
  
  # Adjust refname order according to polygon contour
  if {$debug} {
    puts "Sorting refnames according to polygon contour..."
  }
  # Get sorted refname strings first
  set sortedRefnameStrs [sort_refnames_by_polygon $refnameCenters $polygonPoints $debug]
  
  # Restore to original sublist format based on sorted refname strings
  set sortedRefnames [list]
  foreach refname $sortedRefnameStrs {
    # 使用-index 0参数精确搜索第一个元素匹配的子列表
    set refData [lsearch -inline -exact -index 0 $refnameList $refname]
    lappend sortedRefnames $refData
  }
  
  if {$debug} {
    puts "Sorted refname data: $sortedRefnames"
  }
  
  # Process each refname data and generate result
  set result [list]
  set num 1
  
  foreach refData $sortedRefnames {
    set refname [lindex $refData 0]
    
    set types [lindex $refData 1]
    set direction [expr {[llength $refData] >= 3 ? [lindex $refData 2] : "clockwise"}]
    
    # Validate direction
    if {$direction ni {clockwise counter_clockwise}} {
      error "Invalid direction '$direction' for refname: $refname. Must be 'clockwise' or 'counter_clockwise'"
    }
    
    # Determine if we need to reverse the types list based on direction
    if {[llength $types] > 1 && $direction eq "clockwise"} {
      set processTypes [lreverse $types]
      if {$debug} {
        puts "Reversing types for $refname (clockwise direction). Original: $types, Reversed: $processTypes"
      }
    } else {
      set processTypes $types
      if {$debug} {
        puts "Processing types for $refname in original order: $processTypes"
      }
    }
    
    # Process each type
    foreach type $processTypes {
      # 使用-index 0参数精确搜索类型映射
      set mapIndex [lsearch -exact -index 0 $typeMapList $type]
      if {$mapIndex == -1} {
        error "No mapping found for type: $type (refname: $refname)"
      }
      set celltype [lindex [lindex $typeMapList $mapIndex] 1]
      
      # Create result sublist
      set resultItem [list $celltype "${type}_$num" $refname $direction]
      lappend result $resultItem
      
      if {$debug} {
        puts "Added result item: $resultItem"
      }
      
      incr num
    }
  }
  
  if {$debug} {
    puts "Processing complete. Total items in result: [llength $result]"
  }
  
  return $result
}

# 以下验证函数和辅助函数保持不变
proc validate_refname_list {refnameList} {
  if {[llength $refnameList] == 0} {
    return 0
  }
  
  foreach item $refnameList {
    if {[llength $item] < 2} {
      return 0
    }
    
    set refname [lindex $item 0]
    set types [lindex $item 1]
    
    if {$refname eq "" || [llength $types] == 0} {
      return 0
    }
    
    if {[llength $item] >= 3} {
      set dir [lindex $item 2]
      if {$dir ni {clockwise counter_clockwise}} {
        return 0
      }
    }
  }
  
  return 1
}

proc validate_typemap_list {typeMapList} {
  if {[llength $typeMapList] == 0} {
    return 0
  }
  
  foreach item $typeMapList {
    if {[llength $item] != 2} {
      return 0
    }
    
    set type [lindex $item 0]
    set celltype [lindex $item 1]
    
    if {$type eq "" || $celltype eq ""} {
      return 0
    }
  }
  
  return 1
}

proc validate_polygon_points {polygonPoints} {
  if {[llength $polygonPoints] < 3} {
    return 0
  }
  
  foreach point $polygonPoints {
    if {[llength $point] != 2} {
      return 0
    }
    
    set x [lindex $point 0]
    set y [lindex $point 1]
    
    if {![string is double -strict $x] || ![string is double -strict $y]} {
      return 0
    }
  }
  
  return 1
}

proc is_clockwise {points} {
  set sum 0
  set n [llength $points]
  
  for {set i 0} {$i < $n} {incr i} {
    set j [expr {($i + 1) % $n}]
    set p1 [lindex $points $i]
    set p2 [lindex $points $j]
    set x1 [lindex $p1 0]
    set y1 [lindex $p1 1]
    set x2 [lindex $p2 0]
    set y2 [lindex $p2 1]
    
    set sum [expr {$sum + ($x2 - $x1) * ($y2 + $y1)}]
  }
  
  return [expr {$sum > 0}]
}

proc sort_refnames_by_polygon {refnameCenters polygonPoints {debug 0}} {
  set edges [list]
  set numPoints [llength $polygonPoints]
  
  if {$numPoints < 3} {
    error "Polygon must have at least 3 points"
  }
  
  for {set i 0} {$i < $numPoints} {incr i} {
    set j [expr {($i + 1) % $numPoints}]
    set p1 [lindex $polygonPoints $i]
    set p2 [lindex $polygonPoints $j]
    lappend edges [list $i $p1 $p2]
  }
  
  if {$debug} {
    puts "Generated [llength $edges] edges from polygon points"
  }
  
  set refEdgeMap [list]
  foreach refCenter $refnameCenters {
    set refname [lindex $refCenter 0]
    set center [lindex $refCenter 1]
    set cx [lindex $center 0]
    set cy [lindex $center 1]
    
    if {![string is double -strict $cx] || ![string is double -strict $cy]} {
      error "Invalid center coordinates for refname $refname: ($cx, $cy)"
    }
    
    set minDist [expr {1e20}]
    set closestEdgeIndex -1
    
    foreach edge $edges {
      lassign $edge edgeIndex p1 p2
      lassign $p1 x1 y1
      lassign $p2 x2 y2
      
      set dist [point_to_segment_distance $cx $cy $x1 $y1 $x2 $y2]
      
      if {$dist < $minDist} {
        set minDist $dist
        set closestEdgeIndex $edgeIndex
      }
    }
    
    if {$closestEdgeIndex == -1} {
      error "Failed to find closest edge for refname: $refname"
    }
    
    lappend refEdgeMap [list $refname $closestEdgeIndex $minDist]
    
    if {$debug} {
      puts "Refname $refname closest to edge $closestEdgeIndex with distance $minDist"
    }
  }
  
  set sortedRefs [lsort -integer -index 1 -real -index 2 $refEdgeMap]
  
  set sortedRefnames [list]
  foreach ref $sortedRefs {
    lappend sortedRefnames [lindex $ref 0]
  }
  
  return $sortedRefnames
}

proc point_to_segment_distance {px py x1 y1 x2 y2} {
  foreach coord [list $px $py $x1 $y1 $x2 $y2] {
    if {![string is double -strict $coord]} {
      error "Invalid coordinate value: $coord"
    }
  }
  
  set dx [expr {$x2 - $x1}]
  set dy [expr {$y2 - $y1}]
  
  if {$dx == 0 && $dy == 0} {
    set dx [expr {$px - $x1}]
    set dy [expr {$py - $y1}]
    return [expr {sqrt($dx*$dx + $dy*$dy)}]
  }
  
  set apx [expr {$px - $x1}]
  set apy [expr {$py - $y1}]
  
  set dot [expr {$apx * $dx + $apy * $dy}]
  
  if {$dot <= 0} {
    return [expr {sqrt($apx*$apx + $apy*$apy)}]
  }
  
  set lenSq [expr {$dx*$dx + $dy*$dy}]
  
  if {$dot >= $lenSq} {
    set bpx [expr {$px - $x2}]
    set bpy [expr {$py - $y2}]
    return [expr {sqrt($bpx*$bpx + $bpy*$bpy)}]
  }
  
  set t [expr {double($dot) / $lenSq}]
  set projX [expr {$x1 + $t * $dx}]
  set projY [expr {$y1 + $t * $dy}]
  
  set projpx [expr {$px - $projX}]
  set projpy [expr {$py - $projY}]
  return [expr {sqrt($projpx*$projpx + $projpy*$projpy)}]
}

