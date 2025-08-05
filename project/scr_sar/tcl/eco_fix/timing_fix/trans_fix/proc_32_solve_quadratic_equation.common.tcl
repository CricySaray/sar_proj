#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/05 17:34:01 Tuesday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : calculates coefficients a, b, and c of the quadratic equation y=ax²+bx+c from three given points using floating-point 
#             arithmetic, returns results rounded to 3 decimal places, and includes an optional debug mode.
# return    : a dict var for a/b/c coefficients
# ref       : link url
# --------------------------
proc solve_quadratic_equation {point1 point2 point3 {debug 0}} {
  # Extract coordinates from input points
  lassign $point1 x1 y1
  lassign $point2 x2 y2
  lassign $point3 x3 y3
  
  # Convert all coordinates to floating point
  set x1 [expr {double($x1)}]
  set y1 [expr {double($y1)}]
  set x2 [expr {double($x2)}]
  set y2 [expr {double($y2)}]
  set x3 [expr {double($x3)}]
  set y3 [expr {double($y3)}]
  
  if {$debug} {
    puts "Debug mode enabled"
    puts "Points received (converted to float):"
    puts "Point 1: ($x1, $y1)"
    puts "Point 2: ($x2, $y2)"
    puts "Point 3: ($x3, $y3)"
  }
  
  # Calculate determinants for Cramer's rule
  # System: a*x² + b*x + c = y
  set D [expr {
    ($x1**2)*($x2 - $x3) -
    ($x2**2)*($x1 - $x3) +
    ($x3**2)*($x1 - $x2)
  }]
  
  if {$debug} {
    puts "Determinant D = $D"
  }
  
  # Check for no unique solution
  if {$D == 0} {
    error "The points are colinear or coincident - no unique quadratic solution exists"
  }
  
  # Calculate other determinants
  set Da [expr {
    $y1*($x2 - $x3) -
    $y2*($x1 - $x3) +
    $y3*($x1 - $x2)
  }]
  
  set Db [expr {
    ($x1**2)*($y2 - $y3) -
    ($x2**2)*($y1 - $y3) +
    ($x3**2)*($y1 - $y2)
  }]
  
  set Dc [expr {
    ($x1**2)*($x2*$y3 - $x3*$y2) -
    ($x2**2)*($x1*$y3 - $x3*$y1) +
    ($x3**2)*($x1*$y2 - $x2*$y1)
  }]
  
  if {$debug} {
    puts "Determinant Da = $Da"
    puts "Determinant Db = $Db"
    puts "Determinant Dc = $Dc"
  }
  
  # Calculate coefficients using floating point division
  set a [expr {$Da / $D}]
  set b [expr {$Db / $D}]
  set c [expr {$Dc / $D}]
  
  if {$debug} {
    puts "Raw coefficients (before rounding):"
    puts "a = $a"
    puts "b = $b"
    puts "c = $c"
  }
  
  # Round to 3 decimal places
  set a [format "%.3f" $a]
  set b [format "%.3f" $b]
  set c [format "%.3f" $c]
  
  if {$debug} {
    puts "Coefficients (rounded to 3 decimals):"
    puts "a = $a"
    puts "b = $b"
    puts "c = $c"
  }
  
  # Return as dictionary
  return [dict create a $a b $b c $c]
}

# test
if {0} {
  # Solve for points (0,1), (1,3), (2,7)
  set result [solve_quadratic_equation {0 1} {1 3} {2 7}]
  puts "a = [dict get $result a], b = [dict get $result b], c = [dict get $result c]"

  # With debug mode enabled
  set result [solve_quadratic_equation {0 0} {1 1} {2 4} 1]
  
  puts [dict get [solve_quadratic_equation {0 0} {15 15} {20 100} 1]]
}
