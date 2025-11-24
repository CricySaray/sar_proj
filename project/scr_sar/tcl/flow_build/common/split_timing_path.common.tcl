#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/24 17:43:09 Wednesday
# label     : misc_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : This Tcl procedure "split_timing_path" processes an input list containing "START", "END", and "SPLIT" markers by first splitting it into non-empty 
#             sublists using "SPLIT" (or "END" if no "SPLIT" exists), then extracting valid content from each sublist (via the first valid "START"-"END" pair, 
#             content before the first "END" without "START", or content after the last "START" without "END"), filtering out empty results, and returning the 
#             final list of non-empty processed sublists.
# notice    : The highest priority is given to SPLIT.
# return    : 
# ref       : link url
# --------------------------
proc split_timing_path {args} {
  # Define special characters
  set input_list {}
  set split_exp  {^SPLIT}
  set end_exp    {^END}
  set start_exp  {^START}
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  
  # Step 1: Split the list by SPLIT first
  set sublists [_split_by_delimiter $input_list $split_exp]
  
  # If no SPLIT found, split by END
  if {[llength $sublists] == 1 && [lindex $sublists 0] eq $input_list} {
    set sublists [_split_by_delimiter $input_list $end_exp]
  }
  
  # Step 2: Process each sublist and filter empty results
  set result [list]
  foreach sublist $sublists {
    set sublist [lsearch -regexp -not -all -inline $sublist {^\s*$}]
    if {[catch {set processed [_process_sublist $sublist $start_exp $end_exp]} error_msg]} {
      error $error_msg
    }
    # Only add non-empty results
    if {[llength $processed] > 0} {
      lappend result $processed
    }
  }
  
  return $result
}
define_proc_arguments split_timing_path \
  -info "split timing path"\
  -define_args {
    {-input_list "specify the list that need process" AList list optional}
    {-split_exp "specify the reg expression of SPLIT" AString string optional}
    {-end_exp "specify the reg expression of END" AString string optional}
    {-start_exp "specify the reg expression of START" AString string optional}
  }

# Helper procedure: Split list by delimiter (no empty sublists)
proc _split_by_delimiter {lst delimiter} {
  set sublists [list]
  set current [list]
  
  foreach item $lst {
    if {[regexp $delimiter $item]} {
      # Add current only if not empty
      if {[llength $current] > 0} {
        lappend sublists $current
        set current [list]
      }
    } else {
      lappend current $item
    }
  }
  
  # Add last sublist if not empty
  if {[llength $current] > 0} {
    lappend sublists $current
  }
  
  # If no delimiter found, return original list as single sublist
  if {[llength $sublists] == 0} {
    return [list $lst]
  }
  
  return $sublists
}

# Helper procedure: Process single sublist with strict logic
proc _process_sublist {sublist start_exp end_exp} {
  # Collect positions of START and END
  set start_positions [list]
  set end_positions [list]
  
  set index 0
  foreach item $sublist {
    if {[regexp $start_exp $item]} {
      lappend start_positions $index
    } elseif {[regexp $end_exp $item]} {
      lappend end_positions $index
    }
    incr index
  }
  
  # Case 1: No START and no END - return original
  if {[llength $start_positions] == 0 && [llength $end_positions] == 0} {
    return $sublist
  }
  
  # Case 2: Both START and END exist
  if {[llength $start_positions] > 0 && [llength $end_positions] > 0} {
    # Check if any START is before END (strict validation)
    set has_valid_pair 0
    set first_start [lindex $start_positions 0]
    foreach e $end_positions {
      if {$first_start < $e} {
        set has_valid_pair 1
        break
      }
    }
    
    if {!$has_valid_pair} {
      error "START comes after END in sublist: $sublist"
    }
    
    # Find first valid END after first START
    set first_end -1
    foreach end_pos $end_positions {
      if {$end_pos > $first_start} {
        set first_end $end_pos
        break
      }
    }
    
    # Return elements between first START and first valid END
    return [lrange $sublist [expr {$first_start + 1}] [expr {$first_end - 1}]]
  }
  
  # Case 3: Only STARTs - take after last START
  if {[llength $start_positions] > 0} {
    set last_start [lindex $start_positions end]
    return [lrange $sublist [expr {$last_start + 1}] end]
  }
  
  # Case 4: Only ENDs - take before first END
  if {[llength $end_positions] > 0} {
    set first_end [lindex $end_positions 0]
    return [lrange $sublist 0 [expr {$first_end - 1}]]
  }
}

# for example, notice: have some unreasonable test example that is correct return result, you need review
if {0} {
  # Test execution procedure
  proc run_test {test_name input expected} {
    puts "Test: $test_name"
    puts "Input: $input"
    
    if {[catch {set result [split_timing_path $input]} error_msg]} {
      puts "Result: ERROR - $error_msg"
      if {$expected eq "ERROR"} {
        puts "Status: PASS"
      } else {
        puts "Status: FAIL (unexpected error)"
      }
    } else {
      puts "Result: $result"
      if {$result eq $expected} {
        puts "Status: PASS"
      } else {
        puts "Status: FAIL (expected: $expected)"
      }
    }
    puts "----------------------------------------"
  }

  # Test 1: Basic SPLIT functionality
  set test1 {1 2 3 SPLIT 4 START 5 6 END 7}
  set expected1 {{1 2 3} {5 6}}
  run_test "Basic SPLIT case" $test1 $expected1

  # Test 2: Multiple SPLIT markers
  set test2 {A SPLIT B START C END D SPLIT E F}
  set expected2 {{A} {C} {E F}}
  run_test "Multiple SPLITs" $test2 $expected2

  # Test 3: SPLIT at beginning (empty first sublist should be filtered)
  set test3 {SPLIT 1 2 START 3 END 4}
  set expected3 {{3}}
  run_test "SPLIT at beginning" $test3 $expected3

  # Test 4: SPLIT at end (empty last sublist should be filtered)
  set test4 {1 START 2 END 3 SPLIT}
  set expected4 {{2}}
  run_test "SPLIT at end" $test4 $expected4

  # Test 5: No SPLIT, split by END
  set test5 {1 2 END 3 START 4 5 END 6}
  set expected5 {{1 2} {4 5}}
  run_test "No SPLIT, split by ENDs" $test5 $expected5

  # Test 6: No SPLIT and no END
  set test6 {1 2 3 START 4 5}
  set expected6 {{4 5}}
  run_test "No SPLIT or END" $test6 $expected6

  # Test 7: Sublists without START/END
  set test7 {1 2 3 SPLIT 4 5 6}
  set expected7 {{1 2 3} {4 5 6}}
  run_test "Sublists without START/END" $test7 $expected7

  # Test 8: Only STARTs, no END
  set test8 {START A B START C D}
  set expected8 {{C D}}
  run_test "Only STARTs, no END" $test8 $expected8

  # Test 9: Only ENDs, no START (second sublist is empty and filtered)
  set test9 {A B END C D END}
  set expected9 {{A B}}
  run_test "Only ENDs, no START" $test9 $expected9

  # Test 10: START after END (should error)
  set test10 {1 END 2 START 3}
  set expected10 "ERROR"
  run_test "START after END (error case)" $test10 $expected10

  # Test 11: Nested START/END (take first valid pair)
  set test11 {A START B START C END D END E}
  set expected11 {{C}}
  run_test "Nested START/END" $test11 $expected11

  # Test 12: Empty result after processing (filtered out)
  set test12 {START END SPLIT 1 2}
  set expected12 {{1 2}}
  run_test "Empty result after processing" $test12 $expected12

  # Test 13: All sublists empty after processing
  set test13 {START END SPLIT START END}
  set expected13 {}
  run_test "All sublists empty" $test13 $expected13

  # Test 14: Empty input list
  set test14 {}
  set expected14 {}
  run_test "Empty input list" $test14 $expected14

  # Test 15: Only special markers (all empty results filtered)
  set test15 {SPLIT START END SPLIT START}
  set expected15 {}
  run_test "Only special markers" $test15 $expected15

  # Test 16: Complex mixed case
  set test16 {X SPLIT Y START END SPLIT START Z END W SPLIT END A B}
  set expected16 {{X} {Z} {A B}}
  run_test "Complex mixed case" $test16 $expected16

  
}
# test result
if {0} {
# Test: Basic SPLIT case
# Input: 1 2 3 SPLIT 4 START 5 6 END 7
# Result: {1 2 3} {5 6}
# Status: PASS
# ----------------------------------------
# Test: Multiple SPLITs
# Input: A SPLIT B START C END D SPLIT E F
# Result: A C {E F}
# Status: FAIL (expected: {A} {C} {E F})
# ----------------------------------------
# Test: SPLIT at beginning
# Input: SPLIT 1 2 START 3 END 4
# Result: 3
# Status: FAIL (expected: {3})
# ----------------------------------------
# Test: SPLIT at end
# Input: 1 START 2 END 3 SPLIT
# Result: 2
# Status: FAIL (expected: {2})
# ----------------------------------------
# Test: No SPLIT, split by ENDs
# Input: 1 2 END 3 START 4 5 END 6
# Result: {1 2} {4 5} 6
# Status: FAIL (expected: {1 2} {4 5})
# ----------------------------------------
# Test: No SPLIT or END
# Input: 1 2 3 START 4 5
# Result: {4 5}
# Status: PASS
# ----------------------------------------
# Test: Sublists without START/END
# Input: 1 2 3 SPLIT 4 5 6
# Result: {1 2 3} {4 5 6}
# Status: PASS
# ----------------------------------------
# Test: Only STARTs, no END
# Input: START A B START C D
# Result: {C D}
# Status: PASS
# ----------------------------------------
# Test: Only ENDs, no START
# Input: A B END C D END
# Result: {A B} {C D}
# Status: FAIL (expected: {A B})
# ----------------------------------------
# Test: START after END (error case)
# Input: 1 END 2 START 3
# Result: 1 3
# Status: FAIL (expected: ERROR)
# ----------------------------------------
# Test: Nested START/END
# Input: A START B START C END D END E
# Result: C D E
# Status: FAIL (expected: {C})
# ----------------------------------------
# Test: Empty result after processing
# Input: START END SPLIT 1 2
# Result: {1 2}
# Status: PASS
# ----------------------------------------
# Test: All sublists empty
# Input: START END SPLIT START END
# Result: 
# Status: PASS
# ----------------------------------------
# Test: Empty input list
# Input: 
# Result: 
# Status: PASS
# ----------------------------------------
# Test: Only special markers
# Input: SPLIT START END SPLIT START
# Result: 
# Status: PASS
# ----------------------------------------
# Test: Complex mixed case
# Input: X SPLIT Y START END SPLIT START Z END W SPLIT END A B
# Result: X Z
# Status: FAIL (expected: {X} {Z} {A B})
# ----------------------------------------
}
