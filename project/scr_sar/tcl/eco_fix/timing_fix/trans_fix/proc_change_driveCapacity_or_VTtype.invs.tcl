#!/bin/tclsh
# --------------------------
# author    : aiden song
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
# update    : 2026/01/31 20:37:01 Saturday
#             change method of changing capacity and vt
# return    : changed celltype
# ref       : link url
# --------------------------
source ../lut_build/operateLUT.tcl; # operateLUT
alias sus "subst -nocommands -nobackslashes"
proc change_driveCapacity_or_VTtype {input_str regex pattern_type new_value {debug 0}} {
  # Validate input parameters
  if {![string is boolean -strict $debug]} {
    error "proc change_driveCapacity_or_VTtype: Debug must be a boolean value (0 or 1)"
  }
  if {$pattern_type ne "cap" && $pattern_type ne "vt"} {
    error "proc change_driveCapacity_or_VTtype: Pattern type must be either 'cap' or 'vt'"
  }
  if {$pattern_type eq "cap" && ![string is double -strict $new_value]} {
    error "proc change_driveCapacity_or_VTtype: New value for cap must be an integer"
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
    error "proc change_driveCapacity_or_VTtype: Input string does not match the regular expression"
  }

  # Debug information for matched values
  if {$debug} {
    puts "Debug: Matched cap value: $cap"
    puts "Debug: Matched vt value: $vt"
  }
  set capacityFlag [operateLUT -type read -attr capacityflag]
  lassign [get_driveCapacity_of_celltype_returnCapacityAndVTtype $input_str $regex] temp_capacity temp_vt
  set stdCellFlag [operateLUT -type read -attr stdcellflag]
  # set vtMatchExp [operateLUT -type read -attr vtmatchexp]
  set ifDriveCapacityConvert_from_P_to_point [operateLUT -type read -attr ifDriveCapacityConvert_from_P_to_point]
  set vtMapList [operateLUT -type read -attr vt_maplist]

  if {$pattern_type eq "cap"} {
    set temp_capExp [regsub [sus {^(.*$capacityFlag)${temp_capacity}($stdCellFlag.*)${temp_vt}$}] $input_str [sus {\1<cap>\2${temp_vt}}]]
    if {$ifDriveCapacityConvert_from_P_to_point} {
      set new_value [regsub {\.} $new_value P]
    }
    set result [regsub {<cap>} $temp_capExp $new_value]
    if {![operateLUT -type exists -attr [list celltype $result]]} {
      error "proc change_driveCapacity_or_VTtype: error celltype($result) after changing capacity!!! check it."
    }
  } elseif {$pattern_type eq "vt"} {
    set temp_vtExp [regsub [sus {^(.*$capacityFlag)${temp_capacity}($stdCellFlag.*)${temp_vt}$}] $input_str [sus {\1${temp_capacity}\2<vt>}]]
    set temp_vtname [lindex [lsearch -inline -index 1 -exact $vtMapList $new_value] 0]
    set result [regsub {<vt>} $temp_vtExp $temp_vtname]
    if {![operateLUT -type exists -attr [list celltype $result]]} {
      error "proc change_driveCapacity_or_VTtype: error celltype($result) after changing vt!!! check it."
    }
  }
  return $result
}

