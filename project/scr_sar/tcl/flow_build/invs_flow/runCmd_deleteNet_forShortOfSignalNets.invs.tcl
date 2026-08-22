# TO_WRITE
#
proc runCmd_deleteNet_forShortOfSignalNets {args} {
  set ignoreNetNames [list]
  set ignoreNetRegExp ""
  set shortMarkerNames [list]
  set typeOfObjectToDelete "wires" ; # wires|nets
  set layers {M1 M2 M3 M4 M5 M6} ; # will not specify this option when \$layers is empty
  set methodsOfSelecting "abut" ; # abut|enclose|overlap|bbox
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  deselectAll
  set query_option ""
  if {$methodsOfSelecting eq "abut"} {
    set query_option "-abut_only"
  } elseif {$methodsOfSelecting eq "enclose"} {
    set query_option "-enclosed_only" 
  } elseif {$methodsOfSelecting eq "overlap"} {
    set query_option "-overlap_only" 
  } elseif {
    set query_option "-bbox_overlap" 
  }
  foreach temp_short_marker $shortMarkerNames {
    if {$layers ne ""} {
      if {$query_option eq ""} {
        select_obj [dbQuery -areas [dbShape [dbget [dbget top.markers.subType $temp_short_marker -p].box]] -layers $layers -objType {wire viaInst}]
      } else {
        select_obj [dbQuery -areas [dbShape [dbget [dbget top.markers.subType $temp_short_marker -p].box]] -layers $layers -objType {wire viaInst} $query_option]
      }
    } else {
      if {$query_option eq ""} {
        select_obj [dbQuery -areas [dbShape [dbget [dbget top.markers.subType $temp_short_marker -p].box]] -objType {wire viaInst}]
      } else {
        select_obj [dbQuery -areas [dbShape [dbget [dbget top.markers.subType $temp_short_marker -p].box]] -objType {wire viaInst} $query_optiou]
      }
    }
  }
  set selectedNets [dbget [dbget selected.objType wire -p].net.name -e]
  if {$selectedNets eq ""} {
    error "proc runCmd_deleteNet_forShortOfSignalNets: not found selected nets." 
  }
  
  
}

define_proc_arguments runCmd_deleteNet_forShortOfSignalNets \
  -info "run cmd to delete nets for short of signal nets"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
