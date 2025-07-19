deselectAll
selectInstByCellName VESDC09*
foreach clp [dbGet selected] {
	set n [dbGet $clp.name]
	addHaloToBlock 10 10 10 10 $n
}
deselectAll
