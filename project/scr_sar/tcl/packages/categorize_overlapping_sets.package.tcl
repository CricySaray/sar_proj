#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/03 11:13:52 Sunday
# label     : package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : A procedure that consolidates elements from multiple categories, creates combined categories 
#             with "_AND_" naming, sorts items intelligently, and offers options for original categories and verbosity.
# return    : classified list {{category1 {item1 item2 ...}} {category2 {item1 item2 ...}}}
# ref       : link url
# --------------------------
proc categorize_overlapping_sets {categories {verbose 0} {keep_original 0}} {
  # Helper procedure to sort items intelligently
  proc smart_sort {items} {
    # Check if all items are numeric
    set all_numeric 1
    foreach item $items {
      if {![string is double -strict $item]} {
        set all_numeric 0
        break
      }
    }
    if {$all_numeric} {
      # Sort as numbers (ascending)
      set numeric_items [lmap item $items {expr {$item}}]
      set sorted [lsort -real $numeric_items]
      # Convert back to strings
      return [lmap num $sorted {format "%.10g" $num}]
    } else {
      # Sort as strings (alphabetical order)
      return [lsort -dictionary $items]
    }
  }
  # Check if at least one category is provided
  if {[llength $categories] == 0} {
    error "At least one category must be provided"
  }
  # Validate category format
  foreach category $categories {
    if {[llength $category] != 2} {
      error "Invalid category format: $category. Correct format is {category_name {item1 item2 ...}}"
    }
    set cat_name [lindex $category 0]
    set cat_items [lindex $category 1]
    # Check if items form a valid list using standard TCL method
    if {[catch {llength $cat_items}]} {
      error "Items for category $cat_name are not a valid list: $cat_items"
    }
  }
  # Check for duplicate category names
  set cat_names [list]
  foreach category $categories {
    set cat_name [lindex $category 0]
    if {[lsearch $cat_names $cat_name] != -1} {
      error "Duplicate category name: $cat_name"
    }
    lappend cat_names $cat_name
  }
  # Collect all elements and their associated categories
  array set element_cats {}
  set all_elements [list]
  foreach category $categories {
    set cat_name [lindex $category 0]
    set cat_items [lindex $category 1]
    foreach item $cat_items {
      set item_str [string trim $item]
      if {$item_str eq ""} {
        if {$verbose} {
          puts "Warning: Empty string found in category $cat_name, skipped"
        }
        continue
      }
      lappend element_cats($item_str) $cat_name
      lappend all_elements $item_str
    }
  }
  # Deduplicate elements
  set unique_elements [lsort -unique $all_elements]
  # Create combined categories with new naming convention
  array set combined_cats {}
  foreach element $unique_elements {
    set cats [lsort $element_cats($element)]
    # Use underscores around && to avoid space-separated names
    set combined_name [join $cats "_AND_"]
    lappend combined_cats($combined_name) $element
  }
  # Prepare result
  set result [list]
  # Add original categories if needed
  if {$keep_original} {
    foreach category $categories {
      set cat_name [lindex $category 0]
      set cat_items [lsort -unique [lindex $category 1]]
      # Apply smart sorting
      set sorted_items [smart_sort $cat_items]
      lappend result [list $cat_name $sorted_items]
    }
  }
  # Add combined categories
  foreach combined_name [lsort [array names combined_cats]] {
    # Skip single categories if original categories are kept to avoid duplication
    if {$keep_original && [llength [split $combined_name "_AND_"]] == 1} {
      continue
    }
    # Apply smart sorting to items
    set sorted_items [smart_sort $combined_cats($combined_name)]
    lappend result [list $combined_name $sorted_items]
  }
  # Verbose output
  if {$verbose} {
    puts "Categorization completed:"
    foreach item $result {
      puts "  [lindex $item 0]: [llength [lindex $item 1]] elements"
    }
  }
  return $result
}

# Example usage:
if {0} {
  # Example with mixed string names
  set category1 {error_VTtype {name1 name3 name2 name4 song}}
  set category2 {error_length {name2 name3 name5 name6 song}}
  set category3 {error_capacity {name3 name6 name7 name8 song}}
  set result [categorize_overlapping_sets [list $category1 $category2 $category3]]
  puts ""
  puts $result
  puts ""
  puts "String items result:"
  foreach item $result {
    puts "[lindex $item 0]: [lindex $item 1]"
  }
  # Example with numeric items
  set num_category1 {value_high {3.5 1.2 5.7}}
  set num_category2 {value_low {2.1 1.2 4.3}}
  set num_result [categorize_overlapping_sets [list $num_category1 $num_category2]]
  puts ""
  puts $num_result
  puts ""
  puts "\nNumeric items result:"
  foreach item $num_result {
    puts "[lindex $item 0]: [lindex $item 1]"
  }
}
