source ../../packages/add_file_header.package.tcl; # add_file_header
suppress_message CMD-041
suppress_message ATTR-3
suppress_message SEL-004
suppress_message SEL-010
suppress_message UITE-416

proc report_cell_info {ptn} {
  set cell_list   [get_cells -quiet -hier * -filter "$ptn"]
  set all_cell_num   [sizeof [get_cells -quiet -hier * -filter "is_hierarchical == false"]]
  set num   0
  set area  0
  set ratio 0
  if {$cell_list != ""} {
    set num   [sizeof $cell_list]
    set area  [expr [join [get_attribute $cell_list area] {+}]]
    set ratio [format "%5.2f" [expr $num * 100.0 / $all_cell_num]]
  }
  return [list $num $area $ratio]
}

set design [get_object_name [current_design]]
proc report_design_status {} {
  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip "design.uniquify"
  set designIsUniquify 0
  set design_name [get_object_name [current_design]]
  foreach hinst [lsort -unique -dict -incr [get_attribute [get_cells -quiet * -hierarchical -filter "is_hierarchical==true"] ref_name]] {
    if {![regexp "$design_name" $hinst]} {
      puts "$hinst is not uniquify by \'$design_name\'"
      incr designIsUniquify 1
    }
  }
  if {$designIsUniquify == 0} {
    puts "$design_name is unique by $design_name"
  }
  set totalInstances [sizeof [get_cells -quiet * -hier -filter "is_hierarchical==false&&is_combinational==true&&number_of_pins>2&&number_of_pins<25"]]
  set high_toggle_rate_cell_list [get_attribute [get_lib_cells */* -filter "function_id=~*xor*" -quiet] base_name]
  set high_tr_cell_num 0
  foreach ptn $high_toggle_rate_cell_list {
    set cell_num [sizeof [get_cells * -quiet -hier -filter "ref_name=~$ptn"]]
    set high_tr_cell_num [expr $high_tr_cell_num + $cell_num]
  }
  if {$totalInstances == 0} { set highTRCellRatio 0.0 } else {
    set highTRCellRatio [format "%5.3f" [expr $high_tr_cell_num*100.0/$totalInstances]]
  }
  set ratio_limit 25
  set num 2 ; # can't be zero
  set area_raw [lsort -u -incr -real [get_attribute [get_lib_cells */* -filter "number_of_pins==$num"] area]]
  if {$area_raw != ""} {
    set area [lindex $area_raw 0]
    set ratio_limit  [format "%.2f" [expr $num/$area]]

    set highPinDensityNum 0
    foreach libc [lsort -u [get_attribute [get_cells -quiet -hierarchical * -filter "is_hierarchical==false&&is_combinational==true&&number_of_pins>2&&number_of_pins<25"] ref_name]] {
      set cell_area [lsort -u [get_attribute [get_lib_cells */$libc] area]]
      set cell_pins [lsort -u [get_attribute [get_lib_cells */$libc] number_of_pins]]
      set pinDensity [expr $cell_pins/$cell_area]
      if {$pinDensity > $ratio_limit} {
        set cell_num [sizeof [get_cells -quiet * -hier -filter "ref_name==$libc"]]
        set highPinDensityNum [expr $highPinDensityNum + $cell_num]
      }
    }
    set totalInstances [sizeof [get_cells -quiet * -hier -filter "is_hierarchical==false&&number_of_pins>2&&number_of_pins<25"]]
    if {$totalInstances == 0} { set hpinDNRatio 0.0 } else {
      set hpinDNRatio [format "%5.2f" [expr $highPinDensityNum*100.0/$totalInstances]]
    }
    set maxTrans [get_attribute [current_design] max_transition]
    set maxFanout [get_attribute [current_design] max_fanout]
    set maxCap [get_attribute [current_design] max_capacitance]
  } else {
    puts "# have no content of \$area, check it!!!"
  }
}

proc report_cell_status {} {
  set patterns {
    {combinational   {is_combinational == true && is_hierarchical == false && number_of_pins>2 && number_of_pins<25}}
    {register        {is_sequential==true&&is_memory_cell==false&&is_hierarchical==false&&is_integrated_clock_gating_cell==false&&is_negative_level_sensitive==false&&is_positive_level_sensitive==false}}
    {icg             {is_integrated_clock_gating_cell&&is_hierarchical==false}}
    {latch           {is_sequential==true&&is_memory_cell==false&&is_hierarchical==false&&is_integrated_clock_gating_cell==false&&(is_negative_level_sensitive==true||is_positive_level_sensitive==true)}}
    {buf/inv         {number_of_pins == 2 && is_hierarchical == false}}
    {memory          {is_memory_cell}}
    {macro           {is_memory_cell==false&&is_hierarchical==false&&number_of_pins>25}}
  }

  set iso_cells   [get_attribute -quiet [get_lib_cells */* -quiet -filter "is_isolation==true"] base_name]
  set lvl_cells   [get_attribute -quiet [get_lib_cells */* -quiet -filter "is_level_shifter==true"] base_name]
  set rtn_cells   [get_attribute -quiet [get_lib_cells */* -quiet -filter "is_retention==true"] base_name]
  set aon_cells   [get_attribute -quiet [get_lib_cells */* -quiet -filter "always_on==true"] base_name]

  set lowpower_iso_cell_num 0
  foreach id $iso_cells {
    set a [sizeof_collection [get_cells -hier -filter "ref_name =~ $id && is_hierarchical == false" -q] ]
    if {$a > 0 } {
      set lowpower_iso_cell_num [expr $lowpower_iso_cell_num + $a]
    }
  }
  set lowpower_lvl_cell_num 0
  foreach id $lvl_cells {
    set a [sizeof_collection [get_cells -hier -filter "ref_name =~ $id && is_hierarchical == false" -q] ]
    if {$a > 0 } {
      set lowpower_lvl_cell_num [expr $lowpower_lvl_cell_num + $a]
    }
  }
  set lowpower_rtn_cell_num 0
  foreach id $rtn_cells {
    set a [sizeof_collection [get_cells -hier -filter "ref_name =~ $id && is_hierarchical == false" -q] ]
    if {$a > 0 } {
      set lowpower_rtn_cell_num [expr $lowpower_rtn_cell_num + $a]
    }
  }
  set lowpower_aon_cell_num 0
  foreach id $aon_cells {
    set a [sizeof_collection [get_cells -hier -filter "ref_name =~ $id && is_hierarchical == false" -q] ]
    if {$a > 0 } {
      set lowpower_aon_cell_num [expr $lowpower_aon_cell_num + $a]
    }
  }

  set clock_cells      [get_cells -quiet -of [get_attribute [get_nets -hierarchical * -filter "is_clock_network==true"] leaf_drivers]]
  set high_vth_cells   [filter_collection -regexp $clock_cells { ref_name =~ .*ZTH_* || ref_name=~ .*ZTS_* } ]
  set low_drive_cells  [filter_collection -regexp $clock_cells { ref_name =~ .*_X0B_.* || ref_name =~ .*_X1B_.* || ref_name =~ .*_X2B_.* || ref_name =~ .*_1$ || ref_name =~ .*_2$ || ref_name =~ .*_3$} ]
  set noSymmetry_cells [filter_collection -regexp $clock_cells { ref_name !~ CK.* && ref_name !~ DCCK.* && ref_name !~ .*_S_.* && ref_name !~ .*CKGT.*} ]

  set mixVT_issue 0
  set mixVT_list  [list]
  foreach ckcell [lsort -u [get_attribute $clock_cells ref_name]] {
    foreach vt [array names cell_vt_group_mapList_eg_VTGroupName_regExpression] {
      foreach ptn $cell_vt_group_mapList_eg_VTGroupName_regExpression($vt) {
        if {[regexp "$ptn" $ckcell]} {
          lappend mixVT_list $vt
        }
      }
    }
  }

  foreach vt [array names cell_vt_group_mapList_eg_VTGroupName_regExpression] {
    foreach ptn $cell_vt_group_mapList_eg_VTGroupName_regExpression($vt) {
      set cell_names [get_cells -quiet $clock_cells -filter "ref_name=~*${ptn}"]
      if {[sizeof $cell_names] > 1} {lappend mixVT_list $vt}
    }
  }
  set mixVT_list [lsort -u $mixVT_list]
  if {[llength $mixVT_list] > 1} {
    set mixVT_issue $mixVT_list
  }

  set mixCL_issue 0
  set mixCL_list [list]
  foreach ckcell [lsort -u [get_attribute $clock_cells ref_name]] {
    if {[regexp {[0-9]+P} $ckcell cl]} {
      lappend mixCL_list [string range $cl 0 end-1]
    }
  }
  set mixCL_list [lsort -u $mixCL_list]
  if {[llength $mixCL_list] > 1} {
    set mixCL_issue $mixCL_list
  }

  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip "cells for CTS"

  puts "\n# Summary Reports:"
  puts [format "%-50s%-5s" "Hi-VT cells in Clock Tree:" [sizeof $high_vth_cells]]
  puts [format "%-50s%-5s" "Low-Drive cells in Clock Tree:" [sizeof $low_drive_cells]]
  puts [format "%-50s%-5s" "Non-Symmetry cells in Clock Tree:" [sizeof $noSymmetry_cells]]
  puts [format "%-50s%-5s" "mix-VT cells in Clock Tree:" [llength $mixVT_list]]
  puts [format "%-50s%-5s" "mix-Channel Length cells in Clock Tree:" [llength $mixCL_list]]
  puts "\n# Detail Reports: (the type of cell in clock tree)"
  foreach ckcell [lsort -u [get_attribute $clock_cells ref_name]] {
    puts [format "%-50s%-d" $ckcell [sizeof [get_cells -quiet $clock_cells -filter "ref_name==$ckcell"]]]
  }
  puts "\n# Detail Reports: (Hi-VT cells in Clock Tree)"
  foreach ckcell [lsort -u [get_attribute $high_vth_cells ref_name]] {
    puts [format "%-50s%-d" $ckcell  [sizeof [get_cells -quiet $high_vth_cells -filter "ref_name==$ckcell"]]]
  }
  puts "\n# Detail Reports: (Low-Drive cells in Clock Tree)"
  foreach ckcell [lsort -u [get_attribute $low_drive_cells ref_name]] {
    puts [format "%-50s%-d" $ckcell [sizeof [get_cells -quiet $low_drive_cells -filter "ref_name==$ckcell"]]]
  }
  puts "\n# Detail Reports: (Non-Symmetry cells in Clock Tree)"
  foreach ckcell [lsort -u [get_attribute $noSymmetry_cells ref_name]] {
    puts [format "%-50s%-d" $ckcell [sizeof [get_cells -quiet $noSymmetry_cells -filter "ref_name==$ckcell"]]]
  }
  puts "\n# Detail Reports: (mix-VT cells in Clock Tree)"
  foreach VT $mixVT_list {
    set num($VT) 0
    foreach vt_group $cell_vt_group_mapList_eg_VTGroupName_regExpression($VT) {
      set num($VT) [expr [sizeof [get_cells -quiet $clock_cells -filter "ref_name=~*$vt_group"]] + $num($VT)]
    }
    puts [format "%-50s%-d" $VT  $num($VT)]
  }
  puts "\n# Detail Reports: (mix-Channel Length cells in Clock Tree)"
  foreach CL $mixCL_list {
    puts [format "%-50s%-d" "Channel length $CL:" [sizeof [get_cells -quiet $clock_cells -filter "ref_name=~*T${CL}P*"]]]
  }

  set all_dffs [get_cells * -quiet -hierarchical -filter "is_sequential==true &&number_of_pins>2&&number_of_pins<25&&is_positive_level_sensitive==false&&is_negative_level_sensitive==false&&is_integrated_clock_gating_cell==false"]
  set all_dff_num [sizeof $all_dffs]
  set all_mb2  [sizeof [get_cells -quiet $all_dffs -filter "ref_name =~*2W_*"]]
  set all_mb4  [sizeof [get_cells -quiet $all_dffs -filter "ref_name =~*4W_*"]]
  set all_mb6  [sizeof [get_cells -quiet $all_dffs -filter "ref_name =~*6W_*"]]
  set all_mb8  [sizeof [get_cells -quiet $all_dffs -filter "ref_name =~*8W_*"]]
  set all_sb_cells  [sizeof [get_cells -quiet $all_dffs -filter "ref_name !~ *2W_* && ref_name !~ *4W_* && ref_name !~ *6W_* && ref_name !~ *8W_*"]]
  set all_mb_cells [expr $all_mb2*2+$all_mb4*4+$all_mb6*6+$all_mb8*8]
  set all_sb_num [expr $all_mb_cells + $all_sb_cells]
  if {$all_sb_num != 0} {
    set mbRatio [expr $all_mb_cells*100.0/$all_sb_num]
    set mbRatio [format "%5.2f" $mbRatio]
  } else {
    puts "# \$all_sb_num == 0, can't calculate!!! check it!!!" 
  }
  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip "cell type"
  set w1 20; set w2 30; set w3 30; set w4 30
  set splitline "+[string repeat - $w1]+[string repeat - $w2]+[string repeat - $w3]+[string repeat - $w4]+"
  array unset sumR *
  set sumR(Count)       0
  set sumR(Area)        0
  set sumR(percentage)  0
  set other(Count)      0
  set other(Area)       0
  set other(percentage) 0
  puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s|" \
    "Type" "Count" "Area(um2)" "percentage (%)"]
  foreach ptn $patterns {
    puts "$splitline"
    puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s|" \
      [lindex $ptn 0] "    [lindex [report_cell_info [lindex $ptn 1]] 0]" "    [lindex [report_cell_info [lindex $ptn 1]] 1]" "    [lindex [report_cell_info [lindex $ptn 1]] 2]"]
    set sumR(Count) [expr $sumR(Count) + [lindex [report_cell_info [lindex $ptn 1]] 0]]
    set sumR(Area)  [expr $sumR(Area)  + [lindex [report_cell_info [lindex $ptn 1]] 1]]
    set sumR(percentage) [expr $sumR(percentage) + [lindex [report_cell_info [lindex $ptn 1]] 2]]
  }
  set total_num         [sizeof_collection [get_cells -hierarchical *]]
  set total_area        [expr [join [get_attribute [get_cells -hierarchical *] area] "+"]]
  set other(Count)      [expr $total_num - $sumR(Count)]
  set other(Area)       [expr $total_area - $sumR(Area)]
  set other(percentage) [expr 100 - $sumR(percentage)]
  puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s|"  "Other" "    $other(Count)" "    $other(Area)" "    $other(percentage)"]
  puts "$splitline"
  set sumR(Count)       $total_num
  puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s|" \
    "Total" "    $total_num" "    $total_area" "    100"]
  puts "$splitline"
  set splitline "+[string repeat - $w1]+[string repeat - $w2]+[string repeat - $w3]+"
  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip "MultiBit DFF cells:"
  puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|" "Type" "Multi-Bit" "signal Bit"]
  puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|" "Single-Bit"    "    $all_sb_cells"   "    $all_sb_cells"]; puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|" "MB2"           "    $all_mb2"      "    [expr $all_mb2 * 2]"]; puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|" "MB4"           "    $all_mb4"      "    [expr $all_mb4 * 4]"]; puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|" "MB6"           "    $all_mb6"      "    [expr $all_mb6 * 6]"]; puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|" "MB8"           "    $all_mb8"      "    [expr $all_mb8 * 8]"];puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|" "Total"         "    $all_dff_num" "    $all_sb_num"]
  puts "$splitline"
  set splitline "+[string repeat - $w1]+[string repeat - $w2]+"
  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip "Low Power cells:"
  puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|" "Type" "Low Power Cell Count"]
  puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|" "Isolation Cell"    "    $lowpower_iso_cell_num"]; puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|" "LVL Shifter Cell"  "    $lowpower_lvl_cell_num"]; puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|" "Retention Cell"    "    $lowpower_rtn_cell_num"]; puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|" "Always-On Cell"    "    $lowpower_aon_cell_num"]; puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|" "Total" "    [expr $lowpower_iso_cell_num+$lowpower_lvl_cell_num+$lowpower_rtn_cell_num+$lowpower_aon_cell_num]"]
  puts "$splitline"
}
proc report_floating_pins {} {
  set open_input_nonet     [get_pins -filter "(!defined(net)) && is_hierarchical==false && (direction ==in || direction ==inout)" -hierarchical -quiet]
  set withnet_inputpins    [get_pins -filter "  defined(net)  && is_hierarchical==false && (direction ==in || direction ==inout)" -hierarchical -quiet]
  set open_input_withnet   [get_pins -of_objects [get_nets -of_objects $withnet_inputpins  -filter "number_of_leaf_drivers==0" -q] -leaf -q]
  set float_output_nonet   [get_pins -filter "(!defined(net)) && is_hierarchical==false && (direction ==out || direction ==inout)" -hierarchical -quiet]
  set withnet_outputpins   [get_pins -filter "  defined(net)  && is_hierarchical==false && (direction ==out || direction ==inout)" -hierarchical -quiet]
  set float_output_withnet [get_pins -of_objects [get_nets -of_objects $withnet_outputpins -filter "number_of_leaf_loads==0"   -q] -leaf -q]
  set open_input_nonet_with_case      [filter_collection $open_input_nonet  "defined(case_value)"]
  set open_input_nonet_without_case   [filter_collection $open_input_nonet "!defined(case_value)"]
  set open_input_withnet_with_case    [filter_collection $open_input_withnet  "defined(case_value)"]
  set open_input_withnet_without_case [filter_collection $open_input_withnet "!defined(case_value)"]
  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip PIN.FLOATING
  puts "# input floating (with nets) = [sizeof $open_input_nonet_without_case]"
  foreach_in_collection pin $open_input_nonet_without_case {
    puts [get_attribute $pin full_name]
  }
  puts "# input floating (without nets) = [sizeof $open_input_withnet_without_case]"
  foreach_in_collection pin $open_input_withnet_without_case {
    puts [get_attribute $pin full_name]
  }
  puts "# output floating (with nets) = [sizeof $float_output_withnet]"
  foreach_in_collection pin $float_output_withnet {
    puts [get_attribute $pin full_name]
  }
  puts "# output floating (without nets) = [sizeof $float_output_nonet]"
  foreach_in_collection pin $float_output_nonet {
    puts [get_attribute $pin full_name]
  }
}

proc report_net_status {{fanout_vth 32}} {
  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip net.status
  set all_outpins     [get_pins -filter "is_hierarchical ==false && (direction ==out||direction ==inout)" -hierarchical -quiet]
  set multidriver_net [get_nets -filter "number_of_leaf_drivers > 1" -of $all_outpins  -quiet]
  puts "\n# Multi-driver net number = [sizeof $multidriver_net]"
  foreach_in_collection net $multidriver_net {
    puts [get_attribute $net full_name]
  }
  puts "\n# ICG fanout violation (>32)"
  set icg_fanout_violation 0
  foreach_in_collection icg [get_cells -quiet -of [get_attribute [get_nets -hierarchical * -filter "is_clock_network==true"] leaf_drivers] -filter "is_integrated_clock_gating_cell==true"] {
    set fanout_loadings [all_fanout -from [get_pins -of [get_cells $icg] -filter "direction==out"] -end -flat ]
    if {[sizeof $fanout_loadings] > 32 } {
      puts "[sizeof $fanout_loadings]\t[get_attribute $icg full_name]"
      incr icg_fanout_violation 1
    }
  }
  puts "\n# Net fanout histogram:"
  array unset fanoutHistogram *
  set fanoutHistogram(1,1)    0
  set fanoutHistogram(2,2)    0
  set fanoutHistogram(3,3)    0
  set fanoutHistogram(4,15)   0
  set fanoutHistogram(15,40)  0
  set fanoutHistogram(40,80)  0
  set fanoutHistogram(80,160) 0
  set fanoutHistogram(160,320)    0
  set fanoutHistogram(320,640)    0
  set fanoutHistogram(640,1280)   0
  set fanoutHistogram(1280,2560)  0
  set fanoutHistogram(2560,5120)  0
  set fanoutHistogram(5120,5120)  0

  set clkNetFanoutVioNum 0
  set datNetFanoutVioNum 0
  set totalNets [get_nets * -hierarchical -top_net_of_hierarchical_group]
  set netLimit 32
  foreach_in_collection net $totalNets {
    set x [sizeof [get_attribute $net leaf_loads]]
    foreach rg [array names fanoutHistogram] {
      set min [lindex [split $rg ,] 0]
      set max [lindex [split $rg ,] 1]
      if {$min == 5120 && $x >= $max} {
        incr fanoutHistogram($rg) 1
      } elseif {$min == $x && $x == $max} {
        incr fanoutHistogram($rg) 1
      } elseif {$x >= $min && $x < $max} {
        incr fanoutHistogram($rg) 1
      }
    }
    if {$x > $netLimit} {
      if {[get_attribute $net is_clock_network]} {
        incr clkNetFanoutVioNum 1
      } else {
        incr datNetFanoutVioNum 1
      }
    }
  }
  if {![sizeof $totalNets]} { set len_of_totalNets inf }
  set clkNetFanoutVioRatio [format "%5.2f" [expr $clkNetFanoutVioNum*100.0/$len_of_totalNets]]
  set datNetFanoutVioRatio [format "%5.2f" [expr $datNetFanoutVioNum*100.0/$len_of_totalNets]]

  foreach vrange [lsort -dict -incr [array names fanoutHistogram]] {
    set min [lindex [split $vrange ,] 0]
    set max [lindex [split $vrange ,] 1]
    if {$min == $max} {
      puts [format "%10s   %10s:\t%10d\t%5.2f" $min "" $fanoutHistogram($vrange) [expr $fanoutHistogram($vrange)*100.0/$len_of_totalNets]]
    } else {
      puts [format "%10s ~ %10s:\t%10d\t%5.2f" $min $max $fanoutHistogram($vrange) [expr $fanoutHistogram($vrange)*100.0/$len_of_totalNets]]
    }
  }
  #### dont touch nets
  set DTNets [get_nets -filter "dont_touch == true" -quiet]
  puts "\n# Dont touch net number: [sizeof_collection $DTNets]"
  puts "-------------------------------------------------------------------------------------"
  foreach_in_collection net $DTNets {
    puts "[get_attribute $net full_name]"
  }
}  

proc report_port_status {} {
  set ports_in    [get_ports -quiet -filter "direction == in"]
  set ports_out   [get_ports -quiet -filter "direction == out"]
  set ports_inout [get_ports -quiet -filter "direction == inout"]

  set min_input_delay     50
  set max_input_delay     70
  set min_output_delay    50
  set max_output_delay    70
  set input_dummy_ports ""
  foreach_in_collection port_in $ports_in {
    if {[sizeof_collection [all_fanout -quiet -flat -trace_arcs all -from $port_in]] == 1} {
      lappend input_dummy_ports $port_in
    }
  }

  set out_dummy_ports ""
  foreach_in_collection port_out $ports_out {
    if {[sizeof_collection [all_fanin -quiet -flat -trace_arcs all -to $port_out]] == 1} {
      lappend out_dummy_ports $port_out
    }
  }

  set inout_dummy_ports ""
  foreach_in_collection port_inout $ports_inout {
    if {([sizeof_collection [all_fanin -quiet -flat -trace_arcs all -to $port_inout]] == 1) && ([sizeof_collection [all_fanout -quiet -flat -trace_arcs all -from $port_inout]] == 1)} {
      lappend inout_dummy_ports $port_inout
    }
  }
  set port_all            [sizeof_collection [get_ports *]]
  set port_input          [sizeof_collection [get_ports -quiet $ports_in]]
  set port_input_dummy    [sizeof_collection [get_ports -quiet $input_dummy_ports]]
  set port_output         [sizeof_collection [get_ports -quiet $ports_out]]
  set port_output_dummy   [sizeof_collection [get_ports -quiet $out_dummy_ports]]
  set port_inout          [sizeof_collection [get_ports -quiet $ports_inout]]
  set port_inout_dummy    [sizeof_collection [get_ports -quiet $inout_dummy_ports]]

  set port_all_dummy [expr $port_input_dummy + $port_output_dummy + $port_inout_dummy]
  set output_floating_without_tie_num [sizeof [filter_collection $out_dummy_ports  "!defined(case_value)"]]

  set input_delay_over_100_num 0
  set input_delay_over_70_num 0
  set input_delay_under_50_num 0
  set missing_input_transition_rise 0
  set missing_input_transition_fall 0
  set all_input_except_clocks [remove_from_collection [all_inputs] [filter_collection [get_attribute [all_clocks] sources] object_class==port]]
  foreach_in_collection in_port $all_input_except_clocks {
    set timing_paths [get_timing_paths -from $in_port]
    set input_delay    [get_attribute $timing_paths startpoint_input_delay_value]
    set relative_clock [get_attribute $timing_paths endpoint_clock]
    set period [get_attribute $relative_clock period]
    if {$period!=0 && $period != ""} {
      set ratio_of_input_delay [expr $input_delay*1.0/$period]
      if {$ratio_of_input_delay<$min_input_delay} {incr input_delay_under_50_num 1;}
      if {$ratio_of_input_delay>$max_input_delay} {incr input_delay_over_70_num 1}
      if {$ratio_of_input_delay>1} {incr input_delay_over_100_num 1}
    }
    set trans_rise [get_attribute $in_port input_transition_rise_max]
    set trans_fall [get_attribute $in_port input_transition_fall_max]
    if {$trans_rise==0 || $trans_rise==""} {incr missing_input_transition_rise 1}
    if {$trans_fall==0 || $trans_fall==""} {incr missing_input_transition_fall 1}
  }

  set output_delay_over_100_num 0
  set output_delay_over_70_num 0
  set output_delay_under_50_num 0
  set missing_pin_load_num 0
  set too_large_pin_load_num 0
  foreach_in_collection out_port [all_outputs] {
    set timing_paths [get_timing_paths -to $out_port]
    set output_delay    [get_attribute $timing_paths endpoint_output_delay_value]
    set relative_clock [get_attribute $timing_paths startpoint_clock]
    set period [get_attribute $relative_clock period]
    if {$period!=0 && $period != ""} {
      set ratio_of_output_delay [expr $output_delay*1.0/$period]
      if {$ratio_of_output_delay<$min_output_delay}  {incr output_delay_under_50_num 1}
      if {$ratio_of_output_delay>$max_output_delay}  {incr output_delay_over_70_num 1}
      if {$ratio_of_output_delay>1} {incr output_delay_over_100_num 1}
    }
    set pin_load [get_attribute $out_port pin_capacitance_max]
    if {$pin_load==0||$pin_load==""} {incr missing_pin_load_num 1}
    if {$pin_load>0.05} {incr too_large_pin_load_num 1}
  }

  set w1 20; set w2 30; set w3 30; set w4 30 ;set w5 30; set w6 30; set w7 30; set w8 30
  set splitline "+[string repeat - $w1]+[string repeat - $w2]+[string repeat - $w3]+[string repeat - $w4]+[string repeat - $w5]+[string repeat - $w6]+[string repeat - $w7]+"
  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip "ports"
  puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s|%-${w5}s|%-${w6}s|%-${w7}s|" "Direction" "Count" "Floating" "extDelay>70%" "extDelay<50%" "extDelay>100%" "Trans/Loads"]; puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s|%-${w5}s|%-${w6}s|%-${w7}s|" "input"  $port_input  $port_input_dummy  $input_delay_over_70_num $input_delay_under_50_num $input_delay_over_100_num $missing_input_transition_rise]; puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s|%-${w5}s|%-${w6}s|%-${w7}s|" "output" $port_output $port_output_dummy $output_delay_over_70_num $output_delay_under_50_num $output_delay_over_100_num $missing_pin_load_num]; puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s|%-${w5}s|%-${w6}s|%-${w7}s|" "inout"  $port_inout  $port_inout_dummy 'n/a' 'n/a' 'n/a' 'n/a']; puts "$splitline"
  puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s|%-${w5}s|%-${w6}s|%-${w7}s|" "total"  $port_all  $port_all_dummy [expr $input_delay_over_70_num + $output_delay_over_70_num] [expr $input_delay_under_50_num + $output_delay_under_50_num] [expr $input_delay_over_100_num + $output_delay_over_100_num] [expr $missing_input_transition_rise + $missing_pin_load_num]]; puts "$splitline"
  puts "\n# input port floating"
  foreach_in_collection port $input_dummy_ports {
    puts [get_attribute $port full_name]
  }
  puts "\n# output port floating"
  foreach_in_collection port $out_dummy_ports {
    puts [get_attribute $port full_name]
  }
  puts "\n# inout port floating"
  foreach_in_collection port $inout_dummy_ports {
    puts [get_attribute $port full_name]
  }
}

proc report_clock_status {} {
  set setup_uncertainty_flag 0
  set hold_uncertainty_flag 0
  set rise_transition_flag 0
  set fall_transition_flag 0
  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip "clock"
  puts [format "%-20s%-20s%-20s%-20s%-20s%-20s%-20s" " clock name"  " period"  " frequency"  " setup uncertainty"  " hold uncertainty"  " transition(r/f)"  " Sinks"]
  puts [format "%-20s%-20s%-20s%-20s%-20s%-20s%-20s" "------------" "--------" "-----------" "-------------------" "------------------" "-----------------" "-------"]
  foreach_in_collection clk [all_clocks] {

    set load_num [sizeof_collection [all_fanout -from  [get_attribute [get_clocks $clk] sources] -flat -end]]
    set period [get_attribute [get_clocks $clk] period]
    set period [format "%.3f" $period]
    set frequency [format "%.0fM" [expr 1000/$period]]
    set setup_margin [get_attribute [get_clocks $clk] setup_uncertainty]
    set setup_margin [format "%.3f" $setup_margin]
    set setup_ratio [expr $setup_margin*100.0/$period]
    set setup_uncertainty "$setup_margin (${setup_ratio}%)"
    if {$setup_margin==0} {
      incr setup_uncertainty_flag 1
    }
    set hold_margin  [get_attribute [get_clocks $clk] hold_uncertainty]
    set hold_margin [format "%.3f" $hold_margin]
    set hold_ratio [expr $hold_margin*100.0/$period]
    set hold_uncertainty "$hold_margin (${hold_ratio}%)"
    if {$hold_margin==0} {
      incr hold_uncertainty_flag 1
    }
    set trans_margin_r [get_attribute [get_clocks $clk] max_transition_clock_path_rise]
    if {$trans_margin_r == ""} {set trans_margin_r 0}
    set trans_margin_r [format "%.3f" $trans_margin_r]
    if {$trans_margin_r==0} {incr rise_transition_flag 1}
    set trans_margin_f [get_attribute [get_clocks $clk] max_transition_clock_path_fall]
    if {$trans_margin_f == ""} {set trans_margin_f 0}
    set trans_margin_f [format "%.3f" $trans_margin_f]
    if {$trans_margin_f==0} {incr fall_transition_flag 1}
    set clock_transition "$trans_margin_r/$trans_margin_f"
    puts [format "%-20s%-20s%-20s%-20s%-20s%-20s%-20s" \
      " [get_attribute $clk full_name]" \
      " $period" \
      "   $frequency" \
      "    $setup_uncertainty" \
      "   $hold_uncertainty" \
      "   $clock_transition" \
      "$load_num"]
  }
  set V_CLK [remove_from_collection [get_clocks *] [filter_collection [get_clocks  *]  defined(sources)]]
  foreach_in_collection virtual_clk $V_CLK {
    puts [format "%-80s" "------------------------------------------------------------------------------------------------------------------------------------------------------"]
    puts [format "%-20s " " virtual clock:"]
    puts [format "%-20s" " ------------"]
    puts  [format "%-20s" " [get_attribute $virtual_clk full_name]"]
  }
  set clockDefinedOnHierPinNum 0
  set clockDefinedOnPortNum 0
  set clockDefinedOnPinNum 0
  set clockDefinedNoSourcesNum 0
  foreach_in_collection id [get_clocks *] {
    set source_point [get_attribute [get_clocks $id] sources]
    if {[get_attribute $source_point object_class] == "pin"} {
      if {[get_attribute $source_point is_hierarchical] == "true"} {
        incr clockDefinedOnHierPinNum 1
        puts "Error: the clock [get_attribute $id full_name] defined on hierarchical port: [get_attribute $source_point full_name]"
      } else {
        incr clockDefinedOnPinNum 1
      }
    } elseif {[get_attribute $source_point object_class] == "port"} {
      incr clockDefinedOnPortNum 1
    } else {
      incr clockDefinedNoSources 1
    }
  }
  set no_sink_clock_num 0
  foreach_in_collection id [get_clocks *] {
    set sources [get_attribute [get_attribute [get_clocks $id] sources] full_name]
    if {[sizeof_collection [get_attribute [get_clocks $id] sources] ]} {
      if {[sizeof_collection [ all_fanout -from  [get_attribute [get_clocks $id] sources ] -flat -end ]]} {
        set clock_loads_num [sizeof_collection [ all_fanout -from  [get_attribute [get_clocks $id] sources ] -flat -end ]]
        if {$clock_loads_num == 0} {
          incr no_sink_clock_num 1
          puts "Warning: the clock [get_attribute $id full_name] is no sinks."
        }
      }
    }
  }
}

proc report_dont_use_status {{dont_use_list ""}} {
  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip "Dont Use"
  puts "Dont Use Summary :"
  if {$dont_use_list != ""} {
    set have_dont_use [list]
    foreach ptn $dont_use_list  {
      set number   [sizeof_collection [get_cells -hierarchical -filter "ref_name =~ $ptn" -quiet]]
      puts [format "%-50s= %-d" $ptn $number]
      if {$number > 0} {
        lappend have_dont_use $ptn
        lappend have_dont_use $number
      }
    }
    puts "\n\n"
    puts "Detail Report : "
    foreach {ptn number} $have_dont_use {
      puts [format "# %-48s= %-d :" $ptn $number]
      foreach_in_collection cell [get_cells -hierarchical -filter "ref_name =~ $ptn" -quiet] {
        set name  [get_object_name $cell]
        puts $name
      }
      puts ""
    }
  } else {
    puts "# have no content for \$dont_use_list"
  }
}
proc report_vt_usage {{cell_vt_group_mapList_eg_VTGroupName_regExpression {}}} {
  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip "vt group"
  if {![expr [llength $cell_vt_group_mapList_eg_VTGroupName_regExpression] % 2]} {
    set all_cell_num [sizeof [get_cells * -quiet -hier -filter "is_hierarchical==false"]]
    set all_cell_area [expr [join [get_attribute [get_cells * -quiet -hier -filter "is_hierarchical==false"] area] {+}]]
    array unset cell_count_result *
    array unset cell_area_result *
    foreach {vtptn ptn} ${cell_vt_group_mapList_eg_VTGroupName_regExpression} {
      set area 0
      set num [sizeof [get_cells * -quiet -hierarchical -filter "ref_name=~${ptn}"]]
      if {$num>0} {
        set area [expr [join [get_attribute [get_cells * -quiet -hierarchical -filter "ref_name=~${ptn}"] area] {+}]]
      }
      lappend cell_count_result($vtptn) $num
      lappend cell_area_result($vtptn) $area
    }
    set w1 20; set w2 30; set w3 30; set w4 30 ;set w5 30;
    set splitline "+[string repeat - $w1]+[string repeat - $w2]+[string repeat - $w3]+[string repeat - $w4]+[string repeat - $w5]+"
    puts "$splitline"
    puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s|%-${w5}s|" "VT Group" "Count" "Count Ratio(%)" "Area(um2)" "Area Ratio(%)"]; puts "$splitline"
    foreach {vtptn ptn} ${cell_vt_group_mapList_eg_VTGroupName_regExpression} {
      set total_area [expr [join $cell_area_result($vtptn) {+}]]
      set total_num  [expr [join $cell_count_result($vtptn) {+}]]
      set ratio_area [format "%.0f" [expr $total_area*100.0/$all_cell_area]]
      set ratio_num  [format "%.0f" [expr $total_num*100.0/$all_cell_num]]
      puts [format "|%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s|%-${w5}s|" "$vtptn" "$total_num" "$ratio_num" "$total_area" "$ratio_area"]; puts "$splitline"
    }
  } else {
    puts "# have no content for \$cell_vt_group_mapList_eg_VTGroupName_regExpression"
  }
}

proc report_dft_status {} {
  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip "DFT Information"
  # scan chain (not consider the DFF/Q->DFF/SI)
  set all_sdff_num [sizeof [get_cells -quiet * -hierarchical -filter "ref_name=~*SDF*"]]
  set scan_chain_num 0
  if {$all_sdff_num > 0} {
    set all_drive_of_SI_num  [sizeof [get_cells -quiet -of [get_attribute [get_nets -of [get_pins -of [get_cells -quiet * -hierarchical -filter "ref_name=~*SDF*"] -filter "lib_pin_name ==SI"]] leaf_drivers] -filter "is_sequential==true"]]
    if {$all_drive_of_SI_num == 0} {
      set scan_chain_num "no scan chain"
    } else {
      set scan_chain_num  "[expr $all_sdff_num - $all_drive_of_SI_num] chains"
    }
  }
  puts [format "%-50s%-s" "Scan Chain Number" $scan_chain_num]

  set memory_cells [get_cells -quiet * -hier -filter "is_memory_cell==true"]
  set mbist_status 0
  if {[sizeof $memory_cells] == 0} {
    set mbist_status "no memory"
  } else {
    set mbist_insts [get_cells -quiet * -hier -filter "full_name=~*mbist*||full_name=~*Mbist*||full_name=~*MBIST*||full_name=~*mBIST*"]
    if {[sizeof $mbist_insts] > 0} {
      set mbist_status "exist"
    } else {
      set mbist_status "none"
    }
  }

  set scan_compress_logic_num [sizeof [get_cells * -quiet -hierarchical -filter "full_name=~*edt_*"] ]
  puts [format "%-50s%-s" "Mbist Status" $mbist_status]
  puts [format "%-50s%-s" "Scan Chain Compress Number" $scan_compress_logic_num]

  set dont_touch_inst_num [sizeof [get_cells * -quiet -hier -filter "is_hierarchical==false&&dont_touch==true"]]

  set three_state_cell_num [sizeof [get_cells * -quiet -hier -filter "is_hierarchical==false&&is_three_state==true"]]

  set lockup_cell_num 0
  set lockup_cell_connection_issue 0
  foreach_in_collection lockupcell [get_cells -quiet * -hierarchical -filter "full_name=~*LOCK*"] {
    incr lockup_cell_num 1
    set negative_lockupcell [get_attribute -quiet [get_cells -quiet $lockupcell] is_negative_level_sensitive]
    set posetive_lockupcell [get_attribute -quiet [get_cells -quiet $lockupcell] is_posetive_level_sensitive]
    set datpin [get_pins -of [get_cells -quiet $lockupcell] -filter "direction==in&&is_data_pin==true"]
    set clkpin [get_pins -of [get_cells -quiet $lockupcell] -filter "direction==in&&is_clock_pin==true"]
    set datDriveCellPins [get_attribute -quiet [get_nets -top_net_of_hierarchical_group -of_objects [get_pins $datpin]] leaf_drivers]
    set clkDriveCellPins [get_attribute -quiet [get_attribute [get_nets -top_net_of_hierarchical_group -of_objects [get_pins $clkpin]] leaf_drivers] full_name]
    set negative_drivecell [get_attribute -quiet [get_cells -quiet -of [get_pins $datDriveCellPins]] is_fall_edge_triggered]
    set posetive_drivecell [get_attribute -quiet [get_cells -quiet -of [get_pins $datDriveCellPins]] is_rise_edge_triggered]
    set preDriveCellPins [get_attribute [get_attribute [get_nets -top_net_of_hierarchical_group -of_objects [get_pins -of [get_cells -quiet -of [get_pins $datDriveCellPins]] -filter "direction==in&&is_clock_pin==true"] ] leaf_drivers] full_name]
    if {($posetive_lockupcell==true&&$negative_drivecell==true)||($negative_lockupcell==true&&$posetive_drivecell==true)} {
      if {$preDriveCellPins != $clkDriveCellPins} {
        incr lockup_cell_connection_issue 1
      }
    } else {
      incr lockup_cell_connection_issue 1
    }
  }

  puts [format "%-50s%-s" "Lockup Number" $lockup_cell_num]
  puts [format "%-50s%-s" "Lockup Connectivity Issue Number" $lockup_cell_connection_issue]

  set dff_sel_pin_case_0_num [sizeof [get_pins -quiet -of_objects [get_cells * -quiet -hierarchical -filter "is_sequential==true"] -filter "lib_pin_name==SE&&case_value==0"]]
  set dff_sel_pin_case_1_num [sizeof [get_pins -quiet -of_objects [get_cells * -quiet -hierarchical -filter "is_sequential==true"] -filter "lib_pin_name==SE&&case_value==1"]]
  puts [format "%-50s%-s" "DFF SE Pin Case0 Number" $dff_sel_pin_case_0_num]
  puts [format "%-50s%-s" "DFF SE Pin Case1 Number" $dff_sel_pin_case_1_num]
  puts [format "%-50s%-s" "DFF SE Case0 Number" $dff_sel_pin_case_0_num]
}

proc check_memory_info {} {
  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip "Memory Information"
  set mem_list [get_cells * -hierarchical -quiet -filter "is_memory_cell"]
  set mem_num [sizeof $mem_list]
  set mem_area 0
  set mem_bit 0
  if {$mem_num>0} {
    set mem_area [expr [join [get_attribute $mem_list area] "+"]]
    set mem_cell [lsort -u [get_attribute $mem_list ref_name]]
    foreach mc $mem_cell {
      set mn [sizeof [get_cells * -hier -filter "ref_name==$mc"]]
      set m [string tolower $mc]
      regexp {([0-9]+x[0-9]+)} $m bit_info
      set w [lindex [split $bit_info {x}] 0]
      set h [lindex [split $bit_info {x}] end]
      set bits [expr $w * $h]
      puts [format "  - %-50s=%10d, %10d*%-10d=%-20d" $mc $mn $w $h $bits]
      set mem_bit [expr $mem_bit + $bits*$mn]
    }
  }
  puts "Total Memory Count = $mem_num"
  puts "Total Memory Area = ${mem_area}(um2)"
  puts "Total Memory Bits = ${mem_bit}(Bits)"
}

proc report_dont_touch_status {} {
  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip "Dont Touch"
  set dont_touch_module_list [list]
  set dont_touch_module_num  0
  set dont_touch_cell_list  [list]
  foreach_in_collection hinst [get_cells -quiet * -hierarchical -filter "is_hierarchical==true"] {
    if { [get_attribute [get_cells -quiet $hinst] dont_touch] == "true" } {
      lappend dont_touch_module_list [get_object_name $hinst]
      incr dont_touch_module_num 1
    }
  }
  foreach_in_collection cell [get_cells -quiet * -hierarchical -filter "is_hierarchical==false && dont_touch == true"] {
    lappend dont_touch_cell_list [get_object_name $cell]
  }

  puts "Dont touch module number : $dont_touch_module_num"
  foreach module $dont_touch_module_list {puts "  $module"}

  puts "Dont touch instance number : [llength $dont_touch_cell_list]"
  foreach inst $dont_touch_cell_list { puts "  $inst"}
}

proc report_asyn_status {} {
  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip "Asyn path"
  set async_path_violations_num 0
  set timing_paths [get_timing_paths -slack_lesser_than 0 -to [get_pins * -hierarchical -filter "is_async_pin==true && is_hierarchical==false"]]
  set async_path_violations_num [sizeof $timing_paths]
  puts "\nAsyn timing violation path num : $async_path_violations_num"

  set async_fanout_violation_num 0
  set async_fanout_pins          [list]
  foreach_in_collection pin [get_pins [all_fanin -flat -to [get_pins * -hierarchical -filter "is_async_pin==true && is_hierarchical==false"]] -filter "direction==out"] {
    set load_num [get_attribute [get_nets -of $pin] number_of_leaf_loads]
    if {$load_num>32} {
      incr async_fanout_violation_num 1
      lappend async_fanout_pins [get_object_name $pin]
    }
  }
  puts "Asyn outputpin fanout more than 32 : $async_fanout_violation_num"
  puts "\nAsyn pin fanout more than 32 pin list : "
  foreach pin $async_fanout_pins {
    puts "    $pin"
  }
}

proc report_connectivity_status {} {
  add_file_header -author "David yuan" -ifOnlyPutsNotDumpToFile -descrip "Memory Connection Information"
  set memory_cells  [get_cells * -quiet -hierarchical -filter "is_memory_cell==true"]
  puts [format "%-50s%s" "Memory Number" [sizeof $memory_cells]]
  if {[sizeof $memory_cells] == 0} {
    return
  }
  set memory_pins [get_pins -of [get_cells -quiet $memory_cells]]
  set memory_pin_total_num [sizeof $memory_pins]
  set memory_floating_pin_num 0
  set memory_floating_pin_list [list]
  foreach_in_collection pin $memory_pins {
    set direction [get_attribute $pin direction]
    if {$direction == "in"} {
      set core_inst_num [get_attribute -quiet [get_nets -of $pin] number_of_leaf_drivers]
    } elseif {$direction == "out"} {
      set core_inst_num [get_attribute -quiet [get_nets -of $pin] number_of_leaf_loads]
    }
    if {$core_inst_num == 0} {
      incr memory_floating_pin_num 1
      lappend memory_floating_pins_list [get_object_name $pin]
    }
  }
  set memory_floating_pin_ratio [format "%5.2f" [expr $memory_floating_pin_num/$memory_pin_total_num]]

  puts [format "%-50s%s" "Memory Floating Pin Ratio" $memory_floating_pin_ratio]
  puts "Memory Floating Pin List : "
  foreach pin $memory_floating_pin_list  {puts "  $pin"}
}

