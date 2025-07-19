source -v ./setPlaceMode.tcl
deleteFiller -prefix ENDCAP
deleteFiller -prefix WELLTAP
set tap					TAP01AR9
set left				FILLER4AR9
set right				FILLER4AR9
set top_cell		{FILLER32AR9 FILLER16AR9 FILLER8AR9 FILLER4AR9 FILLER3AR9 FILLER2AR9 FILLER1AR9 }
set bottom_cell	{FILLER32AR9 FILLER16AR9 FILLER8AR9 FILLER4AR9 FILLER3AR9 FILLER2AR9 FILLER1AR9 }

setEndCapMode -reset
setEndCapMode \
	-leftBottomCorner			$left \
	-leftBottomEdge				$left \
	-leftEdge							$left \
	-leftTopCorner				$left	\
	-leftTopEdge					$left \
	-rightBottomCorner		$right \
	-rightBottomEdge			$right \
	-rightEdge						$right \
	-rightTopCorner				$right \
	-rightTopEdge					$right \
	-topEdge							$top_cell \
	-bottomEdge						$bottom_cell \
	-boundary_tap					true \
	-fitGap								true

set_well_tap_mode -rule 39.9 -bottom_tap_cell $tap

addEndCap -prefix ENDCAP -powerDomain PDM_AON
addEndCap -prefix ENDCAP -powerDomain PDM_TOP

addWellTap -cell $tap -cellInterval 99.96 -checkerBoard -prefix WELLTAP -avoidAbutment -powerDomain PDM_AOM
addWellTap -cell $tap -cellInterval 99.96 -checkerBoard -prefix WELLTAP -avoidAbutment -powerDomain PDM_AOM

verifyEndCap
verifyWellTap
