#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/12 18:29:07 Sunday
# label     : 
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : what?
#   - `_validate_var_index`: Validates that `var_index` is an array; initializes it if missing. No return value; throws error if `var_index` exists but isn't an array.
# 	- `defv <full_var> <value> [allow_create_namespace=0]`: Defines a namespaced variable and updates `var_index`. `allow_create_namespace` (0/1) controls if last 
# 	        namespace level can be created. No return value; throws errors on invalid names/paths/duplicates.
# 	- `setv <var_name> <value>`: Updates value of an existing managed variable via its short name. No return value; throws errors if variable is missing/invalid.
# 	- `getv <var_name>`: Retrieves value of a managed variable via its short name. Returns variable's value; throws errors if variable is missing/invalid.
# 	- `_get_all_vars_in_namespace <namespace>`: Recursively gets all variables in a namespace and its subnamespaces. Returns list of full variable paths.
# 	- `importv <namespace> [allow_overwrite=0] [verbose=0]`: Imports variables from a namespace (and subnamespaces) into `var_index`. `allow_overwrite` (0/1) 
# 	        enables overwriting existing entries; `verbose` (0/1) controls output. Returns count of imported variables.
# 	- `clear_namespace_vars <namespace>`: Clears all managed variables in a namespace (and subnamespaces) from both scope and `var_index`. Returns message 
# 	        with count of cleared variables.
# 	- `unsetv <var_name_or_path>`: Removes a managed variable by short name or full path from scope and `var_index`. Returns success message; throws errors 
# 	        if variable is unmanaged/missing.
# 	- `clear_all_vars`: Clears all managed variables from scope and resets `var_index`. Returns success message.
# 	- `listv`: Lists all managed variables with their full paths and values. Returns formatted string with entries like "var -> path = value".
# 	- `linkv ?-force 0|1? ?var1 ...?`: Links managed variables to current scope for direct `$var` access. `-force` (0/1) controls overwriting existing scope 
# 	        variables; no vars = link all. Returns count of linked variables.
# 	- `unlinkv ?var1 ...?`: Unlinks variables from current scope (preserves underlying data). No vars = unlink all linked. Returns count of unlinked variables; 
# 	        throws errors on unlinked/unmanaged vars.
# 	- `getvns <var1> ?var2 ...?`: Returns namespace hierarchy for variables (e.g., "song::an::rui::" for "testvar" in that path). Returns single string for one 
# 	        var, list for multiple; "NA" for missing vars.
# ref       : link url
# --------------------------
# Global index to map simple variable names to their full namespace paths
if {![info exists var_index]} {
    array set var_index {}
}
# Helper procedure to validate var_index is an array
proc _validate_var_index {} {
  if {[info exists var_index]} {
    if {![array exists var_index]} {
      error "proc _validate_var_index: var_index exists but is not an array. Cannot proceed."
    }
  } else {
    # Initialize if not exists
    array set var_index {}
  }
}
# Define a variable with namespace path, maintaining global index
# Usage: defv <full_namespace_variable> <value> [allow_create_namespace=0]
proc defv {full_var value {allow_create_namespace 0}} {
  _validate_var_index
  global var_index
  
  # Check number of arguments
  if {[llength [info level 0]] < 3 || [llength [info level 0]] > 4} {
    error "proc defv: defv requires 2 or 3 arguments: full_variable_path, value, [allow_create_namespace=0]"
  }
  
  # Validate allow_create_namespace is boolean
  if {$allow_create_namespace ne "0" && $allow_create_namespace ne "1"} {
    error "proc defv: allow_create_namespace must be 0 or 1"
  }
  
  # Check if full_var is a valid string (only alphanumerics and :: allowed)
  if {![string is wordchar -strict [string map {:: ""} $full_var]]} {
    error "proc defv: Invalid variable path format: $full_var. Only alphanumerics and :: allowed"
  }
  
  # Split into namespace parts and variable name
  set parts [split $full_var "::"]
  set var_name [lindex $parts end]
  set namespace_parts [lrange $parts 0 end-1]
  set namespace_path [join $namespace_parts "::"]
  
  # Check if variable name is valid
  if {![string is wordchar -strict $var_name] || [string match {[0-9]*} $var_name]} {
    error "proc defv: Invalid variable name: $var_name. Must start with letter and contain only alphanumerics"
  }
  
  # Check namespace hierarchy validity
  if {[llength $namespace_parts] > 0} {
    set current_ns ""
    set valid 1
    set last_ns_idx [expr {[llength $namespace_parts] - 1}]  ;# Index of last namespace part
    
    # Check each namespace level
    for {set i 0} {$i < [llength $namespace_parts]} {incr i} {
      set part [lindex $namespace_parts $i]
      set current_ns [expr {$current_ns eq "" ? $part : "${current_ns}::${part}"}]
      
      # Check if current namespace exists
      if {![namespace exists $current_ns]} {
        # Allow creation only for last namespace part when enabled
        if {$i == $last_ns_idx && $allow_create_namespace} {
          # Will create this namespace later
        } else {
          set valid 0
          break
        }
      }
    }
    
    if {!$valid} {
      error "proc defv: Invalid namespace hierarchy: $namespace_path. Only last namespace part can be created"
    }
    
    # Create last namespace part if needed and allowed
    if {$allow_create_namespace && ![namespace exists $namespace_path]} {
      namespace eval $namespace_path {}
    }
  }
  
  # Check for duplicate variable names in index
  if {[info exists var_index($var_name)]} {
    error "proc defv: Variable name conflict: '$var_name' already exists at '$var_index($var_name)'"
  }
  
  # Check if the variable already exists at this path
  if {[info exists $full_var]} {
    error "proc defv: Variable path already exists: $full_var"
  }
  
  # Create the variable with its value
  uplevel 1 [list set $full_var $value]
  
  # Add to index
  set var_index($var_name) $full_var
}
# Set value for an existing variable using its simple name
# Usage: setv <variable_name> <new_value>
proc setv {var_name value} {
  _validate_var_index
  global var_index
  
  # Check number of arguments
  if {[llength [info level 0]] != 3} {
    error "proc setv: setv requires exactly 2 arguments: variable_name and new_value"
  }
  
  # Check if variable name is valid
  if {![string is wordchar -strict $var_name] || [string match {[0-9]*} $var_name]} {
    error "proc setv: Invalid variable name: $var_name. Must start with letter and contain only alphanumerics"
  }
  
  # Check if variable exists in index
  if {![info exists var_index($var_name)]} {
    error "proc setv: Variable not found: $var_name. Use defv to define it first"
  }
  
  # Get full path and verify it still exists
  set full_var $var_index($var_name)
  if {![info exists $full_var]} {
    error "proc setv: Variable path missing: $full_var. Index may be corrupted"
  }
  
  # Update the variable value
  uplevel 1 [list set $full_var $value]
}
# Get value of a variable using its simple name
# Usage: getv <variable_name>
proc getv {var_name} {
  _validate_var_index
  global var_index
  
  # Check number of arguments
  if {[llength [info level 0]] != 2} {
    error "proc getv: getv requires exactly 1 argument: variable_name"
  }
  
  # Check if variable name is valid
  if {![string is wordchar -strict $var_name] || [string match {[0-9]*} $var_name]} {
    error "proc getv: Invalid variable name: $var_name. Must start with letter and contain only alphanumerics"
  }
  
  # Check if variable exists in index
  if {![info exists var_index($var_name)]} {
    error "proc getv: Variable not found: $var_name. Use defv to define it first"
  }
  
  # Get full path and verify it still exists
  set full_var $var_index($var_name)
  if {![info exists $full_var]} {
    error "proc getv: Variable path missing: $full_var. Index may be corrupted"
  }
  
  # Return the current value
  return [uplevel 1 [list set $full_var]]
}
# Recursive helper to get all variables in namespace and subnamespaces
proc _get_all_vars_in_namespace {namespace} {
  set vars [info vars ${namespace}::*]
  
  # Get subnamespaces
  foreach subns [namespace children $namespace] {
    lappend vars {*}[_get_all_vars_in_namespace $subns]
  }
  
  return $vars
}
# Clear managed index entries (keep actual namespace variables intact)
# Usage: clearv ?-all? ?-namespace|-n <namespace>? ?-recursive|-r? <var_name_or_path>?
# -all: Clear all index entries (mutually exclusive with other options)
# -namespace|-n: Clear index entries for specified namespace (only works with -namespace)
# -recursive|-r: Recursively clear subnamespace index entries (only with -namespace)
# No options: Treat argument as variable name/path to clear from index
proc clearv {{args ""}} {
  _validate_var_index
  global var_index link_info
  
  # Default config
  set all_flag 0
  set namespace ""
  set recursive 0
  set var_target ""
  set arg_count 0
  
  # Parse arguments
  set i 0
  while {$i < [llength $args]} {
    set arg [lindex $args $i]
    switch -exact -- $arg {
      "-all" {
        set all_flag 1
        incr arg_count
      }
      "-namespace" - "-n" {
        if {$i+1 >= [llength $args]} {
          error "proc clearv: $arg requires a namespace name (e.g., -n song)"
        }
        set namespace [lindex $args [incr i]]
        incr arg_count
      }
      "-recursive" - "-r" {
        set recursive 1
        # -r only takes effect with -namespace
        if {$namespace eq ""} {
          error "proc clearv: -r (recursive) only works with -namespace|-n"
        }
      }
      default {
        # Single variable target (name or path)
        if {$var_target ne ""} {
          error "proc clearv: Only one variable can be specified (no multiple targets)"
        }
        set var_target $arg
        incr arg_count
      }
    }
    incr i
  }
  
  # Mutually exclusive check: only one operation type allowed
  if {$arg_count > 1} {
    error "proc clearv: -all, -namespace, and variable target are mutually exclusive"
  }
  # --------------------------
  # Case 1: Clear all index entries
  # --------------------------
  if {$all_flag} {
    if {[array size var_index] == 0} {
      return "clearv: No managed index entries to clear (actual variables remain intact)"
    }
    
    # Only clear index and link tracking (NO unset of actual variables)
    foreach var_name [array names var_index] {
      if {[info exists link_info($var_name)]} {
        unset link_info($var_name)
      }
    }
    array unset var_index
    
    return "clearv: All index entries cleared (actual namespace variables remain intact)"
  }
  # --------------------------
  # Case 2: Clear by namespace
  # --------------------------
  if {$namespace ne ""} {
    # Validate namespace exists
    if {![namespace exists $namespace]} {
      error "proc clearv: Namespace '$namespace' does not exist"
    }
    
    # Get variable paths (recursive or non-recursive)
    if {$recursive} {
      set full_vars [_get_all_vars_in_namespace $namespace]
    } else {
      set full_vars [info vars ${namespace}::*]
    }
    
    if {[llength $full_vars] == 0} {
      return "clearv: No variables found in namespace '$namespace' (index unchanged)"
    }
    
    # Collect index entries to clear (match full path)
    set to_clear_index [list]
    foreach full_var $full_vars {
      set var_name [lindex [split $full_var "::"] end]
      # Ensure variable is in index and full path matches (avoid wrong variable)
      if {[info exists var_index($var_name)] && $var_index($var_name) eq $full_var} {
        lappend to_clear_index $var_name
      }
    }
    
    # Clear index and link info (NO unset of actual variables)
    foreach var_name $to_clear_index {
      unset var_index($var_name)
      if {[info exists link_info($var_name)]} {
        unset link_info($var_name)
      }
    }
    
    # Return status with recursive hint
    set scope_desc [expr {$recursive ? "and its subnamespaces" : ""}]
    return "clearv: Cleared [llength $to_clear_index] index entries from namespace '$namespace' $scope_desc (actual variables remain intact)"
  }
  # --------------------------
  # Case 3: Clear single variable from index
  # --------------------------
  if {$var_target ne ""} {
    # Check if target is full path or short name
    if {[string first "::" $var_target] != -1} {
      # Full path mode: validate path exists and is managed
      if {![info exists $var_target]} {
        error "proc clearv: Actual variable path '$var_target' does not exist (cannot clear non-existent variable from index)"
      }
      set var_name [lindex [split $var_target "::"] end]
      if {![info exists var_index($var_name)] || $var_index($var_name) ne $var_target} {
        error "proc clearv: Variable '$var_target' is not managed by the index system"
      }
    } else {
      # Short name mode: validate index entry exists
      if {![info exists var_index($var_target)]} {
        error "proc clearv: Variable '$var_target' not found in index"
      }
      set var_name $var_target
      set full_var $var_index($var_name)
      # Double-check actual variable still exists (defensive)
      if {![info exists $full_var]} {
        error "proc clearv: Index corruption detected: actual variable '$full_var' (for '$var_name') does not exist"
      }
    }
    
    # Clear index and link info (NO unset of actual variable)
    unset var_index($var_name)
    if {[info exists link_info($var_name)]} {
      unset link_info($var_name)
    }
    
    return "clearv: Index entry for '$var_name' cleared (actual variable '$full_var' remains intact)"
  }
  # No arguments provided
  error "proc clearv: Missing operation. Use -all, -namespace <ns> [-r], or specify a variable name/path"
}
# Import existing namespace variables into index (supports re-import after clearv)
# Usage: importv <namespace> [allow_overwrite=0] [verbose=0]
proc importv {namespace {allow_overwrite 0} {verbose 0}} {
  _validate_var_index
  global var_index
  
  # --------------------------
  # Argument validation
  # --------------------------
  if {[llength [info level 0]] < 1 || [llength [info level 0]] > 3} {
    error "proc importv: Requires 1-3 arguments: <namespace> [allow_overwrite=0] [verbose=0]"
  }
  if {$allow_overwrite ne "0" && $allow_overwrite ne "1"} {
    error "proc importv: allow_overwrite must be 0 or 1 (0=block overwrite, 1=allow overwrite)"
  }
  if {$verbose ne "0" && $verbose ne "1"} {
    error "proc importv: verbose must be 0 or 1 (0=quiet, 1=show details)"
  }
  if {![namespace exists $namespace]} {
    error "proc importv: Namespace '$namespace' does not exist"
  }
  # --------------------------
  # Get all actual variables in namespace (recursive)
  # --------------------------
  set full_vars [_get_all_vars_in_namespace $namespace]
  if {[llength $full_vars] == 0} {
    set msg "No actual variables found in namespace '$namespace' or its subnamespaces"
    if {$verbose} {puts "proc importv: $msg"}
    return 0
  }
  # --------------------------
  # First pass: Validate & collect variables (atomic import)
  # --------------------------
  array set temp_import {}   ;# Map short name -> full path
  array set overwrite_list {};# Track variables needing overwrite
  set import_count 0
  set overwrite_count 0
  foreach full_var $full_vars {
    # Extract short name and validate format
    set parts [split $full_var "::"]
    set parts [lsearch -all -inline -not $parts ""] ;# Remove empty parts (e.g., leading ::)
    set var_name [lindex $parts end]
    
    # Validate short name format
    if {![string is wordchar -strict $var_name] || [string match {[0-9]*} $var_name]} {
      error "proc importv: Invalid variable name '$var_name' in '$full_var' (must start with letter, alphanumerics only)"
    }
    
    # Check for duplicate short names in import set
    if {[info exists temp_import($var_name)]} {
      error "proc importv: Duplicate short name '$var_name' in import (conflict between '$temp_import($var_name)' and '$full_var')"
    }
    
    # Check if actual variable still exists (defensive)
    if {![info exists $full_var]} {
      error "proc importv: Actual variable '$full_var' disappeared during import (possible external modification)"
    }
    
    # Check index conflict & handle overwrite
    if {[info exists var_index($var_name)]} {
      if {!$allow_overwrite} {
        error "proc importv: Name conflict: '$var_name' already in index (path: '$var_index($var_name)'). Use allow_overwrite=1 to replace."
      }
      set overwrite_list($var_name) 1
      incr overwrite_count
    }
    
    set temp_import($var_name) $full_var
    incr import_count
  }
  # --------------------------
  # Second pass: Actual import (only if all validation passed)
  # --------------------------
  foreach var_name [array names temp_import] {
    set full_var $temp_import($var_name)
    # Update index entry without modifying actual variable
    set var_index($var_name) $full_var
  }
  # --------------------------
  # Result reporting
  # --------------------------
  set msg "Imported $import_count variable(s) from '$namespace' and its subnamespaces"
  if {$overwrite_count > 0} {
    append msg " ($overwrite_count variable(s) overwritten in index)"
  }
  if {$verbose} {puts "proc importv: $msg"}
  return $import_count
}
    
    
# List all variables in table format
# Usage: listv (no parameters required)
proc listv {} {
  # Validate variable index system exists
  if {![info exists ::var_index] || ![array exists ::var_index]} {
    error "proc listv: Variable index system not initialized"
  }
  
  # Check if there are any variables to display
  if {[array size ::var_index] == 0} {
    return "No variables in index system"
  }
  
  # Collect and validate all variables
  array set valid_vars {}
  foreach var_name [array names ::var_index] {
    set full_path $::var_index($var_name)
    
    # Fixed: Use full_path directly as it's already an absolute path
    if {![info exists $full_path]} {
      puts stderr "Warning: Stale index entry - variable '$full_path' not found"
      continue
    }
    
    # Safely retrieve variable value
    if {[catch {set value [getv $var_name]} err]} {
      puts stderr "Warning: Failed to retrieve value for '$var_name': $err"
      set value "<retrieval error>"
    }
    
    # Truncate long values for better display
    if {[string length $value] > 30} {
      set value "[string range $value 0 27]..."  ;# Add ellipsis for long values
    }
    
    set valid_vars($var_name) [list $full_path $value]
  }
  
  # Handle case where all variables were invalid
  if {[array size valid_vars] == 0} {
    return "No valid variables found in index system"
  }
  
  # Prepare and format table data
  set table_data [format_table_data [array get valid_vars]]
  set resultTable [table_format_with_title $table_data 0 "left" "" 0]
  
  return [join $resultTable \n]
}
# Helper procedure to prepare table data for table_format_with_title
proc format_table_data {var_data} {
  array set vars $var_data
  
  # Create table structure with header
  set table_data [list]
  lappend table_data [list "Variable Name" "Namespace" "Value"]
  
  # Add formatted data rows
  foreach var_name [lsort [array names vars]] {
    lassign $vars($var_name) full_path value
    
    # Extract namespace from full path
    set ns_end [string last "::" $full_path]
    if {$ns_end == -1} {
      set namespace "::"  ;# Root namespace indicator
    } else {
      set namespace [string range $full_path 0 $ns_end]
    }
    
    lappend table_data [list $var_name $namespace $value]
  }
  
  return $table_data
}
    
    
# Get the namespace hierarchy of variables
# Usage: getvns <var_name1> ?var_name2 ...?
proc getvns {args} {
  _validate_var_index
  global var_index
  
  # Check for minimum arguments
  if {[llength $args] == 0} {
    error "proc getvns: getvns requires at least one variable name as argument"
  }
  
  set results [list]
  
  foreach var_name $args {
    # Validate variable name format
    if {![string is wordchar -strict $var_name] || [string match {[0-9]*} $var_name]} {
      error "proc getvns: Invalid variable name format: '$var_name'. Must start with letter and contain only alphanumerics"
    }
    
    # Check if variable exists in index
    if {![info exists var_index($var_name)]} {
      lappend results "NA"
      continue
    }
    
    # Extract full path and split into components
    set full_path $var_index($var_name)
    set path_parts [split $full_path "::"]
    
    # Remove empty items from path parts (handles cases with leading/trailing :: or consecutive ::)
    set path_parts [lsearch -all -inline -not $path_parts ""]
    
    # If there's only one part, it means no namespace hierarchy
    if {[llength $path_parts] == 1} {
      lappend results ""
      continue
    }
    
    # Extract all parts except the last (variable name) and rejoin with ::
    set namespace_parts [lrange $path_parts 0 end-1]
    set namespace_hierarchy [join $namespace_parts "::"]
    
    # Add trailing :: to clearly indicate hierarchy
    if {$namespace_hierarchy ne ""} {
      append namespace_hierarchy "::"
    }
    
    lappend results $namespace_hierarchy
  }
  
  # Return single result as string, multiple as list
  if {[llength $results] == 1} {
    return [lindex $results 0]
  } else {
    return $results
  }
}
    
source ~/project/scr_sar/tcl/packages/table_format_with_title.package.tcl ; # table_format_with_title
# Global array to track link information
# Check and initialize global array only if it doesn't exist
if {![info exists link_info]} {
    array set link_info {}
}
# Link variables between current scope and namespaces with bidirectional synchronization
# Usage: linkv ?-n <namespace>? ?-r 0|1? ?-force|-f 0|1? ?-list|-l? ?var1 var2 ...?
# -n: Specify source namespace (optional)
# -r: 1=include subnamespaces, 0=only specified namespace (default=1)
# -force|-f: 1=overwrite existing links, 0=skip existing links (default=0)
# -list|-l: Show all linked variables with details (no linking performed)
# Without variables/namespace: Link all managed variables
proc linkv {{args ""}} {
  _validate_var_index
  global var_index link_info
  upvar 1 "" current_scope  ;# Reference current scope
  # Default values
  set force 0
  set recursive 1
  set namespace ""
  set vars_to_link [list]
  set show_list 0
  
  # Parse arguments
  set i 0
  while {$i < [llength $args]} {
    set arg [lindex $args $i]
    switch -exact -- $arg {
      "-force" - "-f" {
        if {$i+1 >= [llength $args]} {
          error "proc linkv: $arg requires a value (0 or 1)"
        }
        set force [lindex $args [incr i]]
        if {$force ne "0" && $force ne "1"} {
          error "proc linkv: $arg must be 0 or 1"
        }
      }
      "-r" {
        if {$i+1 >= [llength $args]} {
          error "proc linkv: -r requires a value (0 or 1)"
        }
        set recursive [lindex $args [incr i]]
        if {$recursive ne "0" && $recursive ne "1"} {
          error "proc linkv: -r must be 0 or 1 (0=only namespace, 1=include subnamespaces)"
        }
      }
      "-n" {
        if {$i+1 >= [llength $args]} {
          error "proc linkv: -n requires a namespace name"
        }
        set namespace [lindex $args [incr i]]
        # Enhanced namespace validation
        if {![namespace exists $namespace]} {
          error "proc linkv: Namespace '$namespace' does not exist"
        }
        if {[info vars $namespace] ne ""} {
          error "proc linkv: '$namespace' is a variable, not a namespace"
        }
        if {[string match "*::*" $namespace]} {
          set parts [split $namespace "::"]
          set current_ns ""
          foreach part $parts {
            set current_ns [expr {$current_ns eq "" ? $part : "${current_ns}::${part}"}]
            if {![namespace exists $current_ns]} {
              error "proc linkv: Invalid namespace hierarchy: '$current_ns' does not exist"
            }
          }
        }
      }
      "-list" - "-l" {
        set show_list 1
      }
      default {
        lappend vars_to_link $arg
      }
    }
    incr i
  }
  # Show linked variables list if requested
  if {$show_list} {
    # Prepare table data
    set table_data [list]
    # Add header row with link time column
    lappend table_data [list "Variable Name" "Namespace Hierarchy" "Value" "Link Method" "Link Time"]
    
    # Add data rows
    foreach var_name [lsort [array names link_info]] {
      # Check if still linked
      if {![uplevel 1 [list info exists $var_name]]} {
        unset link_info($var_name)
        continue
      }
      
      set ns_hierarchy [getvns $var_name]
      set value [getv $var_name]
      set method [dict get $link_info($var_name) method]
      set details [dict get $link_info($var_name) details]
      set link_time [dict get $link_info($var_name) time]
      
      # Truncate long values for better display
      if {[string length $value] > 50} {
        set value "[string range $value 0 47]..."
      }
      
      lappend table_data [list $var_name $ns_hierarchy $value "$method ($details)" $link_time]
    }
    
    if {[llength $table_data] <= 1} {  # Only header exists
      return "No variables are currently linked"
    }
    
    # Format table using provided procedure with title
    set formatted_table [table_format_with_title $table_data 0 "left" "Linked Variables Summary" 0]
    
    # Output formatted table
    return [join $formatted_table \n]
  }
  # Determine link method and details
  set link_method "direct"
  set link_details "specific variable"
  
  if {$namespace ne ""} {
    set link_method "namespace"
    set link_details "namespace='$namespace', recursive=$recursive"
  } elseif {[llength $vars_to_link] == 0} {
    set link_method "all"
    set link_details "all managed variables"
  }
  # Get current time in specified format (YYYY/MM/DD HH:MM:SS)
  set current_time [clock format [clock seconds] -format "%Y/%m/%d %H:%M:%S"]
  # If namespace specified, get variables from that namespace
  if {$namespace ne ""} {
    set ns_vars [_get_all_vars_in_namespace $namespace]
    set ns_var_names [list]
    foreach full_var $ns_vars {
      # Check if variable is in our management system
      set var_name [lindex [split $full_var "::"] end]
      if {[info exists var_index($var_name)] && $var_index($var_name) eq $full_var} {
        # For non-recursive mode, check if variable is directly in specified namespace
        if {!$recursive} {
          set var_ns [getvns $var_name]
          # Remove trailing :: for comparison
          set var_ns [string trimright $var_ns "::"]
          if {$var_ns eq $namespace} {
            lappend ns_var_names $var_name
          }
        } else {
          lappend ns_var_names $var_name
        }
      }
    }
    # If specific variables requested, filter namespace variables
    if {[llength $vars_to_link] > 0} {
      set filtered [list]
      foreach var $vars_to_link {
        if {$var in $ns_var_names} {
          lappend filtered $var
        }
      }
      set vars_to_link $filtered
    } else {
      set vars_to_link $ns_var_names
    }
    
    # Check if any variables matched the namespace filter
    if {[llength $vars_to_link] == 0} {
      error "proc linkv: No managed variables found in namespace '$namespace' (recursive=$recursive)"
    }
  } elseif {[llength $vars_to_link] == 0} {
    # No namespace or variables specified - link all
    set vars_to_link [array names var_index]
  }
  # Check for duplicates in requested variables
  array set temp_check {}
  foreach var_name $vars_to_link {
    if {[info exists temp_check($var_name)]} {
      error "proc linkv: Duplicate variable in request: '$var_name'"
    }
    set temp_check($var_name) 1
  }
  # Link variables with force handling
  set new_count 0
  set overwrite_count 0
  set skip_count 0
  
  foreach var_name $vars_to_link {
    # Check if variable exists in index
    if {![info exists var_index($var_name)]} {
      error "proc linkv: Variable '$var_name' not in management system"
    }
    set full_var $var_index($var_name)
    # Check if underlying variable exists
    if {![info exists $full_var]} {
      error "proc linkv: Underlying variable '$full_var' does not exist"
    }
    # Check if already linked
    set is_linked [info exists link_info($var_name)]
    
    if {$is_linked} {
      if {$force} {
        # Remove existing link
        uplevel 1 [list unset $var_name]
        
        # Create new alias link for bidirectional synchronization
        if {[catch {uplevel 1 [list upvar #0 $full_var $var_name]} err]} {
          error "proc linkv: Failed to create link for '$var_name': $err"
        }
        
        # Update link info with current time
        set link_info($var_name) [dict create method $link_method details $link_details time $current_time]
        incr overwrite_count
      } else {
        # Skip existing link
        incr skip_count
      }
    } else {
      # Create new alias link for bidirectional synchronization
      if {[catch {uplevel 1 [list upvar #0 $full_var $var_name]} err]} {
        error "proc linkv: Failed to create link for '$var_name': $err"
      }
      
      # Record link info with current time
      set link_info($var_name) [dict create method $link_method details $link_details time $current_time]
      incr new_count
    }
  }
  # Prepare result message
  set result "linkv: "
  if {$new_count > 0} {
    append result "$new_count new variable(s) linked, "
  }
  if {$overwrite_count > 0} {
    append result "$overwrite_count existing variable(s) overwritten, "
  }
  if {$skip_count > 0} {
    append result "$skip_count existing variable(s) skipped, "
  }
  # Remove trailing comma and space
  set result [string trimright $result ", "]
  
  return $result
}
    
# Remove variable links: remove short variable links from current scope (doesn't affect underlying variables)
# Usage: unlinkv ?-n <ns>? ?-r 0|1? ?var1 var2 ...?
# -n: specify namespace to unlink variables from (optional)
# -r: 1=include subnamespaces, 0=only specified namespace (default=1)
# If no variables or namespace specified, unlinks all linked variables
proc unlinkv {{args ""}} {
  _validate_var_index
  global var_index link_info
  # Default values
  set recursive 1
  set namespace ""
  set vars_to_unlink [list]
  
  # Parse arguments
  set i 0
  while {$i < [llength $args]} {
    set arg [lindex $args $i]
    switch -exact -- $arg {
      "-r" {
        if {$i+1 >= [llength $args]} {
          error "proc unlinkv: -r requires a value (0 or 1)"
        }
        set recursive [lindex $args [incr i]]
        if {$recursive ne "0" && $recursive ne "1"} {
          error "proc unlinkv: -r must be 0 or 1 (0=only namespace, 1=include subnamespaces)"
        }
      }
      "-n" {
        if {$i+1 >= [llength $args]} {
          error "proc unlinkv: -n requires a namespace name"
        }
        set namespace [lindex $args [incr i]]
        # Enhanced namespace validation
        if {![namespace exists $namespace]} {
          error "proc unlinkv: Namespace '$namespace' does not exist"
        }
        if {[info vars $namespace] ne ""} {
          error "proc unlinkv: '$namespace' is a variable, not a namespace"
        }
        if {[string match "*::*" $namespace]} {
          set parts [split $namespace "::"]
          set current_ns ""
          foreach part $parts {
            set current_ns [expr {$current_ns eq "" ? $part : "${current_ns}::${part}"}]
            if {![namespace exists $current_ns]} {
              error "proc unlinkv: Invalid namespace hierarchy: '$current_ns' does not exist"
            }
          }
        }
      }
      default {
        lappend vars_to_unlink $arg
      }
    }
    incr i
  }
  # Get all currently linked variables if none specified
  if {[llength $vars_to_unlink] == 0 && $namespace eq ""} {
    foreach var_name [array names var_index] {
      if {[uplevel 1 [list info exists $var_name]]} {
        lappend vars_to_unlink $var_name
      }
    }
  }
  # If namespace specified, filter variables from that namespace
  if {$namespace ne ""} {
    set ns_vars [_get_all_vars_in_namespace $namespace]
    set ns_var_names [list]
    foreach full_var $ns_vars {
      set var_name [lindex [split $full_var "::"] end]
      if {[info exists var_index($var_name)] && $var_index($var_name) eq $full_var} {
        # Check if variable is linked
        if {[uplevel 1 [list info exists $var_name]]} {
          # For non-recursive mode, check if variable is directly in specified namespace
          if {!$recursive} {
            set var_ns [getvns $var_name]
            # Remove trailing :: for comparison
            set var_ns [string trimright $var_ns "::"]
            if {$var_ns eq $namespace} {
              lappend ns_var_names $var_name
            }
          } else {
            lappend ns_var_names $var_name
          }
        }
      }
    }
    # If specific variables requested, filter namespace variables
    if {[llength $vars_to_unlink] > 0} {
      set filtered [list]
      foreach var $vars_to_unlink {
        if {$var in $ns_var_names} {
          lappend filtered $var
        }
      }
      set vars_to_unlink $filtered
    } else {
      set vars_to_unlink $ns_var_names
    }
    
    # Check if any variables matched the namespace filter
    if {[llength $vars_to_unlink] == 0} {
      error "proc unlinkv: No linked variables found in namespace '$namespace' (recursive=$recursive)"
    }
  }
  # Validate variables exist in caller's scope
  array set non_existent {}
  foreach var_name $vars_to_unlink {
    if {![uplevel 1 [list info exists $var_name]]} {
      set non_existent($var_name) 1
    }
  }
  if {[array size non_existent] > 0} {
    error "proc unlinkv: Variables not linked in current scope: [join [array names non_existent] ", "]"
  }
  # Validate variables are in our management system
  array set not_managed {}
  foreach var_name $vars_to_unlink {
    if {![info exists var_index($var_name)]} {
      set not_managed($var_name) 1
    }
  }
  if {[array size not_managed] > 0} {
    error "proc unlinkv: Variables not in management system: [join [array names not_managed] ", "]"
  }
  # Remove links from caller's scope
  set unlinked_count 0
  foreach var_name $vars_to_unlink {
    uplevel 1 [list unset $var_name]
    # Remove from link_info tracking
    if {[info exists link_info($var_name)]} {
      unset link_info($var_name)
    }
    incr unlinked_count
  }
  return "unlinkv: Unlinked $unlinked_count variables"
}
    
