#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/03 20:35:46 Sunday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|misc_proc)
# descrip   : Returns 1 if any provided condition is satisfied with given variables, 0 otherwise.
# update    : 2025/08/05 21:45:43 Tuesday
#             (U001) SIMPLIZE!!!(remove $varList) and change args of conditions to scripts, so you need provide some scripts in $args
# return    : 1: meet anyone condition(scripts)
#             0: not meet all conditions(scripts)
# ref       : link url
# --------------------------
proc cond_met_any { args } {
  # Default configuration with flexible switches
  array set opts {
    -verbose 0
    -strict 1
    -case-sensitive 1
  }
  # -verbose:  0=no output, 1=basic info, 2=detailed
  # -strict :  1=abort on error, 0=continue with warning
  # -case-sensitive : 1=variable names are case-sensitive (reserved for future use)

  # Parse switch options from arguments
  set conditions [list]
  for {set j 0} {$j < [llength $args]} {incr j} {
    set arg [lindex $args $j]
    if {[string match "-*" $arg] && [info exists opts($arg)]} {
      # Next argument is the value for this switch
      set opts($arg) [lindex $args [incr j]]
    } else {
      lappend conditions $arg
    }
  }

  if {$opts(-verbose) >= 2} {
    puts "Conditions to check: [llength $conditions]"
  }

  # Check each condition
  foreach cond $conditions {
    if {$opts(-verbose) >= 2} {
      puts "Checking condition: $cond"
    }
    # Evaluate condition with error handling
    if {[catch {uplevel 1 $cond} result]} { ; # U001
      set msg "proc cond_met_any: Error evaluating condition: $cond (error: $result)"
      if {$opts(-strict)} {
        error $msg
      } else {
        puts "WARNING: $msg (skipping)"
        continue
      }
    }
    if {$result == ""} {
      error "proc cond_met_any: have no return value for your script($cond)"
    } elseif {$result} {
      if {$opts(-verbose) >= 1} {
        puts "Condition satisfied: $cond"
      }
      return 1
    }
  }

  # No conditions satisfied
  if {$opts(-verbose) >= 1} {
    puts "No conditions were satisfied"
  }
  return 0
}


if {0} {
  set violValue -0.05
  set netLen 49
  set cond1 {expr $violValue > -0.06 && $netLen < 50} ; # NOTICE: must be surrounded with {  } !!!
  set cond2 {expr $violValue > -0.01 && $netLen < 10}
  set cond3 {puts "snglsdf"}
  set result [cond_met_any $cond3 $cond2 $cond1 -verbose 2]
  puts $result
}
