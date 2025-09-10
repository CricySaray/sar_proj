#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/10 21:00:01 Wednesday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : run cmds of setting path group
# return    : /
# ref       : link url
# --------------------------
source ../packages/logic_AND_OR.package.tcl; # eo
proc runCmd_pathGroupSetting {args} {
  set memExp {x|X} ; # expression of memory
  set shortOrLongExpressionMode "short" ; # short|long
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set allSeqs [all_registers]
  set macros [dbget [dbget top.insts.cell.subClass block -p2].name]
  set mems ""; set ips ""
  foreach m $macros {
    if {[regexp $memExp $m]} {
      lappend memes $m
    } else {
      lappend ips $m
    }
  }
  set regs_and_icgs $allSeqs
  if {$mems != ""} {set regs_and_icgs [remove_from_collection $regs_and_icgs [get_cells $mems]]}
  if {$ips != ""} {set regs_and_icgs [remove_from_collection $regs_and_icgs [get_cells $ips]]}

  set icgs [filter_collection $regs_and_icgs "is_integrated_clock_gating_cell"]
  set regs [remove_from_collection $regs_and_icgs $icgs]
  set inPorts [all_inputs -no_clocks]
  set outPorts [all_outputs]

  reset_path_group -all
  resetPathGroupOptions

  if {$shortOrLongExpressionMode in {short long}} {
    set sl $shortOrLongExpressionMode
    group_path -name [eo [expr {$sl == "short"}] i2r in2reg] -from $inPorts -to $allSeqs
    group_path -name [eo [expr {$sl == "short"}] r2o reg2out] -from $allSeqs -to $outPorts
    group_path -name [eo [expr {$sl == "short"}] i2o in2out] -from $inPorts -to $outPorts

    setPathGroupOptions [eo [expr {$sl == "short"}] i2r in2reg] -effortLevel low
    setPathGroupOptions [eo [expr {$sl == "short"}] r2o reg2out] -effortLevel low
    setPathGroupOptions [eo [expr {$sl == "short"}] i2o in2out] -effortLevel low

    group_path -name [eo [expr {$sl == "short"}] r2r reg2reg] -from $allSeqs -to $allSeqs
    group_path -name [eo [expr {$sl == "short"}] r2g reg2gating] -from $regs -to $icgs

    setPathGroupOptions [eo [expr {$sl == "short"}] r2r reg2reg] -effortLevel high -targetslack 0.0
    setPathGroupOptions [eo [expr {$sl == "short"}] r2g reg2gating] -effortLevel high -targetslack 0.0
    if {$memes != ""} {
      group_path -name [eo [expr {$sl == "short"}] r2m reg2mem] -from $regs_and_icgs -to $memes
      group_path -name [eo [expr {$sl == "short"}] m2g mem2gating] -from $memes -to $icgs
      group_path -name [eo [expr {$sl == "short"}] m2r mem2reg] -from $memes -to $regs
      group_path -name [eo [expr {$sl == "short"}] m2m mem2mem] -from $memes -to $memes

      setPathGroupOptions [eo [expr {$sl == "short"}] r2m reg2mem] -effortLevel high -targetslack 0.0
      setPathGroupOptions [eo [expr {$sl == "short"}] m2g mem2gating] -effortLevel high -targetslack 0.0
      setPathGroupOptions [eo [expr {$sl == "short"}] m2r mem2reg] -effortLevel high -targetslack 0.0
      setPathGroupOptions [eo [expr {$sl == "short"}] m2m mem2mem] -effortLevel high -targetslack 0.0
    }
    if {$ips != ""} {
      group_path -name [eo [expr {$sl == "short"}] r2p reg2ip] -from $regs_and_icgs -to $ips
      group_path -name [eo [expr {$sl == "short"}] p2r ip2reg] -from $ips -to $regs_and_icgs
      group_path -name [eo [expr {$sl == "short"}] p2p ip2ip] -from $ips -to $ips

      setPathGroupOptions [eo [expr {$sl == "short"}] r2p reg2ip] -effortLevel high -targetslack 0.0
      setPathGroupOptions [eo [expr {$sl == "short"}] p2r ip2reg] -effortLevel high -targetslack 0.0
      setPathGroupOptions [eo [expr {$sl == "short"}] p2p ip2ip] -effortLevel high -targetslack 0.0
    }
  }
}

define_proc_arguments runCmd_pathGroupSetting \
  -info "run cmd of setting path group"\
  -define_args {
    {-shortOrLongExpressionMode "specify the mode of short or long mode" oneOfString one_of_string {optional value_type {values {short long}}}}
    {-memExp "specify the expression of mem" AString string optional}
  }
