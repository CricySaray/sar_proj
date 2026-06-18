#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/06/16 13:47:11 Tuesday
# label     : task_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Select the 2nd pg wires of insts related to open or short. After verification, run editDelete -selected to delete them. 
#             This avoids selecting all 2nd pg wires.
# return    : select regular wire of 2nd pg
# ref       : link url
# --------------------------
proc select_regularWireOf2ndpg_forOpenOrShortInst {args} {
  set violInstList            [list]
  set netsOf2ndPgList         [list DVDD_CORE DVDD_SRAM_CORE DVDD_VLP_VB]
  set iterateNumOfSearch2ndpg 2
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set pureInstList [lmap temp_violInst $violInstList {
    if {[dbget top.insts.name $temp_violInst -e] ne ""} {
      set temp_violInst
    } else {
      continue
    }
  }]
  set instsBoxes [list]
  foreach temp_inst $pureInstList {
    set instsBoxes [dbShape $instsBoxes OR [lindex [dbget [dbget top.insts.name $temp_inst -p].box -e] 0]]
  }
  deselectAll
  for {set i 0} {$i < $iterateNumOfSearch2ndpg} {incr i} {
    set instsAndSelectWiresBoxes [dbShape [dbget selected.box -e] OR $instsBoxes]
    foreach temp_net $netsOf2ndPgList {
      set wires_ptr [dbget [dbQuery -areas $instsAndSelectWiresBoxes -objType {viaInst wire} -bbox_overlap].net.name $temp_net -e -p2]
      if {$wires_ptr eq ""} {
        continue
      } else {
        select_obj $wires_ptr
      }
    }
  }
  puts "have select all 2nd pg related to provided insts. IterationNum: $iterateNumOfSearch2ndpg"
}

define_proc_arguments select_regularWireOf2ndpg_forOpenOrShortInst \
  -info "select regular wire of 2nd pg for open or short inst"\
  -define_args {
    {-violInstList "specify the viol inst list" AString string optional}
    {-netsOf2ndPgList "specify the nets list of 2nd pg" AList list optional}
    {-iterateNumOfSearch2ndpg "specify the iteration num when searching 2nd pg net related to viol insts" AInt int optional}
  }
