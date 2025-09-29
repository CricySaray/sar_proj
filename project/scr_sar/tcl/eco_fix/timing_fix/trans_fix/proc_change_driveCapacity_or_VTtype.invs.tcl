#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/29 23:19:33 Monday
# label     : atomic_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
proc change_driveCapacity_or_VTtype {input_str regex pattern_type new_value {debug 0}} {
  # Validate input parameters
  if {![string is boolean -strict $debug]} {
    error "Debug must be a boolean value (0 or 1)"
  }
  if {$pattern_type ne "cap" && $pattern_type ne "vt"} {
    error "Pattern type must be either 'cap' or 'vt'"
  }
  if {$pattern_type eq "cap" && ![string is integer -strict $new_value]} {
    error "New value for cap must be an integer"
  }

  # Debug information for input parameters
  if {$debug} {
    puts "Debug: Input string: $input_str"
    puts "Debug: Regular expression: $regex"
    puts "Debug: Pattern type to replace: $pattern_type"
    puts "Debug: New value: $new_value"
  }

  # Ensure variables don't exist before regexp
  catch {unset cap}
  catch {unset vt}

  # Try to match the regular expression
  if {![regexp $regex $input_str -> cap vt]} {
    if {$debug} {
      puts "Debug: No match found for the input string"
    }
    error "Input string does not match the regular expression"
  }

  # Debug information for matched values
  if {$debug} {
    puts "Debug: Matched cap value: $cap"
    puts "Debug: Matched vt value: $vt"
  }

  # Perform replacement using regsub
  set result $input_str
  if {$pattern_type eq "cap"} {
    # Escape special characters in cap for safe replacement
    set escaped_cap [regsub -all {\W} $cap {\\&}];# Escape special characters
    if {[regsub $escaped_cap $result $new_value result]} {
      if {$debug} {
        puts "Debug: Replaced cap from '$cap' to '$new_value'"
      }
    } else {
      error "Failed to replace cap value in the input string"
    }
  } else {
    # For vt, handle empty string case
    if {$vt eq ""} {
      # Find position to insert new_vt based on regex structure
      # This assumes vt is the last part of the pattern
      set pos [string first $cap $result]
      if {$pos != -1} {
        set pos [expr {$pos + [string length $cap]}]
        set result [string replace $result $pos $pos "[string index $result $pos]$new_value"]
        if {$debug} {
          puts "Debug: Inserted vt '$new_value' at position $pos"
        }
      } else {
        error "Failed to find position to insert vt value"
      }
    } else {
      # Escape special characters in vt for safe replacement
      set escaped_vt [regsub -all {\W} $vt {\\&}]
      if {[regsub $escaped_vt $result $new_value result]} {
        if {$debug} {
          puts "Debug: Replaced vt from '$vt' to '$new_value'"
        }
      } else {
        error "Failed to replace vt value in the input string"
      }
    }
  }

  # Self-validation: check if modified string still matches the regex
  catch {unset new_cap new_vt}
puts "result: $result"
  if {![regexp $regex $result -> new_cap new_vt]} {
    error "Self-validation failed: modified string no longer matches the regex"
  }
  
  # Check if the correct part was replaced
  if {$pattern_type eq "cap" && $new_cap ne $new_value} {
    error "Self-validation failed: cap was not replaced correctly"
  }
  if {$pattern_type eq "vt" && $new_vt ne $new_value} {
    error "Self-validation failed: vt was not replaced correctly"
  }

  # Debug information for the result
  if {$debug} {
    puts "Debug: Original string: $input_str"
    puts "Debug: Modified string: $result"
    puts "Debug: Self-validation passed"
  }

  return $result
}

puts [change_driveCapacity_or_VTtype "BUFFD4BWP" {^.*D(\d+)BWP(U?L?H?VT)?$} vt LVT 1]
