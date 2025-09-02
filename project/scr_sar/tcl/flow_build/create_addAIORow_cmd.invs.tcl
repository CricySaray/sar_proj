#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/31 23:10:22 Sunday
# label     : flow_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
# descrip   : Create appropriate specific command content for the addAIORow command that can be directly executed in the command line; specific 
#             commands with different configurations can be returned by adjusting various parameters of the proc.
# related   : ./get_addAreaIORow_info.invs.tcl: get_addAreaIORow_info
# return    : cmds of addAIORow
# ref       : link url
# --------------------------
proc create_addAIORow_cmd {{dieArea_rect {0 0 10 10}} {IO_site_name ""} {numOrRowEveryEdge {1 1 1 1}} {orientOfEveryEdgeInClockWiseOrder_fromTop {MX MY90 MY MX90}}} {
  if {$IO_site_name == "" || [dbget [dbget head.sites.name $IO_site_name -p].size -e] == ""} {
    error "proc create_addAIORow_cmd: check your input: IO_site_name($IO_site_name) not found!!!"
  } else {
    set IO_site_size {*}[dbget [dbget head.sites.name $IO_site_name -p].size -e]
    set info_of_addAIORow [get_addAreaIORow_info $dieArea_rect $IO_site_size $numOrRowEveryEdge]
    set i 0
    set cmds_of_addAIORow [lmap tempinfo $info_of_addAIORow {
      lassign $tempinfo leftBottomPoint numOfSite direction
      switch $direction { H { set tempdirection -H } V { set tempdirection -V }}
      set orientOfSite [lindex $orientOfEveryEdgeInClockWiseOrder_fromTop $i]
      incr i
      set temp_cmd [list addAIORow -noSnap -site $IO_site_name -orient $orientOfSite $tempdirection -num $numOfSite -loc {*}$leftBottomPoint]
    }]
    return [join $cmds_of_addAIORow \n]
  }
}
### NOTICE: you can run cmds using: set cmds "{[join [split [create_addAIORow_cmd {x y x1 y1} io_site_name] \n] "} {"]}" ; foreach cmd $cmds { puts $cmd ; eval $cmd }

#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/31 23:10:22 Sunday
# label     : flow_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
# descrip   : This procedure places cells along the four sides of a specified rectangular area based on given cell dimensions and specified rows per 
#             side, following specific alignment rules, calculating maximum cell counts per row, returning placement information with coordinates, 
#             counts and directions, while including error handling and debug capabilities.
# return    : info for cmd addAIORow
#             { {{x y} $numOfSite $direction} {{x y} $numOfSite $direction} ...}
#             {x y} : the left-bottom point of every row of specified edge
#             $numOfSite : the num of every row of specified edge
#             $direction : the direction of every row of specified edge
# related   : ./create_addAIORow_cmd.invs.tcl : create_addAIORow_cmd
# ref       : link url
# --------------------------
proc get_addAreaIORow_info {rectangle site_size rows_per_side {debug 0}} {
  # Validate rectangle format (must be {x y x1 y1} with 4 elements)
  if {[llength $rectangle] != 4} {
    error "Invalid rectangle format. Expected {x y x1 y1} with 4 elements"
  }
  
  # Validate site size format (must be {width height} with 2 elements)
  if {[llength $site_size] != 2} {
    error "Invalid site_size format. Expected {width height} with 2 elements"
  }
  
  # Process rows_per_side (single integer or 4-element list for top/right/bottom/left)
  if {[string is integer -strict $rows_per_side]} {
    set top_rows $rows_per_side
    set right_rows $rows_per_side
    set bottom_rows $rows_per_side
    set left_rows $rows_per_side
  } elseif {[llength $rows_per_side] == 4} {
    lassign $rows_per_side top_rows right_rows bottom_rows left_rows
  } else {
    error "Invalid rows_per_side. Must be integer or 4-element list of integers"
  }
  
  # Validate all row counts are non-negative integers
  foreach side {top right bottom left} count [list $top_rows $right_rows $bottom_rows $left_rows] {
    if {![string is integer -strict $count] || $count < 0} {
      error "Invalid row count for $side side: $count. Must be non-negative integer"
    }
  }
  
  # Parse and validate rectangle coordinates (x < x1, y < y1)
  lassign $rectangle x y x1 y1
  foreach coord {x y x1 y1} value [list $x $y $x1 $y1] {
    if {![string is double -strict $value]} {
      error "Invalid $coord coordinate: $value. Must be numeric"
    }
  }
  if {$x >= $x1 || $y >= $y1} {
    error "Invalid rectangle: x must be < x1 and y must be < y1"
  }
  
  # Parse and validate site dimensions (positive numbers)
  lassign $site_size site_w site_h
  foreach dim {width height} value [list $site_w $site_h] {
    if {![string is double -strict $value] || $value <= 0} {
      error "Invalid site $dim: $value. Must be positive number"
    }
  }
  
  # Debug: Initial parameters
  if {$debug} {
    puts "=== Debug Mode Enabled ==="
    puts "Rectangle: bottom-left ($x, $y), top-right ($x1, $y1)"
    puts "Site: width=$site_w, height=$site_h"
    puts "Rows per side: top=$top_rows, right=$right_rows, bottom=$bottom_rows, left=$left_rows"
    puts "=========================="
  }
  
  set result [list]
  
  # Process top side (H: horizontal direction)
  set top_rows_info [list]
  if {$debug} {puts "\nProcessing top side ($top_rows rows)"}
  for {set i 0} {$i < $top_rows} {incr i} {
    set current_y [expr {$y1 - ($i + 1) * $site_h}]
    set available_width [expr {$x1 - $x}]
    set cell_count [expr {int(floor(double($available_width) / $site_w))}]
    set current_x [expr {$x + ($available_width - $cell_count * $site_w)}]
    
    if {$debug} {
      puts "  Top row $i: start=($current_x, $current_y), count=$cell_count, direction=H"
    }
    set top_rows_info [list [list $current_x $current_y] $cell_count "H"]
  }
  set top $top_rows_info
  lappend result $top
  
  # Process right side (V: vertical direction) - corrected coordinates
  set right_rows_info [list]
  if {$debug} {puts "\nProcessing right side ($right_rows rows)"}
  for {set i 0} {$i < $right_rows} {incr i} {
    # X: rectangle's top-right x minus (i+1) * site_h (cell height in horizontal direction)
    set current_x [expr {$x1 - ($i + 1) * $site_h}]
    # Y:紧贴下侧边，使用矩形下边界y坐标 (stick to bottom side, use rectangle's bottom y)
    set current_y $y
    # Available height for vertical placement
    set available_height [expr {$y1 - $y}]
    set cell_count [expr {int(floor(double($available_height) / $site_w))}]
    
    if {$debug} {
      puts "  Right row $i: start=($current_x, $current_y), count=$cell_count, direction=V"
    }
    set right_rows_info [list [list $current_x $current_y] $cell_count "V"]
  }
  set right $right_rows_info
  lappend result $right
  
  # Process bottom side (H: horizontal direction)
  set bottom_rows_info [list]
  if {$debug} {puts "\nProcessing bottom side ($bottom_rows rows)"}
  for {set i 0} {$i < $bottom_rows} {incr i} {
    set current_y [expr {$y + $i * $site_h}]
    set available_width [expr {$x1 - $x}]
    set cell_count [expr {int(floor(double($available_width) / $site_w))}]
    set current_x $x
    
    if {$debug} {
      puts "  Bottom row $i: start=($current_x, $current_y), count=$cell_count, direction=H"
    }
    set bottom_rows_info [list [list $current_x $current_y] $cell_count "H"]
  }
  set bottom $bottom_rows_info
  lappend result $bottom
  
  # Process left side (V: vertical direction)
  set left_rows_info [list]
  if {$debug} {puts "\nProcessing left side ($left_rows rows)"}
  for {set i 0} {$i < $left_rows} {incr i} {
    set current_x [expr {$x + $i * $site_h}]
    set available_height [expr {$y1 - $y}]
    set cell_count [expr {int(floor(double($available_height) / $site_w))}]
    set current_y [expr {$y1 - $cell_count * $site_w}]
    
    if {$debug} {
      puts "  Left row $i: start=($current_x, $current_y), count=$cell_count, direction=V"
    }
    set left_rows_info [list [list $current_x $current_y] $cell_count "V"]
  }
  set left $left_rows_info
  lappend result $left
  
  # Debug: Final result
  if {$debug} {
    puts "\n=== Processing Complete ==="
    puts "Result: $result"
    puts "==========================="
  }
  
  return $result
}

