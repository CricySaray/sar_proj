#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/11/30 17:27:21 Sunday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Sorts target list by reference list order, validates elements exist in reference, with debug support and error handling
# return    : sorted list
# ref       : link url
# --------------------------
proc sort_list_byReferenceList {refList targetList debug} {
  # Validate input types
  if {![llength $refList]} {
    error "proc sort_list_byReferenceList: Reference list cannot be empty"
  }
  if {![llength $targetList]} {
    if {$debug} {puts "Debug: Target list is empty, returning empty list"}
    return {}
  }
  if {$debug ni {0 1}} {
    error "proc sort_list_byReferenceList: Debug parameter must be 0 or 1"
  }

  # Create position mapping from reference list
  array set refPos {}
  set idx 0
  foreach elem $refList {
    if {![info exists refPos($elem)]} {
      set refPos($elem) $idx
      incr idx
    }
    if {$debug} {puts "Debug: Mapped '$elem' to position $refPos($elem)"}
  }

  # Collect all invalid elements in target list
  set invalidElems {}
  foreach elem $targetList {
    if {![info exists refPos($elem)]} {
      lappend invalidElems $elem
    }
  }
  if {[llength $invalidElems] > 0} {
    error "proc sort_list_byReferenceList: Elements in target list not found in reference list: [join $invalidElems {, }]"
  }

  # Sort target list based on reference positions
  set sortedList [lsort -integer -command {apply {{a b} {
    upvar refPos refPos
    set diff [expr {$refPos($a) - $refPos($b)}]
    return $diff
  }}} $targetList]

  if {$debug} {
    puts "Debug: Original target list: $targetList"
    puts "Debug: Sorted target list: $sortedList"
  }

  return $sortedList
}

if {0} {
  # Test Case 1: Normal sorting with debug enabled
  set refList {apple banana cherry date elderberry}
  set targetList {cherry apple date banana}
  set debug 1
  puts "Test Case 1:"
  if {[catch {sort_list_byReferenceList $refList $targetList $debug} result]} {
    puts "Error: $result"
  } else {
    puts "Final Result: $result\n"
  }

  # Test Case 2: Target list with invalid element and debug disabled
  set refList {red green blue yellow}
  set targetList {green purple blue}
  set debug 0
  puts "Test Case 2:"
  if {[catch {sort_list_byReferenceList $refList $targetList $debug} result]} {
    puts "Error: $result"
  } else {
    puts "Final Result: $result\n"
  }

  # Test Case 3: Empty target list with debug enabled
  set refList {a b c d}
  set targetList {}
  set debug 1
  puts "Test Case 3:"
  if {[catch {sort_list_byReferenceList $refList $targetList $debug} result]} {
    puts "Error: $result"
  } else {
    puts "Final Result: $result\n"
  }

  # Test Case 4: Reference list with duplicate elements
  set refList {x y x z y}
  set targetList {y x z}
  set debug 1
  puts "Test Case 4:"
  if {[catch {sort_list_byReferenceList $refList $targetList $debug} result]} {
    puts "Error: $result"
  } else {
    puts "Final Result: $result\n"
  }

}
