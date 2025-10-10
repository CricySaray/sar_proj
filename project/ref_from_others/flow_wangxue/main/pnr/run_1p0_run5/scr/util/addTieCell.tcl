setTieHiLoMode -cell $vars(tie_cells) -maxDistance 5 -maxFanout 4 -prefix TIECELL
foreach cell $vars(tie_cells) { 
   setDontUse $cell false
}
exec rm -rf ./tie_exclude.tcl
set pins {u_afe_core/i_tx_dyn_pwr_ctrl_tx_pa u_afe_core/rx0_rfpll_paddr[15] u_afe_core/rx0_rfpll_paddr[14] u_afe_core/rx0_rfpll_paddr[13] u_afe_core/rx0_rfpll_paddr[12]}
foreach pin $pins {
	echo $pin >> tie_exclude.tcl
}

addTieHiLo -matchingPDs true  -excludePin tie_exclude.tcl

foreach cell {TIELBWP7T35P140 TIEHBWP7T35P140 } { 
   setDontUse $cell true
}

verifyTieCell
