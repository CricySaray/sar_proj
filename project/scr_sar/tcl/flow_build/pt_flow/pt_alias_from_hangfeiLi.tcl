proc pt_get_hier_df_list {hier_name} {
  return [get_object_name [get_cells -filter "full_name =~ $hier_name/* && is_sequential == true" -hier]]
}
proc pt_get_hier_df_list_other {hier_name other_hier} {
  return [get_object_name [get_cells -filter "full_name =~ $hier_name/* && is_sequential == true && full_name !~ $other_hier/*" -hier]]
}
proc pt_get_hier_rst_pin {hier_name} {
  return [get_object_name [get_pins -filter "full_name =~ $hier_name/*/CDN" -hier]]
}
proc pt_get_fanout {pin} {
  return [get_object_name [all_fanout -from $pin -endpoints_only -flat -continue_trace generated_clock_source]]
}
proc pt_get_fanout_num {pin} {
  return [llength [pt_get_fanout $pin]]
}
proc pt_get_pin_setup_slack {pin} {
  suppress_message UITE-416
  suppress_message RC-201
  suppress_message RC-204
  suppress_message UITE-479
  return [get_attribute [get_timing_paths -to $pin] slack]
}
proc pt_get_pin_setup_pba_slack {pin} {
  suppress_message RC-201
  suppress_message RC-204
  suppress_message UITE-479
  suppress_message UITE-416
  return [get_attribute [get_timing_paths -to $pin -pba_mode ex] slack]
}
proc pt_get_pin_hold_slack {pin} {
  suppress_message RC-201
  suppress_message RC-204
  suppress_message UITE-479
  suppress_message UITE-416
  return [get_attribute [get_timing_paths -to $pin -delay_type min] slack]
}
proc pt_get_pin_hold_pba_slack {pin} {
  suppress_message RC-201
  suppress_message RC-204
  suppress_message UITE-479
  suppress_message UITE-416
  return [get_attribute [get_timing_paths -to $pin -pba_mode ex -delay_type min] slack]
}
proc pt_get_from_pin_setup_slack {pin} {
  suppress_message RC-201
  suppress_message RC-204
  suppress_message UITE-479
  suppress_message UITE-416
  return [get_attribute [get_timing_paths -to $pin -from $pin] slack]
}
proc pt_get_from_pin_setup_pba_slack {pin} {
  suppress_message RC-201
  suppress_message RC-204
  suppress_message UITE-479
  suppress_message UITE-416
  return [get_attribute [get_timing_paths -from $pin -pba_mode ex] slack]
}
proc pt_get_from_pin_hold_slack {pin} {
  suppress_message RC-201
  suppress_message RC-204
  suppress_message UITE-479
  suppress_message UITE-416
  return [get_attribute [get_timing_paths -from $pin -delay_type min] slack]
}
proc pt_get_from_pin_hold_pba_slack {pin} {
  suppress_message RC-201
  suppress_message RC-204
  suppress_message UITE-479
  suppress_message UITE-416
  return [get_attribute [get_timing_paths -from $pin -pba_mode ex -delay_type min] slack]
}
proc pt_get_clock_pin_fanout_endpoint_setup_slack {pin} {
  set leaf_cell [get_object_name [all_fanout -from $pin -endpoints_only -flat -only_cells]]
  set slack 9999
  set worst_pin ""
  foreach tmp_leaf_cell $leaf_cell {
    set tmp_slack [pt_get_pin_setup_slack $tmp_leaf_cell]
    echo "$tmp_leaf_cell $tmp_slack"
    if {$slack > $tmp_slack} {
      set slack $tmp_slack
      set worst_pin $tmp_leaf_cell 
    } 
  }
  echo "worst case : $worst_pin $slack"
}
proc pt_get_clock_pin_fanout_endpoint_hold_slack {pin} {
  set leaf_cell [get_object_name [all_fanout -from $pin -endpoints_only -flat -only_cells]]
  set slack 9999
  set worst_pin ""
  foreach tmp_leaf_cell $leaf_cell {
    set tmp_slack [pt_get_pin_hold_slack $tmp_leaf_cell]
    echo "$tmp_leaf_cell $tmp_slack"
    if {$slack > $tmp_slack} {
      set slack $tmp_slack
      set worst_pin $tmp_leaf_cell 
    } 
  }
  echo "worst case : $worst_pin $slack"
}
proc pt_get_clock_pin_fanout_endpoint_setup_pba_slack {pin} {
  set leaf_cell [get_object_name [all_fanout -from $pin -endpoints_only -flat -only_cells]]
  set slack 9999
  set worst_pin ""
  foreach tmp_leaf_cell $leaf_cell {
    set tmp_slack [pt_get_pin_setup_pba_slack $tmp_leaf_cell]
    echo "$tmp_leaf_cell $tmp_slack"
    if {$slack > $tmp_slack} {
      set slack $tmp_slack
      set worst_pin $tmp_leaf_cell 
    } 
  }
  echo "worst case : $worst_pin $slack"
}
proc pt_get_clock_pin_fanout_endpoint_hold_pba_slack {pin} {
  set leaf_cell [get_object_name [all_fanout -from $pin -endpoints_only -flat -only_cells]]
  set slack 9999
  set worst_pin ""
  foreach tmp_leaf_cell $leaf_cell {
    set tmp_slack [pt_get_pin_hold_pba_slack $tmp_leaf_cell]
    echo "$tmp_leaf_cell $tmp_slack"
    if {$slack > $tmp_slack} {
      set slack $tmp_slack
      set worst_pin $tmp_leaf_cell 
    } 
  }
  echo "worst case : $worst_pin $slack"
}
proc pt_get_clock_pin_fanout_startpoint_setup_slack {pin} {
  set leaf_cell [get_object_name [all_fanout -from $pin -endpoints_only -flat -only_cells]]
  set slack 9999
  set worst_pin ""
  foreach tmp_leaf_cell $leaf_cell {
    set tmp_slack [pt_get_from_pin_setup_slack $tmp_leaf_cell]
    echo "$tmp_leaf_cell $tmp_slack"
    if {$slack > $tmp_slack} {
      set slack $tmp_slack
      set worst_pin $tmp_leaf_cell 
    } 
  }
  echo "worst case : $worst_pin $slack"
}
proc pt_get_clock_pin_fanout_startpoint_hold_slack {pin} {
  set leaf_cell [get_object_name [all_fanout -from $pin -endpoints_only -flat -only_cells]]
  set slack 9999
  set worst_pin ""
  foreach tmp_leaf_cell $leaf_cell {
    set tmp_slack [pt_get_from_pin_hold_slack $tmp_leaf_cell]
    echo "$tmp_leaf_cell $tmp_slack"
    if {$slack > $tmp_slack} {
      set slack $tmp_slack
      set worst_pin $tmp_leaf_cell 
    } 
  }
  echo "worst case : $worst_pin $slack"
}
proc pt_get_clock_pin_fanout_startpoint_hold_slack_test {pin} {
  set leaf_cell_col [all_fanout -from $pin -endpoints_only -flat -only_cells]
  set leaf_cell_col_o [remove_from_collection [all_registers] leaf_cell_col]
  return [get_attribute [get_timing_paths -from $leaf_cell_col -to $leaf_cell_col_o -delay_type min] slack]
}
proc pt_get_clock_pin_fanout_endpoint_hold_slack_test {pin} {
  set leaf_cell_col [all_fanout -from $pin -endpoints_only -flat -only_cells]
  set leaf_cell_col_o [remove_from_collection [all_registers] leaf_cell_col]
  return [get_attribute [get_timing_paths -to $leaf_cell_col -from $leaf_cell_col_o -delay_type min] slack]
}
proc pt_get_clock_pin_fanout_startpoint_setup_slack_test {pin} {
  set leaf_cell_col [all_fanout -from $pin -endpoints_only -flat -only_cells]
  set leaf_cell_col_o [remove_from_collection [all_registers] leaf_cell_col]
  return [get_attribute [get_timing_paths -from $leaf_cell_col -to $leaf_cell_col_o -delay_type max] slack]
}
proc pt_get_clock_pin_fanout_endpoint_setup_slack_test {pin} {
  set leaf_cell_col [all_fanout -from $pin -endpoints_only -flat -only_cells]
  set leaf_cell_col_o [remove_from_collection [all_registers] leaf_cell_col]
  return [get_attribute [get_timing_paths -to $leaf_cell_col -from $leaf_cell_col_o -delay_type max] slack]
}
proc pt_get_clock_pin_fanout_startpoint_setup_pba_slack {pin} {
  set leaf_cell [get_object_name [all_fanout -from $pin -endpoints_only -flat -only_cells]]
  set slack 9999
  set worst_pin ""
  foreach tmp_leaf_cell $leaf_cell {
    set tmp_slack [pt_get_from_pin_setup_pba_slack $tmp_leaf_cell]
    echo "$tmp_leaf_cell $tmp_slack"
    if {$slack > $tmp_slack} {
      set slack $tmp_slack
      set worst_pin $tmp_leaf_cell 
    } 
  }
  echo "worst case : $worst_pin $slack"
}
proc pt_get_clock_pin_fanout_startpoint_hold_pba_slack {pin} {
  set leaf_cell [get_object_name [all_fanout -from $pin -endpoints_only -flat -only_cells]]
  set slack 9999
  set worst_pin ""
  foreach tmp_leaf_cell $leaf_cell {
    set tmp_slack [pt_get_from_pin_hold_pba_slack $tmp_leaf_cell]
    echo "$tmp_leaf_cell $tmp_slack"
    if {$slack > $tmp_slack} {
      set slack $tmp_slack
      set worst_pin $tmp_leaf_cell 
    } 
  }
  echo "worst case : $worst_pin $slack"
}
proc lshow {list_tmp} {
  foreach tmp_list_tmp $list_tmp {
    echo $tmp_list_tmp 
  }
}
proc pt_get_common_clock_pin_slack {full_path_file_name clk_pin} {
  set flag_common_clock_pin 0
  set slack 9999
  set clk_pin_cnt 0
  set flag_path_start 0
  set f [open $full_path_file_name "r"]
  while {[gets $f current_line] != -1} {
    if {[regexp Startpoint $current_line]} {
      set clk_pin_cnt 0
      set flag_path_start 1
    } 
    if {[regexp $clk_pin $current_line] && $flag_path_start} {
      incr clk_pin_cnt 
    }
    if {[regexp "slack" $current_line] && $flag_path_start} {
      set flag_path_start 0
      set tmp_slack [lindex $current_line 2]
      if {$clk_pin_cnt > 1} {
        set flag_common_clock_pin 1 
      } else {
        echo $tmp_slack
        set flag_common_clock_pin 0
        if {$tmp_slack < $slack} {
          set slack $tmp_slack
          echo $slack 
        } 
      }
    }
  }
  close $f
  return $slack
}
proc pt_get_pin_hold_slack_remove_common_clk_pin {pin clk_pin} {
  report_timing -to $pin -nos -path_type full_clock_expanded -sort_by slack -max_paths 100000 -nworst 100 -slack_lesser_than 1 -delay_type min > ~/tmp.rpt
  return [pt_get_common_clock_pin_slack ~/tmp.rpt $clk_pin]
}
proc pt_get_pin_setup_slack_remove_common_clk_pin {pin clk_pin} {
  report_timing -to $pin -nos -path_type full_clock_expanded -sort_by slack -max_paths 100000 -nworst 100 -slack_lesser_than 1 -delay_type max > ~/tmp.rpt
  return [pt_get_common_clock_pin_slack ~/tmp.rpt $clk_pin]
}
proc pt_get_pin_setup_pba_slack_remove_common_clk_pin {pin clk_pin} {
  report_timing -to $pin -nos -path_type full_clock_expanded -sort_by slack -max_paths 100000 -nworst 100 -slack_lesser_than 1 -delay_type max -pba_mode ex > ~/tmp.rpt
  return [pt_get_common_clock_pin_slack ~/tmp.rpt $clk_pin]
}
proc pt_get_from_pin_setup_slack_remove_common_clk_pin {pin clk_pin} {
  report_timing -from $pin -nos -path_type full_clock_expanded -sort_by slack -max_paths 100000 -nworst 100 -slack_lesser_than 1 -delay_type max > ~/tmp.rpt
  return [pt_get_common_clock_pin_slack ~/tmp.rpt $clk_pin]
}
proc pt_get_from_pin_setup_pba_slack_remove_common_clk_pin {pin clk_pin} {
  report_timing -from $pin -nos -path_type full_clock_expanded -sort_by slack -max_paths 100000 -nworst 100 -slack_lesser_than 1 -delay_type max -pba_mode ex > ~/tmp.rpt
  return [pt_get_common_clock_pin_slack ~/tmp.rpt $clk_pin]
}
proc pt_get_from_pin_hold_slack_remove_common_clk_pin {pin clk_pin} {
  report_timing -from $pin -nos -path_type full_clock_expanded -sort_by slack -max_paths 100000 -nworst 100 -slack_lesser_than 1 -delay_type min > ~/tmp.rpt
  return [pt_get_common_clock_pin_slack ~/tmp.rpt $clk_pin]
}
proc pt_get_clock_pin_fanout_endpoint_setup_slack_remove_common_clk_pin {pin} {
  set leaf_cell [get_object_name [all_fanout -from $pin -endpoints_only -flat -only_cells]]
  set slack 9999
  set worst_pin ""
  foreach tmp_leaf_cell $leaf_cell {
    set tmp_slack [pt_get_pin_setup_slack_remove_common_clk_pin $tmp_leaf_cell $pin] 
    echo "$tmp_leaf_cell $tmp_slack"
    if {$slack > $tmp_slack} {
      set slack $tmp_slack
      set worst_pin $tmp_leaf_cell 
    }
  }
  echo "worse case : $worst_pin $slack"
}
proc pt_get_clock_pin_fanout_endpoint_hold_slack_remove_common_clk_pin {pin} {
  set leaf_cell [get_object_name [all_fanout -from $pin -endpoints_only -flat -only_cells]]
  set slack 9999
  set worst_pin ""
  foreach tmp_leaf_cell $leaf_cell {
    set tmp_slack [pt_get_pin_hold_slack_remove_common_clk_pin $tmp_leaf_cell $pin] 
    echo "$tmp_leaf_cell $tmp_slack"
    if {$slack > $tmp_slack} {
      set slack $tmp_slack
      set worst_pin $tmp_leaf_cell 
    }
  }
  echo "worse case : $worst_pin $slack"
}
proc pt_get_clock_pin_fanout_endpoint_setup_pba_slack_remove_common_clk_pin {pin} {
  set leaf_cell [get_object_name [all_fanout -from $pin -endpoints_only -flat -only_cells]]
  set slack 9999
  set worst_pin ""
  foreach tmp_leaf_cell $leaf_cell {
    set tmp_slack [pt_get_pin_setup_pba_slack_remove_common_clk_pin $tmp_leaf_cell $pin] 
    echo "$tmp_leaf_cell $tmp_slack"
    if {$slack > $tmp_slack} {
      set slack $tmp_slack
      set worst_pin $tmp_leaf_cell 
    }
  }
  echo "worse case : $worst_pin $slack"
}
proc pt_get_clock_pin_fanout_startpoint_setup_slack_remove_common_clk_pin {pin} {
  set leaf_cell [get_object_name [all_fanout -from $pin -endpoints_only -flat -only_cells]]
  set slack 9999
  set worst_pin ""
  foreach tmp_leaf_cell $leaf_cell {
    set tmp_slack [pt_get_from_pin_setup_slack_remove_common_clk_pin $tmp_leaf_cell $pin] 
    echo "$tmp_leaf_cell $tmp_slack"
    if {$slack > $tmp_slack} {
      set slack $tmp_slack
      set worst_pin $tmp_leaf_cell 
    }
  }
  echo "worse case : $worst_pin $slack"
}
proc pt_get_clock_pin_fanout_startpoint_hold_slack_remove_common_clk_pin {pin} {
  set leaf_cell [get_object_name [all_fanout -from $pin -endpoints_only -flat -only_cells]]
  set slack 9999
  set worst_pin ""
  foreach tmp_leaf_cell $leaf_cell {
    set tmp_slack [pt_get_from_pin_hold_slack_remove_common_clk_pin $tmp_leaf_cell $pin] 
    echo "$tmp_leaf_cell $tmp_slack"
    if {$slack > $tmp_slack} {
      set slack $tmp_slack
      set worst_pin $tmp_leaf_cell 
    }
  }
  echo "worse case : $worst_pin $slack"
}
proc pt_get_clock_pin_fanout_startpoint_setup_pba_slack_remove_common_clk_pin {pin} {
  set leaf_cell [get_object_name [all_fanout -from $pin -endpoints_only -flat -only_cells]]
  set slack 9999
  set worst_pin ""
  foreach tmp_leaf_cell $leaf_cell {
    set tmp_slack [pt_get_from_pin_setup_pba_slack_remove_common_clk_pin $tmp_leaf_cell $pin] 
    echo "$tmp_leaf_cell $tmp_slack"
    if {$slack > $tmp_slack} {
      set slack $tmp_slack
      set worst_pin $tmp_leaf_cell 
    }
  }
  echo "worse case : $worst_pin $slack"
}
proc pt_get_clock_pin_fanout_clocks {clock_pin} {
  return [lsort -u [get_object_name [get_attribute [all_fanout -from $clock_pin -endpoints_only -flat] clocks]]]
}
proc pt_insert_buffer_num {pin cell num} {
  for {set i 0} {$i < $num} {incr i} {
    insert_buffer $pin $cell 
  }
}
proc pt_get_hier_hold_margin_cell {hier margin filename} {
  echo "user_guide : pt_get_hier_hold_margin_cell U_PERI_SUB_WRAP 0.05 ~/peri_hold_margin.rpt"
  echo "" > $filename
  set inst [get_object_name [get_cells -filter "full_name =~ $hier/*xtop* || ref_name =~ DEL* && full_name =~ $hier/*" -hier]]
  foreach tmp_inst $inst {
    set hold_margin [pt_get_pin_hold_slack $tmp_inst] 
    if {$hold_margin > $margin} {
      echo "$tmp_inst $hold_margin" >> $filename 
    } 
  }
}
proc pt_get_from_clock_to_other_clock_hold_margin {clk_name} {
  return [get_attribute [get_timing_paths -from $clk_name -to [get_clocks -filter "full_name != $clk_name"] -delay_type min] slack]
}
proc pt_get_from_clock_to_other_clock_setup_margin {clk_name} {
  return [get_attribute [get_timing_paths -from $clk_name -to [get_clocks -filter "full_name != $clk_name"] -delay_type max] slack]
}
proc pt_get_to_clock_from_other_clock_hold_margin {clk_name} {
  return [get_attribute [get_timing_paths -to $clk_name -to [get_clocks -filter "full_name != $clk_name"] -delay_type min] slack]
}
proc pt_get_to_clock_from_other_clock_setup_margin {clk_name} {
  return [get_attribute [get_timing_paths -to $clk_name -to [get_clocks -filter "full_name != $clk_name"] -delay_type max] slack]
}
proc pt_get_other_clock {clk_name} {
  return [get_clocks -filter "full_name !~ $clk_name"]
}
