#
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : task_proc
#   -> (atomic_proc|display_proc|task_proc)
#   -> atomic_proc : Specially used for calling and information transmission of other procs, providing a variety of error prompt codes for easy debugging
#   -> display_proc : Specifically used for convenient access to information in the innovus command line, focusing on data display and aesthetics
#   -> task_proc  : composed of multiple atomic_proc , focus on logical integrity, process control, error recovery, and the output of files and reports when solving problems.
# descrip   : fix overlap insts with fixed pstatus: set placed -> refinePlace -> set fixed
#             can exclude endcap/welltap and block cell
# ref       : link url
# --------------------------
proc fix_overlap_insts_fixed {{test "test"} {only_refinePlace_violInsts "false"} {overlap_marker_name "SPOverlapViolation"}} {
  set default_dontTouchExp "ENDCAP|WELLTAP"; #regexp can match {/ENDCAP|/WELLTAP}
  set default_dontTouchBlock [dbget [dbget top.insts.cell.subClass block -p2].name]
  set default_removeList [concat $default_dontTouchExp $default_dontTouchBlock]
  set default_removeExp "[join $default_removeList |]"
  set putPrompt "songINFO:"
  #checkPlace
  set violobjs [dbget top.markers.subType $overlap_marker_name -p]
  set violBoxes [dbget $violobjs.box]
  deselectAll
  set insts [dbget [dbQuery -areas $violBoxes -objType {inst} -enclosed_only].name]
  #puts "$insts"
  # remove block insts and endcap/welltap insts
  foreach inst $insts {
    if {[regexp $default_removeExp $inst]} {set insts [lreplace $insts [lsearch -exact $insts "$inst"] [lsearch -exact $insts "$inst"]]}
  }
  #puts "after: $insts"
  select_obj $insts
  set insts_ptr [dbget selected.]
  if {$test == "run"} {
    if {"" != $insts_ptr} {
      dbSet $insts_ptr.pstatus placed
      setPlaceMode -place_detail_eco_max_distance 10
      puts "$putPrompt begin refinePlace for overlap insts..."
      if {$only_refinePlace_violInsts == "true"} {refinePlace -inst [dbget $insts_ptr.name]
      } else { refinePlace -eco true }
      puts "$putPrompt begin ecoRoute for overlap insts..."
      ecoRoute
      dbSet $insts_ptr.pstatus fixed
    } else { puts "$putPrompt no Overlap insts!!!"}
  } elseif {$test == "test"} {
    puts "$putPrompt testing ... " 
  }
}
