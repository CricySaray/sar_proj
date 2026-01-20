#!/bin/tclsh
# --------------------------
# author    : clourney semi
# date      : 2026/01/20 11:08:28 Tuesday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : check antenna cell
# return    : output file and format list
# ref       : link url
# --------------------------
proc check_antennaCell {args} {
  set ipCelltypeToCheckAnt [list]
  set rptName "signoff_check_antennaCell.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set ipInsts [list]
  foreach temp_ipCelltype $ipCelltypeToCheckAnt {
    set temp_inst [dbget [dbget top.insts.cell.name $temp_ipCelltype -p2].name -e] 
    if {$temp_inst ne ""} {
      lappend ipInsts {*}$temp_inst 
    }
  }
  set fo [open $rptName w]
  set antCellNum [llength [dbget top.insts.cell.name ANTENNA*]]
  puts $fo "antenna cell num in design: $antCellNum"
  set totalNum 0
  foreach temp_inst $ipInsts {
    set temp_pins [dbget [dbget [dbget top.insts.name $temp_inst -p].instTerms.isOutput 1 -p].name -e] 
    foreach temp_pin $temp_pins {
      set temp_net [dbget [dbget top.insts.instTerms.name $temp_pin -p].net.name -e]
      if {$temp_net ne "" && ![regexp {NIL|UNCONNECTED} $temp_net]} {
        set temp_net_insts_col [get_cells -q -of [get_nets $temp_net]] 
        if {![regexp {ANT} [get_property $temp_net_insts_col ref_name]]} {
          puts $fo "noAntennaCell pin: $temp_pin"
          incr totalNum
        }
      }
    }
  }
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "noAntCellPin $totalNum"
  close $fo
  return [list noAntCellPin $totalNum]
}

define_proc_arguments check_antennaCell \
  -info "check antenna cell"\
  -define_args {
    {-ipCelltypeToCheckAnt "specify the list of ip celltype" AList list optional}
    {-rptName "specify output file name" AString string optional}
  }
