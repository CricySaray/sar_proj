########################################
# author: David Yuan
# Date: 2024/10/21
# Version: 1.0
# path group setting
########################################

#if { [regexp {route} $vars(step)] } {
#    set handshake_ports [get_ports "*valid* *vld* *ready* *rdy*" -filter "direction==out" -quiet]
#    if { $handshake_ports != "" } { 
#        set sinks [get_object_name [filter_collection [all_fanin -to $handshake_ports -startpoint -view func_wcl_cworst_t] name=~CK*]]
#        if { $sinks != "" } { 
#            echo "INFO: for handshake signals"
#            group_path -name  to_handshake -from [all_registers] -to [get_cells -of [get_pins $sinks]]
#            setPathGroupOptions to_handshake -effortLevel high -weight 2
#        }   
#    }
#}
reset_path_group -all
if {$vars(step) == "init"}  {
    createBasicPathGroups -expanded
    setPathGroupOptions in2out -effortLevel low
    setPathGroupOptions in2reg -effortLevel low
    setPathGroupOptions reg2out -effortLevel low
    setPathGroupOptions reg2cgate -effortLevel high
    setPathGroupOptions reg2reg -effortLevel high
    reportPathGroupOptions
} else {
    
    # Create collection for each category
    set inp   [all_inputs -no_clocks]
    set outp  [all_outputs]
    if {[get_cells -hierarchical -filter "is_memory_cell == true"  -q ] != "" } {
        set mems  [filter_collection [all_registers -macros  ] is_memory_cell -q]
    } 
    if {[get_cells -hierarchical -filter "is_macro_cell==true && is_memory_cell == false && number_of_pins > 50" -q ] != "" } {
        set blks [get_cells -hierarchical -filter "is_macro_cell==true && is_memory_cell == false && number_of_pins > 50" -q]
    }
    set icgs  [filter_collection [all_registers] "is_integrated_clock_gating_cell == true"]
    set regs  [remove_from_collection [all_registers ] $icgs]
    
    if {[get_cells -hierarchical -filter "is_memory_cell == true"  -q ] != "" } {
        set regs  [remove_from_collection $regs $mems ]
    } 
    
    if {[get_cells -hierarchical -filter "is_macro_cell==true && is_memory_cell == false && number_of_pins > 50" -q ] != "" } {
        set regs [remove_from_collection $regs $blks ]
    }
    
    
    set allregs  [all_registers]
    # Create IO Path Groups
    group_path   -name in2reg       -from  $inp -to $allregs
    group_path   -name reg2out      -from $allregs -to $outp
    group_path   -name in2out       -from $inp   -to $outp
    
    #Create REG Path Groups
    group_path   -name reg2reg      -from $regs -to $regs
    if {[get_cells -hierarchical -filter "is_memory_cell == true"  -q ] != "" } {
        group_path   -name reg2mem      -from $regs -to $mems
        group_path   -name mem2reg      -from $mems -to $regs
    }
    
    if {[get_cells -hierarchical -filter "is_macro_cell==true && is_memory_cell == false && number_of_pins>50" -q ] != "" } {
        group_path	-name reg2blk 	-from $regs -to $blks
        group_path	-name blk2reg 	-from $blks -to $regs
    }
    group_path   -name reg2cgate    -from $allregs -to $icgs
    
    # create sub-block path group 
    # ETM  TODO
    # It's best to defien the sub-block path group name reg2blk and blk2reg
    # ILM
    
    
    if {[info exists env($vars(step)_setup_margin)]}     {set setup_margin     $env($vars(step)_setup_margin)}     else {set setup_margin 0}
    if {[info exists env($vars(step)_icg_setup_margin)]} {set icg_setup_margin $env($vars(step)_icg_setup_margin)} else {set icg_setup_margin  0 }
    if {[info exists env($vars(step)_hold_margin)]}      {set hold_margin      $env($vars(step)_hold_margin)}      else {set hold_margin 0}
    
    if {$setup_margin != ""} {
        setPathGroupOptions reg2reg -slackAdjustment [expr 0 - $setup_margin] -effortLevel high -weight 15
    
        if {[get_cells -hierarchical -filter "is_memory_cell == true"  -q ] != "" } {
            setPathGroupOptions reg2mem -slackAdjustment [expr 0 - $setup_margin] -effortLevel high -weight 15
            setPathGroupOptions mem2reg -slackAdjustment [expr 0 - $setup_margin] -effortLevel high -weight 15
        }
        if {[get_cells -hierarchical -filter "is_macro_cell==true && is_memory_cell == false && number_of_pins > 50" -q ] != "" } {
            setPathGroupOptions reg2blk -slackAdjustment [expr 0 - $setup_margin] -effortLevel high -weight 15
            setPathGroupOptions blk2reg -slackAdjustment [expr 0 - $setup_margin] -effortLevel high -weight 15
        }
    }
    
    if {[info exists icg_setup_margin] && $icg_setup_margin != ""} {
        setPathGroupOptions reg2cgate -slackAdjustment [expr 0 - $icg_setup_margin] -effortLevel high -weight 15
    }
    
    if {$hold_margin != ""} {
        setPathGroupOptions reg2reg -slackAdjustment [expr 0 - $hold_margin] -early
    }
    
    
    foreach group {in2reg reg2out in2out} {
        setPathGroupOptions $group -effortLevel high  -weight 5
    }
    
    reportPathGroupOptions
}
