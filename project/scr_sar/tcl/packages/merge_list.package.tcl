#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/04 17:25:07 Monday
# label     : package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|misc_proc)
# descrip   : merge list
#             Merge multiple lists, retaining only those with non-empty values at the specified index position
# return    : merged list
# ref       : link url
# --------------------------
proc merge_lists {index_spec check_mode args} {
	# Parameters:
	#   index_spec - Index specification list, e.g., {1 1} means index 1 at the first level, index 1 at the second level
	#   check_mode - Check mode: 0-lax mode, 1-strict mode (default 0)
	#   args - Multiple lists to be processed

	# Set default check mode
	if {![info exists check_mode]} {
		set check_mode 1
	}
	# Validate index specification
	foreach idx $index_spec {
		if {![string is integer -strict $idx] || $idx < 0} {
			error "Invalid index: $idx must be a non-negative integer"
		}
	}
	# Validate check_mode parameter
	if {$check_mode ni {0 1}} {
		error "check_mode must be 0 or 1"
	}
	set result [list]
	# Process each input list
	foreach input_list $args {
		# Check if it's a valid list
		if {![string is list $input_list]} {
			if {$check_mode} {
				error "Invalid list format: $input_list"
			} else {
				continue
			}
		}
		set current $input_list
		set valid 1
		# Traverse index specification to check each level
		foreach idx $index_spec {
			if {[llength $current] <= $idx} {
				# Index out of range
				set valid 0
				break
			}
			set current [lindex $current $idx]
		}
		# Check if the final value is non-empty
		if {$valid} {
			# Determine if the value is non-empty (not empty string or empty list)
			if {$current ne "" && [llength $current] > 0} {
				lappend result $input_list
			}
		} elseif {$check_mode} {
			error "Index out of range for list $input_list"
		}
	}
	return $result
}

if {0} {
  # Usage example:
  set list1 {a {b c d} e}
  set list2 {x {y "" z} w}
  set list3 {1 {2 3 4} 5}
  
  # Check if the element at index 1 of the sublist at index 1 is non-empty in each list
  puts [merge_lists {1} 1 $list1 $list2 $list3]
}
