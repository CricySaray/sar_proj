#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/03 20:35:46 Sunday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|misc_proc)
# descrip   : Returns 1 if any provided condition is satisfied with given variables, 0 otherwise.
# return    : 1: meet anyone condition
#             0: not meet all conditions
# ref       : link url
# --------------------------
proc cond_met_any { varList args } {
  # Default configuration with flexible switches
  array set opts {
    -verbose 0
    -strict 1
    -case-sensitive 1
  }
  # -verbose:  0=no output, 1=basic info, 2=detailed
  # -strict :  1=abort on error, 0=continue with warning
  # -case-sensitive : 1=variable names are case-sensitive

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
  # Error checking for variable list (must be even number of elements)
  if {[llength $varList] % 2 != 0} {
    error "Variable list must contain even number of elements (name-value pairs)"
  }
  # Create local variables from name-value pairs
  array set variables {}
  for {set i 0} {$i < [llength $varList]} {incr i 2} {
    set varName [lindex $varList $i]
    set varValue [lindex $varList [expr $i + 1]]
    # Validate variable name
    if {![string match {[a-zA-Z_]*} $varName] || [string match "::*" $varName]} {
      set msg "Invalid variable name: $varName (must start with letter/underscore and not be namespace-qualified)"
      if {$opts(-strict)} {
        error $msg
      } else {
        puts "WARNING: $msg (skipped)"
        continue
      }
    }
    # Handle case insensitivity
    if {!$opts(-case-sensitive)} {
      set varName [string tolower $varName]
    }
    # Check for duplicate variable names
    if {[info exists variables($varName)]} {
      set msg "Duplicate variable name: $varName (overwriting previous value)"
      if {$opts(-verbose) >= 1} {
        puts "WARNING: $msg"
      }
    }
    # Create local variable and store in array for reference
    set $varName $varValue
    set variables($varName) $varValue
  }
  if {$opts(-verbose) >= 2} {
    puts "Processed variables:"
    foreach var [array names variables] {
      puts "  $var = $variables($var)"
    }
    puts "Conditions to check: [llength $conditions]"
  }
  # Check each condition
  foreach cond $conditions {
    if {$opts(-verbose) >= 2} {
      puts "Checking condition: $cond"
    }
    # Evaluate condition with error handling
    if {[catch {expr $cond} result]} {
      set msg "Error evaluating condition: $cond (error: $result)"
      if {$opts(-strict)} {
        error $msg
      } else {
        puts "WARNING: $msg (skipping)"
        continue
      }
    }
    if {$result} {
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
  set cond1 {$v > -0.06 && $n < 50} ; # NOTICE: must be surrounded with {  } !!!
  set cond2 {$v > -0.01 && $n < 10}
  set result [cond_met_any [list v $violValue n $netLen] $cond2 $cond1 -verbose 2]
  puts $result
}
