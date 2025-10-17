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
# ref       : link url
# --------------------------
proc genCmd_specifyInstPadding_forFilteredSelectedInsts {args} {
  set removeCellType         [list TAPCELL]
  set removeInstByNameRegExp [list]
  set paddingOfTBLR          {0 0 2 2}
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set allSelectedInst_ptrs [dbget selected.insts. -e]
  if {$allSelectedInst_ptrs == ""} {
    error "proc genCmd_specifyInstPadding_forFilteredSelectedInsts: check your gui, have no selected insts!!!" 
  } else {
    foreach temp_celltype $removeCellType {
      set allSelectedInst_ptrs [dbget -regexp -v $allSelectedInst_ptrs.cell.name $temp_celltype -p2] 
    }
    foreach temp_inst_regexp $removeInstByNameRegExp {
      set allSelectedInst_ptrs [dbget -regexp -v $allSelectedInst_ptrs.name $temp_inst_regexp -p] 
    }
    set cmdsList [list]
    foreach temp_selectedinst_ptr $allSelectedInst_ptrs {
      set temp_selectedinst_name [dbget $temp_selectedinst_ptr.name]
      
    }
  }
}

define_proc_arguments genCmd_specifyInstPadding_forFilteredSelectedInsts \
  -info "gen cmd of specifying inst padding for filtered selected insts"\
  -define_args {
    {-type "specify the type of eco" oneOfString one_of_string {required value_type {values {change add delRepeater delNet move}}}}
    {-inst "specify inst to eco when type is add/delete" AString string require}
    {-distance "specify the distance of movement of inst when type is 'move'" AFloat float optional}
  }
