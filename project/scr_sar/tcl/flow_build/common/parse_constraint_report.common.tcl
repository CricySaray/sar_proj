#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/28 18:14:51 Sunday
# label     : package_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : Parse the report_constraint command to obtain the number of VIOLATED instances and the maximum violated value for constraints such as setup, 
#             hold, max_transition, max_cap, max_fanout, min_pulse_width, and min_period.
# return    : nested list: {{min_delay worstViolValue violNum} {max_daley worstViolValue violNum} {max_capacitance worstViolValue violNum} {max_transition worstViolValue violNum} {max_fanout worstViolValue violNum} {min_pulse_width worstViolValue violNum} {min_period worstViolValue violNum}}
# ref       : link url
# --------------------------
proc parse_constraint_report {filename {debug 0}} {
  set max_delay_content "NA"
  set min_delay_content "NA"
  set max_capacitance_content "NA"
  set max_transition_content "NA"
  set max_fanout_content "NA"
  set min_pulse_width_content "NA"
  set min_period_content "NA"
  set path ""
  
  if {![file exists $filename]} {
    if {$debug} {puts "Error: proc parse_constraint_report: File $filename does not exist"}
    return [list]
  }
  
  if {[catch {open $filename r} fid]} {
    if {$debug} {puts "Error opening file: $fid"}
    return [list]
  }
  set content [split [read $fid] \n]
  close $fid
  
  set report_index -1
  set line_num 0
  foreach line $content {
    if {[regexp {^Report : constraint} $line]} {
      set report_index $line_num
      break
    }
    incr line_num
  }
  
  if {$report_index == -1} {
    if {$debug} {puts "Report : constraint section not found"}
    return [_prepare_result \
      $max_delay_content $min_delay_content \
      $max_capacitance_content $max_transition_content $max_fanout_content \
      $min_pulse_width_content $min_period_content]
  }
  
  if {$debug} {puts "Found Report : constraint at line [expr {$report_index + 1}]"}
  
  set options_content [lrange $content [expr {$report_index + 1}] end]
  set processing_options 1
  
  foreach line $options_content {
    if {!$processing_options} {
      break
    }
    
    if {![regexp {^\s*-\w+} $line]} {
      set processing_options 0
      break
    }
    
    if {[regexp {^\s*-max_delay} $line]} {
      set max_delay_content "GET"
      if {$debug} {puts "Found -max_delay option"}
    } elseif {[regexp {^\s*-min_delay} $line]} {
      set min_delay_content "GET"
      if {$debug} {puts "Found -min_delay option"}
    } elseif {[regexp {^\s*-max_capacitance} $line]} {
      set max_capacitance_content "GET"
      if {$debug} {puts "Found -max_capacitance option"}
    } elseif {[regexp {^\s*-max_transition} $line]} {
      set max_transition_content "GET"
      if {$debug} {puts "Found -max_transition option"}
    } elseif {[regexp {^\s*-max_fanout} $line]} {
      set max_fanout_content "GET"
      if {$debug} {puts "Found -max_fanout option"}
    } elseif {[regexp {^\s*-min_pulse_width} $line]} {
      set min_pulse_width_content "GET"
      if {$debug} {puts "Found -min_pulse_width option"}
    } elseif {[regexp {^\s*-min_period} $line]} {
      set min_period_content "GET"
      if {$debug} {puts "Found -min_period option"}
    } elseif {[regexp {^\s*-path\s+(end|slack_only)} $line -> path_val]} {
      set path $path_val
      if {$debug} {puts "Found -path option with value: $path_val"}
    }
  }
  
  set blocks [list]
  set line_num 0
  foreach line $content {
    if {[regexp {^\s*min_delay\/hold\s\(\'(\w+)\' group\)$} $line -> group]} {
      lappend blocks [list "min_delay" $group $line_num]
    } elseif {[regexp {^\s*max_delay\/setup\s\(\'(\w+)\' group\)$} $line -> group]} {
      lappend blocks [list "max_delay" $group $line_num]
    } elseif {[regexp {^\s*max_capacitance$} $line]} {
      lappend blocks [list "max_capacitance" "" $line_num]
    } elseif {[regexp {^\s*max_transition$} $line]} {
      lappend blocks [list "max_transition" "" $line_num]
    } elseif {[regexp {^\s*min_period$} $line]} {
      lappend blocks [list "min_period" "" $line_num]
    } elseif {[regexp {^\s*min_pulse_width$} $line]} {
      lappend blocks [list "min_pulse_width" "" $line_num]
    } elseif {[regexp {^\s*max_fanout$} $line]} {
      lappend blocks [list "max_fanout" "" $line_num]
    }
    incr line_num
  }
  
  set block_contents [dict create]
  set total_lines [llength $content]
  set block_count [llength $blocks]
  
  set indices [list]
  for {set i 0} {$i < $block_count} {incr i} {lappend indices $i}
  
  foreach i $indices {
    lassign [lindex $blocks $i] block_type group start_line
    
    if {$i < [expr {$block_count - 1}]} {
      set end_line [lindex [lindex $blocks [expr {$i+1}]] 2]
    } else {
      set end_line $total_lines
    }
    
    set block_lines [list]
    set line_indices [list]
    for {set line_idx $start_line} {$line_idx < $end_line} {incr line_idx} {
      lappend line_indices $line_idx
    }
    
    foreach line_idx $line_indices {
      lappend block_lines [lindex $content $line_idx]
    }
    
    if {$group ne ""} {
      dict lappend block_contents $block_type [list $group $block_lines]
      if {$debug} {
        puts "Found $block_type block with group $group"
        puts "  Contains [llength $block_lines] lines (lines $start_line to [expr {$end_line-1}])"
      }
    } else {
      dict set block_contents $block_type $block_lines
      if {$debug} {
        puts "Found $block_type block"
        puts "  Contains [llength $block_lines] lines (lines $start_line to [expr {$end_line-1}])"
      }
    }
  }
  
  set group_vars [dict create]
  
  if {![dict exists $block_contents min_delay]} {
    set min_delay_subcontents "" 
  } else {
    set min_delay_blocks [dict get $block_contents "min_delay"]
    set min_delay_subcontents [list]
    foreach block $min_delay_blocks {
      lassign $block group lines
      set var_name "min_delay_${group}_content"
      dict set group_vars $var_name $lines
      lappend min_delay_subcontents $lines
      if {$debug} {
        puts "Stored min_delay sub-block $group with [llength $lines] lines"
      }
    }
  }
  if {![dict exists $block_contents max_delay]} {
    set max_delay_subcontents ""
  } else {
    set max_delay_blocks [dict get $block_contents "max_delay"]
    set max_delay_subcontents [list]
    foreach block $max_delay_blocks {
      lassign $block group lines
      set var_name "max_delay_${group}_content"
      dict set group_vars $var_name $lines
      lappend max_delay_subcontents $lines
      if {$debug} {
        puts "Stored max_delay sub-block $group with [llength $lines] lines"
      }
    }
  }
  
  foreach block_type {max_capacitance max_transition max_fanout min_pulse_width min_period} {
    if {[dict exists $block_contents $block_type]} {
      set var_name "${block_type}_content"
      if {[set $var_name] eq "GET"} {
        set $var_name [dict get $block_contents $block_type]
        if {$debug} {
          puts "Assigned $var_name with [llength [set $var_name]] lines"
        }
      }
    }
  }
  
  if {$min_delay_content eq "GET" && [llength $min_delay_subcontents] > 0} {
    set min_delay_content [concat {*}$min_delay_subcontents]
    if {$debug} {
      puts "Merged min_delay sub-blocks into min_delay_content with [llength $min_delay_content] lines"
    }
  }
  
  if {$max_delay_content eq "GET" && [llength $max_delay_subcontents] > 0} {
    set max_delay_content [concat {*}$max_delay_subcontents]
    if {$debug} {
      puts "Merged max_delay sub-blocks into max_delay_content with [llength $max_delay_content] lines"
    }
  }
  
  foreach var {max_delay_content min_delay_content \
                max_capacitance_content max_transition_content max_fanout_content \
                min_pulse_width_content min_period_content} {
    if {[set $var] eq "GET"} {
      set $var "EMPTY"
      if {$debug} {puts "Set $var to EMPTY (no content found)"}
    }
  }
  
  dict for {var content} $group_vars {
    if {[info exists ::$var]} {
      upvar 1 $var gvar
      set gvar $content
    } else {
      uplevel 1 [list set $var $content]
    }
    if {$debug} {puts "Set group variable: $var"}
  }
  
  foreach var {max_delay_content min_delay_content \
                max_capacitance_content max_transition_content max_fanout_content \
                min_pulse_width_content min_period_content} {
    if {[set $var] eq "GET"} {
      error "Invalid state: option detected but content not processed for $var"
    }
  }
  
  return [_prepare_result \
    $max_delay_content $min_delay_content \
    $max_capacitance_content $max_transition_content $max_fanout_content \
    $min_pulse_width_content $min_period_content]
}

proc _prepare_result {max_delay_content min_delay_content \
  max_capacitance_content max_transition_content max_fanout_content \
  min_pulse_width_content min_period_content} {
  
  set result [list]
  
  lappend result [_process_constraint "min_delay" $min_delay_content]
  lappend result [_process_constraint "max_delay" $max_delay_content]
  lappend result [_process_constraint "max_capacitance" $max_capacitance_content]
  lappend result [_process_constraint "max_transition" $max_transition_content]
  lappend result [_process_constraint "max_fanout" $max_fanout_content]
  lappend result [_process_constraint "min_pulse_width" $min_pulse_width_content]
  lappend result [_process_constraint "min_period" $min_period_content]
  
  return $result
}

proc _process_constraint {type content} {
  if {$content eq "NA"} {
    return [list $type "NA" "NA"]
  }
  
  if {$content eq "EMPTY"} {
    return [list $type 0 0]
  }
  
  set filtered [list]
  foreach line $content {
    if {[string match "*VIOLATED*" $line]} {
      lappend filtered $line
    }
  }
  
  if {[info exists debug] && $debug} {
    puts "Filtered VIOLATED lines for $type:"
    puts "  Original merged items: [llength $content]"
    puts "  After filtering: [llength $filtered]"
  }
  
  # Process directly with $line without using parts variable
  set processed [list]
  foreach line $filtered {
    # Use regex to extract pin and value directly from line
    if {[regexp {\s*(\S+)\s+.*?(\S+)\s+\(VIOLATED} $line -> pin value]} {
      if {[string is double -strict $value]} {
        lappend processed [list $pin $value]
      }
    }
  }
  
  set num [llength $processed]
  if {$num == 0} {
    return [list $type 0 0]
  }
  
  set min_val Inf
  foreach item $processed {
    lassign $item pin val
    if {$val < $min_val} {
      set min_val $val
    }
  }
  
  return [list $type $min_val $num]
}

