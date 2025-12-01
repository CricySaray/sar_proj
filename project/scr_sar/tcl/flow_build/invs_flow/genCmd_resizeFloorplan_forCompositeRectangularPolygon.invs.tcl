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
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  
}
define_proc_arguments genCmd_resizeFloorplan_forCompositeRectangularPolygon \
  -info "gen cmd for resizing floorplan for composite rectangular polygon"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
