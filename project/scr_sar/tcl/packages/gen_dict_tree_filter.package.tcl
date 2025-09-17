#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/17 16:03:34 Wednesday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : generates a tree-structured representation of a nested dictionary, supporting value validation, value visibility control, maximum depth limitation, 
#             simplified display of repetitive structures, and filtering by key/value regex patterns (including combined filtering and greedy mode).
# Generate a tree-like structure of a nested dictionary as a list of strings with filtering capabilities
# Parameters:
#   var_name          - Name of the dictionary variable to process (will be root node name)
#   value_rules       - Dictionary of value validation rules: keys are regex patterns, 
#                       values are nesting levels (0 for flat lists, 1+ for nested lists)
#   debug             - Debug mode (0 = off, 1 = on), default is 0
#   show_values       - Flag to show values (1 = show, 0 = hide), default is 1
#   max_depth         - Maximum iteration depth (0 = unlimited), default is 0
#   simpleDisplayMode - Enable simplified display mode (1 = on, 0 = off), default is 0
#   threshold         - Threshold for simplified display (only when simpleDisplayMode=1), default is 5
#   filter            - Filter conditions: list of {type pattern} pairs, where type is "key" or "value"
#   greedy            - Greedy mode for key filtering (1 = on, 0 = off), default is 0
# Returns:            - List where each element is a line of the filtered tree structure
# ref       : link url
# --------------------------
source ./every_any.package.tcl; # every
proc gen_dict_tree {args} {
  set var_name          ""
  set value_rules       {} ; # for example: {{^\d(\.\d+)?$} 0 {^\d(\.\d+)?$} 1 {^[LRH]VT$} 0} ; 0 is like list: {1.2 2.3 3.1 ...} , 1 is like list: {{1.1 2.1 2.4} {3 3.2 1.4} ...}
  set show_values       1
  set max_depth         0 ; # 0: not limit
  set simpleDisplayMode 0
  set threshold         5
  set filter            {} ; # for example: [list [list key {^test3}] [list value {^\d+(\.\d+)?$}]]
  set greedy            0
  set debug             0
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }

  set flags_vbar_branch_treeEnd [list "│" "├── " "└── "]
  # Validate parameters
  _validate_parameters $value_rules $debug $show_values $max_depth $simpleDisplayMode $threshold $filter $greedy
  
  # Access variable from caller's scope using upvar 1
  if {[catch {upvar 1 $var_name dict_data} err]} {
    error "Error: Failed to access variable '$var_name' from caller scope: $err"
  }
  
  # Check if the variable exists in caller's scope
  if {![info exists dict_data]} {
    error "Error: Variable '$var_name' does not exist in caller scope."
  }
  
  # Make a copy of the original data for filtering
  set filtered_data $dict_data
  
  # Apply filtering if specified
  if {[llength $filter] > 0} {
    set has_key_filter [expr {[lsearch -glob $filter {key *}] != -1}]
    set has_value_filter [expr {[lsearch -glob $filter {value *}] != -1}]
    
    if {$has_key_filter && $has_value_filter} {
      # First filter by key, then by value
      set key_filters [lsearch -all -inline -glob $filter {key *}]
      set key_filters [lmap f $key_filters {lindex $f 1}]
      set filtered_by_key [_filter_by_key $filtered_data $key_filters $greedy 0 $debug]
      
      if {$filtered_by_key eq ""} {
        return [list "No matches found for key filters"]
      }
      
      set value_filters [lsearch -all -inline -glob $filter {value *}]
      set value_filters [lmap f $value_filters {lappend temp_value_filters [lindex $f 1] 0} ; set temp_value_filters]
      set filtered_data [_filter_by_value $filtered_by_key $value_filters $debug]
    } elseif {$has_key_filter} {
      # Only filter by key
      set key_filters [lsearch -all -inline -glob $filter {key *}]
      set key_filters [lmap f $key_filters {lindex $f 1}]
      set filtered_data [_filter_by_key $filtered_data $key_filters $greedy 0 $debug]
    } elseif {$has_value_filter} {
      # Only filter by value
      set value_filters [lsearch -all -inline -glob $filter {value *}]
      set value_filters [lmap f $value_filters {lappend temp_value_filters [lindex $f 1] 0} ; set temp_value_filters]
      set filtered_data [_filter_by_value $filtered_data $value_filters $debug]
    }
    
    if {$filtered_data eq ""} {
      return [list "No matches found for specified filters"]
    }
    
    # Handle cases where we need a temporary root
    if {[llength $filtered_data] % 2 != 0 || ![dict exists $filtered_data [lindex [dict keys $filtered_data] 0]]} {
      set filtered_data [dict create temp_root $filtered_data]
      set var_name "temp_root"
    }
  }
  
  # Initialize the result list
  set result [list]
  
  # Check if filtered data is empty
  if {$filtered_data eq ""} {
    if {$debug} {
      puts "Debug: Filtered data is empty"
    }
    lappend result "$var_name: {}"
    return $result
  }
  
  # Verify it's a valid dictionary (even number of elements)
  if {[llength $filtered_data] % 2 != 0} {
    error "Error: Filtered data is not a valid dictionary (odd number of elements)."
  }
  
  if {$debug} {
    puts "Debug: Starting tree generation for variable '$var_name'"
    puts "Debug: Total top-level entries: [expr {[llength $filtered_data] / 2}]"
    puts "Debug: Using value validation rules: $value_rules"
    puts "Debug: Show values flag: $show_values"
    puts "Debug: Maximum iteration depth: [expr {$max_depth == 0 ? "unlimited" : $max_depth}]"
    puts "Debug: Simple display mode: [expr {$simpleDisplayMode ? "on" : "off"}] (threshold: $threshold)"
    puts "Debug: Filter conditions: $filter"
    puts "Debug: Greedy mode: [expr {$greedy ? "on" : "off"}]"
  }
  
  # Add root node to result
  lappend result $var_name
  
  # Get and sort top-level nodes for consistent output
  set top_nodes [lsort [dict keys $filtered_data]]
  set total_nodes [llength $top_nodes]
  
  # Process top-level nodes with possible simplification
  set processed_nodes [_process_nodes_with_simplification \
    $filtered_data $top_nodes "" $value_rules $debug $show_values 1 $max_depth $simpleDisplayMode $threshold $flags_vbar_branch_treeEnd]
  lappend result {*}$processed_nodes
  
  if {$debug} {
    puts "Debug: Tree generation completed"
  }
  
  return $result
}
define_proc_arguments gen_dict_tree \
  -info "gen dict tree with filter function"\
  -define_args {
    {-var_name "specify the var name, NOTICE: variable name" AString string optional}
    {-value_rules "specify the rules for identify value expression" AList list optional}
    {-show_values "if it shows value of every key, default: 1, you need specify 1 or 0" oneOfString one_of_string {optional value_type {values {1 0}}}}
    {-max_depth "specify the max depth to show, default:0 that is not limit for max depth" AInt int optional}
    {-simpleDisplayMode "if turn on the simple display mode. if it is on, will simplize the key structure that is similar with each other" "" boolean optional}
    {-threshold "specify the threshold of similar number of key structure" AInt int optional}
    {-filter "Filter conditions: list of {type pattern} pairs, where type is \"key\" or \"value\"" AList list optional}
    {-greedy "Greedy mode for key filtering (1 = on, 0 = off), default is 0" "" boolean optional}
    {-debug "debug mode" "" boolean optional}
  }

# Validate input parameters
proc _validate_parameters {value_rules debug show_values max_depth simpleDisplayMode threshold filter greedy} {
  # Validate value_rules is a dictionary
  if {[llength $value_rules] % 2 != 0} {
    error "Invalid value_rules: must be a dictionary with even number of elements"
  }
  
  # Validate boolean parameters
  if {$debug ni {0 1}} { error "debug must be 0 or 1" }
  if {$show_values ni {0 1}} { error "show_values must be 0 or 1" }
  if {$simpleDisplayMode ni {0 1}} { error "simpleDisplayMode must be 0 or 1" }
  if {$greedy ni {0 1}} { error "greedy must be 0 or 1" }
  
  # Validate numeric parameters
  if {![string is integer -strict $max_depth] || $max_depth < 0} {
    error "max_depth must be a non-negative integer"
  }
  if {![string is integer -strict $threshold] || $threshold < 1} {
    error "threshold must be a positive integer"
  }
  
  # Validate filter format
  foreach condition $filter {
    if {[llength $condition] != 2} {
      error "Invalid filter condition: must be a list of two elements {type pattern}"
    }
    lassign $condition type pattern
    if {$type ni {key value}} {
      error "Invalid filter type '$type': must be 'key' or 'value'"
    }
    # Test if pattern is a valid regular expression
    if {[catch {regexp $pattern ""}]} {
      error "Invalid regular expression pattern: '$pattern'"
    }
  }
}

# Filter dictionary by key patterns
proc _filter_by_key {dict_data patterns greedy current_depth debug} {
  set result [dict create]
  set matched_any 0
  
  foreach key [dict keys $dict_data] {
    set value [dict get $dict_data $key]
    set is_valid_value [_is_valid_value $value {} $debug]
    set is_dict [expr {!$is_valid_value && [llength $value] % 2 == 0 && [llength $value] > 0 && [catch {dict keys $value} err]==0}]
    
    # Check if current key matches any pattern
    set key_matches 0
    foreach pattern $patterns {
      if {[regexp $pattern $key]} {
        set key_matches 1
        break
      }
    }
    
    if {$key_matches} {
      set matched_any 1
      # Add this key to results with all its content
      dict set result $key $value
    } elseif {$is_dict} {
      # Recursively check child keys
      set filtered_children [_filter_by_key $value $patterns $greedy [expr {$current_depth + 1}] $debug]
      if {[dict size $filtered_children] > 0} {
        set matched_any 1
        if {$greedy} {
          # In greedy mode, add entire subtree
          dict set result $key $value
        } else {
          # In non-greedy mode, add only filtered path
          dict set result $key $filtered_children
        }
      }
    }
  }
  
  return [expr {$matched_any ? $result : ""}]
}

# Filter dictionary by value patterns
proc _filter_by_value {dict_data patterns debug} {
  set result [dict create]
  set matched_any 0
  
  foreach key [dict keys $dict_data] {
    set value [dict get $dict_data $key]
    set is_valid_value [_is_valid_value $value $patterns $debug]
    set is_dict [expr {!$is_valid_value && [llength $value] % 2 == 0 && [llength $value] > 0 && [catch {dict keys $value} err]==0}]
    
    if {$is_valid_value} {
      # Value matches pattern - add this path
      dict set result $key $value
      set matched_any 1
    } elseif {$is_dict} {
      # Recursively check child nodes
      set filtered_children [_filter_by_value $value $patterns $debug]
      if {[dict size $filtered_children] > 0} {
        dict set result $key $filtered_children
        set matched_any 1
      }
    }
  }
  
  return [expr {$matched_any ? $result : ""}]
}

# Helper procedure to process nodes with possible simplification
proc _process_nodes_with_simplification {parent_dict nodes prefix value_rules debug show_values current_depth max_depth simpleDisplayMode threshold threeFlagsForBuildTree} {
  set lines [list]
  set total_nodes [llength $nodes]
  
  if {$simpleDisplayMode && $total_nodes >= $threshold} {
    # Group nodes by their structure
    set structure_groups [_group_nodes_by_structure $parent_dict $nodes $value_rules $debug $current_depth $max_depth]
    
    foreach group $structure_groups {
      lassign $group struct_key group_nodes
      
      set group_size [llength $group_nodes]
      if {$group_size < $threshold} {
        # Process small groups normally
        foreach node $group_nodes {
          set value [dict get $parent_dict $node]
          set is_last [expr {$node eq [lindex $nodes end]}]
          set node_results [_get_dict_node $node $value $prefix $is_last $value_rules $debug $show_values $current_depth $max_depth $simpleDisplayMode $threshold $threeFlagsForBuildTree]
          lappend lines {*}$node_results
        }
      } else {
        # Process large groups with simplification
        if {$debug} {
          puts "Debug: Applying simplification to group of $group_size nodes with structure: $struct_key"
        }
        
        # Get first and last nodes in the group
        set first_node [lindex $group_nodes 0]
        set last_node [lindex $group_nodes end]
        
        # Process first node
        set first_value [dict get $parent_dict $first_node]
        set is_last_first [expr {0}]
        set first_results [_get_dict_node $first_node $first_value $prefix $is_last_first $value_rules $debug $show_values $current_depth $max_depth $simpleDisplayMode $threshold $threeFlagsForBuildTree]
        lappend lines {*}$first_results
        
        # Add ellipsis for middle nodes
        set ellipsis_prefix $prefix
        set ellipsis_line "${ellipsis_prefix}│   ..."
        lappend lines $ellipsis_line
        set count_line "${ellipsis_prefix}│   (omitted [expr {$group_size - 2}] similar entries)"
        lappend lines $count_line
        
        # Process last node
        set last_value [dict get $parent_dict $last_node]
        set is_last_last [expr {$last_node eq [lindex $nodes end]}]
        set last_results [_get_dict_node $last_node $last_value $prefix $is_last_last $value_rules $debug $show_values $current_depth $max_depth $simpleDisplayMode $threshold $threeFlagsForBuildTree]
        lappend lines {*}$last_results
      }
    }
  } else {
    # Process all nodes normally
    for {set i 0} {$i < $total_nodes} {incr i} {
      set node [lindex $nodes $i]
      set value [dict get $parent_dict $node]
      set is_last [expr {$i == $total_nodes - 1}]
      
      if {$debug} {
        puts "Debug: Processing key '$node' (is_last=$is_last, level=$current_depth)"
      }
      
      set node_results [_get_dict_node $node $value $prefix $is_last $value_rules $debug $show_values $current_depth $max_depth $simpleDisplayMode $threshold $threeFlagsForBuildTree]
      lappend lines {*}$node_results
    }
  }
  
  return $lines
}

# Helper procedure to group nodes by their structure
proc _group_nodes_by_structure {parent_dict nodes value_rules debug current_depth max_depth} {
  set groups [dict create]
  
  foreach node $nodes {
    set value [dict get $parent_dict $node]
    set is_valid_value [_is_valid_value $value $value_rules $debug]
    set is_dict [expr {!$is_valid_value && [llength $value] % 2 == 0 && [llength $value] > 0 && [catch {dict keys $value} err]==0}]
    
    # Create a unique key representing the node structure
    if {$is_dict && ($max_depth == 0 || $current_depth < $max_depth)} {
      set child_keys [lsort [dict keys $value]]
      set struct_key "dict: [join $child_keys ,]"
    } else {
      set struct_key "value:[expr {$is_valid_value ? "valid" : "invalid"}]"
    }
    
    # Add node to appropriate group
    if {![dict exists $groups $struct_key]} {
      dict set groups $struct_key [list]
    }
    dict lappend groups $struct_key $node
  }
  
  # Convert to list of groups and sort by size (largest first)
  set group_list [list]
  dict for {key members} $groups {
    lappend group_list [list $key $members]
  }
  
  return [lsort -integer -decreasing -index 2 [lmap g $group_list {lappend g [llength [lindex $g 1]]}]]
}

# Recursive helper procedure to build tree nodes list
proc _get_dict_node {current_key current_value prefix is_last value_rules debug show_values current_depth max_depth simpleDisplayMode threshold threeFlagsForBuildTree} {
  lassign $threeFlagsForBuildTree vbar branch treeEnd
  set lines [list]
  
  # Determine connector based on whether this is the last child
  set connector [expr {$is_last ? $treeEnd : $branch}]
  
  # Check if current value is a valid value based on rules, or a dictionary
  set is_valid_value [_is_valid_value $current_value $value_rules $debug]
  set is_dict [expr {!$is_valid_value && [llength $current_value] % 2 == 0 && [llength $current_value] > 0 && [catch {dict keys $current_value} err]==0}]
  
  # Add current node line
  if {$is_dict} {
    # This is an intermediate node (contains more keys)
    lappend lines "${prefix}${connector}${current_key}"
    if {$debug} {
      puts "Debug: Key '$current_key' contains [expr {[llength $current_value]/2}] subkeys (level=$current_depth)"
    }
  } else {
    # This is a leaf node - show/hide value based on flag
    if {$show_values} {
      if {$current_value eq ""} {
        lappend lines "${prefix}${connector}${current_key}: {}"
      } else {
        set display_value [expr {$is_valid_value ? "{$current_value}" : $current_value}]
        lappend lines "${prefix}${connector}${current_key}: $display_value"
      }
    } else {
      # Only show key without value
      lappend lines "${prefix}${connector}${current_key}"
    }
    if {$debug} {
      puts "Debug: Leaf node '$current_key' with value: [expr {$current_value eq "" ? "{}" : $current_value}] (level=$current_depth)"
    }
    return $lines
  }
  
  # Check if we've reached maximum depth
  if {$max_depth > 0 && $current_depth >= $max_depth} {
    if {$debug} {
      puts "Debug: Reached maximum depth ($max_depth) at key '$current_key'"
    }
    return $lines
  }
  
  # Calculate prefix for child nodes
  set child_prefix [expr {$is_last ? "${prefix}    " : "${prefix}${vbar}   "}]
  set next_depth [expr {$current_depth + 1}]
  
  # Get and sort child keys
  set child_keys [lsort [dict keys $current_value]]
  
  # Process child nodes with possible simplification
  set processed_children [_process_nodes_with_simplification \
    $current_value $child_keys $child_prefix $value_rules $debug $show_values $next_depth $max_depth $simpleDisplayMode $threshold]
  lappend lines {*}$processed_children
  
  return $lines
}

# Helper procedure to validate if a value is a valid leaf value based on rules
proc _is_valid_value {value value_rules debug} {
  # Empty value is always valid
  if {$value eq ""} {
    return 1
  }
  
  # Check each rule
  dict for {pattern depth} $value_rules {
    if {[_validate_list_depth $value $pattern $depth $debug]} {
      if {$debug} {
        puts "Debug: Value matches rule - pattern: '$pattern', depth: $depth"
      }
      return 1
    }
  }
  
  if {$debug} {
    puts "Debug: Value does not match any validation rules"
  }
  return 0
}

# Helper procedure to validate list structure and content
proc _validate_list_depth {list_data pattern depth debug} {
  if {$depth == 0} {
    # Validate flat list
    return [every x $list_data { regexp $pattern $x }]
  } else {
    # Validate nested list
    set cmd "every y \$list_data \{ every x \$y \{ regexp \$pattern \$x \} \}"
    # Build nested every commands for deeper levels
    for {set i 2} {$i <= $depth} {incr i} {
      set var [string index "xyzabcdefghijklmnopqrstuvwxyz" $i]
      set cmd "every $var \$list_data \{ $cmd \}"
    }
    
    if {$debug} {
      puts "Debug: Validating with command: $cmd"
    }
    
    # Execute the constructed validation command using uplevel with list expansion
    return [uplevel 1 [list {*}$cmd]]
  }
}


if {0} {
  # Test procedure for filtering functionality
  proc test_filtering {} {
    # Create a sample nested dictionary with 4 levels
    set test_data {
      root {
        level1 {
          test1 {
            level2 {
              level3 {
                value 123.45
              }
            }
          }
          test2 {
            level2 {
              level3 {
                value 67.89
              }
            }
          }
          other1 {
            level2 {
              level3 {
                value abc
              }
            }
          }
          test3 {
            level2 {
              level3 {
                value 100
              }
            }
          }
          test4 {
            nested {
              level3 {
                value 200.5
              }
            }
          }
          other2 {
            level2 {
              level3 {
                value def
              }
            }
          }
        }
      }
    }
    
    puts "=== Original Tree ==="
    set original [gen_dict_tree -var_name test_data]
    foreach line $original { puts $line }
    
    puts "\n\n=== Filter by key matching '^test' ==="
    set key_filter [list [list key {^test}]]
    set filtered_by_key [gen_dict_tree -var_name test_data -filter $key_filter]
    foreach line $filtered_by_key { puts $line }
    
    puts "\n\n=== Filter by value matching numbers ==="
    set value_filter [list [list value {^\d+(\.\d+)?$}]]
    set filtered_by_value [gen_dict_tree -var_name test_data -filter $value_filter]
    foreach line $filtered_by_value { puts $line }
    
    puts "\n\n=== Filter by key '^test' and value matching numbers ==="
    set combined_filter [list [list key {^test3}] [list value {^\d+(\.\d+)?$}]]
    set filtered_combined [gen_dict_tree -var_name test_data -filter $combined_filter]
    foreach line $filtered_combined { puts $line }
    
    puts "\n\n=== Filter with greedy mode ==="
    set filtered_greedy [gen_dict_tree -var_name test_data -filter $key_filter]
    foreach line $filtered_greedy { puts $line }
  }

  # Run test
  test_filtering

}
