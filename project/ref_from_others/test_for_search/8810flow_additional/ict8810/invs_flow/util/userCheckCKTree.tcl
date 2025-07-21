proc userCheckCKTree {vt}  {
##userCheckCKTree A9TR50
	global vars
	set file [open $vars(rpt_dir)/[dbgDesignName].$vars(step).CheckCKTree.$vars(view_rpt).rpt w]
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
					if {[dbGet ${instPtr}.cell.baseClass] == "block" || [dbGet ${instPtr}.cell.baseClass] == "pad" } {
						continue
					} else {
						#set instPtr [dbget $instPtr.name]
						set InstName [dbget $instPtr.name]
						set cell [dbget [dbInstCell $instPtr].name]
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
								puts "# Clock Tree Inst $InstName ($cell) is not $vt cell,please check"
								puts $file "# Clock Tree Inst $InstName ($cell) is not $vt cell"
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
