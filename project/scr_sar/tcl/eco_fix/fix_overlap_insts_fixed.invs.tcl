#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# update    : 2025/07/15 09:15:53 Tuesday
#             add switch var $preCheckPlace to checkPlace(will clear Markers), you can use it when eco flow or every stage of flow
# label     : task_proc
#   -> (atomic_proc|display_proc|task_proc)
# descrip   : fix overlap insts with fixed pstatus: set placed -> refinePlace -> set fixed
#             can exclude endcap/welltap and block cell
# ref       : link url
# --------------------------
proc fix_overlap_insts_fixed {{testOrRun "test"} {preCheckPlace 1} {ifRunRefinePlace 1} {ifRunEcoRoute 1} {only_refinePlace_violInsts "false"} {overlap_marker_name {SPOverlapViolation SPFillerGapViolation}}} {
  set default_dontTouchExp "ENDCAP|WELLTAP"; #regexp can match {/ENDCAP|/WELLTAP}
  set default_dontTouchBlock [dbget [dbget top.insts.cell.subClass block -p2].name]
  set default_dontTouchISOcell [dbget [dbget top.insts.cell.name ISO* -p2].name]
  set default_removeList [concat $default_dontTouchExp $default_dontTouchBlock $default_dontTouchISOcell]
  set default_removeExp "[join $default_removeList |]"
  set promptINFO "songINFO:"
  #checkPlace
  set violobjs [list ]
  if {$preCheckPlace} { 
    set cmd_precheck "checkPlace -clearMarker -ignoreOutOfCore"
    puts "$promptINFO $cmd_precheck"
    eval $cmd_precheck
  }
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
  # $testOrRun have low priority, $ifRunRefinePlace and $ifRunEcoRoute have higher priority!!
  if {$testOrRun == "run"} {
    if {$insts_ptr != ""} {
      puts "$promptINFO set insts placed (unfixed)"
      dbSet $insts_ptr.pstatus placed
      setPlaceMode -place_detail_eco_max_distance 10
      if {$ifRunRefinePlace} {
        puts "$promptINFO begin refinePlace for overlap insts..."
        if {$only_refinePlace_violInsts == "true"} {refinePlace -inst [dbget $insts_ptr.name]
        } else { refinePlace -eco true }
      }
      if {$ifRunEcoRoute} {
        puts "$promptINFO begin ecoRoute for overlap insts..."
        ecoRoute
      }
      puts "$promptINFO reset insts fixed"
      dbSet $insts_ptr.pstatus fixed
    } else { puts "$promptINFO no Overlap insts!!!"}
  } elseif {$testOrRun == "test"} {
    puts "$promptINFO testing ... " 
  }
}
