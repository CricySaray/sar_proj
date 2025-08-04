#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/04 15:40:32 Monday
# label     : check_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|misc_proc)
# descrip   : check long net
# return    : rpt of long nets
# update    : 2025/08/04 22:34:24 Monday
#             U001: classify four parts: data(1v1 one2more) and clk(1v1 and one2more), can specify thresholds seperately
#                   and add cmd_selectViolNets file for convenience
# ref       : link url
# --------------------------
source ../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl; # get_net_length
source ../packages/print_formattedTable_D2withCategory.package.tcl; # print_formattedTable_D2withCategory
source ../packages/print_formattedTable.package.tcl; # print_formattedTable
source ../packages/logic_AND_OR.package.tcl; # eo er
source ../packages/pw_puts_message_to_file_and_window.package.tcl; # pw
proc check_longnet {{clockOne2OneThreshold 130} {clockOne2MoreThreshold 350} {dataOne2OneThreshold 120} {dataOne2MoreThreshold 260} {rpt_file "sor_longnet.list"} {cmd_selectViolNets "so_longnet.tcl"}} {
  if {![string is integer $dataOne2OneThreshold] || ![string is integer $dataOne2MoreThreshold] || ![string is integer $clockOne2OneThreshold] || ![string is integer $clockOne2MoreThreshold]} {
    error "proc check_longnet: check your input : dataThreshold($dataOne2OneThreshold | $dataOne2MoreThreshold) and clockThreshold($clockOne2OneThreshold | $clockOne2MoreThreshold) must be integer!!!" 
  } else {
    set clockNets_col [get_nets -of [get_clock_network_objects -type pin]]
    set clockNets [get_object_name $clockNets_col]
    foreach clknet $clockNets {
      set clknetLen [get_net_length $clknet]
      set clknetFanout [get_fanout_of_net $clknet]
      if {$clknetLen > $clockOne2OneThreshold && $clknetFanout == 1} {
        lappend violClkOne2OneNets [list $clknetLen $clknet] 
      } elseif {$clknetLen > $clockOne2MoreThreshold && $clknetFanout > 1} {
        lappend violClkOne2MoreNets [list $clknetLen $clknetFanout $clknet]
      }
    }
    set allNets_col [get_nets -hier *]
    set dataNets_col [remove_from_collection $allNets_col $clockNets_col]
    set dataNets [get_object_name $dataNets_col]
    foreach datanet $dataNets {
      set datanetLen [get_net_length $datanet]
      set datanetFanout [get_fanout_of_net $datanet]
      if {$datanetLen > $dataOne2OneThreshold && $datanetFanout == 1} {
        lappend violDataOne2OneNets [list $datanetLen $datanet] 
      } elseif {$datanetLen > $dataOne2MoreThreshold && $datanetFanout > 1} {
        lappend violDataOne2MoreNets [list $datanetLen $datanetFanout $datanet]
      }
    }
    set cates [list violClkOne2OneNets violClkOne2MoreNets violDataOne2OneNets violDataOne2MoreNets]
    set thresholds [list $clockOne2OneThreshold $clockOne2MoreThreshold $dataOne2OneThreshold $dataOne2MoreThreshold]
    set allNumNet 0
    foreach cate_temp $cates { ; # U001
      set $cate_temp [lsort -index 0 -real -decreasing [eval set temp \${$cate_temp}]]
      array set cate [list $cate_temp [llength [eval set temp \${$cate_temp}]]]
      set allNumNet [expr $allNumNet + $cate($cate_temp)]
    }
    if {$allNumNet} {
      foreach cate_temp $cates threshold $thresholds { ; # U001
        er $cate($cate_temp) { lappend violNets [list ${cate_temp}_greaterThan_$threshold [eval set temp \${$cate_temp}]] } {}
        lappend summaryOfCates [list "-" ${cate_temp}_greaterThan_$threshold $cate($cate_temp)]
        lappend cmd_so_longnet "alias so_$cate_temp select_obj \{ \\\n[join [lmap items [eval set temp \${$cate_temp}] { set itemtemp "[lindex $items end]"}] " \\\n"] \\\n\}"
      }
      set fo [open $rpt_file w]
      set so [open $cmd_selectViolNets w]
      puts $fo [print_formattedTable_D2withCategory $violNets]
      puts $so [join $cmd_so_longnet \n]
      pw $fo ""
      pw $fo "  ============================="
      pw $fo [print_formattedTable $summaryOfCates]
      pw $fo ""
      close $fo; close $so
    } else {
      puts "" 
      puts "proc check_longnet: HAVE NO LONG NET!!!"
      puts "" 
    }
  }
}

proc get_fanout_of_net {{netname ""}} {
  if {$netname == "" || $netname == "0x0" || [dbget top.nets.name $netname -e ] == ""} {
    error "proc get_fanout_of_net: check your input: netname($netname) is incorrect!!!"
  } else {
    set fanout [dbget [dbget top.nets.name $netname -p].numInputTerms]
    return $fanout
  }
}
