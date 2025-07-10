proc gen_fix_hold_scr_advance {{filepath ""} {timestamp ""} {hier ""}} {
  catch {unset candidate} 
  if {![file exist $filepath/hold_path_$timestamp.list]} { puts "no hold path file."; return}
  set fi2 [open $filepath/hold_path_$timestamp.list r]

  set fol [open $filepath/setup_margin_$timestamp.list w]
  set fo2 [open $filepath/fix_hold_${timestamp}_invs.tcl w]
  set fo3 [open $filepath/fix_hold_${timestamp}_pt.tcl w]
  set fo4 [open $filepath/no_margin_$timestamp w]
  set fo5 [open $filepath/io_path_$timestamp w]

  puts $fo2 "setEcoMode -reset""
  puts $fo2 "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"
  while {[gets $fi2 line] > -1} {
    set points [lindex $line 0]
    set vio [lindex $line 1]

    set maxMargin 0 
    set maxMarginPin ""
    set succeed 0

    foreach point $points {
      if {[regexp {ISO|LVL} [get_attribute [get_cells -of $point] ref_name]]} {
        puts "ISO or LVL encountered, trace backwards!!!" 
      }
      set pathObj [get_timing_paths -delay_type max -thr $point]
      set margin [get_attribute $pathObj slack]
      if {"" == $margin} {set margin 10000}
      if {$margin > $maxMargin} {set maxMargin $margin; set maxMarginPin $point}
      if {[expr $margin + $vio * 2.5] >= 0 && $margin > 0.012} {
        if {[regexp ]} 
      }
    }
  }


}
