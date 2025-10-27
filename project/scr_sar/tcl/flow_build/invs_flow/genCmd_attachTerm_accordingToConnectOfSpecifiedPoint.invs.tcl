#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/26 14:57:59 Sunday
# label     : eco_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : According to the position of the specified point, then obtain the pin shape of the inst, then obtain the connection 
#             relationship of the pin, and then connect the same connection relationship to the pin of the specified inst
# situation : First, I placed the io cell, and then placed the pad cell on top of it. However, the signal pin of the pad cell needs 
#             to have the same connection as the M8 layer of the io cell. Therefore, I need to perform an attachTerm connection on 
#             the signal pin of the pad cell based on the connection of the io cell. The main way is to obtain their connection 
#             relationship according to their positions, and then perform attachTerm on the corresponding signal pin of the pad cell.
# return    : cmds list
# ref       : link url
# --------------------------
source ../../packages/every_any.package.tcl; # every
proc genCmd_attachTerm_accordingToConnectOfSpecifiedPoint {args} {
  set typeOfSearch                "rect" ; # rect|point
  set rect                        {} ; # {1 2 3 4}
  set point                       {} ; # {1 2}
  set layerOfPinOfRefInst         8
  set typeOfPin                   "all" ; # pgInstTerms|instTerms|all
  set acceptCellTypeOfRefInstList {} ; # you can limit cell type of ref inst, it will not limit if it is empty
  set acceptRefInstNameList       {{.*_bondpad}} ; # you can alse limit ref inst name, it will not limit if it is empty
  set priorityOfTypeOfPin         "pgInstTerms" ; # pgInstTerms|instTerms
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {[llength $point] != 2 || ![every x $point {string is double $x}]} {
    error "proc genCmd_attachTerm_accordingToConnectOfSpecifiedPoint: check your input: point($point) is not 2 item or is not double number!!!"
  }
  if {$typeOfSearch eq "point"} {
    lassign $point temp_left temp_bottom
    set mfg [dbget head.mfgGrid]
    set rect [list [expr $temp_left - $mfg] [expr $temp_bottom - $mfg] [expr $temp_left + $mfg] [expr $temp_bottom + $mfg]]
  } elseif {$typeOfSearch eq "rect"} {
    if {[llength $rect] != 4 || ![every x $rect {string is double $x}]} {
      error "proc genCmd_attachTerm_accordingToConnectOfSpecifiedPoint: check your input: rect($rect) is not 4 item or is not double number!!!"
    } else {
      set temp_terms [list]

      set temp_inst [dbQuery -areas $rect -objType inst -layer $layerOfPinOfRefInst]

      set temp_instTerms [dbget $temp_inst.]  ; # TODO
      set temp_pgInstTerms [dbQuery -areas $rect -objType pgInstTerm -layer $layerOfPinOfRefInst]
      
      if {$typeOfSearch eq "all" || $typeOfSearch eq "instTerms"} { 
        if {$temp_instTerms ne "" && [llength $temp_instTerms] == 1} {
          lappend temp_terms [list instTerms $temp_instTerms]
        } else {
          if {[llength $temp_instTerms] > 1} {
            error "proc genCmd_attachTerm_accordingToConnectOfSpecifiedPoint: check your db, rect($rect) have more instTerms([dbget $temp_instTerms.name]), that is forbidden!!!"
          }
        }
      }
      if {$typeOfSearch eq "all" || $typeOfSearch eq "pgInstTerms"} {
        if {$temp_pgInstTerms ne "" && [llength $temp_pgInstTerms] == 1} {
          lappend temp_terms [list pgInstTerms $temp_pgInstTerms]
        } else {
          if {[llength $temp_pgInstTerms] > 1} {
            error "proc genCmd_attachTerm_accordingToConnectOfSpecifiedPoint: check your db, rect($rect) have more pgInstTerms([dbget $temp_pgInstTerms.name]), that is forbidden!!!"
          }
        }
      }
      if {}
    }
  }
}

define_proc_arguments genCmd_attachTerm_accordingToConnectOfSpecifiedPoint \
  -info "gen cmd for attachTerm according to connection of specified point"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
