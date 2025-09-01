#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/01 15:39:39 Monday
# label     : check_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
# descrip   : Check whether there are any issues with the placement of each mem and IP during the Floorplan phase. Three states are checked in total:
#             - Within the specified area (not adjacent to the boundary)
#             - Adjacent to the boundary
#             - Outside the boundary (including two scenarios: completely outside the area and partially outside the area)
#             You can specify the area for this check as either the die or the core area, depending on your specific situation.
#             and you can select insts of every state from cmdFile conviniently.
# return    :  a table file, and the table will also be displayed on the screen.
# ref       : link url
# --------------------------
source ../eco_fix/timing_fix/lut_build/operateLUT.tcl; # operateLUT
source ../packages/table_col_format_wrap.package.tcl; # table_col_format_wrap
source ../packages/pw_puts_message_to_file_and_window.package.tcl; # pw
source ../packages/add_file_header.package.tcl; # add_file_header
source ../packages/logic_AND_OR.package.tcl; # eo
proc gen_report_if_memAndIP_in_coreOrDieRegion {{suffixOfFile ""} {coreRegion {}} {dieRegion {}} {instsToCheckIfInCoreRegion {}} {instsToCheckIfInDieRegion {}}} {
  set sumFile [eo [expr {$suffixOfFile != ""}] "report_if_memAndIP_in_coreOrDieRegion_$suffixOfFile.rpt" "report_if_memAndIP_in_coreOrDieRegion.rpt"]
  set cmdFile_select_InstsForEveryState [eo [expr {$suffixOfFile != ""}] "cmdFile_if_memAndIP_in_coreOrDieRegion_$suffixOfFile.tcl" "cmdFile_if_memAndIP_in_coreOrDieRegion.tcl"]
  if {![llength $coreRegion]} { set coreRegion [operateLUT -type read -attr {core_rects}] ; set afterValidCore 1}
  if {![llength $dieRegion]} { set dieRegion [dbget top.fplan.box] ; set afterValidDie 1}
  if {$sumFile == ""} { 
    error "proc gen_report_if_memAndIP_in_coreOrDieRegion: check your input : sumFile($sumFile) is empty!!!"
  }
  if {![llength $coreRegion] || ![llength $dieRegion]} {
    error "proc gen_report_if_memAndIP_in_coreOrDieRegion: check your input : coreRegion($coreRegion) [expr {[expr {[info exists afterValidCore] && $afterValidCore}] ? "after validing " : ""}]and \
      dieRegion($dieRegion) [expr {[expr {[info exists afterValidDie] && $afterValidDie}] ? "after validing " : ""}]not valid!!!"
  } else {
    set coreCheck [list [list type num detail]] ; lappend coreCheck [list checkRegion "/" $coreRegion]
    set coreSelectCmd_1 [list ] ; set coreSelectCmd_2 [list ] ; set coreSelectCmd_3 [list ]
    set dieCheck [list [list type num detail]] ; lappend dieCheck [list checkRegion "/" $dieRegion]
    set dieSelectCmd_1 [list ] ; set dieSelectCmd_2 [list ] ; set dieSelectCmd_3 [list ]
    if {![llength $instsToCheckIfInCoreRegion]} { lappend coreCheck [list "/" 0 "/"] } else {
      set core_check_regions [lmap temp_coreinsts $instsToCheckIfInCoreRegion {
          set temp_region {*}[dbget [dbget top.insts.name $temp_coreinsts -p].boxes]
          list $temp_coreinsts $temp_region
       }]
      catch { unset inst_region_of_fully_inside_not_touching ; unset inst_region_of_touching_boundary ; unset inst_region_of_out_of_bounds }
      lassign [check_regions $coreRegion $core_check_regions] inst_region_of_out_of_bounds inst_region_of_touching_boundary inst_region_of_fully_inside_not_touching
      set inst_of_fully_inside_not_touching [lmap temp_inst_region [lindex $inst_region_of_fully_inside_not_touching 1] { lindex $temp_inst_region 0 }]
      set inst_of_touching_boundary [lmap temp_inst_region [lindex $inst_region_of_touching_boundary 1] { lindex $temp_inst_region 0 }]
      set inst_of_out_of_bounds [lmap temp_inst_region [lindex $inst_region_of_out_of_bounds 1] { lindex $temp_inst_region 0}]
      lappend coreCheck [list fully_inside_not_touching [llength $inst_of_fully_inside_not_touching] $inst_of_fully_inside_not_touching]
      lappend coreCheck [list touching_boundary [llength $inst_of_touching_boundary] $inst_of_touching_boundary]
      lappend coreCheck [list out_of_bounds [llength $inst_of_out_of_bounds] $inst_of_out_of_bounds]
      lappend coreSelectCmd_1 {*}[if {[llength $inst_of_out_of_bounds]} { 
        set temp [list "# for core: type out_of_bounds" "alias soc1 \"select_obj \{$inst_of_out_of_bounds\}\""]
      } else {
        set temp [list "# empty!!! have no cmd for core: type out_of_bounds"]
        } ; list {*}$temp]
      lappend coreSelectCmd_2 {*}[if {[llength $inst_of_touching_boundary]} { 
        set temp [list "# for core: type touching_boundary" "alias soc2 \"select_obj \{$inst_of_touching_boundary\}\""]
      } else {
        set temp [list "# empty!!! have no cmd for core: type touching_boundary"]
        } ; list {*}$temp]
      lappend coreSelectCmd_3 {*}[if {[llength $inst_of_fully_inside_not_touching]} { 
        set temp [list "# for core: type fully_inside_not_touching" "alias soc3 \"select_obj \{$inst_of_fully_inside_not_touching\}\""]
      } else {
        set temp [list "# empty!!! have no cmd for core: type fully_inside_not_touching"]
        } ; list {*}$temp]
    }
    if {![llength $instsToCheckIfInDieRegion]} { lappend dieCheck [list $dieRegion "/" "/" "/"] } else {
      set die_check_regions [lmap temp_dieinsts $instsToCheckIfInDieRegion {
          set temp_region {*}[dbget [dbget top.insts.name $temp_dieinsts -p].boxes]
          list $temp_dieinsts $temp_region
       }]
      catch { unset inst_region_of_fully_inside_not_touching ; unset inst_region_of_touching_boundary ; unset inst_region_of_out_of_bounds }
      lassign [check_regions $dieRegion $die_check_regions] inst_region_of_out_of_bounds inst_region_of_touching_boundary inst_region_of_fully_inside_not_touching 
      set inst_of_fully_inside_not_touching [lmap temp_inst_region [lindex $inst_region_of_fully_inside_not_touching 1] { lindex $temp_inst_region 0 }]
      set inst_of_touching_boundary [lmap temp_inst_region [lindex $inst_region_of_touching_boundary 1] { lindex $temp_inst_region 0 }]
      set inst_of_out_of_bounds [lmap temp_inst_region [lindex $inst_region_of_out_of_bounds 1] { lindex $temp_inst_region 0}]
      lappend dieCheck [list fully_inside_not_touching [llength $inst_of_fully_inside_not_touching] $inst_of_fully_inside_not_touching]
      lappend dieCheck [list touching_boundary [llength $inst_of_touching_boundary] $inst_of_touching_boundary]
      lappend dieCheck [list out_of_bounds [llength $inst_of_out_of_bounds] $inst_of_out_of_bounds]
      lappend dieSelectCmd_1 {*}[if {[llength $inst_of_out_of_bounds]} { 
        set temp [list "# for die: type out_of_bounds" "alias sod1 \"select_obj \{$inst_of_out_of_bounds\}\""]
      } else {
        set temp [list "# empty!!! have no cmd for core: type out_of_bounds"]
        } ; list {*}$temp]
      lappend dieSelectCmd_2 {*}[if {[llength $inst_of_touching_boundary]} { 
        set temp [list "# for die: type touching_boundary" "alias sod2 \"select_obj \{$inst_of_touching_boundary\}\""]
      } else {
        set temp [list "# empty!!! have no cmd for core: type touching_boundary"]
        } ; list {*}$temp]
      lappend dieSelectCmd_3 {*}[if {[llength $inst_of_fully_inside_not_touching]} { 
        set temp [list "# for die: type fully_inside_not_touching" "alias sod3 \"select_obj \{$inst_of_fully_inside_not_touching\}\""]
      } else {
        set temp [list "# empty!!! have no cmd for core: type fully_inside_not_touching"]
        } ; list {*}$temp]
    }
    set coreCheck_formatted_to_table [table_col_format_wrap $coreCheck 3 30 200]
    set dieCheck_formatted_to_table [table_col_format_wrap $dieCheck 3 30 200]
    set fi [open $sumFile w]
    set descrip "The two tables below respectively represent the area inclusion check for mem or IP in the core area and die area. \
      Of particular note is the out_of_bounds item -- you need to specifically check whether the inst in the content of this item is compliant. \
      Especially during the Floorplan phase, you can use the command names set in the attached additional command file $cmdFile_select_InstsForEveryState \
      to conveniently check whether these three states meet your expectations. If there are any states that exceed expectations, timely modifications are required."
    set usage "see this cmd file: $cmdFile_select_InstsForEveryState"
    add_file_header -fileID $fi -author "sar song" -descrip $descrip -usage $usage -line_width 150 -splitLineWidth 36 -tee
    pw $fi "CORE REGION CHECK:"
    pw $fi ""
    pw $fi $coreCheck_formatted_to_table
    pw $fi ""
    pw $fi "DIE REGION CHECK:"
    pw $fi ""
    pw $fi $dieCheck_formatted_to_table
    pw $fi ""
    close $fi
    set cmdfi [open $cmdFile_select_InstsForEveryState w]
    set usage "source this file and can use cmds below"
    add_file_header -fileID $fi -author "sar song" -usage $usage -line_width 150 -splitLineWidth 36 -tee
    pw $cmdfi ""
    pw $cmdfi "# CMDS FOR CORE SELECT"
    pw $cmdfi ""
    pw $cmdfi [join $coreSelectCmd_1 \n]
    pw $cmdfi [join $coreSelectCmd_2 \n]
    pw $cmdfi [join $coreSelectCmd_3 \n]
    pw $cmdfi ""
    pw $cmdfi "# CMDS FOR DIE SELECT"
    pw $cmdfi ""
    pw $cmdfi [join $dieSelectCmd_1 \n]
    pw $cmdfi [join $dieSelectCmd_2 \n]
    pw $cmdfi [join $dieSelectCmd_3 \n]
    close $cmdfi
  }
}

#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/01 15:59:17 Monday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
# descrip   : checks multiple irregular regions (composed of rectangles) against a specification region (composed of rectangles), classifying 
#             them as out of bounds, touching the boundary, or fully inside without touching, and returns a list of these classifications with 
#             optional debug information.
# return    : [list \
#                 [list "out_of_bounds" $out_of_bounds] \
#                 [list "touching_boundary" $touching_boundary] \
#                 [list "fully_inside_not_touching" $fully_inside_not_touching] \
#             ]
# ref       : link url
# --------------------------
proc check_regions {spec_region check_regions {debug 0}} {
  # Validate input parameters format
  if {![validate_spec_region_format $spec_region]} {
    error "proc check_regions: Invalid format for specification region. Expected: {{x y x1 y1} {x y x1 y1} ...}"
  }
  
  if {![validate_check_regions_format $check_regions]} {
    error "proc check_regions: Invalid format for check regions. Expected: {{name1 {{x...}...}} {name2 ...} ...}"
  }
  
  if {![string is boolean -strict $debug]} {
    error "proc check_regions: debug must be 0 or 1"
  }
  
  # Initialize result lists for three states
  set out_of_bounds [list]           ;# Regions exceeding specification
  set touching_boundary [list]       ;# Regions touching specification boundary
  set fully_inside_not_touching [list] ;# Regions fully inside without touching
  
  if {$debug} {
    puts "Starting region check process"
    puts "Specification region contains [llength $spec_region] rectangles"
    puts "Number of regions to check: [llength $check_regions]"
  }
  
  # Calculate overall boundaries of the specification region
  set spec_bounds [get_region_boundaries $spec_region]
  lassign $spec_bounds spec_min_x spec_min_y spec_max_x spec_max_y
  
  if {$debug} {
    puts "Specification region boundaries - Min X: $spec_min_x, Min Y: $spec_min_y"
    puts "                           Max X: $spec_max_x, Max Y: $spec_max_y"
  }
  
  # Process each check region
  foreach check_item $check_regions {
    lassign $check_item region_name region_rects
    
    if {$debug} {
      puts "\nProcessing region: $region_name with [llength $region_rects] rectangles"
    }
    
    # Check if any part is out of bounds
    set is_out_of_bounds 0
    foreach rect $region_rects {
      if {![is_rect_fully_contained $rect $spec_region $debug]} {
        set is_out_of_bounds 1
        if {$debug} {
          puts "Rectangle $rect in region $region_name is out of bounds"
        }
        break
      }
    }
    
    if {$is_out_of_bounds} {
      lappend out_of_bounds $check_item
      if {$debug} {
        puts "Region $region_name classified as: out_of_bounds"
      }
    } else {
      # Check if touching boundary
      set is_touching [is_region_touching_boundary $region_rects $spec_bounds $debug]
      
      if {$is_touching} {
        lappend touching_boundary $check_item
        if {$debug} {
          puts "Region $region_name classified as: touching_boundary"
        }
      } else {
        # Fully inside and not touching
        lappend fully_inside_not_touching $check_item
        if {$debug} {
          puts "Region $region_name classified as: fully_inside_not_touching"
        }
      }
    }
  }
  
  # Prepare result in required format with English keys
  set result [list \
    [list "out_of_bounds" $out_of_bounds] \
    [list "touching_boundary" $touching_boundary] \
    [list "fully_inside_not_touching" $fully_inside_not_touching] \
  ]
  
  if {$debug} {
    puts "\nCheck complete. Summary:"
    puts "  out_of_bounds: [llength $out_of_bounds] regions"
    puts "  touching_boundary: [llength $touching_boundary] regions"
    puts "  fully_inside_not_touching: [llength $fully_inside_not_touching] regions"
  }
  
  return $result
}

# Validate specification region format: {{x y x1 y1} {x y x1 y1} ...}
proc validate_spec_region_format {spec_region} {
  # Must be a list
  if {![llength $spec_region]} {
    return 0
  }
  
  # Each element must be a rectangle with 4 numeric coordinates
  foreach rect $spec_region {
    if {[llength $rect] != 4} {
      return 0
    }
    lassign $rect x y x1 y1
    # Coordinates must be numbers
    if {![string is double -strict $x] || ![string is double -strict $y] ||
        ![string is double -strict $x1] || ![string is double -strict $y1]} {
      return 0
    }
    # Must be valid rectangle (x1 > x and y1 > y)
    if {$x >= $x1 || $y >= $y1} {
      return 0
    }
  }
  return 1
}

# Validate check regions format: {{name1 {{x...}...}} {name2 ...} ...}
proc validate_check_regions_format {check_regions} {
  # Must be a list
  if {![llength $check_regions]} {
    return 0
  }
  
  # Each element must be a region with name and rectangles
  foreach region $check_regions {
    if {[llength $region] != 2} {
      return 0
    }
    set name [lindex $region 0]
    set rects [lindex $region 1]
    
    # Name must be a valid identifier
    if {![string is ascii -strict $name]} {
      return 0
    }
    # Rectangles must follow specification region format
    if {![validate_spec_region_format $rects]} {
      return 0
    }
  }
  return 1
}

# Get overall boundaries of a region composed of multiple rectangles
proc get_region_boundaries {region} {
  set min_x [lindex [lindex $region 0] 0]
  set min_y [lindex [lindex $region 0] 1]
  set max_x [lindex [lindex $region 0] 2]
  set max_y [lindex [lindex $region 0] 3]
  
  foreach rect $region {
    lassign $rect x y x1 y1
    set min_x [expr min($min_x, $x)]
    set min_y [expr min($min_y, $y)]
    set max_x [expr max($max_x, $x1)]
    set max_y [expr max($max_y, $y1)]
  }
  
  return [list $min_x $min_y $max_x $max_y]
}

# Check if a rectangle is fully contained in the spec region
proc is_rect_fully_contained {rect spec_region debug} {
  lassign $rect x y x1 y1
  
  # Check four corners of the rectangle
  set corners [list \
    [list $x $y]  \
    [list $x $y1] \
    [list $x1 $y] \
    [list $x1 $y1] \
  ]
  
  foreach corner $corners {
    if {![is_point_in_regions $corner $spec_region $debug]} {
      if {$debug} {
        puts "Corner $corner is outside specification region"
      }
      return 0
    }
  }
  
  # Check midpoints of the edges
  set edge_midpoints [list \
    [list [expr ($x + $x1) / 2.0] $y]  \
    [list [expr ($x + $x1) / 2.0] $y1] \
    [list $x [expr ($y + $y1) / 2.0]]  \
    [list $x1 [expr ($y + $y1) / 2.0]] \
  ]
  
  foreach point $edge_midpoints {
    if {![is_point_in_regions $point $spec_region $debug]} {
      if {$debug} {
        puts "Edge midpoint $point is outside specification region"
      }
      return 0
    }
  }
  
  return 1
}

# Check if a point is in any of the spec region rectangles
proc is_point_in_regions {point spec_region debug} {
  lassign $point px py
  
  foreach spec_rect $spec_region {
    lassign $spec_rect sx sy sx1 sy1
    
    # Check if point is inside current spec rectangle (including boundaries)
    if {$px >= $sx && $px <= $sx1 && $py >= $sy && $py <= $sy1} {
      if {$debug} {
        puts "Point $point is inside spec rectangle $spec_rect"
      }
      return 1
    }
  }
  
  if {$debug} {
    puts "Point $point is outside all spec rectangles"
  }
  return 0
}

# Check if a region is touching the boundary of the spec region
proc is_region_touching_boundary {region_rects spec_bounds debug} {
  lassign $spec_bounds spec_min_x spec_min_y spec_max_x spec_max_y
  
  foreach rect $region_rects {
    lassign $rect x y x1 y1
    
    # Check if touching any boundary of the spec region
    if {$x == $spec_min_x || $y == $spec_min_y || $x1 == $spec_max_x || $y1 == $spec_max_y} {
      if {$debug} {
        puts "Rectangle $rect is touching specification boundary"
      }
      return 1
    }
  }
  
  if {$debug} {
    puts "Region is not touching any specification boundary"
  }
  return 0
}

