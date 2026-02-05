#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/02/05 16:01:12 Thursday
# label     : drc_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------
proc selectObj_fixdrc_editDeleteNet_forExample_G4_M2i {args} {
  set searchBoxType {normal} ; # normal|overlap|enclosed|abut|bboxoverlap , can multi-selected
  set objectTypeToDelete {Wire pWire viaInst}
  set layersToDelete {M1 M2 M3}
  set markersTypeToSearch {G.4:M2i}
  set ifEditDeleteAfterSelecting 0
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set allSearchBox [list]
  foreach temp_drctype $markersTypeToSearch {
    set temp_box [dbget [dbget top.markers.userType $temp_drctype -p].box -e]
    if {$temp_box ne ""} {
      lappend allSearchBox {*}$temp_box
    }
  }
  deselectAll
  set searchMethodOptions ""
  if {$searchBoxType eq "normal"} {
    set searchMethodOptions ""
  } elseif {$searchBoxType eq "overlap"} {
    set searchMethodOptions "-overlap_only" 
  } elseif {$searchBoxType eq "enclosed"} {
    set searchMethodOptions "-enclosed_only" 
  } elseif {$searchBoxType eq "abut"} {
    set searchMethodOptions "-abut_only" 
  } elseif {$searchBoxType eq "bboxoverlap"} {
    set searchMethodOptions "-bbox_overlap" 
  } else {
    error "proc selectObj_fixdrc_editDeleteNet_forExample_G4_M2i: invalid searchBoxType($searchBoxType)!!!" 
  }
  if {$searchMethodOptions eq ""} {
    foreach temp_box $allSearchBox {
      select_obj [dbQuery -area $temp_box -objType $objectTypeToDelete -layers $layersToDelete $searchMethodOptions]
    }
  } else {
    foreach temp_box $allSearchBox {
      select_obj [dbQuery -area $temp_box -objType $objectTypeToDelete -layers $layersToDelete ]
    }
  }
  
  if {$ifEditDeleteAfterSelecting} {
    editDelete -selected -type Regular
  }
  
}
define_proc_arguments selectObj_fixdrc_editDeleteNet_forExample_G4_M2i \
  -info "whatFunction"\
  -define_args {
    {-searchBoxType "specify the type of searching box" oneOfString one_of_string {optional value_type {values {normal overlap enclosed abut bboxoverlap}}}}
    {-objectTypeToDelete "specify the type of object to delete" oneOfString one_of_string {optional value_type {values {Wire pWire viaInst}}}}
    {-layersToDelete "specify layers to delete" AList list optional}
    {-markersTypeToSearch "specify the marker type to search box" AList list optional}
    {-ifEditDeleteAfterSelecting "if delete wire or vias after selecting object" "" boolean optional}
  }
