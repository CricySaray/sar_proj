#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/01/04 14:06:04 Sunday
# label     : eco_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : To unify the vt and channel types on the clock tree, a specific vt type can be designated. This proc can automatically 
#             generate executable commands to directly replace the instances that need their cell types changed with a unified type.
# return    : cmds list
# ref       : link url
# --------------------------
alias sus "subst -nocommands -nobackslashes"
proc genCmd_changeClockTreeVt {args} {
  set typeOfCell           "logic"; # logic|buffer|inverter|clock_gate|source|generator|all
  set commonCelltypeExp    {.*D\d+BWP\d+(T\d+)?P\d+}
  set allVtCelltypeExp     {{SVT ""} {LVT LVT} {ULVT ULVT}}
  set typeOfTargetCelltype "LVT" ; # using index method of lindex
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set cmdsList [list]
  lappend cmdsList "setEcoMode -reset"
  lappend cmdsList "setEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false"
  lappend cmdsList ""
  set clock_tree_cells_list {}
  foreach cktree [get_ccopt_clock_trees *] {
    foreach inst [get_ccopt_clock_tree_cells * -node_types $typeOfCell -in_clock_trees $cktree] {
      if {[dbGet [dbGet -p top.insts.name $inst].cell.baseClass] eq "core"} {
        if {[lsearch $clock_tree_cells_list $inst] == -1} {lappend clock_tree_cells_list $inst}
      }
    }
  }
  foreach inst $clock_tree_cells_list {
    set old_celltype [dbInstCellName $inst]
    set inst_name [dbInstName $inst]
    set target_celltype_exp_list [lsearch -index 0 -inline $allVtCelltypeExp $typeOfTargetCelltype]
    if {[llength $target_celltype_exp_list] == 2} {
      set temp_target_celltype_exp [lindex $target_celltype_exp_list 1]
      set otherVtCelltypeExp [lsearch -not -index 0 -all -inline $allVtCelltypeExp $typeOfTargetCelltype]
      foreach temp_vt_celltype_exp $otherVtCelltypeExp {
        set temp_other_celltype_exp [lindex $temp_vt_celltype_exp 1]
        set new_celltype [regsub [sus {^($commonCelltypeExp)$temp_other_celltype_exp$}] $old_celltype [sus {\1$temp_target_celltype_exp}]]
        if {$new_celltype ne ""} {
          if {$new_celltype ne $old_celltype} {
            lappend cmdsList "# $old_celltype - > $new_celltype : $inst_name"
            lappend cmdsList "ecoChangeCell -inst $inst_name -cell $new_celltype"
          } 
        }
      }
    }
  }  
  lappend cmdsList ""
  lappend cmdsList "setEcoMode -reset"

  return $cmdsList
}
define_proc_arguments genCmd_changeClockTreeVt \
  -info "whatFunction"\
  -define_args {
    {-typeOfCell "specify the type of cell of clock tree" oneOfString one_of_string {optional value_type {values {logic buffer inverter clock_gate source generator all}}}}
    {-commonCelltypeExp "specify common celltype expression for allVtCelltypeExp" AString string optional}
    {-allVtCelltypeExp "specify all vt celltype expression for selection of typeOfTargetCelltype" AString string optional}
    {-typeOfTargetCelltype "specify the index of target vt celltype of allVtCelltypeExp" AString string optional}
  }
