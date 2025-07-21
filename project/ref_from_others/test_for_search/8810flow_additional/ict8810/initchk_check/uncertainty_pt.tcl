set margins(SETUP.PLL_JITTER)     7.5 ; # Precent of cycle time
set margins(SETUP.CLK_JITTER)   0.003 ; # 3ps for CT iitter
set margins(SETUP.AGING)            0 ; # Precent of cycle time
set margins(SETUP.SPATIAL)        0.0 ; # Precent of cycle time
set margins(SETUP.DPT)              0 ; # 5ps for DPT
set margins(SETUP.SYN)              0 ; # Precent of cycle time
set margins(SETUP.PLACE)            0 ; # Precent of cycle time
set spec_jitter                     0

foreach_in_collection clk [all_clocks] {
    set clkName   [get_attribute $clk full_name]
    set clkPeriod [lsort -u [get_attribute [get_clock $clkName] period -quiet]]
    if { $clkPeriod !="" } {
        set setup_pll_jitter [expr $clkPeriod * $margins(SETUP.PLL_JITTER) / 100]
        set setup_clk_jitter $margins(SETUP.CLK_JITTER)
        set setup_aging   [expr $clkPeriod * $margins(SETUP.AGING) / 100]
        set setup_spatial [expr $clkPeriod * $margins(SETUP.SPATIAL)/100]
        set setup_dpt     $margins(SETUP.DPT)
        set setup_uncertainty [expr ceil(($setup_pll_jitter + $setup_clk_jitter + $setup_aging + $setup_spatial + $setup_dpt) * 1000)/1000]
        if {$setup_uncertainty > 0.200} {set setup_uncertainty 0.200}
        echo "set_clock_uncertainty -setup $setup_uncertainty \[get_clocks $clkName\]"
        set_clock_uncertainty -setup $setup_uncertainty [get_clocks $clkName]
    }
}
proc min {a b} {
    if {$a < $b} {
        return $a
    } else {
        return $b
    }
}

catch {unset clk_arr}

proc set_max_data_transition {MAX_DATA_SLEW} {
    foreach_in_collection clk [all_clocks] {
        set clk_name   [get_attribute $clk full_name]
        set clk_period [get_attribute $clk period -quiet]
        if {$clk_period !¡Ô ""} {
            set clk_arr($clk_name) $clk_period
        }
    }
    foreach {name period} [lsort -stride 2 -index 1 -real -decreasing [array get clk_arr]] {
        set max_slew [expr (ceil ($period / 3.000 * 1000)) / 1000]
        set min_slew [min $max_slew $MAX_DATA_SLEW]
        echo "set_max_transition $min_slew -data_path $name"
        set_max_transition $min_slew -data_path [get_clocks $name]
    }
}

proc set_max_clock_transition {MAX_CLK_SLEW} {
    foreach_in_collection clk [all_clocks] {
        set clk_name   [get_attribute $clk full_name]
        set clk_period [get_attribute $dlk period -quiet]
        if { $clk_period != "" } {
            set clk_arr($clk_name) $clk_period
        }
    }
    foreach {name period} [lsort -stride 2 -index 1 -real -decreasing [array get clk_arr]] {
        #set max_slew [expr (ceil ($period /6.000 * 1000)) / 1000]
        set max_slew [expr (ceil ($period / 10.000*1000)) / 1000]
        set min_slew [min $max_slew $MAX_CLK_SLEW]
        echo "set_max_transition $min_slew -clock_path $name"
        set max_transition $min_slew -clock_path [get_clocks $name ]
    }
}
