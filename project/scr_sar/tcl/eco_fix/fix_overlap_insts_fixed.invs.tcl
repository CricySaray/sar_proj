#
#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : task_proc
#   -> (atomic_proc|display_proc|task_proc)
# descrip   : fix overlap insts with fixed pstatus: set placed -> refinePlace -> set fixed
#             can exclude endcap/welltap and block cell
# ref       : link url
# --------------------------
proc fix_overlap_insts_fixed {{test "test"} {only_refinePlace_violInsts "false"} {overlap_marker_name {SPOverlapViolation SPFillerGapViolation}}} {
  set default_dontTouchExp "ENDCAP|WELLTAP"; #regexp can match {/ENDCAP|/WELLTAP}
  set default_dontTouchBlock [dbget [dbget top.insts.cell.subClass block -p2].name]
  set default_dontTouchISOcell [dbget [dbget top.insts.cell.name ISO* -p2].name]
  set default_removeList [concat $default_dontTouchExp $default_dontTouchBlock $default_dontTouchISOcell]
  set default_removeExp "[join $default_removeList |]"
  set putPrompt "songINFO:"
  #checkPlace
  set violobjs [list ]
  foreach marker $overlap_marker_name {
    set violobjs [concat $violobjs [dbget top.markers.subType $marker -p -e]]
  }
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
