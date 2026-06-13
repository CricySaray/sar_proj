#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/06/12 18:00:37 Friday
# label     : task_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This procedure first validates input format and data legitimacy, then filters points outside the designated rectangular 
#             placement regions. It calculates the shortest moving direction and distance from each out-of-bound point to the nearest 
#             valid area and returns the result in the specified format.
#             Set the debug parameter to 1 to enable runtime log output for troubleshooting.
# return    : cmds file
# ref       : link url
# --------------------------
source ../../packages/filter_and_calculate_move_distance.package.tcl; # filter_and_calculate_move_distance
proc genFile_moveInstToSpecifyAreaBoundary {args} {
  set instList [list]
  set boxesList {{x y x1 y1} {x y x1 y1}} ; # boxes
  set offsetValue -5
  set outputfilename "moveInstToSpecifyAreaBoundary_[clock format [clock second] -format "%Y%m%d_%H%M%S"].tcl"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set shrinkedBoxes [dbShape $boxesList SIZE $offsetValue]
  set ringOfBoxes [dbShape $boxesList ANDNOT $shrinkedBoxes]
  set inst_pt_List [lmap temp_inst $instList {
    set temp_box_of_inst [lindex [dbget [dbget top.insts.name $temp_inst -p].box] 0]
    set temp_center_of_inst [db_rect -center $temp_box_of_inst]
    list $temp_inst $temp_center_of_inst
  }]
  set resultList [filter_and_calculate_move_distance $ringOfBoxes $inst_pt_List]
  # puts [join $resultList \n]
  set cmdsList [list]
  foreach temp_result $resultList {
    lassign $temp_result temp_inst_name temp_moves
    foreach temp_item_move $temp_moves {
      lassign $temp_item_move temp_direction temp_distance
      lappend cmdsList "move_obj $temp_inst_name -direction $temp_direction -distance $temp_distance"
    }
  }
  set fo [open $outputfilename w] 
  puts $fo [join $cmdsList \n]
  close $fo
  puts "dump output file : $outputfilename"

}

define_proc_arguments genFile_moveInstToSpecifyAreaBoundary \
  -info "whatFunction"\
  -define_args {
    {-instList "specify the inst List" AList list optional}
    {-boxesList "specify boxes list" AList list optional}
    {-offsetValue "specify the offset value to shrink boxes" AFloat float optional}
    {-outputfilename "specify the output file name" AString string optional}
  }
