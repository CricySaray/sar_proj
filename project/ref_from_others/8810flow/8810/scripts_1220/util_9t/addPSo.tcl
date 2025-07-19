addPowerSwitch -column     \
	-powerDomain $pgvars(domain)                      \
        -globalSwitchCellName $pgvars(channel_pso_cell)   \
	-enablePinIn { MSLEEPIN2 MSLEEPIN1 } \
	-enablePinOut { MSLEEPOUT2 MSLEEPOUT1 } \
	-enableNetIn { lb_pwr_en lb_top/lb_in1_1 } \
	-enableNetOut { lb_top/lb_in1_OUT2 lb_pwr_ack } \
	-backToBackChain RToL \
	-incremental 0 \
	-loopbackAtEnd 0 \
        -placementAdjustX -2.38 \
        -placeunderverticalnet {VDD_CORE M7}  \
	-honorNonRegularPitchStripe \
	-ignreSoftBlockage \
	-topDown 1 \
	-noFixedStdCellOverlap \
	-area { 0 1 500 700 } \
        -switchModuleInstance lb_te_top/cc

createPlaceBlockage -type hard name temp_blk -boxList { }


addPowerSwitch -column     \
	-powerDomain $pgvars(domain)                      \
        -globalSwitchCellName $pgvars(channel_pso_cell)   \
	-enablePinIn { MSLEEPIN2 MSLEEPIN1 } \
	-enablePinOut { MSLEEPOUT2 MSLEEPOUT1 } \
	-enableNetIn { lb_top/lb_in1_OUT2 lb_top/lb_in1_2 } \
	-enableNetOut { lb_top/lb_in1_OUT2_2 lb_top/lb_in1_1} \
	-backToBackChain RToL \
	-incremental 1 \
	-loopbackAtEnd 0 \
        -placementAdjustX -2.38 \
        -placeunderverticalnet {VDD_CORE M7}  \
	-honorNonRegularPitchStripe \
	-ignreSoftBlockage \
	-topDown 0 \
	-noFixedStdCellOverlap \
	-checkerBoard \
        -switchModuleInstance lb_te_top/cc

createPlaceBlockage -type hard name temp_blk1 -boxList { }
