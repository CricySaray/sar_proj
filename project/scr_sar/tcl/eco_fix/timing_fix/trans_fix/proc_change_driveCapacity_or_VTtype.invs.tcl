#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/29 23:19:33 Monday
# label     : atomic_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : Use a regexp expression to match the `celltype`, retrieve the `driveCapacity` and `VTtype` from it, then specify the type to be replaced (`cap` or `vt`), and 
#             provide the string that needs to be used for replacement. This `proc` (procedure) will then return the `celltype` after replacement.
# update    : 2025/09/30 01:53:04 Tuesday
#             This proc will extract the flag character preceding `driveCapacity` based on your regular expression. For example, it extracts "D" or "X" from "D4 / X8" — the 
#             specific result depends on the regular expression. The extraction principle is as follows: locate the single character that comes right before the first `(\d+)` 
#             (digit group) in the regular expression. 
#             Take the regular expression `{^.*D(\d+)BWP(U?L?H?VT)?$}` as an example: the character "D" here is the flag character. When using `regsub` to replace the drive 
#             size, this flag character will be included in the replacement process to improve the accuracy of the replacement.
# return    : changed celltype
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
    # Extract the leading character before the cap field (\d+)
    if {![regexp {.*(\w)\(\\d\+\)} $regex -> leader_char]} {
      error "Failed to extract leader character before cap in regex"
    }
    # Remove possible regex metacharacters from leader character
    set leader_char [string trimright $leader_char "*."]
    if {$debug} {
      puts "Debug: Extracted leader character for cap: '$leader_char'"
    }
    
    # Build matching pattern with leader character for more accurate replacement
    set cap_pattern "${leader_char}${cap}"
    set escaped_cap_pattern [regsub -all {\W} $cap_pattern {\\&}]
    set new_cap_str "${leader_char}${new_value}"
    
puts "point 0: cap_pattern : $cap_pattern | escaped_cap_pattern: $escaped_cap_pattern | new_cap_str: $new_cap_str"
    if {[regsub $escaped_cap_pattern $result $new_cap_str result]} {
      if {$debug} {
        puts "Debug: Replaced cap pattern '$cap_pattern' with '$new_cap_str'"
      }
    } else {
      error "Failed to replace cap value in the input string"
    }
  } else {
    # For vt, handle empty string case
    if {$vt eq ""} {
      # Extract the part after cap to the end of the string (including fixed structures like BWP)
      set cap_pos [string first $cap $result]
      if {$cap_pos == -1} {
        error "Failed to find cap value in the string"
      }
      set after_cap_pos [expr {$cap_pos + [string length $cap]}]
      set after_cap [string range $result $after_cap_pos end]
      
      # Append new vt value to the end using string concatenation
      set result "${result}${new_value}"
      
      if {$debug} {
        puts "Debug: Appended vt '$new_value' to end of string"
        puts "Debug: Cap was at position $cap_pos, followed by: '$after_cap'"
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

# puts [change_driveCapacity_or_VTtype "BUFF4D4BWPLVT" {^.*D(\d+)BWP(U?L?H?VT)?$} cap 5 1]
