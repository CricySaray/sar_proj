#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/16 18:33:36 Tuesday
# label     : gui_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : takes a nested dictionary variable name and returns a list of strings representing its tree structure with proper indentation and hierarchy indicators.
# return    : list with specified tree structrue
# ref       : link url
# --------------------------
# Generate a tree-like structure of a nested dictionary as a list of strings
# Parameters:
#   var_name  - Name of the dictionary variable to process (will be root node name)
#   debug     - Debug mode (0 = off, 1 = on), default is 0
# Returns:    - List where each element is a line of the tree structure
proc gen_dict_tree {var_name {debug 0}} {
  # Access variable from caller's scope using upvar 1
  if {[catch {upvar 1 $var_name dict_data} err]} {
    error "Error: Failed to access variable '$var_name' from caller scope: $err"
  }
  
  # Check if the variable exists in caller's scope
  if {![info exists dict_data]} {
    error "Error: Variable '$var_name' does not exist in caller scope."
  }
  
  # Initialize the result list
  set result [list]
  
  # Check if variable is empty
  if {$dict_data eq ""} {
    if {$debug} {
      puts "Debug: Variable '$var_name' is empty"
    }
    lappend result "$var_name: {}"
    return $result
  }
  
  # Verify it's a valid dictionary (even number of elements)
  if {[llength $dict_data] % 2 != 0} {
    error "Error: Variable '$var_name' is not a valid dictionary (odd number of elements)."
  }
  
  if {$debug} {
    puts "Debug: Starting tree generation for variable '$var_name'"
    puts "Debug: Total top-level entries: [expr {[llength $dict_data] / 2}]"
  }
  
  # Add root node to result
  lappend result $var_name
  
  # Get and sort top-level nodes for consistent output
  set top_nodes [lsort [dict keys $dict_data]]
  set total_nodes [llength $top_nodes]
  
  # Process each top-level node
  for {set i 0} {$i < $total_nodes} {incr i} {
    set node [lindex $top_nodes $i]
    set value [dict get $dict_data $node]
    set is_last [expr {$i == $total_nodes - 1}]
    
    if {$debug} {
      puts "Debug: Processing top-level key '$node' (is_last=$is_last)"
    }
    
    # Call helper to process children and accumulate results
    set node_results [_gen_dict_node $node $value "" $is_last $debug]
    lappend result {*}$node_results
  }
  
  if {$debug} {
    puts "Debug: Tree generation completed"
  }
  
  return $result
}

# Recursive helper procedure to build tree nodes list
# Parameters:
#   current_key  - Current key name
#   current_value - Value associated with current key
#   prefix       - Visual prefix for current level
#   is_last      - Whether this is the last child of its parent
#   debug        - Debug mode flag
# Returns:       - List of lines for this node and its children
proc _gen_dict_node {current_key current_value prefix is_last debug} {
  set lines [list]
  
  # Determine connector based on whether this is the last child
  set connector [expr {$is_last ? "└── " : "├── "}]
  
  # Check if current value is a dictionary (potential parent node with more keys)
  set is_dict [expr {[llength $current_value] % 2 == 0 && [llength $current_value] > 0 && [catch {dict keys $current_value} err]==0}]
  
  # Add current node line
  if {$is_dict} {
    # This is an intermediate node (contains more keys)
    lappend lines "${prefix}${connector}${current_key}"
    if {$debug} {
      puts "Debug: Key '$current_key' contains [expr {[llength $current_value]/2}] subkeys"
    }
  } else {
    # This is a leaf node - show the value
    if {$current_value eq ""} {
      lappend lines "${prefix}${connector}${current_key}: {}"
    } else {
      lappend lines "${prefix}${connector}${current_key}: $current_value"
    }
    if {$debug} {
      puts "Debug: Leaf node '$current_key' with value: [expr {$current_value eq "" ? "{}" : $current_value}]"
    }
    return $lines
  }
  
  # Calculate prefix for child nodes
  set child_prefix [expr {$is_last ? "${prefix}    " : "${prefix}│   "}]
  
  # Get and sort child keys
  set child_keys [lsort [dict keys $current_value]]
  set total_children [llength $child_keys]
  
  # Recursively process each child key
  for {set i 0} {$i < $total_children} {incr i} {
    set child_key [lindex $child_keys $i]
    set child_value [dict get $current_value $child_key]
    set child_is_last [expr {$i == $total_children - 1}]
    
    set child_lines [_gen_dict_node $child_key $child_value $child_prefix $child_is_last $debug]
    lappend lines {*}$child_lines
  }
  
  return $lines
}

# TEST
if {1} {
  # Complex test case for print_dict_tree procedure
  proc complex_test_case {} {
    # Create a deeply nested dictionary with various edge cases
    set software_project {
      name "Advanced Toolkit v2.3.1"
      description "A comprehensive development framework with multiple modules"
      version {
        major 2
        minor 3
        patch 1
        release "stable"
        build {
          number 456
          date "2023-10-15"
          compiler {
            name "GCC"
            version "11.2.0"
          }
        }
      }
      
      modules {
        core {
          description "Core functionality"
          files {
            main.c "Main entry point"
            utils.c "Utility functions"
            config.h ""
            {data structures} {
              list.c "Linked list implementation"
              hash.c "Hash table functions"
              tree.c "Binary tree operations"
            }
          }
          dependencies {}
        }
        
        network {
          description "Network communication module"
          status "beta"
          protocols {
            tcp {
              enabled 1
              port 8080
              options {
                timeout 30
                retries 3
              }
            }
            udp {
              enabled 0
              port 5000
            }
          }
        }
        
        ui {
          description "User interface components"
          themes {
            light {
              background "#FFFFFF"
              text "#000000"
            }
            dark {
              background "#222222"
              text "#EEEEEE"
            }
          }
        }
      }
      
      settings {
        logging {
          enabled 1
          level "info"
          {output destinations} {
            console 1
            file "app.log"
            syslog 0
          }
        }
        security {
          encryption {
            enabled 1
            algorithm "AES-256"
          }
          authentication {
            methods {
              password 1
              token 1
              biometric 0
            }
          }
        }
      }
      
      {special characters test!@#} {
        {key with spaces} "value with spaces and\t tabs"
        {empty value} ""
        {nested!} {
          deep {
            very_deep {
              deepest "We made it to the bottom!"
            }
          }
        }
      }
      
      empty_section {}
    }
    
    # Test in normal mode
    puts "=== Normal Mode Output ==="
    set result [gen_dict_tree software_project]
    puts [join $result \n]
    # Test in debug mode with more details
    #puts "\n\n=== Debug Mode Output ==="
    #print_dict_tree software_project 1
  }

  # Execute the complex test case
  complex_test_case
}
