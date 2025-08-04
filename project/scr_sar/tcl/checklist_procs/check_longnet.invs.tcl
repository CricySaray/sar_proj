#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/04 15:40:32 Monday
# label     : check_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|misc_proc)
# descrip   : check long net
# return    : rpt of long nets
# TODO      : U001: classify four parts: data(1v1 one2more) and clk(1v1 and one2more), can specify thresholds seperately
# ref       : link url
# --------------------------
source ../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl; # get_net_length
source ../packages/print_formattedTable_D2withCategory.package.tcl; # print_formattedTable_D2withCategory
source ../packages/print_formattedTable.package.tcl; # print_formattedTable
source ../packages/logic_AND_OR.package.tcl; # eo
proc check_longnet {{dataThreshold 150} {clockThreshold 250} {rpt_file "sor_longnet.list"}} {
  if {![string is integer $dataThreshold] || ![string is integer $clockThreshold]} {
    error "proc check_longnet: check your input : dataThreshold($dataThreshold) and clockThreshold($clockThreshold) must be integer!!!" 
  } else {
    set clockNets_col [get_nets -of [get_clock_network_objects -type pin]]
    set clockNets [get_object_name $clockNets_col]
    set violClkNets [lmap clknet $clockNets {
      set clknetLen [get_net_length $clknet]
      if {$clknetLen > $clockThreshold} {
        set clknetLen_name [list $clknetLen $clknet] 
      } else {
        continue 
      }
    }]
    set violClkNets [lsort -index 0 -real -decreasing $violClkNets]

    set allNets_col [get_nets -hier *]
    set dataNets_col [remove_from_collection $allNets_col $clockNets_col]
    set dataNets [get_object_name $dataNets_col]
    set violDataNets [lmap datanet $dataNets {
      set datanetLen [get_net_length $datanet]
      if {$datanetLen > $dataThreshold} {
        set datanetLen_name [list $datanetLen $datanet] 
      } else {
        continue 
      }
    }]
    set violDataNets [lsort -index 0 -real -decreasing $violDataNets]
    array set cate [list violClkNets [llength $violClkNets]]
    array set cate [list violDataNets [llength $violDataNets]]
    set allNumNet [expr $cate(violClkNets) + $cate(violDataNets)]
    if {$allNumNet} {
      er $cate(violClkNets) { lappend violNets [list violated_clk_nets_greaterThan_$clockThreshold $violClkNets] } {}
      er $cate(violDataNets) { lappend violNets [list violated_data_nets_greaterThan_$dataThreshold $violDataNets] } {}
      set fo [open $rpt_file w]
      puts $fo [print_formattedTable_D2withCategory $violNets]
      puts $fo ""
      puts $fo "  ============================="
      puts $fo [print_formattedTable [list [list "-" violated_clk_nets_greaterThan_$clockThreshold $cate(violClkNets)] [list "-" violated_data_nets_greaterThan_$dataThreshold $cate(violDataNets)]]]
      close $fo
    } else {
      puts "" 
      puts "proc check_longnet: HAVE NO LONG NET!!!"
      puts "" 
    }
  }
}
