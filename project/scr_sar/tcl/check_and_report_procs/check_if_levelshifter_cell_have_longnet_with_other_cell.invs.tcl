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
proc check_if_levelshifter_cell_have_longnet_with_port {args} {
  set levelshifterCelltypeExp {CKLS*}
  set thresholdOfDistance  50
  set outputfilename "check_if_levelshifter_cell_have_longnet_with_port_[clock format [clock seconds] -format "%Y%m%d_%H%M%S"].tcl"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  # set all_levelshifter_insts_ptr [dbget top.insts.cell.name $levelshifterCelltypeExp -p]
  set all_targetConnectionInstsList [dbget top.insts.name *sar_fix_boundary_buffer_*]
  set violationList [list]
  set passList [list]
  set i 0
  puts "processing ... (total [llength $all_targetConnectionInstsList] boundary buffers)"
  foreach temp_boundary_buffer_inst_ptr $all_targetConnectionInstsList {
    incr i
    puts -nonewline "$i "
    flush stdout
    # set all_connected_insts_col [get_cells -of [get_nets -of [get_cells [dbget $temp_boundary_buffer_inst_ptr.name]]]]
    set all_connected_insts_list [dbget $temp_boundary_buffer_inst_ptr.instTerms.net.instTerms.inst.name -e]
    foreach temp_connected_inst $all_connected_insts_list {
      if {[regexp $levelshifterCelltypeExp [get_property [get_cells $temp_connected_inst] ref_name]]} {
        set temp_levelshifter_inst_pt [lindex [dbget [dbget top.insts.name $temp_connected_inst -p].pt] 0]
        set temp_boundary_buffer_inst_pt [lindex [dbget [dbget top.insts.name [dbget $temp_boundary_buffer_inst_ptr.name] -p].pt] 0]
        set temp_manhattan_distance [calculate_manhattan_distance $temp_levelshifter_inst_pt $temp_boundary_buffer_inst_pt]
        if {$temp_manhattan_distance > $thresholdOfDistance} {
          lappend violationList [list $temp_manhattan_distance $temp_connected_inst]
        } else {
          lappend passList [list $temp_manhattan_distance $temp_connected_inst]
        }
        break
      } else {
        continue
      }
    }
  }
  puts ""
  set violationList [lsort -decreasing -real -index 0 $violationList]
  set passList [lsort -decreasing -real -index 0 $passList]
  set violationList [linsert $violationList 0 [list netLength levelshifterInst]]
  set passList [linsert $passList 0 [list netLength levelshifterInst]]

  set fo [open $outputfilename w] 
  puts $fo "total [llength $all_targetConnectionInstsList] boundary buffers :"
  puts $fo ""
  puts $fo "violation list:( > $thresholdOfDistance um ) \[total [llength $violationList]\]"
  puts $fo [join [table_format_with_title $violationList 0 left "" 0] \n]
  puts $fo "pass list:( < $thresholdOfDistance um ) \[total [llength $passList]\]"
  puts $fo [join [table_format_with_title $passList 0 left "" 0] \n]
  close $fo
  puts "dump output file to : $outputfilename"
}

define_proc_arguments check_if_levelshifter_cell_have_longnet_with_port \
  -info "whatFunction"\
  -define_args {
    {-levelshifterCelltypeExp "specify the level shifter cell type exp" AString string optional}
    {-thresholdOfDistance "specify the threshold of manhattan distance" AFloat float optional}
  }
