#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/10 20:58:56 Wednesday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : run cmds of setting path groups for pt
# NOTICE    : There are some differences in the syntax between the `define_proc_a*` and `value_*` commands in PT and invs:  
#             - In invs, the corresponding commands are: `define_proc_arguments` and `value_type`.  
#             - In PT, the corresponding commands are: `define_proc_attributes` and `value_help`.  
#             Please note the distinction.  
# return    : /
# ref       : link url
# --------------------------
source ../packages/logic_AND_OR.package.tcl; # eo
proc runCmd_pathGroupSetting_pt {args} {
  set memExp                    {x|X} ; # expression of memory
  set shortOrLongExpressionMode "short" ; # short|long
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  # DONT CHANGE IT AT WILL:
  set allSeqs [all_registers]
  set macros [get_object_name [get_cells -quiet -hierarchical -filter "is_black_box"]]
  set mems ""; set ips ""
  foreach m $macros {
    if {[regexp $memExp $m]} {
      lappend mems $m
    } else {
      lappend ips $m
    }
  }
  set regs_and_icgs $allSeqs
  if {$mems != ""} {set regs_and_icgs [remove_from_collection $regs_and_icgs [get_cells $mems]]}
  if {$ips != ""} {set regs_and_icgs [remove_from_collection $regs_and_icgs [get_cells $ips]]}
  set icgs [filter_collection $regs_and_icgs "is_integrated_clock_gating_cell"]
  #set regs [remove_from_collection [all_registers -edge_triggered] $icgs]
  set regs [remove_from_collection $regs_and_icgs $icgs]
  set inPorts [all_inputs -exclude_clock_ports]
  set outPorts [all_outputs]
  remove_path_group -all
  if {$shortOrLongExpressionMode in {short long}} {
    set sl $shortOrLongExpressionMode
    group_path -name [eo [expr {$sl == "short"}] i2r in2reg] -from $inPorts -to $allSeqs
    group_path -name [eo [expr {$sl == "short"}] r2o reg2out] -from $allSeqs -to $outPorts
    group_path -name [eo [expr {$sl == "short"}] i2o in2out] -from $inPorts -to $outPorts

    group_path -name [eo [expr {$sl == "short"}] r2r reg2reg] -from $allSeqs -to $allSeqs
    group_path -name [eo [expr {$sl == "short"}] r2g reg2gate] -from $regs -to $icgs
    if {$mems != ""} {
      group_path -name [eo [expr {$sl == "short"}] r2m reg2mem] -from $regs_and_icgs -to $mems
      group_path -name [eo [expr {$sl == "short"}] m2g mem2gate] -from $mems -to $icgs
      group_path -name [eo [expr {$sl == "short"}] m2r mem2reg] -from $mems -to $regs
      group_path -name [eo [expr {$sl == "short"}] m2m mem2mem] -from $mems -to $mems
    }
    if {$ips != ""} {
      group_path -name [eo [expr {$sl == "short"}] r2p reg2ip] -from $regs_and_icgs -to $ips
      group_path -name [eo [expr {$sl == "short"}] p2r ip2reg] -from $ips -to $regs_and_icgs
      group_path -name [eo [expr {$sl == "short"}] p2p ip2ip] -from $ips -to $ips 
    }
  }
}

define_proc_attributes runCmd_pathGroupSetting_pt \
  -info "run cmd of setting path group"\
  -define_args {
    {-shortOrLongExpressionMode "specify the mode of short or long mode" oneOfString one_of_string {optional value_help {values {short long}}}} 
    {-memExp "specify the expression of mem" AString string optional}
  }
