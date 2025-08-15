#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/06 10:06:02 Wednesday
# label     : package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : computes the symmetric difference of two lists by first removing duplicates and returning elements present in either list but not in both.
# return    : list 
# ref       : link url
# --------------------------
# Calculate the symmetric difference of two lists
alias xor "symmetric_diff"
proc symmetric_diff {list1 list2} {
  # Remove duplicates first
  set a [unique $list1]
  set b [unique $list2]
  set diff {}
  # Collect elements in A that are not in B
  foreach elem $a {
    if {![in_list $elem $b]} {
      lappend diff $elem
    }
  }
  # Collect elements in B that are not in A
  foreach elem $b {
    if {![in_list $elem $a]} {
      lappend diff $elem
    }
  }
  return $diff
}
# Helper function: Check if an element is in a list
proc in_list {elem list} {
  return [expr {[lsearch -exact $list $elem] != -1}]
}
# Helper function: Remove duplicates from a list
proc unique {list} {
  set result {}
  foreach elem $list {
    if {![in_list $elem $result]} {
      lappend result $elem
    }
  }
  return $result
}
if {0} {
  # Test
  set listA {1 2 3 4}
  set listB {3 4 5 6}
  puts "Symmetric difference: [symmetric_diff $listA $listB]" ;# Output: 1 2 5 6
  set a {song an rui}
  set b {an}
  puts "test 2: [symmetric_diff $a $b]"
}
