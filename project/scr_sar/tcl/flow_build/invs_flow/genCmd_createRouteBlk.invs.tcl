#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/09 17:11:02 Tuesday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : gen cmd for createRouteBlk
# return    : cmds
# ref       : link url
# --------------------------
source ../packages/every_any.package.tcl; # every
source ../packages/adjust_rectangle.rect_off.package.tcl; # adjust_rectangle
source ../flow_build/batchRunCmd_forProc_genCmd.common.tcl; # batchRunCmd_forProc_genCmd
proc genCmd_createRouteBlk {{insts {}} {off {}} {layer {1 2 3 4}} {cutLayer {1 2 3 4}} {ifPgNetOnly 1}} {
  set promptPrefix "# song"
  set promptWARN [string cat $promptPrefix "WARN"]
  if {$insts == "" || ![llength $off]} {
    error "proc genCmd_createRouteBlk: check your input: insts($insts) is empty or off($off) is empty!!!"
  } else {
    set cmdsList [list ]
    foreach inst $insts {
      if {[dbget top.insts.name $inst -e] == ""} {
        error "proc genCmd_createRouteBlk: inst($inst) not found!!!" 
      } else {
        set boxes {*}[dbget [dbget top.insts.name $inst -p].boxes -e]
        if {$boxes == ""} {puts "$promptWARN: inst($inst) have no boxes" ; continue} else { 
          lappend cmdsList "# for inst : $inst | off: $off" }
        foreach box $boxes {
          set box_offed [adjust_rectangle $box $off]
          lappend cmdsList "createRouteBlk -box $box_offed -layer \{$layer\} -cutLayer \{$cutLayer\} [if {$ifPgNetOnly} {set temp "-pgnetonly"}]"
        }
      }
    }
    return $cmdsList
  }
}

if {0} {
  set mem [lrange [dbget [dbget top.insts.cell.subClass block -p2].name] 0 end-2]
  set off 1.9
  set mem_cmd [genCmd_createRouteBlk $mem $off {1 2 3 4} {1 2 3 4} 1]
  batchRunCmd_forProc_genCmd $mem_cmd
  set ip [list U_ANARF_TOP U_PMU_TOP]
  set off 9.5
  set ip_cmd [genCmd_createRouteBlk $ip $off {1 2 3 4 5 6 7 8} {1 2 3 4 5 6 7 8} 1]
  batchRunCmd_forProc_genCmd $ip_cmd
}
