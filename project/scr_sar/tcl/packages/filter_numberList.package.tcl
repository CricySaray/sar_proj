#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/06 10:46:09 Wednesday
# label     : package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : filters a list of numbers to retain those within a specified range, with options to control boundary 
#             inclusion, sorting, and uniqueness, while performing input validation.
# return    : filtered list 
# ref       : link url
# --------------------------
proc filter_numberList {numbers range {include_min 1} {include_max 1} {sort 1} {unique 1}} {
  # Error checking: ensure numbers is a valid list
  if {![llength $numbers]} {
    error "proc filter_numberList: Invalid number list: must provide a list containing numbers"
  }
  # Error checking: ensure range is a list with two elements
  if {[llength $range] != 2} {
    error "proc filter_numberList: Invalid range: range must be a list containing two numbers, e.g. {1 10}"
  }
  set range [lsort -increasing -real $range]
  # Extract and validate range values
  set min_val [lindex $range 0]
  set max_val [lindex $range 1]
  # Check if range values are numbers
  if {![string is double -strict $min_val] || ![string is double -strict $max_val]} {
    error "proc filter_numberList: Range values must be numbers"
  }
  # Convert to numeric type
  set min_val [expr {$min_val}]
  set max_val [expr {$max_val}]
  # Automatically swap if min is greater than max
  if {$min_val > $max_val} {
    set temp $min_val
    set min_val $max_val
    set max_val $temp
  }
  # Filter the number list
  set result [list]
  foreach num $numbers {
    # Skip non-numeric elements
    if {![string is double -strict $num]} {
      puts "Warning: skipping non-numeric element '$num'"
      continue
    }
    set num [expr {$num}]
    set include 0
    # Determine inclusion based on switches
    if {$include_min && $include_max} {
      if {$num >= $min_val && $num <= $max_val} {
        set include 1
      }
    } elseif {$include_min} {
      if {$num >= $min_val && $num < $max_val} {
        set include 1
      }
    } elseif {$include_max} {
      if {$num <= $max_val && $num > $min_val} {
        set include 1
      }
    } else {
      if {$num > $min_val && $num < $max_val} {
        set include 1 
      } 
    }
    if {$include} {
      lappend result $num
    }
  }
  # Handle uniqueness
  if {$unique} {
    set result [lsort -unique $result]
  }
  # Handle sorting
  if {$sort} {
    # Avoid re-sorting if we already did unique sort
    if {!$unique} {
      set result [lsort -real $result]
    }
    set result [lsort -real $result]
  }
  return $result
}

if {1} {
  # 基本使用
  set nums {5 12 3 15 8 1}
  set filtered [filter_numberList $nums {3 10} 0 0]
  puts $filtered ;# 输出: 5 8 3
  # 不包含边界值
  set filtered [filter_numberList $nums {3 10} 0 0]
  puts $filtered ;# 输出: 5 8
  # 排序并去重
  set nums {5 12 5 3 15 8 1 8}
  set filtered [filter_numberList $nums {3 10} 1 1 1 1]
  puts $filtered ;# 输出: 3 5 8
  
  set nums {20 16 12 8 4}
  set filtered [filter_numberList $nums {1 12}]
  puts $filtered
}
