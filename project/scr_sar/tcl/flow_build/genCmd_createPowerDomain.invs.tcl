#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/09 19:08:14 Tuesday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : gen cmd of create power domain
# input     : coreRect : {{x y x1 y1} {...} ...}
#             pd_names_boxList_minGaps : {{PDM_AON {{x y x1 y1} {...} ...} {top bottom left right}} ... }
#             lastPowerDomainName      : rect of coreRect removed by front pds rects
#             removeRectOfInst         : 
# return    : cmds
# ref       : link url
# --------------------------
source ../packages/every_any.package.tcl; # any
source ../packages/adjust_rectangle.rect_off.package.tcl; # adjust_boxes
proc genCmd_createPowerDomain {{coreRect {}} {pd_names_boxList_minGaps {}} {lastPowerDomainName "PDM_TOP"} {removeRectOfInst {}} {off_ofRemoveRectOfInst 0}} {
  if {[any x $pd_names_boxList_minGaps {expr {![llength $x]}}]} {
    error "proc genCmd_createPowerDomain: check your input: pd_names_boxList_minGaps($pd_names_boxList_minGaps) have empty item!!!"
  } elseif {![llength $coreRect]} {
    error "proc genCmd_createPowerDomain: check your input: coreRect($coreRect) is empty!!!"
  } else {
    set cmdsList [list]
    if {[llength removeRectOfInst]} {
      foreach temp_inst $removeRectOfInst {
        set boxes {*}[dbget [dbget top.insts.name $temp_inst -p].boxes -e]
        if {$boxes != ""} {
          set coreRect [dbShape $coreRect ANDNOT [adjust_boxes $boxes $off_ofRemoveRectOfInst] -output hrect]
        }
      }
    }
    foreach temp_pdname_boxList_minGaps $pd_names_boxList_minGaps {
      lassign $temp_pdname_boxList_minGaps pdname boxlist mingaps
      lappend cmdsList "# for power domain: $pdname"
      lappend cmdsList "setObjFPlanBoxList Group $pdname \{$boxlist\}"
      lappend cmdsList "modifyPowerDomainAttr $pdname -minGaps \{$mingaps\}"
      set lastPdRect [dbShape $coreRect ANDNOT [adjust_boxes $boxlist $mingaps] -output hrect]
    }
    #lappend cmdsList "# for last power domain: $lastPowerDomainName"
    #lappend cmdsList "setObjFPlanBoxList Group $lastPowerDomainName \{$lastPdRect\}"
    lappend cmdsList "deleteRow -all"
    lappend cmdsList "initCoreRow"
    return $cmdsList
  }
}
