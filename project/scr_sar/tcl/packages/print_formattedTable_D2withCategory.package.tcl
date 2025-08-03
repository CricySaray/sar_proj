#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/03 13:11:17 Sunday
# label     : display_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : advance edition of print_formattedTable
#             can print category name and table list belong to this category
# return    : display formatted table
# ref       : link url
# --------------------------
proc print_formattedTable_D2withCategory {{dataList {}} {indentChar "\t"} {separator "-"}} {
  # Validate input format
  if {![llength $dataList]} {
    error "Input list is empty or invalid"
  }
  if {![string length $indentChar]} {
    error "Indent character cannot be empty"
  }

  set output [list]
  
  # Process each category in top level
  foreach category $dataList {
    # Extract category name and items (enforce structure)
    set categoryName [lindex $category 0]
    set items [lindex $category 1]
    
    if {![string length $categoryName] || ![llength $items]} {
      error "Invalid category structure: must be {categoryName {itemList}}"
    }
    
    # Add category name as header
    lappend output $categoryName
    
    # Prepare items for formatting
    set itemLines [list]
    foreach item $items {
      lappend itemLines [join $item "\t"]
    }
    
    # Format items with column command for alignment
    set pipe [open "| column -t" w+]
    puts $pipe [join $itemLines "\n"]
    close $pipe w
    
    # Read formatted items and add indentation
    set formattedItems [list]
    while {[gets $pipe line] > -1} {
      lappend formattedItems "${indentChar}${line}"
    }
    close $pipe
    
    # Add separator line between header and items
    if {[llength $formattedItems] > 0} {
      set sepLength [expr [string length [lindex $formattedItems 0]] - [string length $indentChar]]
      set sepLine "${indentChar}[string repeat $separator $sepLength]"
      lappend output $sepLine
    }
    
    # Add formatted items to output
    lappend output {*}$formattedItems
  }
  
  return [join $output "\n"]
}

# for example
if {0} {
  set test {{cate1 {{sdjfl 1} {jalsdfjlkjg 1244} {jslkkdfjlksjflskdjf 3}}} {cate2 {{jf 34} {sjldkfjklsdjfl k}}}}
  puts [print_formattedTable_D2withCategory $test]
}
