#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/05 12:40:11 Tuesday
# label     : package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : The sort_nested_list proc sorts sublists in a nested list by category using regex-matched 
#             sorting methods with validated lsort options, featuring configurable checks for category-method matching and unmatched categories.
# return    : sorted list
# ref       : link url
# --------------------------
proc sort_nested_list {nested_list sort_methods {strict_category_count 0} {allow_unmatched 0} {default_sort {-increasing}}} {
  # Validate input structure is a proper nested list
  if {![llength $nested_list]} {
    error "proc sort_nested_list: Empty nested list provided"
  }
  
  # Extract categories and validate structure
  set categories [list]
  foreach entry $nested_list {
    if {[llength $entry] != 2} {
      error "proc sort_nested_list: Invalid entry format: $entry. Expected {category {items...}}"
    }
    lappend categories [lindex $entry 0]
  }
  set category_count [llength $categories]

  # Validate sort methods structure
  if {![llength $sort_methods]} {
    error "proc sort_nested_list: Empty sort methods list provided"
  }
  
  set sort_method_count [llength $sort_methods]
  foreach method $sort_methods {
    if {[llength $method] != 2} {
      error "proc sort_nested_list: Invalid sort method format: $method. Expected {pattern {options...}}"
    }
    lassign $method pattern options
    validate_sort_options $options
  }

  # Check category count matches sort method count if strict mode enabled
  if {$strict_category_count && $category_count != $sort_method_count} {
    error "proc sort_nested_list: Category count ($category_count) does not match sort method count ($sort_method_count)"
  }

  # Process each category
  set result [list]
  foreach entry $nested_list {
    lassign $entry category items
    
    # Find matching sort method using regex (first match has highest priority)
    set matched 0
    set sort_options ""
    foreach method $sort_methods {
      lassign $method pattern options
      if {[regexp -- $pattern $category]} {
        set sort_options $options
        set matched 1
        break
      }
    }
    
    # Handle unmatched categories
    if {!$matched} {
      if {!$allow_unmatched} {
        error "proc sort_nested_list: No matching sort method found for category: $category"
      } else {
        set sort_options $default_sort
      }
    }

    # Apply sorting and add to result
    set sorted_items [lsort {*}$sort_options $items]
    lappend result [list $category $sorted_items]
  }

  return $result
}

proc validate_sort_options {options} {
  # Valid lsort options (TCL 8.6)
  set valid_options {
    -ascii -dictionary -integer -real -nocase -unique
    -increasing -decreasing -index -stride -command
  }
  
  # Check for valid options and proper syntax
  set i 0
  while {$i < [llength $options]} {
    set opt [lindex $options $i]
    
    # Check if option is valid
    if {$opt ni $valid_options} {
      error "proc validate_sort_options: Invalid sort option: $opt. Valid options are: $valid_options"
    }
    
    # Check options that require an argument
    if {$opt in {-index -stride -command}} {
      if {$i + 1 >= [llength $options]} {
        error "proc validate_sort_options: Option $opt requires an argument"
      }
      # Validate argument types
      switch $opt {
        -index {
          set arg [lindex $options [incr i]]
          if {![string is integer -strict $arg] || $arg < 0} {
            error "proc validate_sort_options: Invalid index value: $arg. Must be non-negative integer"
          }
        }
        -stride {
          set arg [lindex $options [incr i]]
          if {![string is integer -strict $arg] || $arg <= 0} {
            error "proc validate_sort_options: Invalid stride value: $arg. Must be positive integer"
          }
        }
        -command {
          incr i ;# Just increment, we can't validate the command exists here
        }
      }
    }
    incr i
  }
}

if {0} {
	# Test Case 1: Basic sorting functionality test
	puts "=== Test Case 1: Basic Sorting Functionality ==="
	set test_data1 {
		{integers {
			{5 0.8 "item5"} {2 0.2 "item2"} {7 0.7 "item7"}
			{1 0.1 "item1"} {3 0.3 "item3"} {6 0.6 "item6"}
			{4 0.4 "item4"} {8 0.8 "item8"}
		}}
		{floats {
			{3 0.00001 "val3"} {1 0.15 "val1"} {4 0.47 "val4"}
			{2 0.89 "val2"} {5 0.36 "val5"} {7 0.72 "val7"}
			{6 0.55 "val6"} {8 0.28 "val8"}
		}}
	}

	set sort_methods1 {
		{integers {-index 0 -increasing -integer}}
		{floats {-index 1 -decreasing -real}}
	}

	# Execute sorting
	set sorted_data1 [sort_nested_list $test_data1 $sort_methods1]

	# Display results
	puts "Integers category sorted (by index 0 ascending):"
	puts [lindex $sorted_data1 0 1]
	puts "\nFloats category sorted (by index 1 descending):"
	puts [lindex $sorted_data1 1 1]


	# Test Case 2: Regex matching test
	puts "\n\n=== Test Case 2: Regular Expression Matching ==="
	set test_data2 {
		{groupA {
			{b 3 "apple"} {a 1 "banana"} {d 4 "cherry"}
			{c 2 "date"} {f 6 "elderberry"} {e 5 "fig"}
			{h 8 "grape"} {g 7 "kiwi"}
		}}
		{groupB {
			{3 "red" 100} {1 "blue" 200} {4 "green" 50}
			{2 "yellow" 150} {6 "purple" 75} {5 "orange" 125}
			{8 "pink" 30} {7 "black" 90}
		}}
		{otherGroup {
			{x 99} {b 22} {m 55} {a 11} {z 88}
			{p 77} {g 44} {d 33}
		}}
	}

	set sort_methods2 {
		{groupA {-index 0 -increasing -ascii}}
		{groupB {-index 2 -decreasing -integer}}
		{other.* {-index 1 -increasing -integer}}
	}

	# Execute sorting (using non-strict mode)
	set sorted_data2 [sort_nested_list $test_data2 $sort_methods2 0]

	# Display results
	puts "GroupA after sorting (by index 0 alphabetical ascending):"
	puts [lindex $sorted_data2 0 1]
	puts "\nGroupB after sorting (by index 2 numerical descending):"
	puts [lindex $sorted_data2 1 1]
	puts "\nOtherGroup after sorting (by index 1 numerical ascending):"
	puts [lindex $sorted_data2 2 1]

}
