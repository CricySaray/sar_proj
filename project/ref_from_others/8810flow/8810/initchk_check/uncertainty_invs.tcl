set setup_analysis_view [all_setup_analysis_views]
set hold_analysis_view  [all_hold_analysis_views]

#-----------------------------------------------------------------------------------------
# proc
#-----------------------------------------------------------------------------------------
proc set_setup_uncertainty {clk} {
    set margins(SETUP.PLL_JITTER)            7.5   ; # Precent of cycle time
    set margins(SETUP.CLK_JITTER)            0.003  ; # for CT jitter
    set margins(SETUP.AGING)                 0      ; # Precent of cycle time

    set clk_period  [get_attribute [get_clocks $clk] period -quiet]
    if {$clk_period != ""} {
        set setup_pll_jitter    [expr $clk_period * $margins(SETUP.PLL_JITTER)/100]
        set setup_clk_jitter     $margins(SETUP.CLK_JITTER)
        set setup_aging          [expr $clk_period * $margins(SETUP.AGING)]
        set setup_uncertainty    [expr ceil(($setup_pll_jitter + $setup_clk_jitter + $setup_aging) * 1000)/1000]
        if {$setup_uncertainty > 0.200} {set setup_uncertainty 0.200}
        echo "set_clock_uncertainty -setup $setup_uncertainty $clk"
        set_clock_uncertainty -setup $setup_uncertainty $clk
		}

}

#-----------------------------------------------------------------------------------------
# setup and hold
#-----------------------------------------------------------------------------------------
# Setup
foreach id $setup_analysis_view {
    echo $id
	set_analysis_view -setup $id -hold $id

    foreach_in_collection clk [all_clocks] {
        set clk_name  [get_attribute $clk full_name]
   		set_setup_uncertainty $clk_name
    }

}

# Hold
set hold_unc   "0.030"
foreach id $hold_analysis_view {
    echo $id
	set_analysis -setup $id -hold $id
	set_interactive_constraint_modes  [all_constrain_modes -active_hold]
	set_clock_uncertainty -hold $hold_unc_bc [all_clocks]
	set_interactive_constraint_modes {}
}
