#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/12/01 17:24:34 Monday
# label     : gui_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# analysis  : Use the floorplan command to outline the bounding box, which is the largest rectangular border. Then use the setObjFPlanBoxList 
#             command to detail the specific shape of the polygonal rectangle. Note that when using the setObjFPlanBoxList command, its maximum 
#             rectangle must be the same size as the rectangle specified by floorplan; otherwise, it cannot be executed successfully.
# descrip   : what?
# return    : 
# ref       : link url
# --------------------------

proc genCmd_resizeFloorplan_forCompositeRectangularPolygon {args} {
  set typeOfInput "dieBoxes" ; # dieBoxes|coreBoxes
  set designName  [dbget top.name]
  set boxes       {{}} ; # boxes of die or core
  set coreToEdge  {1.4 1.4 1.4 1.4} ; # {left bottom right top}
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set cmdsList [list]
  if {$typeOfInput in "dieBoxes coreBoxes"} {
    if {$typeOfInput eq "dieBoxes"} {
      set bboxOfDieBoxes {*}[dbShape -output hrect $boxes BBOX]
      lappend cmdsList "floorPlan -b \{$bboxOfDieBoxes $bboxOfDieBoxes $bboxOfDieBoxes\}"
      lappend cmdsList "setObjFPlanBoxList Cell $designName \{$boxes\}"
      lappend cmdsList "changeFloorplan -coreToEdge \{$coreToEdge\}"
    } elseif {$typeOfInput eq "coreBoxes"} {
      set boxes_offseted [lmap temp_box $boxes {
        lassign $temp_box temp_ll_x temp_ll_y temp_ur_x temp_ur_y 
      }]
      set bboxOfDieBoxes {*}[dbShape -output hrect $boxes BBOX]
      lappend cmdsList "floorPlan -b \{$bboxOfDieBoxes $bboxOfDieBoxes $bboxOfDieBoxes\}"
      lappend cmdsList "setObjFPlanBoxList Cell $designName \{$boxes\}"
      lappend cmdsList "changeFloorplan -coreToEdge \{$coreToEdge\}"
     
    }
   
  } else {
    error "proc genCmd_resizeFloorplan_forCompositeRectangularPolygon: typeOfInput only be dieBoxes or coreBoxes" 
  }
  
}
define_proc_arguments genCmd_resizeFloorplan_forCompositeRectangularPolygon \
  -info "gen cmd for resizing floorplan for composite rectangular polygon"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
