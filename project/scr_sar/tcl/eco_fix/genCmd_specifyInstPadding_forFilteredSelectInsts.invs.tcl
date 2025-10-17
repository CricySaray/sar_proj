#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/17 20:09:45 Friday
# label     : eco_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Add inst padding to the specified inst, reduce the local density, and prevent the refinePlace from failing to solve all overlap problems.
# return    : cmds List
# side_effect : Create a variable at the same level as proc to store the inst list with added padding.
# ref       : link url
# --------------------------
source ../packages/every_any.package.tcl; # every
proc genCmd_specifyInstPadding_forFilteredSelectedInsts {args} {
  set removeCellTypeRegExps   [list {^TAP}] ; # regexp, support more than one expression
  set removeInstByNameRegExps [list {^WELLTAP}] ; # same as above
  set paddingOfTBLR           {0 0 2 2}
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set allSelectedInst_ptrs [dbget selected.objType inst -p -e]
  if {$allSelectedInst_ptrs == ""} {
    error "proc genCmd_specifyInstPadding_forFilteredSelectedInsts: check your gui, have no selected insts!!!" 
  } else {
    foreach temp_celltype $removeCellTypeRegExps {
      set allSelectedInst_ptrs [dbget -regexp -v $allSelectedInst_ptrs.cell.name $temp_celltype -p2] 
    }
    foreach temp_inst_regexp $removeInstByNameRegExps {
      set allSelectedInst_ptrs [dbget -regexp -v $allSelectedInst_ptrs.name $temp_inst_regexp -p] 
    }
    set cmdsList [list]
    if {![every x $paddingOfTBLR { string is integer $x }]} {
      error "proc genCmd_specifyInstPadding_forFilteredSelectedInsts: check your input: paddingOfTBLR($paddingOfTBLR) is not meet requirements, which all must be integer number!!!" 
    }
    lassign $paddingOfTBLR top bottom left right
    uplevel 1 [list set paddingInsts_ptr $allSelectedInst_ptrs]
    uplevel 1 [list set paddingInsts [dbget $allSelectedInst_ptrs.name -e]]
    foreach temp_selectedinst_ptr $allSelectedInst_ptrs {
      set temp_selectedinst_name [dbget $temp_selectedinst_ptr.name]
      lappend cmdsList "specifyInstPad $temp_selectedinst_name -top $top -bottom $bottom -left $left -right $right"
    }
    return $cmdsList
  }
}

define_proc_arguments genCmd_specifyInstPadding_forFilteredSelectedInsts \
  -info "gen cmd of specifying inst padding for filtered selected insts"\
  -define_args {
    {-removeCellTypeRegExps "specify the list of regexp for removing selected inst by cell type" AList list optional}
    {-removeInstByNameRegExps "specify the list of regexp for removing selected inst by inst name" AList list optional}
    {-paddingOfTBLR "specify the distance of movement of inst when type is 'move'" AList list optional}
  }
