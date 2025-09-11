#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/11 10:36:29 Thursday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : gen cmd of add corner IO filler
# return    : cmdsList
# ref       : link url
# --------------------------
proc genCmd_addCornerIoFiller {args} {
  set ioFillerCellName "PCORNER_33_33_NT_DR"
  set insertPointList  {} ; # {{x y} {x y} ...}
  set dieRects         [dbget top.fplan.box] ; # {{x y x1 y1} ...}
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$ioFillerCellName == "" || [dbget head.libCells.name $ioFillerCellName -e] == ""} {
    error "proc genCmd_addCornerIoFiller: check your input: ioFillerCellName($ioFillerCellName) is empty or not found!!!" 
  } 
  if {![llength $insertPointList]} {
    error "proc genCmd_addCornerIoFiller: check your input : insertPointList($insertPointList) is empty!!!" 
  }
  if {![llength $dieRects]} {
    error "proc genCmd_addCornerIoFiller: check your input : dieRects($dieRects) is empty!!!" 
  }
  set cmdsValuesList [get_coordinate_of_cornerIoFiller_toInsert $dieRects $insertPointList $ioFillerCellName 0]
  set cmdsList [lmap temp_value $cmdsValuesList {
    lassign $temp_value temp_celltype temp_instname temp_point 
    set temp "addIoInstance -cell $temp_celltype -inst $temp_instname -loc $temp_point"
  }]
  return $cmdsList
}
define_proc_arguments genCmd_addCornerIoFiller \
  -info "gen cmds for adding corner io filler"\
  -define_args {
    {-ioFillerCellName "specify the celltype name of io filler" AString string optional}
    {-insertPointList "specify the list of points" AList list optional}
    {-dieRects "specify the rects of die area, like {{x y x1 y1} ...}" AList list optional}
  }
proc get_coordinate_of_cornerIoFiller_toInsert {rect_blocks coord_list cornerName {debug 0}} {
  # Validate input parameters
  if {![llength $rect_blocks]} {
    error "proc get_coordinate_of_cornerIoFiller_toInsert: rect_blocks must be a non-empty nested list"
  }
  
  if {![llength $coord_list]} {
    error "proc get_coordinate_of_cornerIoFiller_toInsert: coord_list must be a non-empty list of coordinates"
  }
  
  if {![string length $cornerName]} {
    error "proc get_coordinate_of_cornerIoFiller_toInsert: cornerName must be a non-empty string"
  }
  
  # Validate rect_blocks format
  foreach rect $rect_blocks {
    if {[llength $rect] != 4} {
      error "proc get_coordinate_of_cornerIoFiller_toInsert: Invalid rectangle format: $rect. Expected {x y x1 y1}"
    }
    foreach coord $rect {
      if {![string is double -strict $coord]} {
        error "proc get_coordinate_of_cornerIoFiller_toInsert: Invalid coordinate value: $coord. Must be a number"
      }
    }
    lassign $rect x y x1 y1
    if {$x >= $x1 || $y >= $y1} {
      error "proc get_coordinate_of_cornerIoFiller_toInsert: Invalid rectangle coordinates: $rect. Expected x < x1 and y < y1"
    }
  }
  
  # Validate coord_list format
  foreach coord $coord_list {
    if {[llength $coord] != 2} {
      error "proc get_coordinate_of_cornerIoFiller_toInsert: Invalid coordinate format: $coord. Expected {x y}"
    }
    foreach val $coord {
      if {![string is double -strict $val]} {
        error "proc get_coordinate_of_cornerIoFiller_toInsert: Invalid coordinate value: $val. Must be a number"
      }
    }
  }
  
  # Check if all rectangles are connected (form a single polygon)
  if {[llength $rect_blocks] > 1 && ![are_rectangles_connected $rect_blocks $debug]} {
    error "proc get_coordinate_of_cornerIoFiller_toInsert: Rectangles have disconnected parts. Please provide interconnected rectangles."
  }
  
  if {$debug} {
    puts "Debug mode enabled"
    puts "Number of boundary rectangles: [llength $rect_blocks]"
    puts "Number of coordinates to process: [llength $coord_list]"
    puts "Target rectangle name: $cornerName"
  }
  
  # Get the size of the target rectangle using the updated command
  if {$debug} {
    puts "Retrieving size for rectangle: $cornerName"
  }
  if {[catch {dbget [dbget head.libCells.name $cornerName -p].size} size_result]} {
    error "proc get_coordinate_of_cornerIoFiller_toInsert: Failed to retrieve size for $cornerName: $size_result"
  }
  set cornerSize {*}$size_result
  
  if {[llength $cornerSize] != 2} {
    error "proc get_coordinate_of_cornerIoFiller_toInsert: Invalid size format for $cornerName: $cornerSize. Expected {width height}"
  }
  lassign $cornerSize width height
  
  if {$width <= 0 || $height <= 0} {
    error "proc get_coordinate_of_cornerIoFiller_toInsert: Invalid rectangle dimensions: width=$width, height=$height. Must be positive"
  }
  
  if {$debug} {
    puts "Target rectangle dimensions - width: $width, height: $height (no rotation)"
  }
  
  # Extract outline vertices (corners) of the connected polygon
  set outline_vertices [extract_outline_vertices $rect_blocks $debug]
  
  if {![llength $outline_vertices]} {
    error "proc get_coordinate_of_cornerIoFiller_toInsert: No valid outline vertices extracted from connected rectangles"
  }
  
  if {$debug} {
    puts "Extracted [llength $outline_vertices] unique outline vertices from connected rectangles"
    if {$debug} {
      puts "Outline vertices: $outline_vertices"
    }
  }
  
  # Process each coordinate to find corresponding vertex and place rectangle
  set result [list]
  set coord_index 0
  
  foreach coord $coord_list {
    incr coord_index
    lassign $coord x y
    
    if {$debug} {
      puts "\nProcessing coordinate $coord_index: ($x, $y)"
    }
    
    # Find nearest outline vertex to the given coordinate
    set nearest_vertex [find_nearest_corner [list $x $y] $outline_vertices $debug]
    
    if {$nearest_vertex eq ""} {
      error "proc get_coordinate_of_cornerIoFiller_toInsert: No nearest vertex found for coordinate ($x, $y)"
    }
    
    lassign $nearest_vertex vx vy
    if {$debug} {
      puts "Nearest outline vertex found at: ($vx, $vy)"
    }
    
    # Try to place rectangle with one vertex overlapping the outline vertex (no rotation)
    if {$debug} {
      puts "Attempting to place rectangle at this vertex (no rotation)..."
    }
    if {[catch {try_placements $nearest_vertex $width $height $rect_blocks $debug} placed_rect]} {
      error "proc get_coordinate_of_cornerIoFiller_toInsert: Failed to place rectangle at coordinate ($x, $y): $placed_rect"
    }
    
    # Calculate bottom-left coordinate (x is minimum x, y is minimum y of the placed rectangle)
    lassign $placed_rect min_x min_y max_x max_y
    # For axis-aligned rectangles (no rotation), bottom-left is (min_x, min_y)
    set bottom_left [list $min_x $min_y]
    
    if {$debug} {
      puts "Successfully placed rectangle (no rotation). Bottom-left coordinate: $bottom_left"
      puts "Placed rectangle boundaries: min_x=$min_x, min_y=$min_y, max_x=$max_x, max_y=$max_y"
    }
    
    # Create new name with incremental index (corner_1, corner_2, ...)
    set new_name "${cornerName}_[expr {$coord_index}]"
    lappend result [list $cornerName $new_name $bottom_left]
  }
  
  if {$debug} {
    puts "\nProcessing complete. Returning [llength $result] coordinates"
  }
  
  return $result
}

proc are_rectangles_connected {rects debug} {
  set n [llength $rects]
  if {$n <= 1} {
    return 1 ;# Single rectangle is trivially connected
  }
  
  # Initialize Union-Find structure
  array set parent {}
  for {set i 0} {$i < $n} {incr i} {
    set parent($i) $i
  }
  
  # Helper procedure for Union-Find find
  proc find {parent_var node} {
    upvar $parent_var parent
    if {$parent($node) != $node} {
      set parent($node) [find parent $parent($node)]
    }
    return $parent($node)
  }
  
  # Check each pair of rectangles for connection
  for {set i 0} {$i < $n} {incr i} {
    set rect1 [lindex $rects $i]
    lassign $rect1 x1 y1 x1_1 y1_1
    
    for {set j [expr {$i + 1}]} {$j < $n} {incr j} {
      set rect2 [lindex $rects $j]
      lassign $rect2 x2 y2 x2_1 y2_1
      
      # Check if rectangles overlap or share a common edge
      set overlap [expr {
        $x1 < $x2_1 && $x2 < $x1_1 &&
        $y1 < $y2_1 && $y2 < $y1_1
      }]
      
      # Check if they share a common edge (touching)
      set share_edge [expr {
        ($x1 == $x2_1 || $x1_1 == $x2) &&
        !($y1 >= $y2_1 || $y1_1 <= $y2)
      }] || [expr {
        ($y1 == $y2_1 || $y1_1 == $y2) &&
        !($x1 >= $x2_1 || $x1_1 <= $x2)
      }]
      
      if {$overlap || $share_edge} {
        # Union the two sets
        set root_i [find parent $i]
        set root_j [find parent $j]
        set parent($root_j) $root_i
        
        if {$debug} {
          puts "Rectangles $i and $j are connected"
        }
      }
    }
  }
  
  # Check if all rectangles belong to the same set
  set root [find parent 0]
  for {set i 1} {$i < $n} {incr i} {
    if {[find parent $i] != $root} {
      if {$debug} {
        puts "Rectangles are disconnected (found separate component at index $i)"
      }
      return 0
    }
  }
  
  return 1
}

proc extract_outline_vertices {rects debug} {
  # First get all corners with their parent rectangles
  set all_corners [list]
  set rect_index 0
  
  foreach rect $rects {
    lassign $rect x y x1 y1
    # Store corners with their parent rectangle index
    lappend all_corners [list [list $x $y] $rect_index]
    lappend all_corners [list [list $x1 $y] $rect_index]
    lappend all_corners [list [list $x $y1] $rect_index]
    lappend all_corners [list [list $x1 $y1] $rect_index]
    incr rect_index
  }
  
  # Identify outline vertices (corners not shared by another rectangle)
  set outline_vertices [list]
  
  foreach corner_data $all_corners {
    lassign $corner_data corner rect_idx
    lassign $corner cx cy
    set is_internal 0
    
    # Check if this corner is shared by another rectangle
    foreach other_data $all_corners {
      lassign $other_data other_corner other_rect_idx
      if {$other_rect_idx == $rect_idx} {
        continue ;# Skip same rectangle
      }
      
      lassign $other_corner ocx ocy
      if {$cx == $ocx && $cy == $ocy} {
        # This corner is shared with another rectangle - internal
        set is_internal 1
        break
      }
    }
    
    if {!$is_internal} {
      lappend outline_vertices $corner
    }
  }
  
  # Remove duplicates and return
  set unique_outline [lsort -unique $outline_vertices]
  
  if {$debug} {
    puts "Found [llength $unique_outline] outline vertices (excluded [expr {[llength $all_corners]/4 - [llength $unique_outline]}] internal corners)"
  }
  
  return $unique_outline
}

proc find_nearest_corner {point corners debug} {
  lassign $point x y
  set min_dist Inf
  set nearest_corner ""
  
  foreach corner $corners {
    lassign $corner cx cy
    set dist [expr {sqrt(pow($x - $cx, 2) + pow($y - $cy, 2))}]
    
    if {$debug} {
      puts "Distance to corner ($cx, $cy): $dist"
    }
    
    if {$dist < $min_dist} {
      set min_dist $dist
      set nearest_corner $corner
    }
  }
  
  return $nearest_corner
}

proc try_placements {corner width height boundary_rects debug} {
  lassign $corner cx cy
  
  # Define four possible axis-aligned placements (no rotation)
  # Each placement aligns one corner of the rectangle with the boundary vertex:
  # 1. Align top-left corner of rectangle with boundary vertex
  # 2. Align top-right corner of rectangle with boundary vertex
  # 3. Align bottom-left corner of rectangle with boundary vertex
  # 4. Align bottom-right corner of rectangle with boundary vertex
  set placements [list \
    [list $cx $cy [expr {$cx + $width}] [expr {$cy + $height}]] \
    [list [expr {$cx - $width}] $cy $cx [expr {$cy + $height}]] \
    [list $cx [expr {$cy - $height}] [expr {$cx + $width}] $cy] \
    [list [expr {$cx - $width}] [expr {$cy - $height}] $cx $cy] \
  ]
  
  if {$debug} {
    puts "Trying 4 axis-aligned placements (no rotation):"
    foreach placement $placements index {1 2 3 4} {
      lassign $placement min_x min_y max_x max_y
      puts "  Placement $index: min_x=$min_x, min_y=$min_y, max_x=$max_x, max_y=$max_y"
    }
  }
  
  # Check each placement to see if it's inside the boundary
  foreach placement $placements index {1 2 3 4} {
    if {[is_inside_boundary $placement $boundary_rects $debug]} {
      if {$debug} {
        puts "Placement $index is valid (axis-aligned)"
      }
      return $placement
    } elseif {$debug} {
      puts "Placement $index is invalid (outside boundary)"
    }
  }
  
  error "proc try_placements: Cannot place rectangle at corner $corner without exceeding boundary (no valid axis-aligned position)"
}

proc is_inside_boundary {rect boundary_rects debug} {
  lassign $rect min_x min_y max_x max_y
  
  # Check if all four corners of the axis-aligned rectangle are inside the boundary
  # Corner order: top-left, top-right, bottom-left, bottom-right
  set corners [list \
    [list $min_x $min_y] \
    [list $max_x $min_y] \
    [list $min_x $max_y] \
    [list $max_x $max_y] \
  ]
  
  if {$debug} {
    puts "Checking if all corners are inside boundary:"
  }
  
  foreach corner $corners cname {top-left top-right bottom-left bottom-right} {
    lassign $corner cx cy
    set in_boundary 0
    
    foreach b_rect $boundary_rects {
      lassign $b_rect bx by bx1 by1
      if {$cx >= $bx && $cx <= $bx1 && $cy >= $by && $cy <= $by1} {
        set in_boundary 1
        break
      }
    }
    
    if {$debug} {
      puts "  $cname corner ($cx, $cy): [expr {$in_boundary ? "inside" : "outside"}]"
    }
    
    if {!$in_boundary} {
      return 0
    }
  }
  
  return 1
}

