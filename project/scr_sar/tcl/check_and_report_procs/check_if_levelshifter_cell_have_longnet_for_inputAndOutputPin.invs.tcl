#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/06/10 19:33:08 Wednesday
# label     : check_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
source ../packages/calculate_manhattan_distance.package.tcl; # calculate_manhattan_distance
source ../packages/table_format_with_title.package.tcl; # table_format_with_title
proc check_if_levelshifter_cell_have_longnet_for_inputAndOutputPin {args} {
  set levelshifterCelltypeExp {CKLS*}
  set thresholdOfDistance     50
  set outputfilename          "check_if_levelshifter_cell_have_longnet_for_inputAndOutputPin_[clock format [clock seconds] -format "%Y%m%d_%H%M%S"].tcl"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  # set all_levelshifter_insts_ptr [dbget top.insts.cell.name $levelshifterCelltypeExp -p]
  set all_levelshifter_inst_ptr [dbget top.insts.cell.name $levelshifterCelltypeExp -p2]
  set violationLevelShifterPinList [list]
  set passLevelShifterPinList [list]
  set pins_of_levelshifter [list I Z]
  set i 0
  puts "processing ... (total [llength $all_levelshifter_inst_ptr] level shifter insts.)"
  foreach temp_level_shifter_inst_ptr $all_levelshifter_inst_ptr {
    incr i
    puts -nonewline "$i "
    flush stdout
    # set all_connected_insts_col [get_cells -of [get_nets -of [get_cells [dbget $temp_level_shifter_inst_ptr.name]]]]
    
    set all_connected_instTerms_ptr [dbget $temp_level_shifter_inst_ptr.instTerms.net.instTerms. -e]
    foreach temp_pin_of_lvl $pins_of_levelshifter {
      set temp_lvl_pin_ptr [dbget top.insts.instTerms.name [dbget $temp_level_shifter_inst_ptr.name -e]/$temp_pin_of_lvl -p]
      set temp_lvl_pin_pt [lindex [dbget $temp_lvl_pin_ptr.pt -e] 0]
      set temp_connected_pins_ptr [dbget $temp_lvl_pin_ptr.net.instTerms. -e]
      set temp_connected_terms_ptr [dbget $temp_lvl_pin_ptr.net.terms. -e]
      set maxLengthForEveryLvlPinConnected 0
      foreach temp_connected_pin_ptr $temp_connected_pins_ptr {
        if {[dbget $temp_connected_pin_ptr.name] eq "[dbget $temp_level_shifter_inst_ptr.name]/$temp_pin_of_lvl"} {
          continue
        } else {
          set temp_connected_pin_pt [lindex [dbget $temp_connected_pin_ptr.pt -e] 0]
          set temp_manhattan_distance [calculate_manhattan_distance $temp_lvl_pin_pt $temp_connected_pin_pt]
          if {$temp_manhattan_distance > $maxLengthForEveryLvlPinConnected} {
            set maxLengthForEveryLvlPinConnected $temp_manhattan_distance
          }
        }
      }
      foreach temp_connected_term_ptr $temp_connected_terms_ptr {
        if {[dbget $temp_connected_term_ptr.name] eq "[dbget $temp_level_shifter_inst_ptr.name]/$temp_pin_of_lvl"} {
          continue
        } else {
          set temp_connected_pin_pt [lindex [dbget $temp_connected_term_ptr.pt -e] 0]
          set temp_manhattan_distance [calculate_manhattan_distance $temp_lvl_pin_pt $temp_connected_pin_pt]
          if {$temp_manhattan_distance > $maxLengthForEveryLvlPinConnected} {
            set maxLengthForEveryLvlPinConnected $temp_manhattan_distance
          }
        }
      }
      if {$maxLengthForEveryLvlPinConnected > $thresholdOfDistance} {
        lappend violationLevelShifterPinList [list $maxLengthForEveryLvlPinConnected [dbget $temp_lvl_pin_ptr.name -e]]
      } else {
        lappend passLevelShifterPinList [list $maxLengthForEveryLvlPinConnected [dbget $temp_lvl_pin_ptr.name -e]]
      }
      # if {[regexp $levelshifterCelltypeExp [get_property [get_cells $temp_connected_instterm_ptr] ref_name]]} {
      #   set temp_levelshifter_inst_pt [lindex [dbget [dbget top.insts.name $temp_connected_instterm_ptr -p].pt] 0]
      #   set temp_boundary_buffer_inst_pt [lindex [dbget [dbget top.insts.name [dbget $temp_level_shifter_inst_ptr.name] -p].pt] 0]
      #   set temp_manhattan_distance [calculate_manhattan_distance $temp_levelshifter_inst_pt $temp_boundary_buffer_inst_pt]
      #   if {$temp_manhattan_distance > $thresholdOfDistance} {
      #     lappend violationLevelShifterPinList [list $temp_manhattan_distance $temp_connected_instterm_ptr]
      #   } else {
      #     lappend passLevelShifterPinList [list $temp_manhattan_distance $temp_connected_instterm_ptr]
      #   }
      #   break
      # } else {
      #   continue
      # }
    }
  }
  puts ""
  set violationLevelShifterPinList [lsort -decreasing -real -index 0 $violationLevelShifterPinList]
  set passLevelShifterPinList [lsort -decreasing -real -index 0 $passLevelShifterPinList]
  set violationLevelShifterPinList [linsert $violationLevelShifterPinList 0 [list netLength levelshifterInst]]
  set passLevelShifterPinList [linsert $passLevelShifterPinList 0 [list netLength levelshifterInst]]

  set fo [open $outputfilename w] 
  puts $fo "total [llength $all_levelshifter_inst_ptr] boundary buffers :"
  puts $fo ""
  puts $fo "violation list:( > $thresholdOfDistance um ) \[total [llength $violationLevelShifterPinList]\]"
  puts $fo [join [table_format_with_title $violationLevelShifterPinList 0 left "" 0] \n]
  puts $fo "pass list:( < $thresholdOfDistance um ) \[total [llength $passLevelShifterPinList]\]"
  puts $fo [join [table_format_with_title $passLevelShifterPinList 0 left "" 0] \n]
  close $fo
  puts "dump output file to : $outputfilename"
}

define_proc_arguments check_if_levelshifter_cell_have_longnet_for_inputAndOutputPin \
  -info "whatFunction"\
  -define_args {
    {-levelshifterCelltypeExp "specify the level shifter cell type exp" AString string optional}
    {-thresholdOfDistance "specify the threshold of manhattan distance" AFloat float optional}
  }
