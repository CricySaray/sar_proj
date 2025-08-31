#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/31 21:06:54 Sunday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
# descrip   : This proc adjusts the first number to be an integer multiple of the second number($baseNum_toBeMultiple) based on the specified strategy (roundUp, roundDown, or round).
# return    : a num that is multiple of $baseNum_toBeMultiple
# ref       : link url
# --------------------------
proc adjust_to_multiple_of_num {numToProcessBeMultiple baseNum_toBeMultiple {strategy "round"}} {
  # Check if parameters are valid numbers
  if {![string is double $numToProcessBeMultiple]} {
    error "First parameter must be an integer or float, got: $numToProcessBeMultiple"
  }
  if {![string is double $baseNum_toBeMultiple]} {
    error "Second parameter must be an integer or float, got: $baseNum_toBeMultiple"
  }
  
  # Convert to numeric type
  set numToProcessBeMultiple [expr {$numToProcessBeMultiple}]
  set baseNum_toBeMultiple [expr {$baseNum_toBeMultiple}]
  
  # Check if baseNum_toBeMultiple is zero
  if {$baseNum_toBeMultiple == 0} {
    error "Second parameter (baseNum_toBeMultiple) cannot be zero"
  }
  
  # Check if strategy is valid
  set valid_strategies {roundUp roundDown round}
  if {$strategy ni $valid_strategies} {
    error "Third parameter must be one of: [join $valid_strategies {, }]"
  }
  
  # Calculate the multiple
  set multiple [expr {$numToProcessBeMultiple / $baseNum_toBeMultiple}]
  
  # Adjust the multiple according to strategy
  switch $strategy {
    roundUp {
      # Round up, keep as is if already an integer
      if {int($multiple) == $multiple} {
        set adjusted_multiple $multiple
      } else {
        set adjusted_multiple [expr {ceil($multiple)}]
      }
    }
    roundDown {
      # Round down
      set adjusted_multiple [expr {floor($multiple)}]
    }
    round {
      # Round to nearest integer
      set adjusted_multiple [expr {round($multiple)}]
    }
  }
  
  # Calculate and return the adjusted result
  return [expr {$adjusted_multiple * $baseNum_toBeMultiple}]
}

