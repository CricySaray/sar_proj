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
# NOTICE    : please generate report file using command: report_constraint -all_violator -path_type slack_only -nos -max_delay -min_delay -max_transition -max_capacitance -max_fanout -min_period -min_pulse_width
#             waive_list_file: split with blank character
#             line 1: CAP /inst/to/pin/name
#             line 2: SETUP /inst/to/pin/name
#             line 3: HOLD /inst/to/pin/name
#             line 4: HOLD /inst/to/pin/name
#             line 5: TRAN /inst/to/pin/name
#             line 6: CAP /inst/to/pin/name
#             line 7: CAP regexp:{^\w+/U_PAD_ADDA_\w+/PAD$}
#             line 8: TRAN regexp:{^U_ANARF_TOP/\w+$}
#             line 9: CAP /inst/to/pin/name
#             NOTICE: The first item of each sublist in `waive_prefix_prompt_list` must be one of the following options. It is recommended to set the corresponding `waive_prefix_prompt` for all 
#             the following items (which means this list will have a total of 7 items). Alternatively, you can set only a few of them. If your `waive_list_file` does not include the `waive_pin` 
#             settings for some of these items, you may skip setting the `waive_prefix_prompt` for those specific types.
#               "max_delay min_delay max_transition max_capacitance max_fanout min_pulse_width min_period"
# ref       : link url
# --------------------------
source ../../packages/every_any.package.tcl; # every
source ../../packages/print_formattedTable.package.tcl; # print_formattedTable
proc parse_constraint_report {filename {waive_list_file ""} {waive_prefix_prompt_list {{max_delay SETUP} {min_delay HOLD} {max_transition TRAN} {max_capacitance CAP} {max_fanout FANOUT} {min_pulse_width PULSE} {min_period PERIOD}}} {outputDir "./"} {prefixOutPutFile "sor_DesignName_"} {debug 0}} {
  if {![llength $waive_prefix_prompt_list] || $waive_list_file == ""} {
    set flagToWaive 0
  } else {
    set flagToWaive 1
  }
  if {$waive_list_file != "" && ![file isfile $waive_list_file]} {
    error "proc parse_constraint_report: check your input : waive_list_file($waive_list_file) is not found!!!"
  } elseif {$waive_list_file != "" && [file isfile $waive_list_file] && ![llength $waive_list_file]} {
    error "proc parse_constraint_report: check your input : waive_list_file($waive_list_file) exists but waive_prefix_prompt_list($waive_prefix_prompt_list) is empty!!!"
  }
  set fi [open $waive_list_file r] ; set waive_content [split [read $fi] "\n"] ; close $fi ; set waive_content [lsearch -not -all -inline -regexp $waive_content {^\s*$}]
  if {![every x $waive_content {expr {[llength $x] == 2}}]} {
    error "proc parse_constraint_report: check your input: waive_list_file($waive_list_file) have line that is not only include two columns!!! check it."
  }
  set all_prefix_prompt_on_waive_file [lsort -u [lmap temp_line $waive_content { lindex $temp_line 0 }]]
  set all_avaiable_prefix_prompt [lmap temp_list $waive_prefix_prompt_list { lindex $temp_list 1 }]
  if {![every x $all_prefix_prompt_on_waive_file { expr {$x in $all_avaiable_prefix_prompt} }]} {
    set invalid_lines [lmap temp_line $waive_content {
      if {[lindex $temp_line 0] ni $all_avaiable_prefix_prompt} {
        set temp_error $temp_line
      } else {
        continue
      }
    }]
    set prefix_prompt_invalid [lsort -u [lmap temp_line $invalid_lines { lindex $temp_line 0 }]]
    error "proc parse_constraint_report: check your input: waive_list_file($waive_list_file) have invalid prefix prompt: $prefix_prompt_invalid\ninvalid lines:\n[join $invalid_lines \n]"
  }
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
  if {$path eq "slack_only"} {
    error "proc parse_constraint_report: check your command of report_constraint, please use option: -path end , dont use -path slack_only"
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
      set $var_name [dict get $block_contents $block_type]
      if {$debug} {
        puts "Assigned $var_name with [llength [set $var_name]] lines"
      }
    }
  }
  
  if {[llength $min_delay_subcontents] > 0} {
    set min_delay_content [concat {*}$min_delay_subcontents]
    if {$debug} {
      puts "Merged min_delay sub-blocks into min_delay_content with [llength $min_delay_content] lines"
    }
  }
  
  if {[llength $max_delay_subcontents] > 0} {
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
    $min_pulse_width_content $min_period_content $waive_list_file $waive_prefix_prompt_list $outputDir $prefixOutPutFile]
}

proc _prepare_result {max_delay_content min_delay_content \
  max_capacitance_content max_transition_content max_fanout_content \
  min_pulse_width_content min_period_content waive_list_file waive_prefix_prompt_list outputDir prefixOutPutFile} {
  
  set result [list]
  
  lappend result [_process_constraint "min_delay" $min_delay_content $waive_list_file $waive_prefix_prompt_list $outputDir $prefixOutPutFile]
  lappend result [_process_constraint "max_delay" $max_delay_content $waive_list_file $waive_prefix_prompt_list $outputDir $prefixOutPutFile]
  lappend result [_process_constraint "max_capacitance" $max_capacitance_content $waive_list_file $waive_prefix_prompt_list $outputDir $prefixOutPutFile]
  lappend result [_process_constraint "max_transition" $max_transition_content $waive_list_file $waive_prefix_prompt_list $outputDir $prefixOutPutFile]
  lappend result [_process_constraint "max_fanout" $max_fanout_content $waive_list_file $waive_prefix_prompt_list $outputDir $prefixOutPutFile]
  lappend result [_process_constraint "min_pulse_width" $min_pulse_width_content $waive_list_file $waive_prefix_prompt_list $outputDir $prefixOutPutFile]
  lappend result [_process_constraint "min_period" $min_period_content $waive_list_file $waive_prefix_prompt_list $outputDir $prefixOutPutFile]
  
  return $result
}

proc _process_constraint {type content waive_list_file waive_prefix_prompt_list outputDir prefixOutPutFile} {
  switch $type {
    "max_delay" {set outputFileBody "setup"}
    "min_delay" {set outputFileBody "hold"}
    default {set outputFileBody $type}
  }
  if {$content eq "NA"} {
    set output_file "${outputDir}/${prefixOutPutFile}$outputFileBody.viol.list"
    if {[file isdirectory [file dirname $output_file]]} {
      exec touch $output_file
    } else {
      error "proc _process_constraint: check your outputDir($outputDir) is not found!!!(NA mode)"
    }
    return [list $type "NA" "NA"]
  }
  
  if {$content eq "EMPTY"} {
    set output_file "${outputDir}/${prefixOutPutFile}$outputFileBody.viol.list"
    if {[file isdirectory [file dirname $output_file]]} {
      exec touch $output_file
    } else {
      error "proc _process_constraint: check your outputDir($outputDir) is not found!!!(EMPTY mode)"
    }
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
    if {[regexp {\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+\(VIOLATED} $line -> pin required_path_delay actual_path_delay value]} {
      if {[string is double -strict $value]} {
        lappend processed [list $pin $required_path_delay $actual_path_delay $value]
      }
    }
  }
  set removed_waive_item_precessed [_remove_waive_items $type $processed $waive_list_file $waive_prefix_prompt_list]
  set list_to_dump_rpt [linsert $removed_waive_item_precessed 0 [list viol_pin required_path_delay actual_path_delay slack_value]]
  set output_file "${outputDir}/${prefixOutPutFile}$outputFileBody.viol.list"
  if {[file isdirectory [file dirname $output_file]]} {
    set fo [open $output_file w]
    puts $fo [print_formattedTable $list_to_dump_rpt] ; close $fo
  } else {
    error "proc _process_constraint: check your outputDir($outputDir) is not found!!!"
  }

  set num [llength $removed_waive_item_precessed]
  if {$num == 0} {
    return [list $type 0 0]
  }
  
  set min_val Inf
  foreach item $removed_waive_item_precessed {
    lassign $item pin require actual val
    if {$val < $min_val} {
      set min_val $val
    }
  }
  
  return [list $type $min_val $num]
}
proc _remove_waive_items {type content_list waive_list_file waive_prefix_prompt_list} {
  if {![llength $content_list]} {
    return $content_list
  } else {
    if {![llength $waive_prefix_prompt_list] || $waive_list_file == ""} {
      return $content_list
    } else {
      set fi [open $waive_list_file r] ; set waive_content [split [read $fi] "\n"] ; close $fi ; set waive_content [lsearch -not -all -inline -regexp $waive_content {^\s*$}]
      if {![every x $waive_content {expr {[llength $x] == 2}}]} {
        error "proc _remove_waive_items: check your input : waive_list_file($waive_list_file) have lines that is not only include two columns!!! check it."
      } else {
        if {$type ni {max_delay min_delay max_transition max_capacitance max_fanout min_pulse_width min_period}} {
          error "proc _remove_waive_items: check your input : type($type) is not one of (max_delay min_delay max_transition max_capacitance max_fanout min_pulse_width min_period) !!!"
        }
        set prefix_prompt_of_type [lindex [lsearch -index 0 -exact -inline $waive_prefix_prompt_list $type] 1]
        set waive_pin_of_type [lmap temp_line $waive_content {
          if {[lindex $temp_line 0] eq $prefix_prompt_of_type} {
            set temp [lindex $temp_line 1]
          } else {
            continue
          }
        }]
        foreach temp_pin_expr $waive_pin_of_type {
          if {[regexp {^regexp:(.*)} $temp_pin_expr -> temp_regExp]} {
            set content_list [lsearch -regexp -index 0 -not -all -inline $content_list $temp_regExp] ; # Match the pin names that require waiving based on the regular expressions (regexp) specified in the waive_list.
          } else {
            set content_list [lsearch -exact -index 0 -not -all -inline $content_list $temp_pin_expr]
          }
        }
        return $content_list
      }
    }
  }
}
