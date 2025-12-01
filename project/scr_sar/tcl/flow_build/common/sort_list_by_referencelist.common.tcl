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
proc sort_list_byReferenceList {refList targetList index debug} {
  # Validate input types
  if {![llength $refList]} {
    error "Reference list cannot be empty"
  }
  if {![llength $targetList]} {
    if {$debug} {puts "Debug: Target list is empty, returning empty list"}
    return {}
  }
  if {$debug ni {0 1}} {
    error "Debug parameter must be 0 or 1"
  }
  if {![string is integer -strict $index] || $index < -1} {
    error "Index parameter must be -1 or non-negative integer"
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
    # Get comparison element based on index
    set compElem [expr {$index == -1 ? $elem : [lindex $elem $index]}]
    if {![info exists refPos($compElem)]} {
      lappend invalidElems $elem
    }
  }
  if {[llength $invalidElems] > 0} {
    error "Elements in target list not found in reference list: [join $invalidElems {, }]"
  }

  # Prepare comparison data for sorting
  set sortIndex $index
  array set sortRefPos {}
  foreach {k v} [array get refPos] {
    set sortRefPos($k) $v
  }

  # Sort target list with 2-parameter comparison function
  set sortedList [lsort -command {apply {{a b} {
    upvar sortIndex sortIndex sortRefPos sortRefPos
    set aComp [expr {$sortIndex == -1 ? $a : [lindex $a $sortIndex]}]
    set bComp [expr {$sortIndex == -1 ? $b : [lindex $b $sortIndex]}]
    set diff [expr {$sortRefPos($aComp) - $sortRefPos($bComp)}]
    if {$diff < 0} {
      return -1
    } elseif {$diff > 0} {
      return 1
    } else {
      return 0
    }
  }}} $targetList]

  if {$debug} {
    puts "Debug: Original target list: $targetList"
    puts "Debug: Sorted target list: $sortedList"
  }

  return $sortedList
}

if {0} {
	# Test Case 1: Basic sorting with index=-1 (normal mode)
	set refList {apple banana cherry date}
	set targetList {cherry apple banana}
	set debug 0
	set index -1
	puts "Test Case 1: Basic sorting (index=-1)"
	if {[catch {sort_list_byReferenceList $refList $targetList $index $debug} result]} {
		puts "Error: $result"
	} else {
		puts "Result: $result\n"
	}

	# Test Case 2: Sorting sublists with index=0
	set refList {fruit vegetable meat dairy}
	set targetList {{vegetable carrot} {dairy milk} {fruit apple}}
	set debug 0
	set index 0
	puts "Test Case 2: Sublist sorting (index=0)"
	if {[catch {sort_list_byReferenceList $refList $targetList $index $debug} result]} {
		puts "Error: $result"
	} else {
		puts "Result: $result\n"
	}

	# Test Case 3: Sorting sublists with index=1
	set refList {red green blue yellow}
	set targetList {{apple green} {banana yellow} {cherry red}}
	set debug 0
	set index 1
	puts "Test Case 3: Sublist sorting (index=1)"
	if {[catch {sort_list_byReferenceList $refList $targetList $index $debug} result]} {
		puts "Error: $result"
	} else {
		puts "Result: $result\n"
	}

	# Test Case 4: Invalid element in target list (sublist mode)
	set refList {cat dog bird}
	set targetList {{pet cat} {pet fish} {pet dog}}
	set debug 0
	set index 1
	puts "Test Case 4: Invalid element in sublist"
	if {[catch {sort_list_byReferenceList $refList $targetList $index $debug} result]} {
		puts "Error: $result"
	} else {
		puts "Result: $result\n"
	}

	# Test Case 5: Empty target list
	set refList {a b c}
	set targetList {}
	set debug 1
	set index 0
	puts "Test Case 5: Empty target list"
	if {[catch {sort_list_byReferenceList $refList $targetList $index $debug} result]} {
		puts "Error: $result"
	} else {
		puts "Result: $result\n"
	}

	# Test Case 6: Invalid index parameter
	set refList {x y z}
	set targetList {y x z}
	set debug 0
	set index -2
	puts "Test Case 6: Invalid index value"
	if {[catch {sort_list_byReferenceList $refList $targetList $debug $index} result]} {
		puts "Error: $result"
	} else {
		puts "Result: $result\n"
	}

	# Test Case 7: Reference list with duplicates (sublist mode)
	set refList {one two one three two}
	set targetList {{num two} {num one} {num three}}
	set debug 1
	set index 1
	puts "Test Case 7: Reference list with duplicates"
	if {[catch {sort_list_byReferenceList $refList $targetList $debug $index} result]} {
		puts "Error: $result"
	} else {
		puts "Result: $result\n"
	}

}
