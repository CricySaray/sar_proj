#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/24 09:30:45 Friday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Add new io instances based on the positions of existing io instances, while supporting the specification of different 
#             orients for different directions. Since the positions of io instances cannot be manually dragged or changed, their 
#             specific positions need to be specified at the very beginning.
#             orient is the same as the referenced inst, and pstatusOfNewInst is also the same
# return    : cmds list
# ref       : link url
# --------------------------
proc genCmd_addIoInstance_accordingToExistedIoInstanceLocation {args} {
  set instsToRef                    [list] ; # If there are several referenced insts, then several new io instances will be assumed.
  set celltypeToAdd                 ""
  set pstatusOfNewInst              "fixed"
  set ifUsePhysicalOption           false ; # It is not recommended to use the -physical option to addInst.
  set matchListOfOrientAndDirection {{MX top} {MY90 right} {MY bottom}} ; # Determine the direction of the io instance you need to obtain for reference based on this orient, which can help determine how to move and offset.
  set prefixOfNewIoInstance         "_bondpad"
  set typeToChangeOfDirection       "outer" ; # inner|outer|left|right|top|bottom
  set offsetOfLocation              2
  set offsetOfInnerOrOuterDirection {-5 18.175} ; # {direction_perpendicular_to_the_inner_or_outer_direction outer_or_inner_dirction } left -> - number, right -> + number, inner/outer: same dirction: + number, different dirction: - number
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set inner_directionMatchList {{top bottom} {bottom top} {left right} {right left}}
  set outer_directionMatchList {{top top} {bottom bottom} {left left} {right right}} ; # redundancy
  if {[every x $matchListOfOrientAndDirection {expr {[lindex $x 1] in {left right top bottom}}}] && [llength [lsort -unique -index 1 $matchListOfOrientAndDirection]] <= 4} {
    if {![llength $instsToRef]} {
      error "proc genCmd_addIoInstance_accordingToExistedIoInstanceLocation: check your input: \$instsToRef is empty!!!" 
    } else {
      if {$prefixOfNewIoInstance eq ""} {
        error "proc genCmd_addIoInstance_accordingToExistedIoInstanceLocation: check your input: prefixOfNewIoInstance can't be empty!!!"
      } else {
        if {[expr {(![llength $matchListOfOrientAndDirection] || ![string is double $offsetOfLocation]) && $typeToChangeOfDirection in {inner outer}}]} {
          error "proc genCmd_addIoInstance_accordingToExistedIoInstanceLocation: check your input: if you select type: inner|outer, you must input \$matchListOfOrientAndDirection!!!"
        } elseif {![string is double $offsetOfLocation] && $typeToChangeOfDirection in {left right top bottom}} {
          error "proc genCmd_addIoInstance_accordingToExistedIoInstanceLocation: check your input: if you select type: left|right|top|bottom!!!"
        } else {
          set instAndLocationAndOrientAndDirectionList [lmap temp_inst $instsToRef {
            set temp_inst_ptr [dbget top.insts.name $temp_inst -e -p]
            if {$temp_inst_ptr eq ""} {
              error "proc genCmd_addIoInstance_accordingToExistedIoInstanceLocation: check your input: inst($temp_inst) is not found!!!" 
            } else {
              set temp_location {*}[dbget $temp_inst_ptr.pt -e]
              if {$temp_location eq ""} {
                error "proc genCmd_addIoInstance_accordingToExistedIoInstanceLocation: check your input: location of inst($temp_inst) is empty!!!" 
              }
              set temp_orient [dbget $temp_inst_ptr.orient -e]
              if {$temp_orient eq ""} {
                error "proc genCmd_addIoInstance_accordingToExistedIoInstanceLocation: check your input: orient of inst($temp_inst) is empty!!!" 
              }
            }
            set temp_orientDirection [lsearch -inline -index 0 $matchListOfOrientAndDirection $temp_orient]
            if {$typeToChangeOfDirection eq "inner"} {
              if {$temp_orientDirection eq ""} {
                error "proc genCmd_addIoInstance_accordingToExistedIoInstanceLocation: check your input : orient($temp_orient) of inst($temp_inst) is not found in \$matchListOfOrientAndDirection($matchListOfOrientAndDirection) !!!" 
              } else {
                set temp_direction [lindex [lsearch -inline -index 0 $inner_directionMatchList [lindex $temp_orientDirection 1]] 1]
              }
            } elseif {$typeToChangeOfDirection eq "outer"} {
              set temp_direction [lindex $temp_orientDirection 1]
            } elseif {$typeToChangeOfDirection in {left right top bottom}} {
              set temp_direction $typeToChangeOfDirection
            } else {
              error "proc genCmd_addIoInstance_accordingToExistedIoInstanceLocation: check your input : \$typeToChangeOfDirection is only one of inner|outer|left|right|top|bottom!!!" 
            }
            list $temp_inst $temp_location $temp_orient $temp_direction
          }]
          set cmdsList [lmap temp_List $instAndLocationAndOrientAndDirectionList {
            lassign $temp_List temp_inst temp_location temp_orient temp_direction
            if {$temp_direction eq "left"} {
              # Since the obtained location is the coordinates of the lower-left corner, there is no need to move in the left direction.
              # lset temp_location 0 [expr [lindex $temp_location 0] - [lindex $offsetOfInnerOrOuterDirection 0]] 
              lset temp_location 1 [expr [lindex $temp_location 1] + [lindex $offsetOfInnerOrOuterDirection 0]]
            } elseif {$temp_direction eq "right"} {
              lset temp_location 0 [expr [lindex $temp_location 0] + [lindex $offsetOfInnerOrOuterDirection 1]]
              lset temp_location 1 [expr [lindex $temp_location 1] + [lindex $offsetOfInnerOrOuterDirection 0]]
            } elseif {$temp_direction eq "top"} {
              lset temp_location 0 [expr [lindex $temp_location 0] + [lindex $offsetOfInnerOrOuterDirection 0]]
              lset temp_location 1 [expr [lindex $temp_location 1] + [lindex $offsetOfInnerOrOuterDirection 1]]
            } elseif {$temp_direction eq "bottom"} {
              lset temp_location 0 [expr [lindex $temp_location 0] + [lindex $offsetOfInnerOrOuterDirection 0]]
            } else {
              error "proc genCmd_addIoInstance_accordingToExistedIoInstanceLocation: direction($temp_direction) of inst($temp_inst) is not valid!!!" 
            }
            if {$celltypeToAdd eq ""} {
              error "proc genCmd_addIoInstance_accordingToExistedIoInstanceLocation: check your input: \$celltypeToAdd is invalid!!!" 
            }
            if {$pstatusOfNewInst eq ""} {
              error "proc genCmd_addIoInstance_accordingToExistedIoInstanceLocation: check your input: \$pstatusOfNewInst is invalid!!!" 
            }
            set temp "addInst -cell $celltypeToAdd -ori $temp_orient -inst ${temp_inst}$prefixOfNewIoInstance -place_status $pstatusOfNewInst -loc \{$temp_location\}"
            if {$ifUsePhysicalOption} {
              set temp [string cat $temp " -physical"] 
            }
            set temp
          }]
          return $cmdsList
        }
      }
    }
     
  } else {
    error "proc genCmd_addIoInstance_accordingToExistedIoInstanceLocation: check your input: \$matchListOfOrientAndDirection($matchListOfOrientAndDirection) is invalid!!!" 
  }
}

define_proc_arguments genCmd_addIoInstance_accordingToExistedIoInstanceLocation \
  -info "gen cmd for addding io instance according to existed io instance location"\
  -define_args {
    {-instsToRef "specify the insts to reference" AList list optional}
    {-celltypeToAdd "specify cell type to add" AString string optional}
    {-pstatusOfNewInst "specify the place status of new insts" oneOfString one_of_string {optional value_type {values {fixed placed}}}}
    {-ifUsePhysicalOption "if use option: -physical of cmd: addInst" oneOfString one_of_string {optional value_type {values {0 1}}}}
    {-matchListOfOrientAndDirection "specify the matched list of ref inst orient and direction of new inst to place" AList list optional}
    {-prefixOfNewIoInstance "specify the prefix of new io instance" AString string optional}
    {-typeToChangeOfDirection "specify the type of changing location" oneOfString one_of_string {optional value_type {values {inner outer left right top bottom}}}}
    {-offsetOfLocation "specify the offset value of location to change" AFloat float optional}
    {-offsetOfInnerOrOuterDirection "specify the offset of inner or outer dirction" AList list optional}
  }
