# ------------------------
# pt alias 

alias s "source"
alias sa "source ~/.pt_alias.tcl"
alias rs "restore_session"
alias sc "set_host_options -max_cores" ; # you need input number of max cores
set_host_options -max_cores 8
alias sa "source ~/.pt_alias.tcl"

set pba_mode "ex"
set common_options "-nos -input -nets -transition_time -variation -capacitance -crosstalk_delta -derate -significant_digits 3 -pba_mode $pba_mode -delay_type"
set common_options_split "-input -nets -transition_time -variation -capacitance -crosstalk_delta -derate -significant_digits 3 -pba_mode $pba_mode -delay_type"
alias rt "report_timing $common_options max -nworst 1"
alias rtf "report_timing $common_options max -nworst 1 -path_type full_clock_expanded"
alias rth "report_timing $common_options min -nworst 1"
alias rthf "report_timing $common_options min -nworst 1 -path_type full_clock_expanded"

alias rts "report_timing $common_options_split max -nworst 1"
alias rtfs "report_timing $common_options_split max -nworst 1 -path_type full_clock_expanded"
alias rths "report_timing $common_options_split min -nworst 1"
alias rthfs "report_timing $common_options_split min -nworst 1 -path_type full_clock_expanded"


proc get_fanin_startpoints {pin {type "all"}} { ; # type : all reg block port
  set all_startpoins [get_object_name [all_fanin -startpoints_only -to $pin]]
  if {$all_startpoins ne ""} {
    if {$type eq "all"} {
      return $all_startpoins
    } elseif {$type eq "reg"} {
      return [lmap temp_pin $all_startpoins {
        if {[get_attribute [get_cells -of [get_pins $temp_pin]] is_sequential]} {
          set temp_pin 
        } else { continue }
      }]
    } elseif {$type eq "block"} {
      return [lmap temp_pin $all_startpoins {
        if {[get_attribute [get_cells -of [get_pins $temp_pin]] is_black_box]} {
          set temp_pin 
        } else { continue }
      }]
    } elseif {$type eq "port"} {
      return [lmap temp_pin $all_startpoins {
        if {[get_ports $temp_pin] ne ""} {
          set temp_pin 
        } else { continue }
      }]
    } else {
      error "porc get_fanin_startpoints: error type ($type) is invalid" 
    }
  } else {
    puts "WARNING: have no startpoints!!!"
    return [list] 
  }
}
proc get_fanout_endpoints {pin {type "all"}} {
  set all_endpoints [get_object_name [all_fanout -endpoints_only -from $pin]]
  if {$all_endpoints ne ""} {
    if {$type eq "all"} {
      return $all_endpoints
    } elseif {$type eq "reg"} {
      return [lmap temp_pin $all_endpoints {
        if {[get_attribute [get_cells -of [get_pins $temp_pin]] is_sequential]} {
          set temp_pin 
        } else { continue }
      }]
    } elseif {$type eq "block"} {
      return [lmap temp_pin $all_endpoints {
        if {[get_attribute [get_cells -of [get_pins $temp_pin]] is_black_box]} {
          set temp_pin 
        } else { continue }
      }]
    } elseif {$type eq "port"} {
      return [lmap temp_pin $all_endpoints {
        if {[get_ports $temp_pin] ne ""} {
          set temp_pin 
        } else { continue }
      }]
    } else {
      error "porc get_fanout_endpoints: error type ($type) is invalid" 
    }
  } else {
    puts "WARNING: have no endpoints!!!"
    return [list] 
  }
}


# --------------------------
# author    : sar song
# date      : 2026/02/17 13:57:58 Tuesday
# label     : clock_tree_relative_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Obtain the slack values of the given pins or insts as startpoints or endpoints. You can specify the number of lines of content 
#             to output at the end, with the last line showing the worst slack value. If the pin or inst name you input belongs to a block and 
#             requires an additional prefix to be referenced in the chip top level, you can specify what the prefix is. You can also specify the 
#             PBA mode. It can automatically filter out insts or pins that are not registers or mem/IP, and only retrieve slack values for registers 
#             or mem/IP.
#             This proc facilitates checking the uniformity of slack values for the fanout (endpoints) or fanin (startpoints) of a pin, and 
#             identifying whether they are good or bad.
# return    : print sorted result of slack and input pin_or_inst
# ref       : link url
# --------------------------
proc get_slack_forSepecifiedPins {{type startpoint} {pinsOrInsts ""} {pba_mode ex} {prefixOfInstInTopSta U_M3KL_MAIN_SUB_WRAP} {showlastItemNum 10}} {
  set ifDumpSmallSlackPath 1
  set thresholdOfDumpPath 0.03
  set outputFileBodyName "slackLessPathDump_fromProc_get_slack_forSepcifiedPins"
  set output_dir "./"

  set slack_less 9999
  set list_slack_inst [list]
  set list_notFoundSlack_pin [list]
  puts "total get [llength $pinsOrInsts] pinsOrInsts, begin find slack..."
  set i 0
  set sequential_or_black_box_pinOrInst_num 0
  puts "processing ...: "
  suppress_message UITE-416
  suppress_message UITE-479
  foreach temp_pin_or_inst $pinsOrInsts {
    incr i
    puts -nonewline "$i "
    flush stdout
    set temp_original_name $temp_pin_or_inst
    if {$prefixOfInstInTopSta ne ""} {
      set temp_pin_or_inst "$prefixOfInstInTopSta/$temp_pin_or_inst" 
    }
    if {[get_object_name [get_pins -q $temp_pin_or_inst]] ne ""} {
      set temp_inst [get_cells -of [get_pins $temp_pin_or_inst]] 
      if {[get_attribute $temp_inst is_sequential] || [get_attribute $temp_inst is_black_box]} {
        if {[regexp start $type]} {
          set temp_pins_col [get_pins -of $temp_inst -filter "direction==out"]
        } elseif {[regexp end $type]} {
          set temp_pins_col [get_pins -of $temp_inst -filter "direction==in"]
        } else {
          error "proc get_slack_forSepecifiedPins: error type at 1: is invalid type : $type "
        }
      } else {
        continue 
      }
    } elseif {[get_object_name [get_cells -q $temp_pin_or_inst]] ne ""} {
      set temp_inst [get_cells $temp_pin_or_inst]
      if {[get_attribute [get_cells $temp_pin_or_inst] is_sequential] || [get_attribute [get_cells $temp_pin_or_inst] is_black_box]} {
        if {[regexp start $type]} {
          set temp_pins_col [get_pins -of $temp_inst -filter "direction==out"]
        } elseif {[regexp end $type]} {
          set temp_pins_col [get_pins -of $temp_inst -filter "direction==in"]
        } else {
          error "proc get_slack_forSepecifiedPins: error type at 2: is invalid type : $type "
        }
      } else {
        continue 
      }
    } else {
      error "proc get_slack_forSepecifiedPins: error input list: only accept pins or insts name." 
    }
    incr sequential_or_black_box_pinOrInst_num
    if {[regexp start $type]} {
      set temp_slack [get_attribute [get_timing_paths -from $temp_pins_col -pba_mode $pba_mode -slack_lesser_than $slack_less] slack]
    } elseif {[regexp end $type]} {
      set temp_slack [get_attribute [get_timing_paths -to $temp_pins_col -pba_mode $pba_mode -slack_lesser_than $slack_less] slack]
    } else {
      error "proc get_slack_forSepecifiedPins: error type : $type" 
    }
    if {$temp_slack ne "" && [string is double $temp_slack]} {
      lappend list_slack_inst [list $temp_slack $temp_inst]
    } else {
      lappend list_notFoundSlack_pin [list $type $temp_inst]
      # error "proc get_slack_forSepecifiedPins: error not found slack value or not floating num for temp_pin: $temp_inst"
    }
  } 
  puts ""
  puts " ------ "
  puts "total [llength $pinsOrInsts] pins or insts."
  puts "find $sequential_or_black_box_pinOrInst_num reg or mem/ip pins or insts."
  puts "have [llength $list_notFoundSlack_pin] path that not found slack!!!"
  puts " ------ "
  set list_slack_inst [lsort -index 0 -decreasing -real $list_slack_inst]
  set reverse_list_slack_inst [lreverse $list_slack_inst]
  set outputfilename "$output_dir/$outputFileBodyName.rpt"
  if {[file exists $outputfilename]} {
    file delete $outputfilename 
    exec touch $outputfilename
  }
  foreach temp_slack_pin $reverse_list_slack_inst {
    lassign $temp_slack_pin temp_slack temp_inst
    if {$temp_slack <= $thresholdOfDumpPath} {
      if {[regexp start $type]} {
        set temp_pins [get_pins -of [get_cells $temp_inst] -filter "direction==out"]
        redirect -append $outputfilename "report_timing -from $temp_pins -nos -significant_digits 4 -delay max -inputs_pins -trans -derate -cap -sort_by slack -crosstalk_delta -slack_less 9999 -nets -pba_mode $pba_mode -max_paths 1000 -nworst 1000"
      } elseif {[regexp end $type]} {
        set temp_pins [get_pins -of [get_cells $temp_inst] -filter "direction==in"]
        redirect -append $outputfilename "report_timing -to $temp_pins -nos -significant_digits 4 -delay max -inputs_pins -trans -derate -cap -sort_by slack -crosstalk_delta -slack_less 9999 -nets -pba_mode $pba_mode -max_paths 1000 -nworst 1000"
      }
    }
  }
  if {$showlastItemNum != 0} {
    set from_idx [expr {[llength $pinsOrInsts] - $showlastItemNum + 1}]
    set list_slack_inst [lrange $list_slack_inst $from_idx end] 
  }
  puts [join $list_slack_inst \n]
}
