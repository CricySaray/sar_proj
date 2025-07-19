set cmd "set_analysis_view $vars(cts_analysis_view)"
eval $cmd
set setup_analysis_view [all_setup_analysis_views]
set hold_analysis_view  [all_hold_analysis_views]

##-----------------------------------------------------------------------------------------
## proc
##-----------------------------------------------------------------------------------------
#proc set_setup_uncertainty {clk} {
#    set margins(SETUP.PLL_JITTER)            7.5   ; # Precent of cycle time
#    set margins(SETUP.CLK_JITTER)            0.003  ; # for CT jitter
#    set margins(SETUP.AGING)                 0      ; # Precent of cycle time
#
#    set clk_period  [get_attribute [get_clocks $clk] period -quiet]
#    if {$clk_period != ""} {
#        set setup_pll_jitter    [expr $clk_period * $margins(SETUP.PLL_JITTER)/100]
#        set setup_clk_jitter     $margins(SETUP.CLK_JITTER)
#        set setup_aging          [expr $clk_period * $margins(SETUP.AGING)]
#        set setup_uncertainty    [expr ceil(($setup_pll_jitter + $setup_clk_jitter + $setup_aging) * 1000)/1000]
#        if {$setup_uncertainty > 0.200} {set setup_uncertainty 0.200}
#        echo "set_clock_uncertainty -setup $setup_uncertainty $clk"
#        set_clock_uncertainty -setup $setup_uncertainty $clk
#		}
#
#}


#-----------------------------------------------------------------------------------------
# setup and hold
#-----------------------------------------------------------------------------------------
#### Uncertatinty
# The setup uncertainty use LVT
#     all:    3ps
# The hold  uncertainty use LVT
#     SS :   13ps
#     FF :    3ps
if {[regexp place $vars(step)]} {
set setup_uncertainty    0.023
set hold_SS_uncertainty  0.033
set hold_FF_uncertainty  0.023
}
if {[regexp cts $vars(step)]} {
set setup_uncertainty    0.013
set hold_SS_uncertainty  0.023
set hold_FF_uncertainty  0.013
}
if {[regexp route $vars(step)]} {
set setup_uncertainty    0.003
set hold_SS_uncertainty  0.023
set hold_FF_uncertainty  0.013
}
if {[regexp postroute $vars(step)]} {
set setup_uncertainty    0.003
set hold_SS_uncertainty  0.013
set hold_FF_uncertainty  0.003
}
# Setup
# Setup
# Setup
foreach id $setup_analysis_view {
    echo $id
	set_analysis_view -setup $id -hold $id
	set_interactive_constraint_modes  [all_constraint_modes -active_setup]
    set_clock_uncertainty -setup $setup_uncertainty [all_clocks]
    set_interactive_constraint_modes {}
}
# Hold
foreach id $hold_analysis_view {
    echo $id
	set_analysis -setup $id -hold $id
	set_interactive_constraint_modes  [all_constraint_modes -active_hold]
    if {[regexp wc|wcl|wcz $id]} {
	    set_clock_uncertainty -hold $hold_SS_uncertainty [all_clocks]
    } elseif {[regexp ml|lt|bc $id]} {
	    set_clock_uncertainty -hold $hold_FF_uncertainty [all_clocks]
    }
	set_interactive_constraint_modes {}
}
set cmd "set_analysis_view $vars(cts_analysis_view)"
eval $cmd
