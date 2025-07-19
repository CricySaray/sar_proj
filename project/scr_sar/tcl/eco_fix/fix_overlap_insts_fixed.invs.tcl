#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Wed Jul  2 20:38:55 CST 2025
# label     : task_proc
#   -> (atomic_proc|display_proc|task_proc)
# descrip   : fix overlap insts with fixed pstatus: set placed -> refinePlace -> set fixed
#             can exclude endcap/welltap and block cell
# update    : 2025/07/15 09:15:53 Tuesday
#             add switch var $preCheckPlace to checkPlace(will clear Markers), you can use it when eco flow or every stage of flow
# update    : 2025/07/19 23:32:30 Saturday
#             (U001)refinePlace -wire_length_reclaim true: exist on version 23.10 or above version
#             setPlaceMode -place_detail_remove_affected_routing true
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
    setPlaceMode -place_detail_legalization_inst_gap 1
    setPlaceMode -place_detail_remove_affected_routing true; # U001
    set cmd_precheck "checkPlace -ignoreOutOfCore"
    puts "$promptINFO $cmd_precheck"
    eval $cmd_precheck
  }
  foreach marker $overlap_marker_name {
    set violobjs [concat $violobjs [dbget top.markers.subType $marker -p -e]]
  }
  if {![llength $violobjs]} {
    return 0
  } else {
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
    set insts_num [llength $insts_ptr]
    set insts_name [dbget $insts_ptr.name -e -u]
    set formated_instsname [lmap instname $insts_name {set temp "\t$instname"}]
    puts "$promptINFO fix_overlap: have $insts_num overlaped insts:"
    puts [join $formated_instsname \n]
    # $testOrRun have low priority, $ifRunRefinePlace and $ifRunEcoRoute have higher priority!!
    if {$testOrRun == "run"} {
      if {$insts_ptr != ""} {
        puts "$promptINFO set insts placed (unfixed)"
        dbSet $insts_ptr.pstatus placed
        setPlaceMode -place_detail_eco_max_distance 10
        if {$ifRunRefinePlace} {
          puts "$promptINFO begin refinePlace for overlap insts..."
          if {$only_refinePlace_violInsts == "true"} {
            if { [string compare -length 5 [getVersion] "23.10"] > -1} { ; # U001
              refinePlace -inst [dbget $insts_ptr.name] -wire_length_reclaim true
            } else {
              refinePlace -inst [dbget $insts_ptr.name]
            }
          } else { 
            if { [string compare -length 5 [getVersion] "23.10"] > -1} {
              refinePlace -eco true -wire_length_reclaim true
            } else {
              refinePlace -eco true 
            }
          }
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
}
