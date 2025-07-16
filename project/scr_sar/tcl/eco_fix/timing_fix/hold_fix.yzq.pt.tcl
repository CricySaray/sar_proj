#!/bin/tclsh
# --------------------------
# from      : yzq
# date      : 2025/07/11 19:14:40 Friday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : Execute in the worst hold session. In the first step of the entire hold-fixing process 
#             (which consists of two steps), generate a file containing relevant paths with hold violations 
#             and the violations themselves based on the file processed from the hold violation file (either 
#             manually processed, automatically processed via a script, or generated specifically for hold violation 
#             endpoints from PT). This prepares for the second step.
# ref       : link url
# --------------------------
# FIRST STEP
# songNOTE: run at HOLD session
proc gen_hold_path {{filepath ""} {timestamp ""}} {
  if {![file exists $filepath/hold_endpt_$timestamp.list]} { puts "no hold endpt file."; return}
  set fi [open $filepath/hold_endpt_$timestamp.list r]
  set fo [open $filepath/hold_path_$timestamp.list w]
  while {[gets $fi line] > -1} {
    set pin [lindex $line 0]
    set vio [lindex $line 1]
    set pathObj [get_timing_paths -delay_type min -to $pin]
    set pathVio [get_attribute $pathObj slack]
    set pathPoints [list [lrange [lreverse [get_object_name [get_attribute [get_attribute $pathObj points] object]]] 0 end-1]]
    #puts $fo "$pathPoints $pathVio"
    if {$pathObj == ""} {
      puts $fo "$pin $vio" 
    } else {
      puts $fo "$pathPoints $vio" 
    }
  }
  close $fi; close $fo
}

#!/bin/tclsh
# --------------------------
# from      : yzq
# date      : 2025/07/11 19:03:58 Friday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : In the second step of the entire hold-fixing process (which consists of two steps), 
#             execute this proc in the worst setup session based on the path list file generated in the first step. 
#             Then, fix the hold issues according to the setup margin. The fixing should be as conservative as possible, 
#             without being too aggressive.
# ref       : link url
# --------------------------
# SECOND STEP
# songNOTE: run at SETUP session
proc gen_fix_hold_scr_advance {{filepath ""} {timestamp ""} {hier ""}} {
  catch {unset candidate} 
  if {![file exist $filepath/hold_path_$timestamp.list]} { puts "no hold path file."; return}
  set fi [open $filepath/hold_path_$timestamp.list r]

  set fo1 [open $filepath/setup_margin_$timestamp.list w]
  set fo2 [open $filepath/fix_hold_${timestamp}_invs.tcl w]
  set fo3 [open $filepath/fix_hold_${timestamp}_pt.tcl w]
  set fo4 [open $filepath/no_margin_$timestamp w]
  set fo5 [open $filepath/io_path_$timestamp w]

  puts $fo2 "setEcoMode -reset"
  puts $fo2 "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"
  while {[gets $fi line] > -1} {
    set points [lindex $line 0]
    set vio [lindex $line 1]

    set maxMargin 0 
    set maxMarginPin ""
    set succeed 0

    # The number of items in the two variables `VIO_level` and `DEL_cells` must be consistent.
    set VIO_level [list -0.2 -0.11 -0.04 -0.02 -0.01]
    set DEL_cells [list DEL0N2X1AR9 DEL0N1X1AR9 DEL0N0X1AR9 BUFX1AR9 BUFX2AR9]

    foreach point $points {
      if {[regexp {ISO|LVL} [get_attribute [get_cells -of $point] ref_name]]} {
        puts "ISO or LVL encountered, trace backwards!!!" 
      }
      set pathObj [get_timing_paths -delay_type max -thr $point]
      set margin [get_attribute $pathObj slack]
      if {$margin == ""} {set margin 10000}
      if {$margin > $maxMargin} {set maxMargin $margin; set maxMarginPin $point}
      if {[expr $margin + $vio * 2.5] >= 0 && $margin > 0.012} {
        if {[regexp {U_AFE_SUB_WRAP|U_DDR_SUB_WRAP|U_CPU_SUB_WRAP} $point]} {

        } else {
          set hitFlag 0
          foreach violevel $VIO_level del $DEL_cells {
            if {$vio < $violevel && !$hitFlag} {
              set number [expr int(ceil(abs($vio / $violevel)))] 
              set type $del
              set hitFlag 1
            }
          }
          if {!$hitFlag} {
            set number 1
            set type [lindex $DEL_cells end] 
          }
        }
        set portFinded [get_ports -quiet [all_fanin -to $point -flat -startpoints_only]]
        if {$portFinded == ""} {
          if {![info exists candidate($point)]} {
            set candidate($point) [list $number $type $vio] 
          } else {
            if {$vio < [lindex $candidate($point) end]} {
              set candidate($point) [list $number $type $vio]
            } 
          }
          puts "Succeed! $point $vio $margin\n"
          puts $fo1 "#[lindex $point 0]\n$point $vio $margin"
          set succeed 1
          break
        } else {
          set pathIO [get_timing_paths -delay_type max -thr $portFinded -thr $point]
          set marginIO [get_attribute -quiet $pathIO slack]
          if {$marginIO == ""} {set marginIO 10000}
          if {[expr $marginIO + $vio * 2.5] >= 0 && $marginIO > 0.012} {
            if {![info exists candidate($point)]} {
              set candidate($point) [list $number $type $vio]
            } else {
              if {$vio < [lindex $candidate($point) end]} {
                set candidate($point) [list $number $type $vio]
              } 
            }
            puts "Succeed!(IO Path) $point $vio $margin\n"
            puts $fo1 "#[lindex $points 0]\n(IO Path)$point $vio $margin"
            set succeed 1
            break
          } else {
            puts "IO path exists and IO margin is not enough! Trace backwards! $point $vio $margin"
            puts $fo5 "IO path exists and IO margin is not enough! Trace backwards! $point $vio $margin"
          }
        }
      } else {
        puts "No enough margin! Trace backwards! $point $vio $margin" 
      }
    }
    if {!$succeed} {
      puts "Failed! [lindex $points 0]\n"
      puts $fo4 "[lindex $points 0] $vio $maxMargin<$maxMarginPin> == NO MARGIN" 
    }
  }

  set i 0
  foreach point [array names candidate] {
    set pointNew $point
    if {$hier != ""} { regsub -all "$hier/" $point "" pointNew } 
    set number [lindex $candidate($point) 0]
    set type   [lindex $candidate($point) 1]
    for {set j 0} {$j < $number} {incr j} {
      puts $fo2 "ecoAddRepeater -cell $type -term $pointNew -name scr_fix_hold_${timestamp}_${i}_${j} -loc \[dbget \[dbget top.insts.instTerms.name $pointNew -p1\].pt\]" 
      puts $fo3 "insert_buffer $point -new_cell_names add_fix_hold_${timestamp}_${i}_${j} -new_net_name add_fix_hold_${timestamp}_${i}_${j} $type"
    }
    incr i
  }
  
  puts $fo2 "setEcoMode -reset"
  close $fi; close $fo1; close $fo2; close $fo3; close $fo4; close $fo5
}
