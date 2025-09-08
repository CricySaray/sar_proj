# ----------------------

# ----------------------
source ~/project/scr_sar/tcl/misc/gui_actions/to_eco_command_from_selected_obj_in_gui.invs.tcl
alias te "to_eco_command_from_selected_obj_in_gui"
alias li "dbget head.libCells.name"
alias df "deleteFiller -perfix "

alias pgopen "verifyConnectivity -type special -noAntenna -noWeakConnect -noUnroutedNet -noSoftPGConnect -error 1000 -warning 50"
alias ssopen "verifyConnectivity -type regular -noAntenna -noWeakConnect -noUnroutedNet -noSoftPGConnect -error 1000 -warning 50"
alias pc "setLayerPreference pinObj -isVisible 0"
alias po "setLayerPreference pinObj -isVisible 1"

alias rd "restoreDesign"
alias sd "saveDesign -tcon -verilog -def"
alias sdt "saveDesign -tcon -verilog -def -addTiming"
alias snot "restoreDesign -noTiming"
#only check the short between signal and PG. between PG and PG
alias pgshort "verify_PG_short -no_routing_blkg -no_cell_blkg"
#only check the short between signal and signal
alias ssshort "verify_drc -check_short_only -exclude_pg_net"
#check signal and pg open
alias spgopen "verifyConnectivity -noFill -noSoftPGConnect -noWeakConnect -noAntenna -noUnConnPin -noUnroutedNet"
alias setprefer "setPreference CmdLogMode 1"
#get the path of this innovus log
alias vlog "viewLog"

alias len "llength"
alias gs "dbget selected.name"
alias gb "dbget selected.box"
alias glog "getLogFileName -fullPath"
alias gcmd "getCmdLogFileName"
alias si "selectInst"
alias sic "selectInstByCellName"
#alias rp "refinePlace"
#alias er "ecoRoute"
alias cp "checkPlace"
alias gp "get_property"
alias rd "redirect"
alias m "man"
alias seteco "setEcoMode -batchMode true -honorDontTouch false -honorDontUse false -updateTiming false -honorFixedStatus false -LEQCheck false -refinePlace false"
alias setecoreset "setEcoMode -reset"
alias eda "ecoDeleteRepeater"
alias ear "ecoAddRepeater"
alias ecc "ecoChangeCell"
alias dpb "deletePlaceBlockage"
alias rg "report_globals"
alias gcpu "getMultiCpuUsage"
alias scpu "setMultiCpuUsage -localCpu"
alias rt "report_timing"
alias f "fit"
alias w "win"
alias woff "win off"
#alias sh "select_highlighted"
alias sp "selectPin"
alias sn "selectNet"
alias hl "highlight"
alias dhl "dehighlight"
alias dhls "dehighlight -select"
alias zs "zoomSelected"
alias ds "deselectAll"
alias so "select_obj"
proc dso {objs} {deselectAll ; select_obj $objs; zoomSelected}
alias dg "dbget"
alias s "source"
alias sa "source /home/pd_sar/.invs_alias.tcl"
alias g "gvim"
alias c "cd"

# --------------------------
# default config for invs gui
# --------------------------
setLayerPreference node_blockage -isVisible 0
setLayerPreference node_power -isVisible 0
setLayerPreference node_layer -isVisible 0
setLayerPreference M0 -isVisible 0
setLayerPreference VIA0 -isVisible 0

setDbGetMode -displayFormat table

# --------------------------
# internal variables of invs  
# --------------------------
set restore_db_file_check 0

# --------------------------
# alias for innovus
# --------------------------
set sar "/backend/project/p100/pd/PNR/100P/d2d_ss/sar"

# --------------------------
# some proc using invs shell or for GUI
# --------------------------
# 

alias sip "selectInstOfSelectedPin_invsGUI"
# This proc has a defect
proc selectInstOfSelectedPin_invsGUI {{removeInst ""}} {
  set selpins_ptr [dbget selected.objType instTerm -p -e]
  if {$selpins == ""} {
    error "proc selectInstOfSelectedPin_invsGUI: no selected pins in GUI!!!" 
  } else {
    set selpinsname [dbget $selpins_ptr.name]
    set allRelatedPins [list]
    foreach pin $selpinsname {
      set relatedPins [get_object_name [get_pins -of [get_nets -of $pin]]]
      set allRelatedPins [concat $allRelatedPins $relatedPins]
    }
    set allRelatedInsts [lmap related_pin $allRelatedPins {
      set inst [get_object_name [get_cells -of $related_pin] ]
    }]
    select_obj [lsort -unique $allRelatedPins]
    select_obj [lsort -unique $allRelatedInsts]
  }
}

proc autosoft {{channelSpace 15}} {
	setFinishFPlanMode -activeObj {core macro fence hardBlkg softBlkg partialBlkg routingBlkg} -drcRegionObj {macro macroHalo hardBlkg minGap coreSpacing} -direction xy -override false
	finishFloorplan -fillPlaceBlockage soft $channelSpace
}

proc list_fanout_load_pins {pin} {
	set i 1
	set drive [dbget top.insts.instTerms.name $pin -p]
	set loads [dbget $drive.net.allTerms.isInput 1 -p]
	set load_pins [dbget $loads.name]
	puts "Drive_pin : $pin"
	foreach load_pin $load_pins {
		set cell [dbget top.insts.instTerms.name $load_pin -p2]
		set cell_name [dbget $cell.cell.name]
		puts "  Load_pin $i : $cell_name  $load_pin"
		incr i
	}
}
alias load "list_fanout_load_pins"

proc list_driver_pins {pin} {
	set i 1
	set drivers [dbget [dbget [dbget top.insts.instTerms.name $pin -p].net.instTerms.isOutput 1 -p].name]
	puts "Load_pin : $pin"
	foreach driver $drivers {
		set full_name [dbget [dbget top.insts.instTerms.name $driver -p2].name]
		set ref_name [dbget [dbget top.insts.instTerms.name $driver -p2].cell.name]
		puts "  Driver_pin $i : $driver  $ref_name"
		incr i
	}
}
alias driver "list_driver_pins"

proc multiple_select_and_zoomIn {obj_list} {
	deselectAll
	foreach obj $obj_list {
		select_obj $obj
	}
	zoomSelected
}
alias goo "multiple_select_and_zoomIn"


proc M3saveDesign {dbs_name} {
  saveDesign ${dbs_name}.enc -verilog -def 
}
alias msd "M3saveDesign"

proc setecomode {} {
	setEcoMode -reset
	setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false	
}
alias seteco "setecomode"
alias resetecomode "setEcoMode -reset"

proc sar_get_cell_info {} {
	set insts [dbget selected.]
	set i 0
	set blocks [list ]
	set cell_len 0
	foreach inst $insts {
		set instname [dbget $inst.name]
		set cellname [dbget $inst.cell.name]
		if {$cellname != 0x0} {
			incr i
			#puts "$i :$cellname $instname"
			lappend blocks [list $cellname $instname]
			set cell_len_tmp [string length $cellname]
			if {$cell_len < $cell_len_tmp} { set cell_len $cell_len_tmp }
		}
	}
	set num [llength $blocks]
	set mod [expr [expr int(log10($num))] + 1]
	#puts "$mod $num"
	set j 0
	set blocks [lsort -ascii -index 0 $blocks]
	foreach block $blocks {
		incr j
		printf "%-${mod}s: %-${cell_len}s [lindex $block 1]\n" "$j" [lindex $block 0]
	}
}
alias cell "sar_get_cell_info"

proc sar_get_whole_net_lengths {{nets ""}} {
	if {$nets == ""} { set nets [dbget selected.net.name -u] }
	if {$nets == "0x0"} {
		puts "Error: No provided nets and No selected nets. Please input nets!!!"
	} else {
		set num 0
		set mod 1
		set net_length_blocks [list ]
		foreach net $nets {
			incr i
			if {[dbget top.nets.name $net] == "0x0"} {
				lappend net_length_blocks [list "NaN" $net]
			} else {
				set wires_split_length [dbget [dbget top.nets.name $net -u -p].wires.length]
				set net_length 0
				foreach wire_len $wires_split_length {
					set net_length [expr $net_length + $wire_len]
				}
				lappend net_length_blocks [list $net_length $net]
			}
		}
		foreach keyvalue $net_length_blocks {
			set len_wide [string length [lindex $keyvalue 0]]
			#puts $len_wide
			if {$mod < $len_wide} {set mod $len_wide}
		}
		set num_mod [expr [expr int(log10($i))] + 1]
		set net_length_blocks [lsort -decreasing -real -index 0 $net_length_blocks]
		#puts $net_length_blocks
		set j 0
		foreach block $net_length_blocks {
			incr j
			printf "%-${num_mod}s : %-${mod}s um : [lindex $block 1]\n" "$j" [lindex $block 0]
		}
	}
}
alias len "sar_get_whole_net_lengths"

