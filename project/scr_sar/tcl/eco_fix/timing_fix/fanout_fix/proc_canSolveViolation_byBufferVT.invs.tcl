#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/26 19:52:40 Saturday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : judge if this case can be solved by changing VT/driverCapacity
# return    : 0: can solve by changing VT/driveCapacity
#             1: can't solve this case
# ref       : link url
# --------------------------
# Determine if a violation can be resolved by changing buffer size or VT type
# Parameters:
#   violation - Violation value (ns), negative value indicates a violation
#   netlength - Wire length (um)
# Returns:
#   0 - Can be resolved; 1 - Cannot be resolved
proc can_solve_violation_by_buffer_vt {violation netlength} {
  # Ensure parameters are numeric
  if {![string is double -strict $violation] || ![string is double -strict $netlength]} {
    error "Parameters must be numeric"
  }
  # If there is no violation, return 0 directly
  if {$violation >= 0} {
    return 0
  }
  # Calculate the maximum resolvable violation based on wire length
  # Use linear interpolation based on known data points
  # Data points: {10, -0.010}, {50, -0.030}, {100, -0.040}
  set max_solvable_violation 0.0
  if {$netlength <= 10} {
    # Wire length <=10um, maximum resolvable violation is -0.010ns
    set max_solvable_violation -0.010
  } elseif {$netlength >= 100} {
    # Wire length >=100um, maximum resolvable violation is -0.040ns
    set max_solvable_violation -0.040
  } else {
    # 10um < wire length < 100um, calculate using linear interpolation
    if {$netlength <= 50} {
      # Interpolation between 10-50um
      set slope [expr (-0.030 - (-0.010)) / (50 - 10)]
      set max_solvable_violation [expr -0.010 + $slope * ($netlength - 10)]
    } else {
      # Interpolation between 50-100um
      set slope [expr (-0.040 - (-0.030)) / (100 - 50)]
      set max_solvable_violation [expr -0.030 + $slope * ($netlength - 50)]
    }
  }
  # Compare the violation value with the maximum resolvable violation
  if {$violation >= $max_solvable_violation} {
    return 1  ;# Can be resolved
  } else {
    return 0  ;# Cannot be resolved
  }
}

if {0} {
  # Test examples
  puts [can_solve_violation_by_buffer_vt -0.005 15]   ;# Output 0, resolvable
  puts [can_solve_violation_by_buffer_vt -0.020 30]   ;# Output 0, resolvable
  puts [can_solve_violation_by_buffer_vt -0.050 80]   ;# Output 1, not resolvable
  puts [can_solve_violation_by_buffer_vt 0.005 50]    ;# Output 0, no violation    

}
