#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/11 10:27:43 Friday
# label     : check_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, 
#                    providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, 
#                    focusing on data display and aesthetics
#   -> gui_proc   : for gui display, or effort can be viewed in invs GUI
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, 
#                   process control, error recovery, and the output of files and reports when solving problems.
#   -> dump_proc  : dump data with specific format from db(invs/pt/starrc/pv...)
#   -> check_proc : only for checking for some stage(FP/place/cts/route/finish...)
#   -> misc_proc  : some other uses of procs
# descrip   : check routing blkg in every stage(init/cts/preroute), for routing !!!
#             if have routing blkg that is for powerplan that is not only surrounding with mem/ip...
#             it will spend a lot of time when routing!!!
# ref       : link url
# --------------------------
proc check_routingBlkg_forFP {{exclude_blocks {U_ANARF_TOP U_PMU_TOP}} {off {11 11 11 11}} {ifSelectRouteBlkg 1} {debug 1} {promptWARN "songWARN"}} {
  # $debug : print debug info
  # $off   : It is recommended to set a larger value for the variable "off" to avoid misjudgments 
  #           caused by routing blockages that are inherently larger than mem/IP regions.
  # $exclude_blocks : Although the variable `exclude_blocks` is named "exclude", it actually means "not excluding". 
  #                   That is, when checking regions, the areas covered by these `exclude_blocks` will be included in the check. 
  #                   In contrast, the `blocks` within the procedure refer to the inspection regions that need to be excluded!
  set blocks_ptr [dbget top.insts.cell.subClass block -p2]
  set name_box_blocks [lmap ptr $blocks_ptr {
    set name [dbget $ptr.name]
    set box [dbget $ptr.boxes] 
    set name_box [list $name [lindex $box 0]]
  }]
if {$debug} {puts $name_box_blocks}
  set filtered_name_box_blocks $name_box_blocks
  if {[llength $exclude_blocks]} {
    foreach exclude_block $exclude_blocks {
      set filtered_name_box_blocks [lsearch -not -all -inline -index 0 $filtered_name_box_blocks $exclude_block] 
    }
if {$debug} {puts [join $filtered_name_box_blocks \n]}
  }
  set off_top [lindex $off 0]
  set off_bottom [lindex $off 1]
  set off_left [lindex $off 2]
  set off_right [lindex $off 3]
  set offed_filtered_name_box_blocks [lmap name_box $filtered_name_box_blocks {
    set offedInBox [lmap inBox [lindex $name_box 1] {
      set offed_box_lb [lrange [lindex [dbShape $inBox SIZEX $off_left  SIZEY $off_bottom] 0] 0 1]
      set offed_box_ur [lrange [lindex [dbShape $inBox SIZEX $off_right SIZEY $off_top   ] 0] 2 3]
      set offed_box [concat $offed_box_lb $offed_box_ur]
    }]
    set offed_filtered_name_box [list [lindex $name_box 0] $offedInBox]
  }]

  set filtered_boxes [lmap name_box $offed_filtered_name_box_blocks {
    set box [lindex $name_box 1] 
  }]
  set dieRect [dbget top.fplan.boxes]
  set rectOutOfBlocks $dieRect
  foreach box $filtered_boxes {
      set rectOutOfBlocks [dbShape $rectOutOfBlocks ANDNOT $box -output rect]
  }
  set routeBlkgs_enclosedOnly [dbQuery -areas $rectOutOfBlocks -objType rBlkg -enclosed_only]
  set routeBlkgs_overlapOnly  [dbQuery -areas $rectOutOfBlocks -objType rBlkg -overlap_only]

  set routeBlkgs [concat $routeBlkgs_enclosedOnly $routeBlkgs_overlapOnly]
  puts "$promptWARN : There are [llength $routeBlkgs] routing blockage(s) that are not within the mem or ip regions!!! "
  puts "$promptWARN : Attention should be paid to whether they affect the routing stage!!!"
  set i 0
  set mod [expr [expr int(log10([llength $routeBlkgs]))] + 1]
  foreach rBlkg $routeBlkgs {
    incr i
    set rect [dbget $rBlkg.boxes]
    printf "%-${mod}s : $rect\n" "$i"
  }
  if {$ifSelectRouteBlkg} { select_obj $routeBlkgs }
}
