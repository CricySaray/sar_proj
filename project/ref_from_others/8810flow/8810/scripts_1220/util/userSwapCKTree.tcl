proc userSwapCKTree {vt}  {
##userSwapCKTree A9TR50
	global vars
	set file [open $vars(rpt_dir)/[dbgDesignName].$vars(step).SwapCKTree.$vars(view_rpt).rpt w]
	setEcoMode -refinePlace false -updateTiming false
	setEcoMode -honorDontUse false -honorDontTouch false -honorFixedStatus false
	setEcoMode -LEQCheck true
	dbForEachCellNet [dbgTopCell] netPtr {
		if {[dbget ${netPtr}.isClock] || [dbget ${netPtr}.isCTSClock]} {
			dbForEachNetTerm $netPtr termPtr {
				if {[dbGet ${termPtr}.objType] == "term"} {
					continue
				} else {
					set instPtr [dbTermInst $termPtr]
					if {[dbGet ${instPtr}.cell.baseClass] == "block" || [dbGet ${instPtr}.cell.baseClass] == "pad" || [dbGet  ${instPtr}.cell.name  ANTEN*]!="0x0" } {
						continue
					} else {
						#set instPtr [dbget $instPtr.name]
						set InstName [dbget $instPtr.name]
						set cell [dbget [dbInstCell $instPtr].name]
						#puts "$cell"
						if { [sizeof_collection [get_cells -filter "is_sequential==true && is_integrated_clock_gating_cell == false " $InstName]] } {
							continue
						} else { 
							if {[regexp {^TSMC} $vars(library)]} {
								regsub "BWP.*" $cell $vt cell_1
							} elseif {[regexp {^SMIC} $vars(library)] || [regexp {^ARM} $vars(library)]} {
								regsub "_A.*" $cell _${vt} cell_1
							} else {
								puts "WARNING : No support for $vars(library) now!!"
								break
							}
							if {[dbGetCellByName $cell_1] == "0" } {
								puts "$cell hasn't $vt vtclass"
								continue
							} elseif { $cell == $cell_1} {
								continue
							} else {
								ecoChangeCell -inst $InstName -cell $cell_1
								puts $file "# change cell from $cell to $cell_1"
								puts $file "ecoChangeCell -inst $InstName -cell $cell_1"
							}
						}
					}
				}
			}
		}
	}
	close $file
	setEcoMode -reset
}
