#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/29 03:12:19 Monday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : Emulate the lmap function from Tcl 8.6, that can be used in Tcl 8.5
# return    : /
# ref       : link url
# --------------------------
proc lmap {args} {
  # Check if the number of arguments is valid
  if {[llength $args] < 2} {
    error "wrong # args: should be \"lmap varList list ?varList list ...? command\""
  }
  
  # Separate the last argument as the command body
  set body [lindex $args end]
  set args [lrange $args 0 end-1]
  
  # Check if arguments are in pairs
  if {[llength $args] % 2 != 0} {
    error "wrong # args: should be \"lmap varList list ?varList list ...? command\""
  }
  
  set varLists [list]
  set lists [list]
  
  # Parse variable lists and their corresponding value lists
  foreach {varList list} $args {
    # Validate variable list
    if {![llength $varList]} {
      error "empty variable list"
    }
    foreach var $varList {
      if {![regexp {^\w+$} $var]} {
        error "invalid variable name \"$var\""
      }
    }
    lappend varLists $varList
    lappend lists $list
  }
  
  # Calculate lengths of all lists, use the shortest for iteration count
  set lengths [list]
  foreach l $lists {
    lappend lengths [llength $l]
  }
  if {[llength $lengths] == 0} {
    return [list]
  }
  set maxIdx [expr {[expr min([join $lengths ","])] - 1}]
  
  set result [list]
  
  # Iterate through all lists
  for {set i 0} {$i <= $maxIdx} {incr i} {
    # Assign values at current index to each variable list
    foreach varList $varLists list $lists {
      set elements [lindex $list $i]
      # Ensure enough elements to match variable list
      if {[llength $varList] > 1 && [llength $elements] < [llength $varList]} {
        error "list \"$list\" has too few elements for variable list \"$varList\""
      }
      # Handle single variable case differently to preserve sublists
      if {[llength $varList] == 1} {
        uplevel 1 [list set [lindex $varList 0] $elements]
      } else {
        uplevel 1 [list lassign $elements {*}$varList]
      }
    }
    
    # Execute body and collect result, handling continue
    set code [catch {uplevel 1 $body} value]
    if {$code == 0} {
      # Normal execution, add result to list
      lappend result $value
    } elseif {$code == 4} {
      # Continue command encountered, skip this iteration
      continue
    } else {
      # Re-throw other errors
      error $value $::errorInfo $::errorCode
    }
  }
  
  return $result
}

if {0} {
  set song {{song an rui} {an rui song} {rui an song}} 
  puts [lmap temp_x $song { join $temp_x "_" }]
}
