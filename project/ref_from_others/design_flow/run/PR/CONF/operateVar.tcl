# Global index to map simple variable names to their full namespace paths
array set var_index {}

# Helper procedure to validate var_index is an array
proc _validate_var_index {} {
  if {[info exists var_index]} {
    if {![array exists var_index]} {
      error "var_index exists but is not an array. Cannot proceed."
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
    error "defv requires 2 or 3 arguments: full_variable_path, value, [allow_create_namespace=0]"
  }
  
  # Validate allow_create_namespace is boolean
  if {$allow_create_namespace ne "0" && $allow_create_namespace ne "1"} {
    error "allow_create_namespace must be 0 or 1"
  }
  
  # Check if full_var is a valid string (only alphanumerics and :: allowed)
  if {![string is wordchar -strict [string map {:: ""} $full_var]]} {
    error "Invalid variable path format: $full_var. Only alphanumerics and :: allowed"
  }
  
  # Split into namespace parts and variable name
  set parts [split $full_var "::"]
  set var_name [lindex $parts end]
  set namespace_parts [lrange $parts 0 end-1]
  set namespace_path [join $namespace_parts "::"]
  
  # Check if variable name is valid
  if {![string is wordchar -strict $var_name] || [string match {[0-9]*} $var_name]} {
    error "Invalid variable name: $var_name. Must start with letter and contain only alphanumerics"
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
      error "Invalid namespace hierarchy: $namespace_path. Only last namespace part can be created"
    }
    
    # Create last namespace part if needed and allowed
    if {$allow_create_namespace && ![namespace exists $namespace_path]} {
      namespace eval $namespace_path {}
    }
  }
  
  # Check for duplicate variable names in index
  if {[info exists var_index($var_name)]} {
    error "Variable name conflict: '$var_name' already exists at '$var_index($var_name)'"
  }
  
  # Check if the variable already exists at this path
  if {[info exists $full_var]} {
    error "Variable path already exists: $full_var"
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
    error "setv requires exactly 2 arguments: variable_name and new_value"
  }
  
  # Check if variable name is valid
  if {![string is wordchar -strict $var_name] || [string match {[0-9]*} $var_name]} {
    error "Invalid variable name: $var_name. Must start with letter and contain only alphanumerics"
  }
  
  # Check if variable exists in index
  if {![info exists var_index($var_name)]} {
    error "Variable not found: $var_name. Use defv to define it first"
  }
  
  # Get full path and verify it still exists
  set full_var $var_index($var_name)
  if {![info exists $full_var]} {
    error "Variable path missing: $full_var. Index may be corrupted"
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
    error "getv requires exactly 1 argument: variable_name"
  }
  
  # Check if variable name is valid
  if {![string is wordchar -strict $var_name] || [string match {[0-9]*} $var_name]} {
    error "Invalid variable name: $var_name. Must start with letter and contain only alphanumerics"
  }
  
  # Check if variable exists in index
  if {![info exists var_index($var_name)]} {
    error "Variable not found: $var_name. Use defv to define it first"
  }
  
  # Get full path and verify it still exists
  set full_var $var_index($var_name)
  if {![info exists $full_var]} {
    error "Variable path missing: $full_var. Index may be corrupted"
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

# Import existing namespace variables into the index system (including all subnamespaces)
# Usage: importv <namespace> [allow_overwrite=0] [verbose=0]
proc importv {namespace {allow_overwrite 0} {verbose 0}} {
  _validate_var_index
  global var_index
  
  # Validate arguments
  if {[llength [info level 0]] < 1 || [llength [info level 0]] > 3} {
    error "importv requires 1 to 3 arguments: namespace, [allow_overwrite=0], [verbose=0]"
  }
  
  if {$allow_overwrite ne "0" && $allow_overwrite ne "1"} {
    error "allow_overwrite must be 0 or 1"
  }
  
  if {$verbose ne "0" && $verbose ne "1"} {
    error "verbose must be 0 or 1"
  }
  
  # Check if namespace exists
  if {![namespace exists $namespace]} {
    error "Namespace '$namespace' does not exist"
  }
  
  # Get all variables in namespace and all subnamespaces recursively
  set vars [_get_all_vars_in_namespace $namespace]
  if {[llength $vars] == 0} {
    if {$verbose} {puts "No variables found in namespace '$namespace' or its subnamespaces"}
    return 0
  }
  
  # First pass: collect and validate all variables
  array set temp_import {}
  array set overwrite_candidates {}
  set import_count 0
  set overwrite_count 0
  
  foreach full_var $vars {
    # Extract simple variable name
    set parts [split $full_var "::"]
    set var_name [lindex $parts end]
    
    # Validate variable name format
    if {![string is wordchar -strict $var_name] || [string match {[0-9]*} $var_name]} {
      error "Invalid variable name in '$full_var': '$var_name' (must start with letter, alphanumerics only)"
    }
    
    # Check for duplicates in import set
    if {[info exists temp_import($var_name)]} {
      error "Duplicate variable names in import: '$var_name' found in both '$temp_import($var_name)' and '$full_var'"
    }
    set temp_import($var_name) $full_var
    
    # Check for conflict with existing variables
    if {[info exists var_index($var_name)]} {
      if {!$allow_overwrite} {
        error "Name conflict: '$var_name' already exists at '$var_index($var_name)' (cannot import from '$full_var'). Use allow_overwrite=1 to override."
      } else {
        set overwrite_candidates($var_name) 1
        incr overwrite_count
      }
    }
    incr import_count
  }
  
  # Second pass: actually import variables (only if all checks passed)
  foreach var_name [array names temp_import] {
    # If overwriting, first unset the old variable
    if {[info exists overwrite_candidates($var_name)]} {
      set old_full_var $var_index($var_name)
      unset $old_full_var
    }
    
    # Add to index
    set var_index($var_name) $temp_import($var_name)
  }
  
  # Generate result message
  set msg "Imported $import_count variables from '$namespace' and its subnamespaces"
  if {$allow_overwrite && $overwrite_count > 0} {
    append msg " ($overwrite_count variables overwritten)"
  }
  
  if {$verbose} {puts $msg}
  return $import_count
}

# Clear all variables in a specific namespace and remove from index
# Usage: clear_namespace_vars <namespace>
proc clear_namespace_vars {namespace} {
  _validate_var_index
  global var_index
  
  # Check if namespace exists
  if {![namespace exists $namespace]} {
    error "Namespace '$namespace' does not exist"
  }
  
  # Get all variables in namespace and subnamespaces
  set vars [_get_all_vars_in_namespace $namespace]
  if {[llength $vars] == 0} {
    return "No variables to clear in namespace '$namespace' or its subnamespaces"
  }
  
  # Collect variables that are in our index
  set to_clear [list]
  foreach full_var $vars {
    set var_name [lindex [split $full_var "::"] end]
    if {[info exists var_index($var_name)] && $var_index($var_name) eq $full_var} {
      lappend to_clear $var_name
    }
  }
  
  # Clear variables and index entries
  foreach var_name $to_clear {
    set full_var $var_index($var_name)
    unset $full_var
    unset var_index($var_name)
  }
  
  return "Cleared [llength $to_clear] variables from namespace '$namespace' and its subnamespaces"
}

# Unset a specific variable by name or full path and remove from index
# Usage: unsetv <var_name_or_path>
proc unsetv {var_name_or_path} {
  _validate_var_index
  global var_index
  
  # Check if it's a full path (contains ::)
  if {[string first "::" $var_name_or_path] != -1} {
    # Treat as full path
    if {![info exists $var_name_or_path]} {
      error "Variable path does not exist: $var_name_or_path"
    }
    set var_name [lindex [split $var_name_or_path "::"] end]
    if {![info exists var_index($var_name)] || $var_index($var_name) ne $var_name_or_path} {
      error "Variable '$var_name_or_path' is not managed by this system"
    }
  } else {
    # Treat as simple name
    if {![info exists var_index($var_name_or_path)]} {
      error "Variable '$var_name_or_path' not found in index"
    }
    set var_name $var_name_or_path
    set full_var $var_index($var_name)
    if {![info exists $full_var]} {
      error "Variable path missing: $full_var. Index may be corrupted"
    }
  }
  
  # Perform unset
  unset $var_index($var_name)
  unset var_index($var_name)
  
  return "Variable '$var_name' has been unset"
}

# Clear all managed variables and reset index
# Usage: clear_all_vars
proc clear_all_vars {} {
  _validate_var_index
  global var_index
  
  if {[array size var_index] == 0} {
    return "No managed variables to clear"
  }
  
  # First unset all variables
  foreach var_name [array names var_index] {
    set full_var $var_index($var_name)
    if {[info exists $full_var]} {
      unset $full_var
    }
  }
  
  # Then clear the index
  array unset var_index
  
  return "All managed variables have been cleared"
}

# List all variables and their paths
proc listv {} {
  _validate_var_index
  global var_index
  set result ""
  foreach var_name [lsort [array names var_index]] {
    append result "$var_name -> $var_index($var_name) = [getv $var_name]\n"
  }
  return $result
}
    


# Create variable links: map short variable names to full namespace variables for direct $var access
# Usage: linkv ?-force 0|1? ?var1 var2 ...? （no variables means link all）
proc linkv {{args ""}} {
  _validate_var_index
  global var_index
  upvar 1 "" current_scope  ;# Reference current scope

  # Parse arguments
  set force 0
  set vars_to_link [list]
  
  if {[llength $args] > 0 && [lindex $args 0] eq "-force"} {
    if {[llength $args] < 2} {
      error "linkv: -force requires a value (0 or 1)"
    }
    set force [lindex $args 1]
    if {$force ne "0" && $force ne "1"} {
      error "linkv: -force must be 0 or 1"
    }
    set vars_to_link [lrange $args 2 end]
  } else {
    set vars_to_link $args
  }

  # Determine variables to link (all if none specified)
  if {[llength $vars_to_link] == 0} {
    set vars_to_link [array names var_index]
  }

  # Check for duplicates in requested variables
  array set temp_check {}
  foreach var_name $vars_to_link {
    if {[info exists temp_check($var_name)]} {
      error "linkv: Duplicate variable in request: '$var_name'"
    }
    set temp_check($var_name) 1
  }

  # Check for existing variables in current scope
  array set existing_vars {}
  foreach var_name $vars_to_link {
    if {[info exists current_scope($var_name)]} {
      set existing_vars($var_name) $current_scope($var_name)
    }
  }

  # Handle existing variables based on force flag
  if {[array size existing_vars] > 0 && !$force} {
    set msg "linkv: Cannot link variables - existing in current scope:\n"
    foreach var_name [array names existing_vars] {
      append msg "  '$var_name' = '${existing_vars($var_name)}'\n"
    }
    append msg "Use '-force 1' to overwrite"
    error $msg
  }

  # Create links
  set linked_count 0
  foreach var_name $vars_to_link {
    # Check if variable exists in index
    if {![info exists var_index($var_name)]} {
      error "linkv: Variable '$var_name' not in management system"
    }
    set full_var $var_index($var_name)

    # Check if underlying variable exists
    if {![info exists ::$full_var]} {
      error "linkv: Underlying variable '$full_var' does not exist"
    }

    # Create or overwrite link
    upvar 1 $var_name link_var
    upvar #0 $full_var real_var
    set link_var $real_var
    incr linked_count
  }

  return "linkv: Linked $linked_count variables for direct access with \$var"
}


# Remove variable links: remove short variable links from current scope (doesn't affect underlying variables)
# Usage: unlinkv ?var1 var2 ...? （no variables means unlink all）
proc unlinkv {{vars_to_unlink ""}} {
  _validate_var_index
  global var_index

  # Determine variables to unlink (all linked if none specified)
  if {[llength $vars_to_unlink] == 0} {
    set vars_to_unlink [list]
    foreach var_name [array names var_index] {
      # Check if variable exists in caller's scope using uplevel
      if {[uplevel 1 [list info exists $var_name]]} {
        lappend vars_to_unlink $var_name
      }
    }
  }

  # Validate variables exist in caller's scope
  array set non_existent {}
  foreach var_name $vars_to_unlink {
    # Use uplevel to check existence in caller's scope
    if {![uplevel 1 [list info exists $var_name]]} {
      set non_existent($var_name) 1
    }
  }
  if {[array size non_existent] > 0} {
    error "unlinkv: Variables not linked in current scope: [join [array names non_existent] ", "]"
  }

  # Validate variables are in our management system
  array set not_managed {}
  foreach var_name $vars_to_unlink {
    if {![info exists var_index($var_name)]} {
      set not_managed($var_name) 1
    }
  }
  if {[array size not_managed] > 0} {
    error "unlinkv: Variables not in management system: [join [array names not_managed] ", "]"
  }

  # Remove links from caller's scope
  set unlinked_count 0
  foreach var_name $vars_to_unlink {
    uplevel 1 [list unset $var_name]
    incr unlinked_count
  }

  return "unlinkv: Unlinked $unlinked_count variables"
}
    
