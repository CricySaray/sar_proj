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
  alias setpin "setPinAssignMode -pinEditInBatch true"
  alias resetpin "setPinAssignMode -reset"
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
alias sa "source ~/.invs_alias.tcl"
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
set sar "~/.invs_alias.tcl"

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
  
} elseif {![is_common_ui_mode]} {
  proc add {a b} {expr $a + $b}

  # setting for report_timing of invs
  proc setreport {} {
    set_table_style -name report_timing -no_frame -indent 0
    set_global report_timing_format {hpin cell load fanout pin_location user_derate socv_derate total_derate delay_mean delay_sigma slew incr_delay delay arrival}
  }

  # description : By entering the name of the inst, then obtain all the clock names of all its clock pins, as well as their frequencies and periods in all active views.
  alias getf "get_frequency_of_clock_of_registerClkPin"
  proc get_frequency_of_clock_of_registerClkPin {{regOrMemOrIpInsts ""}} {
    set numOfInst [llength $regOrMemOrIpInsts]
    if {$numOfInst <= 0} {
      error "proc get_frequency_of_clock_of_registerClkPin: check your input, num=$numOfInst, need : num >= 1   !!!" 
    } elseif {$numOfInst >= 1} {
      set resultList [list]
      foreach temp_inst $regOrMemOrIpInsts {
        set clkPins [dbget [dbget [dbget top.insts.name $temp_inst -p].cell.terms.isClk 1 -p].name -e -u]
        if {![llength $clkPins]} {
          lappend resultList [list / / / / $temp_inst]
          #error "proc get_frequency_of_clock_of_registerClkPin: check your input: have no clk pin for : $temp_inst" 
        } else {
          foreach temp_pin $clkPins {
            set clockNames [lsort -u [get_object_name [get_property [get_pins "$temp_inst/$temp_pin"] clocks]]]
            if {![llength $clockNames]} {
              lappend resultList [list / / / $temp_pin $temp_inst] 
            } else {
              foreach temp_clockname $clockNames {
                set periodsOfClock [lsort -u [get_property [get_clocks "$temp_clockname"] period]]
                if {![llength $periodsOfClock]} {
                  lappend resultList [list / / / $temp_pin $temp_inst]
                } else {
                  set frequenciesOfClock [lmap temp_period $periodsOfClock { 
                    set temp_freq [format "%.6f" [expr 1.000 / double($temp_period)]]
                    if {$temp_freq >= 1.000000} {
                      set temp_freq [string cat [format "%.3f" $temp_freq] G]
                    } else {
                      set temp_freq [string cat [format "%.3f" [expr double($temp_freq) * 1000]] M]
                    }
                  }]
                  set periodsString [join $periodsOfClock "/"]
                  set freqsString [join $frequenciesOfClock "/"]
                  lappend resultList [list $temp_clockname "${periodsString}ns" $freqsString $temp_pin $temp_inst]
                } 
              } 
            }
          } 
        }
      } 
      set resultList [linsert $resultList 0 [list clockName clockPeriods clockFreqs PinName instName]]
      puts "NOTICE:  If there is a '/' symbol, it indicates that the relevant information cannot be obtained. 
                  \tIt is necessary to check whether the inst has CLK, CP pins or whether the clock has relevant period settings, etc.
                  \tThere can be multiple clockPeriods and clockFreqs, representing periods or frequencies in different views. 
                  \tYou need to check the sdc or different modes for specific details.
                  \tAfter testing so far, it has been found that the pin generated by the CLK of the PLL cannot obtain its clock name, period, and frequency."
      puts "----------------------------"
      puts [join [table_format_with_title $resultList 0 left "" 0] \n]
    }
  }
  
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



### format procs :

# This proc is from ~/project/scr_sar/tcl/packages/table_format_with_title.package.tcl
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/05 10:30:00 Friday
# label     : display_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This proc formats tabular data from NESTED LIST ONLY into columns (auto-detected from max items in sublists).
#             It supports per-column width restrictions, adds optional grid lines, handles line breaks, 
#             supports per-column or global alignment, and displays a centered title above. Optimized for wrapped content in borderless mode.
# inputArgs : inputData           : tabular data, MUST be a nested list (each sublist represents a row of data)  
#             width_spec          : width specification (non-negative integer or list of non-negative integers). 
#                                   - Integer: uniform width limit for all columns (0 = no restriction)
#                                   - List: per-column width limits (must match column count, 0 = no restriction)
#             title               : table title to be displayed centered above the table (string)
#             align_spec          : alignment specification (valid values: left/center/right, or list of these values).
#                                   - Single value: apply to all columns
#                                   - List: per-column alignment (must match column count)
#                                   - Default: left
#             show_border         : border display switch (0 = no border, 1 = show border)
#                                   - Default: 1
# return    : formatted table string with title
# ref       : based on original table_col_format_wrap proc
# --------------------------
proc table_format_with_title {inputData {width_spec 0} {align_spec "left"} {title ""} {show_border 1}} {
  # Validate input parameters
  if {![llength $inputData]} {
    error "proc table_format_with_title: inputData must be a non-empty nested list (each sublist is a row)"
  }
  foreach row $inputData {
    if {![llength $row] && $row ne ""} {
      error "proc table_format_with_title: all elements in inputData must be sublists (each sublist represents a row)"
    }
  }
  if {![string is integer -strict $width_spec] && ![llength $width_spec]} {
    error "proc table_format_with_title: width_spec must be a non-negative integer or list of non-negative integers"
  }
  if {[string is integer -strict $width_spec] && $width_spec < 0} {
    error "proc table_format_with_title: width_spec integer must be non-negative"
  }
  if {[llength $width_spec]} {
    foreach w $width_spec {
      if {![string is integer -strict $w] || $w < 0} {
        error "proc table_format_with_title: all width_spec list items must be non-negative integers"
      }
    }
  }
  if {![string is list $title] && [llength $title] > 1} {
    error "proc table_format_with_title: title must be a single string"
  }
  set valid_alignments {"left" "center" "right"}
  if {[lsearch -exact $valid_alignments $align_spec] == -1 && [llength $align_spec] == 0} {
    error "proc table_format_with_title: align_spec must be a valid alignment ([join $valid_alignments {, }]) or a list of valid alignments"
  }
  if {![string is integer -strict $show_border] || $show_border < 0 || $show_border > 1} {
    error "proc table_format_with_title: show_border must be 0 (no border) or 1 (show border)"
  }
  
  # Process inputData into standard row-column structure
  set rows [list]
  foreach row $inputData {
    set processed_row [list]
    foreach col $row {
      lappend processed_row [join $col]
    }
    lappend rows $processed_row
  }
  
  # Determine column count
  set col_count 0
  foreach row $rows {
    set current_cols [llength $row]
    if {$current_cols > $col_count} {
      set col_count $current_cols
    }
  }
  if {$col_count == 0} {
    return ""
  }
  
  # Validate and process width_spec
  set col_widths [list]
  if {[string is integer -strict $width_spec]} {
    for {set i 0} {$i < $col_count} {incr i} {
      lappend col_widths $width_spec
    }
  } else {
    if {[llength $width_spec] != $col_count} {
      error "proc table_format_with_title: width_spec list length ([llength $width_spec]) must match column count ($col_count)"
    }
    foreach w $width_spec {
      lappend col_widths $w
    }
  }

  # Process alignment specification
  set align_cols [list]
  if {[lsearch -exact $valid_alignments $align_spec] != -1} {
    for {set i 0} {$i < $col_count} {incr i} {
      lappend align_cols $align_spec
    }
  } elseif {[llength $align_spec] > 0} {
    if {[llength $align_spec] != $col_count} {
      error "proc table_format_with_title: align_spec list length ([llength $align_spec]) must match column count ($col_count)"
    }
    foreach align $align_spec {
      if {[lsearch -exact $valid_alignments $align] == -1} {
        error "proc table_format_with_title: invalid alignment '$align' in align_spec. Must be one of [join $valid_alignments {, }]"
      }
      lappend align_cols $align
    }
  }
  
  # Set table formatting characters based on border switch
  if {$show_border} {
    set col_sep "|"
    set line_char "-"
    set corner_char "+"
    set inter_col_spacing 0  ;# No extra space between columns (border handles separation)
  } else {
    set col_sep ""         ;# Use two spaces for column separation in borderless mode
    set line_char ""
    set corner_char ""
    set inter_col_spacing 2  ;# Explicit spacing for visual separation
  }
  
  # Helper function to split text into lines with max width
  proc wrap_text {text max_width} {
    if {$max_width <= 0} {return [list $text]}
    set lines [list]
    set len [string length $text]
    set start 0
    while {$start < $len} {
      set end [expr {min($start + $max_width, $len)}]
      if {$end < $len && [string index $text $end] ne " " && [string index $text [expr {$end - 1}]] ne " "} {
        set space_pos [string last " " $text [expr {$end - 1}]]
        if {$space_pos > $start} {
          set end $space_pos
        }
      }
      lappend lines [string range $text $start [expr {$end - 1}]]
      set start [expr {$end == $start ? $end + 1 : $end}]
    }
    return $lines
  }
  
  # Preprocess all columns with wrapping
  set wrapped_rows [list]
  set row_heights [list]
  foreach row $rows {
    set row_cols [llength $row]
    set wrapped_cols [list]
    set max_lines 1
    for {set i 0} {$i < $col_count} {incr i} {
      set col_content [expr {$i < $row_cols ? [lindex $row $i] : ""}]
      set wrapped [wrap_text $col_content [lindex $col_widths $i]]
      lappend wrapped_cols $wrapped
      set max_lines [expr {max($max_lines, [llength $wrapped])}]
    }
    lappend wrapped_rows $wrapped_cols
    lappend row_heights $max_lines
  }
  
  # Calculate actual column widths based on wrapped content
  set actual_widths [list]
  for {set i 0} {$i < $col_count} {incr i} {
    set max_w 0
    set width_limit [lindex $col_widths $i]
    for {set r 0} {$r < [llength $wrapped_rows]} {incr r} {
      set row_cols [lindex $wrapped_rows $r]
      set col_lines [lindex $row_cols $i]
      foreach line $col_lines {
        set current_len [string length $line]
        set max_w [expr {max($max_w, $current_len)}]
      }
    }
    if {$width_limit > 0 && $max_w > $width_limit} {
      set max_w $width_limit
    }
    lappend actual_widths $max_w
  }
  
  # Create base separator line if borders are enabled
  set base_sep ""
  if {$show_border} {
    set sep_parts [list $corner_char]
    foreach w $actual_widths {
      append sep_parts [string repeat $line_char [expr {$w + 2}]] $corner_char
    }
    set base_sep $sep_parts
  }
  
  # Build table content
  set table_content [list]
  if {$show_border} {
    lappend table_content $base_sep
  }
  
  for {set r 0} {$r < [llength $wrapped_rows]} {incr r} {
    set row_cols [lindex $wrapped_rows $r]
    set row_height [lindex $row_heights $r]
    for {set line_idx 0} {$line_idx < $row_height} {incr line_idx} {
      set parts [list]
      if {$show_border} {
        lappend parts $col_sep
      }
      for {set i 0} {$i < $col_count} {incr i} {
        set col_lines [lindex $row_cols $i]
        set line_content [expr {$line_idx < [llength $col_lines] ? [lindex $col_lines $line_idx] : ""}]
        set w [lindex $actual_widths $i]
        set align [lindex $align_cols $i]
        
        # Format column content based on alignment
        if {$align eq "left"} {
          set formatted_col [format " %-*s " $w $line_content]
        } elseif {$align eq "center"} {
          set content_len [string length $line_content]
          if {$content_len >= $w} {
            set formatted_col " $line_content "
          } else {
            set pad_left [expr {int(($w - $content_len) / 2)}]
            set pad_right [expr {$w - $content_len - $pad_left}]
            set formatted_col " [string repeat " " $pad_left]$line_content[string repeat " " $pad_right] "
          }
        } elseif {$align eq "right"} {
          set formatted_col [format " %*s " $w $line_content]
        }
        
        lappend parts $formatted_col
        # Add column separator with special handling for borderless mode
        if {$i < [expr {$col_count - 1}]} {
          lappend parts $col_sep
        } elseif {$show_border} {
          lappend parts $col_sep
        }
      }
      lappend table_content [join $parts ""]
    }
    if {$show_border} {
      lappend table_content $base_sep
    }
  }
  
  # --------------------------
  # Fix: Define table_body BEFORE using it (moved from after title processing)
  # --------------------------
  set table_body $table_content
  
  # Process title (now table_body is defined and usable)
  set formatted_output [list]
  if {$title ne ""} {
    # Calculate table width using defined table_body
    set table_width [expr {[llength $table_body] > 0 ? [string length [lindex $table_body 0]] : 0}]
    set title_len [string length $title]
    if {$title_len >= $table_width || $table_width == 0} {
      lappend formatted_output $title
    } else {
      set pad [expr {int(($table_width - $title_len) / 2)}]
      lappend formatted_output [string repeat " " $pad]$title
    }
    lappend formatted_output "" ;# Add blank line between title and table
  }
  
  # Add table body to output
  lappend formatted_output {*}$table_body
  
  return $formatted_output
}

### TEST
if {0} {
  # 1. Prepare nested list data (valid input: only nested list)
  set product_data {
    {"ID" "Product Name" "Stock" "Category" "Description (long text test)"}
    {"PRD-001" "Wireless Mouse" 450 "Peripherals" "Ergonomic design with Bluetooth 5.1 and 2.4G dual-mode; 800-1600 DPI adjustable; up to 60 days battery life"}
    {"PRD-002" "Mechanical Keyboard" 230 "Peripherals" "Blue switch with anti-ghosting; RGB backlight; compatible with Windows/macOS"}
    {"PRD-003" "27\" Monitor" 89 "Displays" "4K UHD (3840×2160); 100% sRGB; HDR10 support; height-adjustable stand"}
  }
  # 2. Call procedure: width specs [10, 18, 6, 12, 35]; title "Office Equipment Inventory"
  set formatted_table [table_format_with_title $product_data {10 18 6 12 35} center "Office Equipment Inventory" 0]
  set formatted_table [table_format_with_title $product_data {10 18 6 12 35} center "" 0]
  # 3. Output result
  puts "=== Test Case 1: Valid Nested List Input ==="
  puts [join $formatted_table \n]
  
  # Test Case 2: Invalid input (non-nested list, e.g., raw string) - should throw error
  puts "\n=== Test Case 2: Error Handling for Non-Nested List Input ==="
  set invalid_data "2024-09-01 Alice Engineering API integration completed"
  puts [join [table_format_with_title $invalid_data 15 center ""] \n]
  
  # Test Case 3: Invalid input (mixed list with non-sublist elements) - should throw error
  puts "\n=== Test Case 3: Error Handling for Mixed List Input ==="
  set mixed_data {{"Row1 Col1" "Row1 Col2"} "This is not a sublist" {"Row3 Col1" "Row3 Col2"}}
  puts [join [table_format_with_title $mixed_data 0 {right left left left left} "" 0] \n]
}
