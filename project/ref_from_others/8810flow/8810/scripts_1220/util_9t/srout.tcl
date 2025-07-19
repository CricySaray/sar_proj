setSrouteMode -corePinLength 6030 -secondaryPinMaxGap 0.5
setViaGenMode -ignore_DRC true
if {[dbGet top.fPlan.coreSite.name] == "core7d5T" } {
	sroute -powerDomain xx -secondaryPinNet VDD_CORE \
		-tagetViaLayerRange {1 7 } \
		-crossoverViaLayerRange {1 7} \
		-corePinCheckStdcellGeoms \
		-connect {secondaryPowerPin}
} elseif {[dbGet top.fPlan.coreSite.name] == "core" } {
	setSrouteMode -secondaryPinRailWidth 0.05
        sroute -powerDomain xx -secondaryPinNet VDD_CORE \
                -tagetViaLayerRange {1 7 } \
                -crossoverViaLayerRange {1 7} \
                -corePinCheckStdcellGeoms \
                -connect {secondaryPowerPin}

}
setSrouteMode -reset
setViaGenMode -ignore_DRC false
