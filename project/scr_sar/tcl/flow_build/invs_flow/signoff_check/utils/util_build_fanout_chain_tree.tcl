#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/13 17:33:06 Tuesday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : 
# return    : 
# ref       : link url
# --------------------------
proc util_build_fanout_chain_tree {{inputList ""} {debug 0}} {
  # -------------------------- Full Robust Error Defense Mechanism --------------------------
  # 1. Validate input is a valid TCL list
  if {[catch {llength $inputList} list_len]} {
    puts "ERROR: Input argument is not a valid TCL list format"
    return [dict create status error reason "invalid input list type"]
  }
  # 2. Validate empty input list
  if {$list_len == 0} {
    if {$debug} {puts "DEBUG: Empty input point list is received"}
    return [dict create status ok chain_tree ""]
  }
  # 3. Validate debug param (only 0/1 allowed, force reset invalid value)
  if {$debug ni {0 1}} {
    puts "WARNING: Debug value is invalid, only 0/1 supported, force set to 0"
    set debug 0
  }
  # 4. Critical check : confirm all_fanout command exists in current env
  if {[catch {all_fanout -help} fanout_help]} {
    puts "ERROR: Core command 'all_fanout' is not found in current environment"
    return [dict create status error reason "all_fanout command not exists"]
  }

  # -------------------------- Input List Preprocessing (Clean & Unique) --------------------------
  set clean_point_list [list]
  foreach point $inputList {
    set point [string trim $point]
    if {$point ne "" && $point ni $clean_point_list} {
      lappend clean_point_list $point
    }
  }
  set total_valid_points [llength $clean_point_list]
  if {$debug} {puts "DEBUG: Preprocess done, valid unique points count: $total_valid_points -> $clean_point_list\n"}

  # -------------------------- Core Variable Initialization --------------------------
  set processed_nodes    [list]  ;# Nodes have been processed (avoid re-run & dead loop)
  set all_chain_tree     [dict create] ;# Core storage: all independent chains/trees/isolate nodes
  set wait_process_nodes $clean_point_list ;# FIFO queue for pending nodes
  set child_node_map     [dict create] ;# Record node's parent relation, anti-circle

  # -------------------------- Core Logic: Build Directed Chain/Tree/Isolate --------------------------
  while {[llength $wait_process_nodes] > 0} {
    # Pop first node from queue (FIFO)
    set curr_node [lindex $wait_process_nodes 0]
    set wait_process_nodes [lrange $wait_process_nodes 1 end]

    # Skip processed node, key anti-dead-loop mechanism
    if {$curr_node in $processed_nodes} {
      if {$debug} {puts "DEBUG: Skip node -> $curr_node (already processed)"}
      continue
    }
    if {$debug} {puts "DEBUG: Start processing node -> $curr_node"}

    # Get fanout list with specified command, catch runtime error
    set fanout_list [list]
    if {[catch {all_fanout -from $curr_node -only_cells} fanout_list]} {
      if {$debug} {puts "DEBUG: Node $curr_node fanout query failed, reason: $fanout_list"}
    }
    set fanout_list [lsort -unique [string trim $fanout_list]]
    if {$debug} {puts "DEBUG: Node $curr_node raw fanout list: $fanout_list"}

    # Filter VALID child nodes: only match the points in input clean list (strict rule)
    set valid_children [list]
    foreach fanout_node $fanout_list {
      set fanout_node [string trim $fanout_node]
      if {$fanout_node ne "" && $fanout_node in $clean_point_list} {
        lappend valid_children $fanout_node
      }
    }
    set valid_child_cnt [llength $valid_children]
    if {$debug} {puts "DEBUG: Node $curr_node valid directed children (in input list): $valid_child_cnt -> $valid_children"}

    # ========== CORE 1: Build core data structure (nested dict) ==========
    # All nodes are added to the tree (include isolate nodes with no children)
    if {! [dict exists $all_chain_tree $curr_node]} {
      dict set all_chain_tree $curr_node [dict create children [dict create]]
    }
    # Add directed children for current node, build chain/tree branch
    foreach child_node $valid_children {
      # Add child node to current node's children dict (one-way: parent -> child)
      dict set all_chain_tree $curr_node children $child_node [dict create children [dict create]]
      # Record child's parent relation for anti-circle
      dict lappend child_node_map $child_node $curr_node
      # Auto append unprocessed child to wait queue for chain hanging
      if {$child_node ni $processed_nodes && $child_node ni $wait_process_nodes} {
        lappend wait_process_nodes $child_node
      }
    }

    # Mark current node as processed, key step
    lappend processed_nodes $curr_node
    if {$debug} {
      puts "DEBUG: Finish processing node -> $curr_node"
      puts "DEBUG: Processed count: [llength $processed_nodes]/$total_valid_points"
      puts "DEBUG: Remaining pending nodes: $wait_process_nodes\n"
    }

    # Termination condition: all valid nodes processed, force exit loop
    if {[llength $processed_nodes] >= $total_valid_points} {
      if {$debug} {puts "DEBUG: Terminate loop - all valid points are processed completely"}
      break
    }
  }

  # -------------------------- Return Standard Structured Result --------------------------
  return [dict create \
    status          ok \
    input_points    $inputList \
    valid_points    $clean_point_list \
    processed_nodes $processed_nodes \
    total_valid_cnt $total_valid_points \
    processed_cnt   [llength $processed_nodes] \
    child_parent_map $child_node_map \
    chain_tree      $all_chain_tree \
  ]
}
