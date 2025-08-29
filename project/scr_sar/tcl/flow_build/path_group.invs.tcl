#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/15 18:41:47 Friday
# label     : 
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
set allSeqs [all_registers]

set macros [dbget [dbget top.insts.cell.subClass block -p2].name]

set mems ""; set ips ""
foreach m $macros {
	if {[regexp {x|X} $m]} {
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

group_path -name i2r -from $inPorts -to $allSeqs
group_path -name r2o -from $allSeqs -to $outPorts
group_path -name i2o -from $inPorts -to $outPorts

setPathGroupOptions i2r -effortLevel low
setPathGroupOptions r2o -effortLevel low
setPathGroupOptions i2o -effortLevel low

group_path -name r2r -from $allSeqs -to $allSeqs
group_path -name r2g -from $regs -to $icgs

setPathGroupOptions r2r -effortLevel high -targetslack 0.0
setPathGroupOptions r2g -effortLevel high -targetslack 0.0

if {$memes != ""} {
    group_path -name r2m -from $regs_and_icgs -to $memes
    group_path -name m2g -from $memes -to $icgs
    group_path -name m2r -from $memes -to $regs
    group_path -name m2m -from $memes -to $memes

    setPathGroupOptions r2m -effortLevel high -targetslack 0.0
    setPathGroupOptions m2g -effortLevel high -targetslack 0.0
    setPathGroupOptions m2r -effortLevel high -targetslack 0.0
    setPathGroupOptions m2m -effortLevel high -targetslack 0.0
}
if {$ips != ""} {
    group_path -name r2p -from $regs_and_icgs -to $ips
    group_path -name p2r -from $ips -to $regs_and_icgs
    group_path -name p2p -from $ips -to $ips

    setPathGroupOptions r2p -effortLevel high -targetslack 0.0
    setPathGroupOptions p2r -effortLevel high -targetslack 0.0
    setPathGroupOptions p2p -effortLevel high -targetslack 0.0

}

