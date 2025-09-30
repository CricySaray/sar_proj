# ----------------------
# sar invs alias and other settings
# ----------------------
history keep 10000
proc shis {index} {
  set history_list [split [history] \n]
  if {$index > [expr [llength $history_list] + 1]} {
    error "proc shis(search history) : index is out of avaiable index list(1 - [expr [llength $history_list] + 1])!!!"
  } else {
    puts [lindex $history_list [expr $index - 1]]
  }
}
if {[is_common_ui_mode]} {
  alias dim "gui_dim_foreground -light_level medium"
  alias li "get_db head.libCells.name"
  alias df "delete_filler -prefix "

  alias pgopen "check_connectivity -type special -ignore_dangling_wires -ignore_weak_connects -ignore_unrouted_nets -ignore_soft_pg_connects -error 1000 -warning 50"
  alias ssopen "check_connectivity -type regular -ignore_dangling_wires -ignore_weak_connects -ignore_unrouted_nets -ignore_soft_pg_connects -error 1000 -warning 50"
  alias pc "set_layer_preference pinObj -is_visible 0"
  alias po "set_layer_preference pinObj -is_visible 1"

  alias rd "read_db"
  alias sd "write_db -verilog -def "
  alias sdt "write_db  -verilog -def -add_ignored_timing"
  alias snot "read_db -no_timing"
  #only check the short between signal and PG. between PG and PG
  alias pgshort "check_pg_shorts -no_routing_blockages -no_cell_blockages"
  #only check the short between signal and signal
  alias ssshort "check_drc -check_short_only -exclude_pg_nets"
  #check signal and pg open
  alias spgopen "check_connectivity -no_fill -ignore_soft_pg_connects -noWeakConnect -noAntenna -noUnConnPin -noUnroutedNet"
  #get the path of this innovus log
  alias vlog "view_log"

  alias len "llength"
  alias gs "get_db selected .name"
  alias gb "get_db selected .bbox"
  alias glog "get_db log_file"
  alias gcmd "get_db cmd_file"
  alias gp "get_property"
  alias seteco "set_db eco_batch_mode 1 eco_hornor_dont_touch 0 eco_honor_dont_use 0 eco_update_timing 0 eco_honor_fixed_status 0 eco_check_logical_equivalence 1 eco_refine_place 0"
  alias setecoreset "reset_db eco_*"
  alias eda "eco_delete_repeater"
  alias ear "eco_add_repeater"
  alias ecc "eco_update_cell"
  alias dpb "deletePlaceBlockage"
  alias rg "report_globals"
  alias gcpu "getMultiCpuUsage"
  alias scpu "setMultiCpuUsage -localCpu"
  alias rt "report_timing"
  alias f "fit"
  alias w "gui_show"
  alias woff "gui_hide"
  #alias sh "select_highlighted"
  alias sp "select_pin"
  alias sn "selectNet"
  alias hl "highlight"
  alias dhl "dehighlight"
  alias dhls "dehighlight -select"
  alias zs "gui_zoom -selected"
  alias ds "deselect_obj -all"
  alias so "select_obj"
  alias sr "select_routes"
  proc dso {objs} {deselectAll ; select_obj $objs; zoomSelected}
  alias dg "get_db"

} else {
  set restore_db_file_check 0
  alias dim "gui_dim_foreground -lightness_level medium"
  alias li "dbget head.libCells.name"
  alias df "deleteFiller -prefix "

  alias pgopen "verifyConnectivity -type special -noAntenna -noWeakConnect -noUnroutedNet -noSoftPGConnect -error 1000 -warning 50"
  alias ssopen "verifyConnectivity -type regular -noAntenna -noWeakConnect -noUnroutedNet -noSoftPGConnect -error 1000 -warning 50"
  alias pc "setLayerPreference pinObj -isVisible 0"
  alias po "setLayerPreference pinObj -isVisible 1"

  alias rd "restoreDesign"
  alias sd "saveDesign -tcon -verilog -def -addTiming"
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
  alias gp "get_property"
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
}
# common
alias s "source"
alias sa "source /home/pd_sar/.invs_alias.tcl"
alias g "gvim"
alias c "cd"
alias m "man"

# --------------------------
# default config for invs gui
# --------------------------
if {[is_common_ui_mode]} {
  set_layer_preference node_blockage -is_visible 0
  set_layer_preference node_power -is_visible 0
  set_layer_preference node_layer -is_visible 0
  set_layer_preference M0 -is_visible 0
  set_layer_preference VIA0 -is_visible 0

} else {
  setLayerPreference node_blockage -isVisible 0
  setLayerPreference node_power -isVisible 0
  setLayerPreference node_layer -isVisible 0
  setLayerPreference M0 -isVisible 0
  setLayerPreference VIA0 -isVisible 0
  setDbGetMode -displayFormat table
}
# common setting for alias commands
dim ; # dim foreground

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

if {[is_common_ui_mode]} {
  eval_legacy {
    alias gll "getLoaders_fromDriverPin"
    proc getLoaders_fromDriverPin {} {
      set pin [dbget selected.name]
      if {[dbget top.insts.instTerms.name $pin -e] != ""} {
        set net [dbget [dbget top.insts.instTerms.name $pin -p].net.name] 
        set inputTermsOnNet [dbget [dbget [dbget top.nets.name $net -p].instTerms.isInput 1 -p].name]
      }
      dehighlight -all
      deselectAll
      select_obj $inputTermsOnNet
      highlight -index 4
    }

    alias gn "get_net"
    proc get_net {} {
      set pin [dbget selected.name]
      set net [get_object_name [get_nets -of $pin]]
      foreach n $net {
        puts "editDelete -net $n" 
      }
    }

    alias tp "to_placeInstance" 
    proc to_placeInstance {} {
      set insts_ptr [dbget selected.]
      foreach inst_ptr $insts_ptr {
        set name [dbget $inst_ptr.name]
        set pt [dbget $inst_ptr.pt]
        puts "placeInstance $name $pt" 
      }
    }


    alias te "toeco"
    alias toeco "to_eco_command_from_selected_obj_in_gui"
    proc to_eco_command_from_selected_obj_in_gui {{objs ""}} {
      if {$objs == ""} { set objs [dbget selected.name -e] }
      if {$objs == ""} {
        puts "error: no selected and no inputs!!!"
      } else {
        set insts ""
        set terms ""
        foreach obj $objs {
          set inst [dbget top.insts.name $obj -e]
          if {$inst != ""} {lappend insts $inst}
          set term [dbget top.insts.instTerms.name $obj -e]
          if {$term != ""} {lappend terms $term}
        }
        if {$insts != ""} {
          foreach i $insts { puts "ecoChangeCell -cell [dbget [dbget top.insts.name $i -p].cell.name] -inst $i" } 
        }
        if {$terms != ""} {
          foreach t $terms { puts "ecoAddRepeater -name sar_fix_what -cell what -term {$t} -loc { }"} 
        }
      }
    }

    alias gl "get_net_length"
    proc get_net_length {{net ""}} {
      if {[lindex $net 0] == [lindex $net 0 0]} { ; # U001
        set net [lindex $net 0]
      }
      if {$net == "0x0" || [dbget top.nets.name $net -e] == ""} { 
        error "proc get_net_length: check your input: net($net) is not found!!!"
      } else {
        set wires_split_length [dbget [dbget top.nets.name $net -u -p].wires.length -e]
        if {$wires_split_length == ""} { return 0 } ; # U002
        set net_length 0
        foreach wire_len $wires_split_length {
          set net_length [expr $net_length + $wire_len]
        }
        return $net_length
      }
    }

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
    alias gls "sar_get_whole_net_lengths"
  }
  
} else {
  alias gll "getLoaders_fromDriverPin"
  proc getLoaders_fromDriverPin {} {
    set pin [dbget selected.name]
    if {[dbget top.insts.instTerms.name $pin -e] != ""} {
      set net [dbget [dbget top.insts.instTerms.name $pin -p].net.name] 
      set inputTermsOnNet [dbget [dbget [dbget top.nets.name $net -p].instTerms.isInput 1 -p].name]
    }
    dehighlight -all
    deselectAll
    select_obj $inputTermsOnNet
    highlight -index 4
  }

  alias gn "get_net"
  proc get_net {} {
    set pin [dbget selected.name]
    set net [get_object_name [get_nets -of $pin]]
    foreach n $net {
      puts "editDelete -net $n" 
    }
  }

  alias tp "to_placeInstance" 
  proc to_placeInstance {} {
    set insts_ptr [dbget selected.]
    foreach inst_ptr $insts_ptr {
      set name [dbget $inst_ptr.name]
      set pt [dbget $inst_ptr.pt]
      puts "placeInstance $name $pt" 
    }
  }


  alias te "toeco"
  alias toeco "to_eco_command_from_selected_obj_in_gui"
  proc to_eco_command_from_selected_obj_in_gui {{objs ""}} {
    if {$objs == ""} { set objs [dbget selected.name -e] }
    if {$objs == ""} {
      puts "error: no selected and no inputs!!!"
    } else {
      set insts ""
      set terms ""
      foreach obj $objs {
        set inst [dbget top.insts.name $obj -e]
        if {$inst != ""} {lappend insts $inst}
        set term [dbget top.insts.instTerms.name $obj -e]
        if {$term != ""} {lappend terms $term}
      }
      if {$insts != ""} {
        foreach i $insts { puts "ecoChangeCell -cell [dbget [dbget top.insts.name $i -p].cell.name] -inst $i" } 
      }
      if {$terms != ""} {
        foreach t $terms { puts "ecoAddRepeater -name sar_fix_what -cell what -term {$t} -loc { }"} 
      }
    }
  }

  alias gl "get_net_length"
  proc get_net_length {{net ""}} {
    if {[lindex $net 0] == [lindex $net 0 0]} { ; # U001
      set net [lindex $net 0]
    }
    if {$net == "0x0" || [dbget top.nets.name $net -e] == ""} { 
      error "proc get_net_length: check your input: net($net) is not found!!!"
    } else {
      set wires_split_length [dbget [dbget top.nets.name $net -u -p].wires.length -e]
      if {$wires_split_length == ""} { return 0 } ; # U002
      set net_length 0
      foreach wire_len $wires_split_length {
        set net_length [expr $net_length + $wire_len]
      }
      return $net_length
    }
  }

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
  alias gls "sar_get_whole_net_lengths"
    
}

if {[is_common_ui_mode]} { gui_hide }
